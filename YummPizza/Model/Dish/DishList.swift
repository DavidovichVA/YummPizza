//
//  DishList.swift
//  YummPizza
//

import RealmSwift
import UIKit

enum DishType : Int
{
   case pizza = 1
   case hotDishes = 2
   case snacks = 3
   case drinks = 4
   case desserts = 5
   case combo = 6
}

extension Notification.Name
{
   static let YPDishListUpdated = Notification.Name("YPDishListUpdatedNotificationName")
}

class DishList: Object
{
   @objc dynamic var dishesHash = ""
   @objc dynamic var lastUpdate: Date? = nil
   
   let allToppings = List<Topping>()
   let allCheeseBorders = List<CheeseBorder>()
   
   let allDishes = List<Dish>()
   let combos = List<Dish>()
   let pizzas = List<Dish>()
   let drinks = List<Dish>()
   let hotDishes = List<Dish>()
   let snacks = List<Dish>()
   let desserts = List<Dish>()
   
   override class func ignoredProperties() -> [String] {
      return ["allDishes"]
   }
   
   var needsUpdate : Bool
   {
      if let lastUpdateTime = lastUpdate {
         return -lastUpdateTime.timeIntervalSinceNow > 3600
      }
      else {
         return true
      }
   }
   
   static var list : DishList
   {
      let realm = Realm.main
      
      if let dishList = realm.objects(DishList.self).first {
         return dishList
      }
      else
      {
         let dishList = DishList()
         realm.writeWithTransactionIfNeeded {
            realm.add(dishList)
         }
         return dishList
      }
   }
   
   // MARK: - Functions
   
   func all(_ type : DishType) -> List<Dish>
   {
      switch type
      {
      case .pizza: return pizzas
      case .hotDishes: return hotDishes
      case .snacks: return snacks
      case .drinks: return drinks
      case .desserts: return desserts
      case .combo: return combos
      }
   }
   func all(_ section : DishSection) -> List<Dish>
   {
      switch section
      {
      case .saleDishes: return DishListController.saleDishes
      case .all: return allDishes
      case .combo: return combos
      case .pizza: return pizzas
      case .drinks: return drinks
      case .hotDishes: return hotDishes
      case .snacks: return snacks
      case .desserts: return desserts
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

      RequestManager.updateDishListIfNeeded(
      success:
      {
         [weak self] in
         Cart.validateItems()
         DishListController.validateSaleDishes()
         NotificationCenter.default.post(name: .YPDishListUpdated, object: self, userInfo: nil)
         success()
      },
      failure: failure)
   }
}

