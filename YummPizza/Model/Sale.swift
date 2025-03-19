//
//  Sale.swift
//  YummPizza
//
//  Created by Blaze Mac on 6/8/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import RealmSwift

struct SaleType : OptionSet
{
   let rawValue: Int
   
   static let delivery = SaleType(rawValue: 1 << 0)
   static let restaurant = SaleType(rawValue: 1 << 1)
   
   static let allTypes : SaleType = [delivery, restaurant]
}

/// список акций
class SalesList: Object
{
   let sales = List<Sale>()
   @objc dynamic var lastUpdate: Date? = nil
   
   var needsUpdate : Bool
   {
      if let lastUpdateTime = lastUpdate {
         return -lastUpdateTime.timeIntervalSinceNow > 3600
      }
      else {
         return true
      }
   }
   
   static var list : SalesList
   {
      let realm = Realm.main
      
      if let salesList = realm.objects(SalesList.self).first {
         return salesList
      }
      else
      {
         let salesList = SalesList()
         realm.writeWithTransactionIfNeeded {
            realm.add(salesList)
         }
         return salesList
      }
   }
   
   func sales(withType type : SaleType) -> Results<Sale>
   {
      if type == .delivery {
         return sales.filter("typeInt == %d OR typeInt == %d", SaleType.delivery.rawValue, SaleType.allTypes.rawValue)
      }
      else if type == .restaurant {
         return sales.filter("typeInt == %d OR typeInt == %d", SaleType.restaurant.rawValue, SaleType.allTypes.rawValue)
      }
      else {
         return sales.filter("typeInt == %d", type.rawValue)
      }
   }
   
   func update(onlyIfNeeded : Bool = true, success : @escaping SuccessCallback = {},
               failure : @escaping FailureCallback = { errorDescription in dlog(errorDescription) } )
   {
      if onlyIfNeeded && !needsUpdate
      {
         success()
         return
      }
      
      RequestManager.updateSalesList(success: success, failure: failure)
   }
}

/// акция
class Sale: Object
{
   @objc dynamic var id : Int64 = 0
   @objc dynamic var name = ""
   @objc dynamic var imageLink : String? = nil
   @objc dynamic var imageAspectRatio : Double = 2.0
   @objc dynamic var saleDescription = ""

   ///условия по блюдам для акции
   let dishes = List<SaleDish>()
   let gifts = List<SaleGift>()
   
   @objc dynamic var typeInt = 0
   var type : SaleType
   {
      get
      {
         return SaleType(rawValue: typeInt)
      }
      set
      {
         modifyWithTransactionIfNeeded {
            typeInt = newValue.rawValue
         }
      }
   }
   
   override class func ignoredProperties() -> [String] {
      return ["type"]
   }
   
   override func propertiesToCascadeDelete() -> [String] {
      return ["dishes", "gifts"]
   }
   
   func updateType(_ typeString : String?)
   {
      guard let typeString = typeString else { return }
      
      var saleType : SaleType = []
      switch typeString
      {
      case "IN_RESTAURANT": saleType = .restaurant
      case "DELIVERY": saleType = .delivery
      case "BOTH": saleType = [.restaurant, .delivery]
      default: break
      }
      
      if self.type != saleType {
         self.type = saleType
      }
   }
}


class SaleDish: Object
{
   @objc dynamic var id = ""
   @objc dynamic var name = ""
   let variants = List<SaleDishVariant>()
   
   override func propertiesToCascadeDelete() -> [String] {
      return ["variants"]
   }
   
   var dish : Dish?
   {
      guard !id.isEmpty, !variants.isEmpty, let menuDish = DishList.list.allDishes.filter("id == %@", id).first else { return nil }
      
      menuDish.salesVariants.removeAll()
      for variant in variants
      {
         if let menuVariant = menuDish.dishVariants.first(where: { $0.id == variant.id }) {
            menuDish.salesVariants.append(menuVariant)
         }
      }
      
      if menuDish.salesVariants.isEmpty {
         return nil
      }
      else {
         return menuDish
      }
   }
}

class SaleDishVariant: Object
{
   @objc dynamic var id = ""
   @objc dynamic var name = ""
}

class SaleGift: Object
{
   @objc dynamic var id = ""
   @objc dynamic var name = ""
}
