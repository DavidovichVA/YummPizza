import SwiftyJSON
import RealmSwift

final class RequestModelHelper
{
   class func updateUserData(_ user : User, _ data : [String : JSON])
   {
      guard !user.isInvalidated else { return }
      if let string = data["phone"]?.stringValue, string != user.phoneNumber { return }
      
      user.modifyWithTransactionIfNeeded
      {
         user.name = data["name"]?.stringValue ?? ""
         user.email = data["email"]?.stringValue ?? ""
         if let num = data["bonuses"]?.number {
            if let points = user.bonusPoints { points.value = num.decimalValue }
            else { user.bonusPoints = DecimalObject(number: num) }
         }
         if let string = data["gender"]?.stringValue, let gender = Gender(rawValue: string) { user.gender = gender }
         else { user.gender = Gender.unknown }
        
         if let string = data["birthday"]?.stringValue, let date = DMYDate(fromString: string) { user.birthday = date }
         else { user.birthday = nil }
        
         if let bool = data["pushEnabled"]?.boolValue { user.allowPushNotifications = bool }
      }
   }
   
   class func updateUserBonuses(_ user : User, _ bonusesData : [JSON])
   {
      guard !user.isInvalidated else { return }
      
      user.modifyWithTransactionIfNeeded
      {
         var bonus : Bonus
         var i = 0
         
         for bonusData in bonusesData
         {
            guard let bonusDict = bonusData.dictionary else { continue }
            guard let id = bonusDict["id"]?.int64 else { continue }
            
            if i < user.bonuses.count, let index = user.bonuses.suffix(from: i).index(where: { $0.id == id })
            {
               if index != i {
                  user.bonuses.move(from: index, to: i)
               }
               bonus = user.bonuses[i]
            }
            else
            {
               bonus = Bonus()
               bonus.id = id
               user.bonuses.insert(bonus, at: i)
            }
            
            if let num = bonusDict["bonusSum"]?.number {
               if let sum = bonus.bonusSum { if sum.value != num.decimalValue {sum.value = num.decimalValue} }
               else { bonus.bonusSum = DecimalObject(number: num) }
            }
            if let num = bonusDict["orderSum"]?.number {
               if let sum = bonus.orderSum { if sum.value != num.decimalValue {sum.value = num.decimalValue} }
               else { bonus.orderSum = DecimalObject(number: num) }
            }
            
            if let num = bonusDict["createDate"]?.double
            {
               let date = Date(timeIntervalSince1970: num/1000)
               if bonus.date != date {bonus.date = date}
            }
            else if bonus.date != nil {
               bonus.date = nil
            }
            
            i += 1
         }
         
         user.realm?.cascadeDelete(user.bonuses.suffix(from: i))
      }
   }
   
   class func updatePizzeriasList(_ data : [String : JSON]) -> Bool
   {
      guard let pointsArray = data["points"]?.array else { return false }
      guard let polygonsArray = data["polygons"]?.array else { return false }
      guard let hash = data["hash"]?.string else { return false }
      
      var pizzerias : [Pizzeria] = []
      for pointData in pointsArray
      {
         let pizzeria = Pizzeria()
         pizzeria.id = pointData["pizzeriaId"].int64Value
         pizzeria.city = pointData["address"]["city"].stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
         pizzeria.street = pointData["address"]["street"].stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
         pizzeria.house = pointData["address"]["home"].stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
         pizzeria.workingTime = pointData["workingTime"].stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
         pizzeria.phone = String(pointData["contactPhone"].stringValue.characters.filter({decimalDigits.contains($0)}))
         let coordinate = Coordinate()
         coordinate.latitude = pointData["lat"].doubleValue
         coordinate.longitude = pointData["lng"].doubleValue
         pizzeria.coordinate = coordinate
         pizzerias.append(pizzeria)
      }
      
      var polygons : [PizzeriaPolygon] = []
      for polygonData in polygonsArray
      {
         guard let polygonPoints = polygonData.array else { continue }
         
         let polygon = PizzeriaPolygon()
         for polygonPointData in polygonPoints
         {
            let point = Coordinate()
            point.latitude = polygonPointData["lat"].doubleValue
            point.longitude = polygonPointData["lng"].doubleValue
            polygon.points.append(point)
         }
         
         polygons.append(polygon)
      }
      
      let realm = Realm.main
      realm.writeWithTransactionIfNeeded
      {
         let list = PizzeriaList.list

         var i = 0
         
         for pizzeria in pizzerias
         {
            if i < list.pizzerias.count, let index = list.pizzerias.suffix(from: i).index(where: { $0.id == pizzeria.id })
            {
               if index != i {
                  list.pizzerias.move(from: index, to: i)
               }
               let oldPizzeria = list.pizzerias[i]
               
               if oldPizzeria.city != pizzeria.city { oldPizzeria.city = pizzeria.city }
               if oldPizzeria.street != pizzeria.street { oldPizzeria.street = pizzeria.street }
               if oldPizzeria.house != pizzeria.house { oldPizzeria.house = pizzeria.house }
               if oldPizzeria.workingTime != pizzeria.workingTime { oldPizzeria.workingTime = pizzeria.workingTime }
               if oldPizzeria.phone != pizzeria.phone { oldPizzeria.phone = pizzeria.phone }
               if (oldPizzeria.coordinate.latitude != pizzeria.coordinate.latitude)
                  || (oldPizzeria.coordinate.longitude != pizzeria.coordinate.longitude)
               {
                  realm.delete(oldPizzeria.coordinate)
                  oldPizzeria.coordinate = pizzeria.coordinate
               }               
            }
            else
            {
               list.pizzerias.insert(pizzeria, at: i)
            }
            
            i += 1
         }
         
         realm.cascadeDelete(list.pizzerias.suffix(from: i))
         
         realm.cascadeDelete(list.pizzeriasAreas)
         list.pizzeriasAreas.append(objectsIn: polygons)
         list.pizzeriasHash = hash
         list.lastUpdate = Date()
      }
      
      return true
   }
   
   
   class func updateStreetList(_ data : [String : JSON]) -> Bool
   {
      guard let streetsArray = data["streets"]?.array else { return false }
      guard let hash = data["hash"]?.string else { return false }
      
      var streets : [Street] = []
      for streetData in streetsArray
      {
         guard let streetId = streetData["id"].string, !streetId.isEmpty else { continue }
         guard let streetName = streetData["name"].string, !streetName.isEmpty else { continue }
         
         let street = Street()
         street.id = streetId
         street.name = streetName
         street.uppercasedName = streetName.uppercased()
         street.flattenedName = String(streetName.characters.filter({!Street.charsToFlatten.contains($0)})).uppercased()
         
         streets.append(street)
      }
      
      let realm = Realm.main
      realm.writeWithTransactionIfNeeded
      {
         let list = StreetList.list
         realm.delete(list.streets)
         
         list.streets.append(objectsIn: streets)
         list.streetsHash = hash
         list.lastUpdate = Date()
      }
      
      return true
   }
   
   
   class func updateCommonValues(_ data : [String : JSON]) -> Bool
   {
      guard let settingsArray = data["settings"]?.array else { return false }
      
      var commonValues : [CommonValue] = []
      for settingData in settingsArray
      {
         if let key = settingData["key"].string, !key.isEmpty
         {
            let commonValue = CommonValue()
            commonValue.key = key
            commonValue.value = settingData["value"].stringValue
            commonValue.desc = settingData["description"].stringValue
            commonValue.isEnabled = settingData["displayInMobile"].boolValue
            commonValues.append(commonValue)
         }
      }
      
      let realm = Realm.main
      realm.writeWithTransactionIfNeeded
      {
         realm.add(commonValues, update: true)
      }
      
      return true
   }
   
   
   class func updateDishList(_ data : [String : JSON]) -> Bool
   {
      guard let hash = data["hash"]?.string else { return false }
      guard let toppingsArray = data["toppings"]?.array else { return false }
      guard let cheeseBordersArray = data["cheeseBorders"]?.array else { return false }
      guard let dishesArray = data["products"]?.array else { return false }
      
      let realm = Realm.main
      realm.writeWithTransactionIfNeeded
      {
         let list = DishList.list
         
         var oldToppings = list.allToppings.toArray()
         list.allToppings.removeAll()
         var topping : Topping
         for toppingData in toppingsArray
         {
            guard let id = toppingData["toppingId"].string, !id.isEmpty else { continue }
 
            if let index = oldToppings.index(where: { $0.id == id } ) {
               topping = oldToppings[index]
               oldToppings.remove(at: index)
            }
            else {
               topping = Topping()
               topping.id = id
            }
            
            if let string = toppingData["name"].string { topping.name = string }
            if let string = toppingData["weight"].string { topping.weightString = string }
            if let num = toppingData["price"].number {
               if let price = topping.price { price.value = num.decimalValue }
               else { topping.price = DecimalObject(number: num) }
            }
            
            list.allToppings.append(topping)
         }
         realm.cascadeDelete(oldToppings)
         
         var oldCheeseBorders = list.allCheeseBorders.toArray()
         list.allCheeseBorders.removeAll()
         var cheeseBorder : CheeseBorder
         for cheeseBorderData in cheeseBordersArray
         {
            guard let id = cheeseBorderData["cheeseBorderId"].string, !id.isEmpty else { continue }
  
            if let index = oldCheeseBorders.index(where: { $0.id == id } ) {
               cheeseBorder = oldCheeseBorders[index]
               oldCheeseBorders.remove(at: index)
            }
            else {
               cheeseBorder = CheeseBorder()
               cheeseBorder.id = id
            }
            
            if let string = cheeseBorderData["name"].string { cheeseBorder.name = string }
            if let num = cheeseBorderData["price"].number {
               if let price = cheeseBorder.price { price.value = num.decimalValue }
               else { cheeseBorder.price = DecimalObject(number: num) }
            }
            
            list.allCheeseBorders.append(cheeseBorder)
         }
         realm.cascadeDelete(oldCheeseBorders)
         
         var oldDishes = list.allDishes
         list.combos.removeAll()
         list.pizzas.removeAll()
         list.drinks.removeAll()
         list.hotDishes.removeAll()
         list.snacks.removeAll()
         list.desserts.removeAll()

         var dish : Dish
         for dishData in dishesArray
         {
            guard let id = dishData["productId"].string, !id.isEmpty else { continue }
            
            if let index = oldDishes.index(where: { $0.id == id } ) {
               dish = oldDishes[index]
               oldDishes.remove(at: index)
            }
            else {
               dish = Dish()
               dish.id = id
            }
            
            guard let variantsArray = dishData["variants"].array, !variantsArray.isEmpty else {
               dish.realm?.cascadeDelete(dish)
               continue
            }
            
            dish.sortValue = dishData["sort"].intValue
            
            if let num = dishData["price"].number {
               if let price = dish.price { price.value = num.decimalValue }
               else { dish.price = DecimalObject(number: num) }
            }
            if let num = dishData["oldPrice"].number {
               if let price = dish.oldPrice { price.value = num.decimalValue }
               else { dish.oldPrice = DecimalObject(number: num) }
            }
            else {
               dish.oldPrice?.realm?.delete(dish.oldPrice!)
               dish.oldPrice = nil
            }
            
            if let num = dishData["categoryId"].int, let type = DishType(rawValue: num)
            {
               dish.typeInt = num
               switch type
               {
               case .pizza: list.pizzas.append(dish)
               case .hotDishes: list.hotDishes.append(dish)
               case .snacks: list.snacks.append(dish)
               case .drinks: list.drinks.append(dish)
               case .desserts: list.desserts.append(dish)
               case .combo: list.combos.append(dish)
               }
            }
            else
            {
               dish.realm?.cascadeDelete(dish)
               continue
            }
            
            if let string = dishData["description"].string { dish.dishDescription = string }
            if let string = dishData["name"].string { dish.name = string.uppercased() }
            if let string = dishData["photoUrl"].string { dish.imageLink = string }
            if let string = dishData["variantsType"].string { dish.dishVariantsType = string.uppercased() }
            
            dish.toppingsGroupId = dishData["toppingsGroupId"].stringValue
            dish.toppings.removeAll()
            if let toppingsArray = dishData["toppings"].array
            {
               for toppingData in toppingsArray
               {
                  guard let toppingId = toppingData.string, !toppingId.isEmpty else { continue }
                  if let topping = list.allToppings.first(where: { $0.id == toppingId }) {
                     dish.toppings.append(topping)
                  }
               }
            }
            
            var oldVariants = dish.dishVariants.toArray()
            dish.dishVariants.removeAll()
            var dishVariant : DishVariant
            for variantData in variantsArray
            {
               guard let id = variantData["variantId"].string, !id.isEmpty else { continue }
               
               if let index = oldVariants.index(where: { $0.id == id } ) {
                  dishVariant = oldVariants[index]
                  oldVariants.remove(at: index)
               }
               else {
                  dishVariant = DishVariant()
                  dishVariant.id = id
               }
               dish.dishVariants.append(dishVariant)
               if let num = variantData["price"].number {
                  if let price = dishVariant.price { price.value = num.decimalValue }
                  else { dishVariant.price = DecimalObject(number: num) }
               }
               if let string = variantData["measureUnit"].string { dishVariant.name = string }
               if let num = variantData["carbohydrateAmount"].double { dishVariant.carbohydrates = num }
               if let num = variantData["energyAmount"].double { dishVariant.calories = num }
               if let num = variantData["fatAmount"].double { dishVariant.fats = num }
               if let num = variantData["fiberAmount"].double { dishVariant.proteins = num }
               if let bool = variantData["forbiddenToPayWithBonuses"].bool { dishVariant.canPayWithBonuses = !bool }
               
               if let string = variantData["cheeseBorder"].string,
                  let cheeseBorder = list.allCheeseBorders.first(where: { $0.id == string })
               {
                  dishVariant.cheeseBorderGroupId = variantData["cheeseBorderGroupId"].stringValue
                  dishVariant.cheeseBorder = cheeseBorder
               }
               else {
                  dishVariant.cheeseBorderGroupId = ""
                  dishVariant.cheeseBorder = nil
               }
               
               if let doughVariantsArray = variantData["dough"].array
               {
                  var oldDoughVariants = dishVariant.doughVariants.toArray()
                  dishVariant.doughVariants.removeAll()
                  var dough : Dough
                  for doughData in doughVariantsArray
                  {
                     guard let id = doughData["doughId"].string, !id.isEmpty else { continue }
                     
                     if let index = oldDoughVariants.index(where: { $0.id == id } ) {
                        dough = oldDoughVariants[index]
                        oldDoughVariants.remove(at: index)
                     }
                     else {
                        dough = Dough()
                        dough.id = id
                     }
                     
                     if let string = doughData["name"].string { dough.name = string }
                     dough.groupId = doughData["doughGroupId"].stringValue
                     
                     dishVariant.doughVariants.append(dough)
                  }
                  realm.delete(oldDoughVariants)
               }
               else {
                  dishVariant.doughVariants.removeAll()
               }
            }
            realm.cascadeDelete(oldVariants)
            
            if dish.dishVariants.isEmpty {
               dish.realm?.cascadeDelete(dish)
            }
         }
         realm.cascadeDelete(oldDishes)

         var sortedArray : [Dish]
         
         sortedArray = list.combos.sorted(byKeyPath: "sortValue").toArray()
         list.combos.removeAll()
         list.combos.append(objectsIn: sortedArray)
         sortedArray = list.pizzas.sorted(byKeyPath: "sortValue").toArray()
         list.pizzas.removeAll()
         list.pizzas.append(objectsIn: sortedArray)
         sortedArray = list.drinks.sorted(byKeyPath: "sortValue").toArray()
         list.drinks.removeAll()
         list.drinks.append(objectsIn: sortedArray)
         sortedArray = list.hotDishes.sorted(byKeyPath: "sortValue").toArray()
         list.hotDishes.removeAll()
         list.hotDishes.append(objectsIn: sortedArray)
         sortedArray = list.snacks.sorted(byKeyPath: "sortValue").toArray()
         list.snacks.removeAll()
         list.snacks.append(objectsIn: sortedArray)
         sortedArray = list.desserts.sorted(byKeyPath: "sortValue").toArray()
         list.desserts.removeAll()
         list.desserts.append(objectsIn: sortedArray)
         
         list.allDishes.removeAll()
         list.allDishes.append(objectsIn: list.combos)
         list.allDishes.append(objectsIn: list.pizzas)
         list.allDishes.append(objectsIn: list.drinks)
         list.allDishes.append(objectsIn: list.hotDishes)
         list.allDishes.append(objectsIn: list.snacks)
         list.allDishes.append(objectsIn: list.desserts)
         
         sortedArray = list.allDishes.sorted(byKeyPath: "sortValue").toArray()
         list.allDishes.removeAll()
         list.allDishes.append(objectsIn: sortedArray)
         
         list.dishesHash = hash
         list.lastUpdate = Date()
      }
      
      return true
   }
   
   
   class func updateSalesList(_ salesData : [JSON])
   {
      let salesList = SalesList.list
      let realm = Realm.main
      realm.writeWithTransactionIfNeeded
      {
         var sale : Sale
         var i = 0
         
         for saleData in salesData
         {
            guard let saleDict = saleData.dictionary else { continue }
            guard let id = saleDict["id"]?.int64 else { continue }
            
            if i < salesList.sales.count, let index = salesList.sales.suffix(from: i).index(where: { $0.id == id })
            {
               if index != i {
                  salesList.sales.move(from: index, to: i)
               }
               sale = salesList.sales[i]
            }
            else
            {
               sale = Sale()
               sale.id = id
               salesList.sales.insert(sale, at: i)
            }
            
            if let string = saleDict["title"]?.string, string != sale.name {
               sale.name = string
            }
            if let string = saleDict["photoUrl"]?.string, string != sale.imageLink {
               sale.imageLink = string
            }
            if let string = saleDict["description"]?.string, string != sale.saleDescription {
               sale.saleDescription = string
            }

            sale.updateType(saleDict["deliveryType"]?.string)
            
            if let width = saleDict["pictureWidth"]?.double, width > 0,
               let height = saleDict["pictureHeight"]?.double, height > 0
            {
               let ratio = width / height
               if ratio != sale.imageAspectRatio {
                  sale.imageAspectRatio = ratio
               }
            }
            
            if let dishesArray = saleDict["listOfProducts"]?.array
            {
               var dish : SaleDish
               var j = 0
               
               for dishData in dishesArray
               {
                  guard let dishDict = dishData.dictionary else { continue }
                  guard let id = dishDict["id"]?.string, !id.isEmpty else { continue }
                  guard let variantsArray = dishDict["listOfVariants"]?.array, !variantsArray.isEmpty else { continue }
                  
                  if j < sale.dishes.count, let index = sale.dishes.suffix(from: j).index(where: { $0.id == id })
                  {
                     if index != j {
                        sale.dishes.move(from: index, to: j)
                     }
                     dish = sale.dishes[j]
                  }
                  else
                  {
                     dish = SaleDish()
                     dish.id = id
                     sale.dishes.insert(dish, at: j)
                  }
                  
                  if let string = dishData["name"].string?.uppercased(), string != dish.name {
                     dish.name = string
                  }
                  
                  var variant : SaleDishVariant
                  var k = 0
                  for variantData in variantsArray
                  {
                     guard let variantDict = variantData.dictionary else { continue }
                     guard let id = variantDict["id"]?.string, !id.isEmpty else { continue }
                     
                     if k < dish.variants.count, let index = dish.variants.suffix(from: k).index(where: { $0.id == id })
                     {
                        if index != k {
                           dish.variants.move(from: index, to: k)
                        }
                        variant = dish.variants[k]
                     }
                     else
                     {
                        variant = SaleDishVariant()
                        variant.id = id
                        dish.variants.insert(variant, at: k)
                     }
                     
                     if let string = variantData["name"].string?.uppercased(), string != variant.name {
                        variant.name = string
                     }
                     
                     k += 1
                  }
                  dish.realm?.cascadeDelete(dish.variants.suffix(from: k))
                  
                  j += 1
               }
               
               sale.realm?.cascadeDelete(sale.dishes.suffix(from: j))
            }
            
            if let giftsArray = saleDict["listOfGifts"]?.array
            {
               var gift : SaleGift
               var j = 0
               
               for giftData in giftsArray
               {
                  guard let giftDict = giftData.dictionary else { continue }
                  guard let id = giftDict["id"]?.string, !id.isEmpty else { continue }
                  
                  if j < sale.gifts.count, let index = sale.gifts.suffix(from: j).index(where: { $0.id == id })
                  {
                     if index != j {
                        sale.gifts.move(from: index, to: j)
                     }
                     gift = sale.gifts[j]
                  }
                  else
                  {
                     gift = SaleGift()
                     gift.id = id
                     sale.gifts.insert(gift, at: j)
                  }
                  
                  if let string = giftData["name"].string, string != gift.name {
                     gift.name = string
                  }
                  
                  j += 1
               }
               
               sale.realm?.cascadeDelete(sale.gifts.suffix(from: j))
            }
            else if !sale.gifts.isEmpty
            {
               realm.delete(sale.gifts)
               sale.gifts.removeAll()
            }
            
            i += 1
         }
         
         realm.cascadeDelete(salesList.sales.suffix(from: i))
      }
   }
   
   /// returns new, unpersisted objects
   class func salesFromData(_ dataArray : [JSON]) -> [Sale]
   {
      var sales : [Sale] = []
      for saleData in dataArray
      {
         if let saleData = saleData.dictionary, let sale = saleFromData(saleData) {
            sales.append(sale)
         }
      }
      return sales
   }
   
   /// returns new, unpersisted object
   class func saleFromData(_ data : [String : JSON]) -> Sale?
   {
      guard let id = data["id"]?.int64, id != 0 else { return nil }
      
      let sale = Sale()
      sale.id = id
      sale.name = data["title"]?.string ?? ""
      sale.imageLink = data["photoUrl"]?.string
      sale.saleDescription = data["description"]?.string ?? ""
      sale.updateType(data["deliveryType"]?.string)
      
      if let width = data["pictureWidth"]?.double, width > 0,
         let height = data["pictureHeight"]?.double, height > 0
      {
         sale.imageAspectRatio = width / height
      }
      
      if let giftsArray = data["listOfGifts"]?.array
      {
         for giftData in giftsArray
         {
            let gift = SaleGift()
            gift.id = giftData["id"].stringValue
            gift.name = giftData["name"].stringValue
            sale.gifts.append(gift)
         }
      }
      
      return sale
   }
   
   /// returns new, unpersisted objects
   class func recommendationsFromData(_ dataArray : [JSON]) -> [Dish]
   {
      var recommendations : [Dish] = []
      for recommendationData in dataArray
      {
         if let recommendationData = recommendationData.dictionary,
            let recommendation = recommendationFromData(recommendationData) {
            recommendations.append(recommendation)
         }
      }
      return recommendations
   }
   
   /// returns new, unpersisted object
   class func recommendationFromData(_ data : [String : JSON]) -> Dish?
   {
      guard let id = data["productId"]?.string, !id.isEmpty else { return nil }
      guard let typeInt = data["categoryId"]?.int, let type = DishType(rawValue: typeInt) else { return nil }
      guard let variantsArray = data["variants"]?.array, !variantsArray.isEmpty else { return nil }
      
      let recommendation = Dish()
      recommendation.id = id
      recommendation.type = type
      recommendation.name = data["name"]?.string?.uppercased() ?? ""
      recommendation.dishDescription = data["description"]?.string ?? ""
      recommendation.imageLink = data["photoUrl"]?.string ?? ""
      if let num = data["price"]?.number { recommendation.price = DecimalObject(number: num) }
      if let num = data["oldPrice"]?.number { recommendation.oldPrice = DecimalObject(number: num) }
      
      let dishList = DishList.list
      
      recommendation.toppingsGroupId = data["toppingsGroupId"]?.string ?? ""
      if let toppingsArray = data["toppings"]?.array
      {
         for toppingData in toppingsArray
         {
            guard let toppingId = toppingData.string, !toppingId.isEmpty else { continue }
            if let topping = dishList.allToppings.first(where: { $0.id == toppingId }) {
               recommendation.toppings.append(topping)
            }
         }
      }
      
      recommendation.dishVariantsType = data["variantsType"]?.string?.uppercased() ?? ""
      for variantData in variantsArray
      {
         guard let id = variantData["variantId"].string, !id.isEmpty else { continue }
         
         let dishVariant = DishVariant()
         dishVariant.id = id
         if let num = variantData["price"].number { dishVariant.price = DecimalObject(number: num) }
         if let string = variantData["measureUnit"].string { dishVariant.name = string }
         if let num = variantData["carbohydrateAmount"].double { dishVariant.carbohydrates = num }
         if let num = variantData["energyAmount"].double { dishVariant.calories = num }
         if let num = variantData["fatAmount"].double { dishVariant.fats = num }
         if let num = variantData["fiberAmount"].double { dishVariant.proteins = num }
         if let bool = variantData["forbiddenToPayWithBonuses"].bool { dishVariant.canPayWithBonuses = !bool }
         
         if let string = variantData["cheeseBorder"].string,
            let cheeseBorder = dishList.allCheeseBorders.first(where: { $0.id == string })
         {
            dishVariant.cheeseBorderGroupId = variantData["cheeseBorderGroupId"].stringValue
            dishVariant.cheeseBorder = cheeseBorder
         }
         else {
            dishVariant.cheeseBorderGroupId = ""
            dishVariant.cheeseBorder = nil
         }
         
         if let doughVariantsArray = variantData["dough"].array
         {
            for doughData in doughVariantsArray
            {
               guard let id = doughData["doughId"].string, !id.isEmpty else { continue }
               let dough = Dough()
               dough.id = id
               dough.name = doughData["name"].stringValue
               dough.groupId = doughData["doughGroupId"].stringValue
               
               dishVariant.doughVariants.append(dough)
            }
         }
         
         recommendation.dishVariants.append(dishVariant)
      }
      
      return recommendation
   }
   
   
   class func createOrderParams(isRegistered: Bool) -> [String : Any]
   {
      var params : [String : Any] = [:]
      
      if let addressType = OrderAddress
      {
         switch addressType
         {
         case .user(let address):
            params["city"] = address.city
            params["street"] = address.street
            var houseString = address.house
            if let blockValue = address.block, !blockValue.isEmpty {
               houseString += "к\(blockValue)"
            }
            params["home"] = houseString
            params["apartment"] = address.apartment ?? ""
            params["selfService"] = false
            
            if let coordinate = address.coordinate?.coordinate2D, let pizzeria = coordinate.closestPizzeria() {
               params["restaurantPhone"] = pizzeria.phone
            }
            else {
               params["restaurantPhone"] = ""
            }
            
         case .pizzeria(let pizzeria):
            params["city"] = pizzeria.city
            params["street"] = pizzeria.street
            params["home"] = pizzeria.house
            params["selfService"] = true
            params["restaurantPhone"] = pizzeria.phone
         }
      }
      
      let dateFormatter = DateFormatter()
      dateFormatter.calendar = calendar
      dateFormatter.timeZone = calendar.timeZone
      dateFormatter.locale = locale
      dateFormatter.dateFormat = "y-MM-dd HH:mm:ss"
      
      params["promoCode"] = OrderPromoCode ?? ""
      params["comment"] = OrderComment ?? ""
      params["paymentByCard"] = !OrderPaymentByCash
      
      if isRegistered
      {
         params["pushEnabled"] = OrderReceiveNotifications
         params["date"] = dateFormatter.string(from: Date())
      }
      else
      {
         if OrderReceiveNotifications, let pushToken = AppDelegate.pushToken, !pushToken.isEmpty
         {
            params["pushEnabled"] = true
            params["deviceId"] = pushToken
         }
         else
         {
            params["pushEnabled"] = false
            params["deviceId"] = ""
         }
         params["deviceType"] = "IOS"
         
         params["name"] = OrderName ?? ""
         params["phone"] = OrderPhone ?? ""
      }

      if OrderPaymentWithBonuses > 0, isRegistered {
         params["discountSum"] = OrderPaymentWithBonuses
      }

      var items : [[String : Any]] = []
      for cartItem in Cart.items
      {
         var itemDict : [String : Any] = [:]
         itemDict["id"] = cartItem.dishVariant.id
         itemDict["name"] = cartItem.dish.name
         itemDict["amount"] = cartItem.count
         itemDict["variantsType"] = cartItem.dish.dishVariantsType
         itemDict["measureUnit"] = cartItem.dishVariant.name
         
         if let cheeseBorder = cartItem.cheeseBorder
         {
            itemDict["cheeseBorder"] = ["id": cheeseBorder.id,
                                        "groupId": cartItem.dishVariant.cheeseBorderGroupId,
                                        "name": cheeseBorder.name,
                                        "amount": 1]
         }
         if let dough = cartItem.dough
         {
            itemDict["dough"] = ["id": dough.id,
                                 "groupId": dough.groupId,
                                 "name": dough.name,
                                 "amount": 1]
         }
         
         if !cartItem.toppingCounts.isEmpty
         {
            var toppings : [[String : Any]] = []
            for toppingCount in cartItem.toppingCounts
            {
               toppings.append(["id": toppingCount.topping.id,
                                "groupId": cartItem.dish.toppingsGroupId,
                                "name": toppingCount.topping.name,
                                "amount": toppingCount.count])
            }
            
            itemDict["toppings"] = toppings
         }
         
         items.append(itemDict)
      }
      
      params["items"] = items
      
      return params
   }
   
   
   /// returns persisted objects
   class func ordersFromData(_ dataArray : [JSON]) -> [Order]
   {
      var orders : [Order] = []
      let realm = Realm.main
      realm.writeWithTransactionIfNeeded
      {
         for orderData in dataArray
         {
            if let orderData = orderData.dictionary, let order = orderFromData(orderData, realm: realm) {
               orders.append(order)
            }
         }
      }
      return orders
   }
   
   /// returns persisted object
   class func orderFromData(_ data : [String : JSON], realm : Realm = Realm.main) -> Order?
   {
      guard let id = data["id"]?.int64, id != 0 else { return nil }

      var order : Order!
      
      realm.writeWithTransactionIfNeeded
      {
         order = realm.object(ofType: Order.self, forPrimaryKey: id)
         if order == nil
         {
            order = Order()
            order.id = id
            realm.add(order)
         }
         
         if let string = data["status"]?.string, string != order.statusCode {
            order.statusCode = string
         }
         if let num = data["time"]?.double {
            let date = Date(timeIntervalSince1970: num/1000)
            if date != order.date { order.date = date }
         }
         if let num = data["sum"]?.number {
            if let sum = order.sum { sum.value = num.decimalValue }
            else { order.sum = DecimalObject(number: num) }
         }
         if let bool = data["pushEnabled"]?.bool, bool != order.pushEnabled {
            order.pushEnabled = bool
         }
         if let string = data["promoCode"]?.string, string != order.promoCode {
            order.promoCode = string
         }
         if let phoneDigits = data["restaurantPhone"]?.string?.characters.filter({decimalDigits.contains($0)})
         {
            let string = String(phoneDigits)
            if string != order.operatorPhoneNumber {
               order.operatorPhoneNumber = string
            }
         }

         if let bool = data["selfService"]?.bool, bool != order.pickup {
            order.pickup = bool
         }
         
         
         if let string = data["itemsJson"]?.string, let itemsArray = JSON(parseJSON: string).array
         {
            var dish : OrderDish
            var i = 0
            
            for itemData in itemsArray
            {
               guard let itemDict = itemData.dictionary else { continue }
               guard let id = itemDict["id"]?.stringValue, !id.isEmpty else { continue }
               
               if i < order.dishes.count, let index = order.dishes.suffix(from: i).index(where: { $0.id == id })
               {
                  if index != i {
                     order.dishes.move(from: index, to: i)
                  }
                  dish = order.dishes[i]
               }
               else
               {
                  dish = OrderDish()
                  dish.id = id
                  order.dishes.insert(dish, at: i)
               }
               
               if let string = itemDict["name"]?.string?.uppercased(), string != dish.name {
                  dish.name = string
               }
               let dishAmount = itemDict["amount"]?.intValue ?? 1
               if dishAmount != dish.count {
                  dish.count = dishAmount
               }
               if let string = itemDict["variantsType"]?.string?.uppercased(), string != dish.variantType {
                  dish.variantType = string
               }
               if let string = itemDict["measureUnit"]?.string, string != dish.variantName {
                  dish.variantName = string
               }
               
               
               if let doughDict = itemDict["dough"]?.dictionary, let doughId = doughDict["id"]?.string, !doughId.isEmpty
               {
                  let dough : OrderDough
                  if let dishDough = dish.dough
                  {
                     dough = dishDough
                     if dough.id != doughId {
                        dough.id = doughId
                     }
                  }
                  else {
                     dough = OrderDough()
                     dough.id = doughId
                     dish.dough = dough
                  }
                  
                  if let string = doughDict["name"]?.string, string != dough.name {
                     dough.name = string
                  }
                  if let string = doughDict["groupId"]?.string, string != dough.groupId {
                     dough.groupId = string
                  }
               }
               else if let dough = dish.dough
               {
                  dish.dough = nil
                  dough.realm?.delete(dough)
               }
               
               
               if let cheeseBorderDict = itemDict["cheeseBorder"]?.dictionary, let cheeseBorderId = cheeseBorderDict["id"]?.string, !cheeseBorderId.isEmpty
               {
                  let cheeseBorder : OrderCheeseBorder
                  if let dishCheeseBorder = dish.cheeseBorder
                  {
                     cheeseBorder = dishCheeseBorder
                     if cheeseBorder.id != cheeseBorderId {
                        cheeseBorder.id = cheeseBorderId
                     }
                  }
                  else {
                     cheeseBorder = OrderCheeseBorder()
                     cheeseBorder.id = cheeseBorderId
                     dish.cheeseBorder = cheeseBorder
                  }
                  
                  if let string = cheeseBorderDict["name"]?.string, string != cheeseBorder.name {
                     cheeseBorder.name = string
                  }
                  if let string = cheeseBorderDict["groupId"]?.string, string != cheeseBorder.groupId {
                     cheeseBorder.groupId = string
                  }
               }
               else if let cheeseBorder = dish.cheeseBorder
               {
                  dish.cheeseBorder = nil
                  cheeseBorder.realm?.delete(cheeseBorder)
               }
               
               
               if let toppingsArray = itemDict["toppings"]?.array
               {
                  var topping : OrderTopping
                  var j = 0
                  
                  for toppingData in toppingsArray
                  {
                     guard let toppingDict = toppingData.dictionary else { continue }
                     guard let id = toppingDict["id"]?.stringValue, !id.isEmpty else { continue }
                     
                     if j < dish.toppings.count, let index = dish.toppings.suffix(from: j).index(where: { $0.id == id })
                     {
                        if index != j {
                           dish.toppings.move(from: index, to: j)
                        }
                        topping = dish.toppings[j]
                     }
                     else
                     {
                        topping = OrderTopping()
                        topping.id = id
                        dish.toppings.insert(topping, at: j)
                     }
                     
                     if let string = toppingDict["name"]?.string, string != topping.name {
                        topping.name = string
                     }
                     if let string = toppingDict["groupId"]?.string, string != topping.groupId {
                        topping.groupId = string
                     }
                     let toppingAmount = toppingDict["amount"]?.intValue ?? 1
                     if toppingAmount != topping.count {
                        topping.count = toppingAmount
                     }
                     
                     j += 1
                  }
                  
                  dish.realm?.cascadeDelete(dish.toppings.suffix(from: j))
               }
               
               i += 1
            }
            
            order.realm?.cascadeDelete(order.dishes.suffix(from: i))
         }
      }

      return order
   }
   
   
   /// returns whether orders were added or removed from active
   class func updateOrdersStatus(orders : [Order], statusesData : [JSON]) -> Bool
   {
      var orders = orders
      var ordersListChanged = false
      
      for statusData in statusesData
      {
         guard let id = statusData["id"].int64, id != 0 else { continue }
         if let index = orders.index(where: {$0.id == id})
         {
            let order = orders[index]
            let statusCode = statusData["status"].stringValue
            
            if order.statusCode != statusCode
            {
               order.modifyWithTransactionIfNeeded {
                  order.statusCode = statusCode
               }
            }
            
            switch statusCode
            {
            case "CLOSED", "CANCELLED": ordersListChanged = true
            default: break
            }
            
            orders.remove(at: index)
         }
         else
         {
            ordersListChanged = true
         }
      }
      
      if !orders.isEmpty {
         ordersListChanged = true
      }
      
      return ordersListChanged
   }
   
   
   class func updateOrdersHistory(_ user : User, _ ordersData : [JSON])
   {
      guard !user.isInvalidated else { return }
      
      user.modifyWithTransactionIfNeeded
      {
         var i = 0
         
         for orderData in ordersData
         {
            guard let orderDict = orderData.dictionary, let order = orderFromData(orderDict) else { continue }
           
            if let index = user.ordersHistory.suffix(from: i).index(of: order)
            {
               if index != i {
                  user.ordersHistory.move(from: index, to: i)
               }
            }
            else
            {
               user.ordersHistory.insert(order, at: i)
            }
            
            i += 1
         }
         
         user.realm?.cascadeDelete(user.ordersHistory.suffix(from: i))
      }
   }
}
