//
//  Dish.swift
//  YummPizza
//

import RealmSwift

class Dish : Object
{
   @objc dynamic var id = ""
   
   @objc dynamic var typeInt = 0
   var type : DishType
   {
      get
      {
         if let dishType = DishType(rawValue: typeInt) {
            return dishType
         }
         else {
            dlog("wrong dish type", typeInt)
            return .pizza
         }
      }
      set
      {
         modifyWithTransactionIfNeeded {
            typeInt = newValue.rawValue
         }
      }
   }
   
   @objc dynamic var name = ""
   @objc dynamic var dishDescription = ""
   @objc dynamic var imageLink = ""
   @objc dynamic var dishVariantsType = ""
   @objc dynamic var price : DecimalObject?
   @objc dynamic var oldPrice : DecimalObject?
   @objc dynamic var toppingsGroupId = ""
   @objc dynamic var sortValue = 0
   let toppings = List<Topping>()
   let dishVariants = List<DishVariant>()
   
   override class func ignoredProperties() -> [String] {
      return ["type", "salesVariants"]
   }
   override func propertiesToCascadeDelete() -> [String] {
      return ["dishVariants", "price", "oldPrice"]
   }
   
   ///варианты для акции, non-persisted
   var salesVariants : [DishVariant] = []
   var variants : List<DishVariant> {
      return salesVariants.isEmpty ? dishVariants : List(salesVariants)
   }
   
   var oldPriceString : String { return "\(oldPrice.value) Р" }
   var priceString : String { return "\(price.value) Р" }
   var defaultVariant : DishVariant! { return variants.first }
}

class DishVariant: Object
{
   @objc dynamic var id = ""
   @objc dynamic var name = ""
   @objc dynamic var price : DecimalObject?
   @objc dynamic var canPayWithBonuses = true
   
   /// килокалории
   @objc dynamic var calories : Double = 0.0
   /// белки, г.
   @objc dynamic var proteins : Double = 0.0
   /// жиры, г.
   @objc dynamic var fats : Double = 0.0
   /// углеводы, г.
   @objc dynamic var carbohydrates : Double = 0.0
   
   @objc dynamic var cheeseBorderGroupId = ""
   @objc dynamic var cheeseBorder: CheeseBorder?
   let doughVariants = List<Dough>()
   
   let ownedByDishes = LinkingObjects(fromType: Dish.self, property: "dishVariants")
   var dish : Dish? { return ownedByDishes.first }
   
   override func propertiesToCascadeDelete() -> [String] {
      return ["doughVariants", "price"]
   }
   
   var priceString : String { return "\(price.value) Р" }
   var defaultDough : Dough? {
      return doughVariants.first(where: {$0.name == "Тонкое"}) ?? doughVariants.first
   }
   var hasNutritionalValue : Bool { return calories > 0 }
}


class Topping: Object
{
   @objc dynamic var id = ""
   @objc dynamic var name = ""
   @objc dynamic var weightString = ""
   @objc dynamic var price : DecimalObject?
   
   override func propertiesToCascadeDelete() -> [String] {
      return ["price"]
   }
   
   var fullName : String { return weightString.isEmpty ? name : "\(name) \(weightString)" }
   var priceString : String { return "\(price.value) Р" }
   
   public static func ==(lhs: Topping, rhs: Topping) -> Bool {
      return lhs.hash == rhs.hash
   }
   
   override var hash: Int { return isInvalidated ? 0 : id.hash }
   override var hashValue: Int { return isInvalidated ? 0 : id.hashValue }
}

/// Тесто
class Dough: Object
{
   @objc dynamic var id = ""
   @objc dynamic var groupId = ""
   @objc dynamic var name = ""
}

/// Сырный край
class CheeseBorder: Object
{
   @objc dynamic var id = ""
   @objc dynamic var name = ""
   @objc dynamic var price : DecimalObject?
   
   override func propertiesToCascadeDelete() -> [String] {
      return ["price"]
   }
}
