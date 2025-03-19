//
//  Street.swift
//  YummPizza
//
//  Created by Blaze Mac on 6/26/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import RealmSwift

class StreetList: Object
{
   ///in alphabetic order
   let streets = List<Street>()
   @objc dynamic var streetsHash = ""
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
   
   static var list : StreetList
   {
      let realm = Realm.main
      
      if let streetList = realm.objects(StreetList.self).first {
         return streetList
      }
      else
      {
         let streetList = StreetList()
         realm.writeWithTransactionIfNeeded {
            realm.add(streetList)
         }
         return streetList
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
      
      RequestManager.updateStreetListIfNeeded(success: success, failure: failure)
   }
}

class Street: Object
{
   @objc dynamic var id = ""
   @objc dynamic var name = ""
   
   ///большими буквами
   @objc dynamic var uppercasedName = ""
   
   ///без гласных
   @objc dynamic var flattenedName = ""
   
   static let charsToFlatten = "аеёиоуыэюяaeiouy".characters
}
