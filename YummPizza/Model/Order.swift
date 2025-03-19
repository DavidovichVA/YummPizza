//
//  Order.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/27/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import RealmSwift

let orderStatusCodes : [String : String] = [ "NEW" : "Новый",
                                             "AWAITING_DELIVERY" : "Ждет отправки",
                                             "ON_THE_WAY" : "В пути",
                                             "CLOSED" : "Закрыто",
                                             "CANCELLED" : "Отменено",
                                             "DELIVERED" : "Доставлено",
                                             "NOT_CONFIRMED" : "Не подтверждено",
                                             "IN_PROGRESS" : "Готовится",
                                             "READY" : "Готово",
                                             "NOT_EXIST" : "Не существует"]


///заказ
class Order: Object
{
   @objc dynamic var id : Int64 = 0
   
   @objc dynamic var statusCode = ""
   var status : String { return orderStatusCodes[statusCode] ?? statusCode }
   
   @objc dynamic var date : Date?
   @objc dynamic var sum : DecimalObject?
   @objc dynamic var pushEnabled = true
   @objc dynamic var promoCode = ""
   
   let dishes = List<OrderDish>()
   
   @objc dynamic var operatorPhoneNumber = ""
   ///самовывоз
   @objc dynamic var pickup = false
   
   override class func primaryKey() -> String? {
      return "id"
   }
   
   override func propertiesToCascadeDelete() -> [String] {
      return ["sum", "dishes"]
   }
   
   
   var canCallOperator : Bool { return operatorPhoneNumber.characters.count == 7 }
   
   func callOperator()
   {
      guard canCallOperator else { return }
      let phoneString = "telprompt://8812\(operatorPhoneNumber)"
      if let url = URL(string: phoneString)
      {
         Application.openURL(url)
      }
   }
}

class OrderDish: Object
{
   @objc dynamic var id = ""
   @objc dynamic var name = ""
   @objc dynamic var variantType = ""
   @objc dynamic var variantName = ""
   @objc dynamic var dough : OrderDough?
   @objc dynamic var cheeseBorder : OrderCheeseBorder?
   let toppings = List<OrderTopping>()
   @objc dynamic var count : Int = 1
   
   override func propertiesToCascadeDelete() -> [String] {
      return ["dough", "cheeseBorder", "toppings"]
   }
   
   
   var cartItem : CartItem?
   {
      guard !id.isEmpty, let dishVariant = Realm.main.objects(DishVariant.self).filter("id == %@", id).first,
         let dish = dishVariant.dish else { return nil }
      
      var dough : Dough?
      if let selfDough = self.dough, !selfDough.id.isEmpty, !selfDough.groupId.isEmpty,
         let menuDough = dishVariant.doughVariants.filter("id == %@ AND groupId == %@", selfDough.id, selfDough.groupId).first
      {
         dough = menuDough
      }
      
      var cheeseBorder : CheeseBorder?
      if let selfCheeseBorder = self.cheeseBorder, !selfCheeseBorder.id.isEmpty, !selfCheeseBorder.groupId.isEmpty,
         dishVariant.cheeseBorderGroupId == selfCheeseBorder.groupId, dishVariant.cheeseBorder?.id == selfCheeseBorder.id
      {
         cheeseBorder = dishVariant.cheeseBorder
      }
      if dough?.name != "Тонкое" {
         cheeseBorder = nil
      }
      
      let toppingCounts = List<ToppingCount>()
      for topping in toppings
      {
         if dish.toppingsGroupId == topping.groupId, let dishTopping = dish.toppings.filter("id == %@", topping.id).first
         {
            let toppingCount = ToppingCount()
            toppingCount.topping = dishTopping
            toppingCount.count = topping.count
            toppingCounts.append(toppingCount)
         }
      }
      
      let item = CartItem(dish: dish, dishVariant: dishVariant, dough: dough, cheeseBorder: cheeseBorder, toppingCounts: toppingCounts, count: count)
      return item
   }
}

class OrderDough: Object
{
   @objc dynamic var id = ""
   @objc dynamic var groupId = ""
   @objc dynamic var name = ""
}

class OrderCheeseBorder: Object
{
   @objc dynamic var id = ""
   @objc dynamic var groupId = ""
   @objc dynamic var name = ""
}

class OrderTopping: Object
{
   @objc dynamic var id = ""
   @objc dynamic var groupId = ""
   @objc dynamic var name = ""
   @objc dynamic var count : Int = 1
}
