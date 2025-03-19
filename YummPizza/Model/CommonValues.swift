//
//  CommonValues.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/27/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import RealmSwift

class CommonValue : Object
{
   @objc dynamic var key : String = ""
   @objc dynamic var value : String = ""
   @objc dynamic var desc : String = ""
   @objc dynamic var isEnabled = true
   
   override class func primaryKey() -> String? {
      return "key"
   }
   
   static var all : Results<CommonValue> { return Realm.main.objects(CommonValue.self) }
   
   class func forKey(_ key : String, onlyIfEnabled : Bool = true) -> CommonValue?
   {
      let optionalValue = Realm.main.object(ofType: CommonValue.self, forPrimaryKey: key)
      if let value = optionalValue, !value.isEnabled, onlyIfEnabled {
         return nil
      }
      return optionalValue
   }
}


extension CommonValue
{
   static var maxPercentPaidWithBonuses : Decimal
   {
      var maxPercentBonuses : Decimal = 0
      if let str = CommonValue.forKey("CAN_PAY_WITH_BONUSES")?.value, let value = Decimal(string: str) {
         maxPercentBonuses = minmax(0, value, 100)
      }
      return maxPercentBonuses
   }
   
   static var sumForFreeDelivery : Decimal
   {
      var sum : Decimal = 0
      if let str = CommonValue.forKey("FREE_DELIVERY_SUM")?.value, let value = Decimal(string: str) {
         sum = max(0, value)
      }
      return sum
   }
}
