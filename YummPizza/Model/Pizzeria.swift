//
//  Pizzeria.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/27/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import RealmSwift
import CoreLocation
import GoogleMaps

class PizzeriaList: Object
{
   let pizzerias = List<Pizzeria>()
   let pizzeriasAreas = List<PizzeriaPolygon>()
   @objc dynamic var pizzeriasHash = ""
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
   
   static var list : PizzeriaList
   {
      let realm = Realm.main
      
      if let pizzeriaList = realm.objects(PizzeriaList.self).first {
         return pizzeriaList
      }
      else
      {
         let pizzeriaList = PizzeriaList()
         realm.writeWithTransactionIfNeeded {
            realm.add(pizzeriaList)
         }
         return pizzeriaList
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
      
      RequestManager.updatePizzeriasListIfNeeded(success: success, failure: failure)
   }
}

class Pizzeria: Object
{
   @objc dynamic var id : Int64 = 0
   
   @objc dynamic var city = "Санкт-Петербург"
   @objc dynamic var street = ""
   @objc dynamic var house = ""
   
   @objc dynamic var workingTime = ""
   @objc dynamic var phone = "" //"6004004"
   @objc dynamic var coordinate: Coordinate!
   
   override func propertiesToCascadeDelete() -> [String] {
      return ["coordinate"]
   }
   
   var addressString : String
   {
      return [street, house].filter({!$0.isEmpty}).joined(separator: ", ")
   }
   
   var phoneShortString : String //"600 400 4"
   {
      return phone.characters.reduce("")
      {
         (currentPhone, char) -> String in
         guard decimalDigits.contains(char) else { return currentPhone }
         
         let currentLength = currentPhone.characters.count as Int
         if currentLength % 4 == 3 {
            return currentPhone + " " + String(char)
         }
         else {
            return currentPhone + String(char)
         }
      }
   }
   
   var phoneLongString : String //"8 812 600 400 4"
   {
      let shortString = phoneShortString
      
      if shortString.isEmpty { return "" }
      else { return "8 812 " + shortString }
   }
   
   func call()
   {
      guard phone.characters.count == 7 else { return }
      let phoneString = "telprompt://8812\(phone)"
      if let url = URL(string: phoneString)
      {
         Application.openURL(url)
      }
   }
}


class PizzeriaPolygon : Object
{
   let points = List<Coordinate>()
   
   override func propertiesToCascadeDelete() -> [String] {
      return ["points"]
   }
}

class Coordinate : Object
{
   @objc dynamic var latitude: Double = 0.0
   @objc dynamic var longitude: Double = 0.0
   
   var coordinate2D : CLLocationCoordinate2D {
      return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
   }
   
   convenience init(_ coordinate : CLLocationCoordinate2D)
   {
      self.init()
      latitude = coordinate.latitude
      longitude = coordinate.longitude
   }
}

extension CLLocationCoordinate2D
{
   /// checks if coordinate is in delivery area
   public func inDeliveryArea(pizzeriaRegions : [GMSPolygon]? = nil) -> Bool
   {
      if let regions = pizzeriaRegions
      {
         for region in regions
         {
            if let path = region.path, GMSGeometryContainsLocation(self, path, region.geodesic) {
               return true
            }
         }
         return false
      }
      else
      {
         let pizzeriaList = PizzeriaList.list
         for area in pizzeriaList.pizzeriasAreas
         {
            guard area.points.count >= 3 else { continue }
            
            let path = GMSMutablePath()
            for coord in area.points {
               path.addLatitude(coord.latitude, longitude: coord.longitude)
            }
            if GMSGeometryContainsLocation(self, path, false) {
               return true
            }
         }
         return false
      }
   }
   
   func closestPizzeria() -> Pizzeria?
   {
      var minDist : CLLocationDistance = CLLocationDistanceMax
      var closestPizzeria : Pizzeria? = nil
      
      let pizzeriaList = PizzeriaList.list
      for pizzeria in pizzeriaList.pizzerias
      {
         if pizzeria.isInvalidated { continue }
         let dist = GMSGeometryDistance(self, pizzeria.coordinate.coordinate2D)
         if dist < minDist
         {
            minDist = dist
            closestPizzeria = pizzeria
         }
      }
      return closestPizzeria
   }
}

