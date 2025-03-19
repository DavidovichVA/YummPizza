//
//  Address.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/30/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import RealmSwift
import CoreLocation

class Address: Object
{
   @objc dynamic var city = "Санкт-Петербург"
   @objc dynamic var street = ""
   @objc dynamic var house = ""
   @objc dynamic var block : String?
   @objc dynamic var apartment : String?
   @objc dynamic var coordinate: Coordinate?
   
   override func propertiesToCascadeDelete() -> [String] {
      return ["coordinate"]
   }
   
   var houseString : String
   {
      if house.isEmpty { return "" }
      
      var string = "д. \(house)"
      if let blockValue = block, !blockValue.isEmpty {
         string += ", корп. \(blockValue)"
      }
      if let apartmentValue = apartment, !apartmentValue.isEmpty {
         string += ", кв. \(apartmentValue)"
      }
      
      return string
   }
   
   var streetHouseString : String
   {
      if street.isEmpty {
         return houseString
      }
      else {
         return "\(street), \(houseString)"
      }
   }
   
   func updateFrom(_ address : Address)
   {
      modifyWithTransactionIfNeeded
      {
         city = address.city
         street = address.street
         house = address.house
         block = address.block
         apartment = address.apartment
         if let coord = address.coordinate
         {
            if let selfCoord = coordinate {
               selfCoord.latitude = coord.latitude
               selfCoord.longitude = coord.longitude
            }
            else {
               coordinate = Coordinate(value: coord)
            }
         }
         else
         {
            coordinate?.realm?.delete(coordinate!)
            coordinate = nil
         }         
      }
   }
   
   func autoFillCoordinate(success: @escaping (CLLocationCoordinate2D) -> (), failure : @escaping FailureCallback = {_ in })
   {
      var addressString = ""
      if !house.isEmpty
      {
         addressString = "д. \(house)"
         if let blockValue = block, !blockValue.isEmpty {
            addressString += ", корп. \(blockValue)"
         }
      }
      if !street.isEmpty
      {
         if addressString.isEmpty {
            addressString = street
         }
         else {
            addressString = "\(street), \(addressString)"
         }
      }
      
      guard !addressString.isEmpty else
      {
         failure("Местоположение не определено")
         return
      }
      
      if city.isEmpty {
         addressString = "Россия, Санкт-Петербург, " + addressString
      }
      else {
         addressString = "Россия, \(city), " + addressString
      }
      
      RequestManager.googleGeocode(addressString,
      success:
      {
         coordinate2D in
         self.modifyWithTransactionIfNeeded {
            self.coordinate = Coordinate(coordinate2D)
         }
         success(coordinate2D)
      },
      failure: failure)
   }
}
