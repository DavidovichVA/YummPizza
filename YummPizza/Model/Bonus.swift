//
//  Bonus.swift
//  YummPizza
//
//  Created by Blaze Mac on 6/21/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import RealmSwift

class Bonus: Object
{
   @objc dynamic var id : Int64 = 0
   @objc dynamic var bonusSum : DecimalObject?
   @objc dynamic var orderSum : DecimalObject?
   @objc dynamic var date : Date?
   
   override func propertiesToCascadeDelete() -> [String] {
      return ["bonusSum", "orderSum"]
   }
}
