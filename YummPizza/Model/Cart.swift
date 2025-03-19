//
//  Cart.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/16/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import Foundation
import RealmSwift

extension Notification.Name
{
   static let YPCartItemsCountChanged = Notification.Name("YPCartItemsCountChangedNotificationName")
   static let YPCartItemsChanged = Notification.Name("YPCartItemsChangedNotificationName")
   static let YPCartItemsChangedFromValidation = Notification.Name("YPCartItemsChangedFromValidationNotificationName")
}

class Cart
{
   static var items : List<CartItem> { return User.current?.cartItems ?? List<CartItem>() }
   static var itemsCount : Int { return User.current?.cartItems.count ?? 0 }
   
   static var isEmpty : Bool { return items.isEmpty }
   
   static func addItem(_ item : CartItem)
   {
      guard !item.isInvalidated, let items = User.current?.cartItems else { return }
      
      if let existingItemIndex = items.index(where: { !$0.isInvalidated && $0 == item })
      {
         items.modifyWithTransactionIfNeeded {
            items[existingItemIndex].count += item.count
         }
         notifyItemsChanged()
      }
      else
      {
         items.modifyWithTransactionIfNeeded {
            items.append(item)
         }
         notifyItemsChanged()
         notifyItemsCountChanged()
      }
   }
   
   static func index(of item : CartItem) -> Int?
   {
      guard !item.isInvalidated, let items = User.current?.cartItems else { return nil }
      return items.index(where: { !$0.isInvalidated && $0 == item })
   }
   
   static func item(_ index : Int) -> CartItem?
   {
      guard let items = User.current?.cartItems else { return nil }
      guard index >= 0, index < items.count else { return nil }
      return items[index]
   }
   
   /// returns removed object index
   @discardableResult
   static func removeItem(_ item : CartItem) -> Int?
   {
      guard !item.isInvalidated, let items = User.current?.cartItems else { return nil }
      if let itemIndex = items.index(where: { !$0.isInvalidated && $0 == item })
      {
         items.modifyWithTransactionIfNeeded
         {
            items.remove(objectAtIndex: itemIndex)
            item.realm?.cascadeDelete(item)
         }
         notifyItemsChanged()
         notifyItemsCountChanged()
         return itemIndex
      }
      else {
         return nil
      }
   }
   
   @discardableResult
   static func removeItem(at index : Int) -> Bool
   {
      guard let items = User.current?.cartItems else { return false }
      guard index >= 0, index < items.count else { return false }
      let item = items[index]
      items.modifyWithTransactionIfNeeded
      {
         items.remove(objectAtIndex: index)
         item.realm?.cascadeDelete(item)
      }
      notifyItemsChanged()
      notifyItemsCountChanged()
      return true
   }
   
   static func removeAllItems()
   {
      guard let items = User.current?.cartItems else { return }
      items.modifyWithTransactionIfNeeded
      {
         items.realm?.cascadeDelete(items)
         items.removeAll()
      }
      notifyItemsChanged()
      notifyItemsCountChanged()
   }
   
   private static func notifyItemsCountChanged() {
      NotificationCenter.default.post(name: .YPCartItemsCountChanged, object: self, userInfo: nil)
   }
   private static func notifyItemsChanged() {
      NotificationCenter.default.post(name: .YPCartItemsChanged, object: self, userInfo: nil)
   }
   private static func notifyItemsChangedFromValidation() {
      NotificationCenter.default.post(name: .YPCartItemsChangedFromValidation, object: self, userInfo: nil)
   }
   
   static func validateItems()
   {
      guard let items = User.current?.cartItems else { return }
      
      var changedItems = false
      var changedCount = false
      
      items.modifyWithTransactionIfNeeded
      {
         var index = 0
         while index < items.count
         {
            let item = items[index]
            if item.dish == nil || item.dish.isInvalidated || item.dishVariant == nil || item.dishVariant.isInvalidated
            {
               items.remove(objectAtIndex: index)
               item.realm?.cascadeDelete(item)
               changedItems = true
               changedCount = true
               continue
            }
            
            if let dough = item.dough, dough.isInvalidated {
               item.dough = item.dishVariant.defaultDough
               changedItems = true
            }
            
            if let cheeseBorder = item.cheeseBorder, cheeseBorder.isInvalidated {
               item.cheeseBorder = nil
               changedItems = true
            }
            
            var toppingIndex = 0
            while toppingIndex < item.toppingCounts.count
            {
               let toppingCount = item.toppingCounts[toppingIndex]
               if toppingCount.topping == nil || toppingCount.topping.isInvalidated || !item.dish.toppings.contains(toppingCount.topping)
               {
                  item.toppingCounts.remove(objectAtIndex: toppingIndex)
                  toppingCount.realm?.delete(toppingCount)
                  changedItems = true
               }
               else {
                  toppingIndex += 1
               }
            }
            
            index += 1
         }
      }
      
      if changedItems
      {
         notifyItemsChanged()
         notifyItemsChangedFromValidation()
      }
      if changedCount
      {
         notifyItemsCountChanged()
      }
   }
   
   static var totalPrice : Decimal
   {
      return items.reduce(Decimal(0), { (total, item) in total + item.price })
   }
   
   static var totalPriceToApplyBonuses : Decimal
   {
      var total = Decimal(0)
      for item in items
      {
         if item.dishVariant.canPayWithBonuses {
            total += item.price
         }
      }
      return total
   }
   
   static var maxSumPaidWithBonuses : Decimal
   {
      var sum = Decimal(0)
      
      let maxPercentBonuses = CommonValue.maxPercentPaidWithBonuses
      let totalPriceToApplyBonuses = self.totalPriceToApplyBonuses
      if let user = User.current, !user.isDefault, let bonusPoints = User.current?.bonusPoints.value, bonusPoints > 0, maxPercentBonuses > 0, totalPriceToApplyBonuses > 0
      {
         let exactFraction = bonusPoints / totalPriceToApplyBonuses
         let maxBonusesFraction = maxPercentBonuses / 100
         
         if exactFraction <= maxBonusesFraction {
            sum = bonusPoints
         }
         else {
            sum = (totalPriceToApplyBonuses * maxBonusesFraction)
         }         
      }
      
      return sum.round(.down)
   }
}

class CartItem : Object
{
   @objc dynamic var dish: Dish!
   @objc dynamic var dishVariant : DishVariant!
   @objc dynamic var dough : Dough?
   @objc dynamic var cheeseBorder: CheeseBorder?
   let toppingCounts = List<ToppingCount>()
   @objc dynamic var count : Int = 1
   
   override func propertiesToCascadeDelete() -> [String] {
      return ["toppingCounts"]
   }
   
   var price : Decimal
   {
      var total = dishVariant.price.value
      for toppingCount in toppingCounts {
         total += toppingCount.price
      }
      total += (cheeseBorder?.price?.value ?? 0)
      total *= count
      return total
   }
   
   convenience init(dish : Dish, dishVariant : DishVariant? = nil, dough : Dough? = nil, cheeseBorder : CheeseBorder? = nil, toppingCounts : List<ToppingCount>? = nil, count : Int = 1)
   {
      self.init()
      self.dish = dish
      self.dishVariant = dishVariant ?? dish.defaultVariant
      self.dough = dough ?? self.dishVariant.defaultDough
      self.cheeseBorder = cheeseBorder
      if let toppingCounts = toppingCounts
      {
         for toppingCount in toppingCounts
         {
            if !toppingCount.topping.isInvalidated && dish.toppings.contains(toppingCount.topping) {
               self.toppingCounts.append(ToppingCount(value: toppingCount))
            }
         }
      }
      self.count = count
   }
    
   convenience init(copyOf cartItem : CartItem)
   {
      self.init(dish: cartItem.dish, dishVariant: cartItem.dishVariant, dough: cartItem.dough, cheeseBorder: cartItem.cheeseBorder, toppingCounts: cartItem.toppingCounts, count: cartItem.count)
   }
   
   func toppingCount(_ topping : Topping) -> Int {
      return toppingCounts.first(where: {$0.topping == topping})?.count ?? 0
   }
   func setToppingCount(_ topping : Topping, _ newCount : Int)
   {
      modifyWithTransactionIfNeeded
      {
         if let toppingCount = toppingCounts.first(where: {$0.topping == topping}) {
            toppingCount.count = newCount
         }
         else
         {
            let toppingCount = ToppingCount()
            toppingCount.topping = topping
            toppingCount.count = newCount
            toppingCounts.append(toppingCount)
         }
      }
   }
   
   func addToppingCount(_ topping : Topping, _ addedCount : Int)
   {
      let newCount = max(0, toppingCount(topping) + addedCount)
      setToppingCount(topping, newCount)
   }
   
   func addCount(_ addedCount : Int)
   {
      modifyWithTransactionIfNeeded {
         count = max(1, count + addedCount)
      }
   }
   
   public static func ==(lhs: CartItem, rhs: CartItem) -> Bool
   {
      if !((lhs.dish.id == rhs.dish.id) && (lhs.dishVariant.id == rhs.dishVariant.id) &&
         (lhs.dough?.id == rhs.dough?.id) && (lhs.cheeseBorder?.id == rhs.cheeseBorder?.id))
      {
         return false
      }

      for topping in lhs.dish.toppings {
         if lhs.toppingCount(topping) != rhs.toppingCount(topping) { return false }
      }
      
      return true
   }
}


class ToppingCount : Object
{
   @objc dynamic var topping : Topping!
   @objc dynamic var count = 0
   
   var price : Decimal {
      return (topping?.price.value ?? Decimal(0)) * count
   }
}

