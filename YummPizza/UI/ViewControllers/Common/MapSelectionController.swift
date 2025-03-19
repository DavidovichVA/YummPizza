//
//  MapSelectionController.swift
//  YummPizza
//
//  Created by Blaze Mac on 6/1/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import GoogleMaps

let pizzeriaRegionNormalColor : UIColor = rgba(12, 169, 204, 0.3)
let pizzeriaRegionSelectedColor : UIColor = rgba(77, 255, 77, 0.3)
let pizzeriaRegionBorderColor : UIColor = rgb(12, 169, 204)

class MapSelectionController: UIViewController, GMSMapViewDelegate
{
   @IBOutlet weak var mapContainerView: UIView!
   @IBOutlet weak var userPinImageView: UIImageView!
   @IBOutlet weak var addressViewHeight: NSLayoutConstraint!
   @IBOutlet weak var addressLabel: UILabel!
   @IBOutlet weak var selectButton: UIButton!
   
   @IBOutlet var pizzeriaPopupView: UIView!
   @IBOutlet weak var pizzeriaPopupNameLabel: UILabel!
   @IBOutlet weak var pizzeriaPopupPhoneButton: UIButton!
   @IBOutlet weak var pizzeriaPopupTimeLabel: UILabel!
   
   public var selectingPizzeria : Bool = false
   /// return true to confirm selection and dismiss controller; return false to stay
   public var onCompletion : (_ mapController : MapSelectionController, _ userConfirmedSelection : Bool) -> Bool =
   { _,_ in return true }
   
   public var selectedPizzeria : Pizzeria?
   public var selectedUserAddress : Address?
   
   private var mapView : GMSMapView!
   private var pizzeriaPins : [GMSMarker] = []
   private var pizzeriaRegions : [GMSPolygon] = []
   private var centerCoordinate : CLLocationCoordinate2D { return mapView.camera.target }
   
   private var showingPizzeriaPopup : Bool { return pizzeriaPopupView.superview != nil }
   
    
   //MARK: - Methods
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      
      addressLabel.text = nil
      hideAddressString(animated: false)
      
      pizzeriaPopupView.frame = CGRect(x: 0, y: 0, width: 270 * WidthRatio, height: 160 * WidthRatio)
      pizzeriaPopupPhoneButton.titleLabel?.textAlignment = .center
      pizzeriaPopupPhoneButton.titleLabel?.lineBreakMode = .byWordWrapping
      pizzeriaPopupPhoneButton.titleLabel?.numberOfLines = 0
      pizzeriaPopupView.layer.masksToBounds = false
      pizzeriaPopupView.layer.shadowOpacity = 0.4
      pizzeriaPopupView.layer.shadowOffset =  CGSize(width: 0, height: 7 * WidthRatio)
      pizzeriaPopupView.layer.shadowRadius = 5 * WidthRatio
      pizzeriaPopupView.layer.shadowColor = UIColor.black.cgColor
      
      let camera = GMSCameraPosition.camera(withLatitude: 59.93863, longitude: 30.31413, zoom: 9.5)
      mapView = GMSMapView.map(withFrame: mapContainerView.bounds, camera: camera)
      mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      mapView.delegate = self
      mapContainerView.insertSubview(mapView, at: 0)
      
      updateDisplayedData()
      updateButtonEnabled()
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      updateSelectedRegion()
   }
   
   //MARK: - Methods
   
   func updateDisplayedData()
   {
      for pin in pizzeriaPins { pin.map = nil }
      for region in pizzeriaRegions { region.map = nil }
      pizzeriaPins.removeAll()
      pizzeriaRegions.removeAll()
      
      let pizzeriaList = PizzeriaList.list
      for pizzeria in pizzeriaList.pizzerias
      {
         let marker = GMSMarker()
         marker.position = pizzeria.coordinate.coordinate2D
         marker.icon = mapPinPizzeriaImage
         marker.groundAnchor = CGPoint(x: 0.5, y: 1)
         marker.infoWindowAnchor = CGPoint(x: 0.5, y: 0)
         marker.title = pizzeria.addressString
         marker.isTappable = selectingPizzeria
         marker.userData = pizzeria
         marker.map = mapView
         pizzeriaPins.append(marker)
      }
      for area in pizzeriaList.pizzeriasAreas
      {
         guard area.points.count >= 3 else { continue }
         let path = GMSMutablePath()
         for coord in area.points {
            path.addLatitude(coord.latitude, longitude: coord.longitude)
         }
         let polygon = GMSPolygon(path: path)
         polygon.fillColor = pizzeriaRegionNormalColor
         polygon.strokeColor = pizzeriaRegionBorderColor
         polygon.strokeWidth = 2
         polygon.isTappable = false
         polygon.map = mapView
         pizzeriaRegions.append(polygon)
      }
   }
   
   func updateSelectedRegion()
   {
      let mapCenter = centerCoordinate
      for region in pizzeriaRegions
      {
         if !showingPizzeriaPopup, let path = region.path, GMSGeometryContainsLocation(mapCenter, path, region.geodesic) {
            region.fillColor = pizzeriaRegionSelectedColor
         }
         else {
            region.fillColor = pizzeriaRegionNormalColor
         }
      }
   }
   
   func selectPizzeria(_ pizzeria : Pizzeria)
   {
      selectedPizzeria = pizzeria
      
      UIView.performWithoutAnimation
      {
         pizzeriaPopupNameLabel.text = pizzeria.addressString.uppercased()
         pizzeriaPopupPhoneButton.setTitle(pizzeria.phoneLongString, for: .normal)
         pizzeriaPopupTimeLabel.setTextKeepingAttributes(pizzeria.workingTime)
         
         pizzeriaPopupView.frame = CGRect(x: 0, y: 0, width: 270 * WidthRatio, height: ScreenHeight - 100)
         pizzeriaPopupView.layoutIfNeeded()
         let neededHeight = ceil(pizzeriaPopupTimeLabel.bottom + 24 * WidthRatio)
         pizzeriaPopupView.frame = CGRect(x: 0, y: 0, width: 270 * WidthRatio, height: neededHeight)
         pizzeriaPopupView.center = mapView.center
      }
      
      mapContainerView.addSubview(pizzeriaPopupView)
      userPinImageView.isHidden = true
      updateButtonEnabled()
      updateSelectedRegion()
   }
   
   func deselectPizzeria()
   {
//      mapView.selectedMarker = nil
      selectedPizzeria = nil
      pizzeriaPopupView.removeFromSuperview()
      userPinImageView.isHidden = false
      updateButtonEnabled()
      updateSelectedRegion()
   }
   
   func updateButtonEnabled()
   {
      if selectingPizzeria {
         selectButton.isEnabled = (selectedPizzeria != nil)
      }
      else {
         selectButton.isEnabled = (selectedUserAddress != nil)
      }
   }
   
   func showAddressString(_ addressString : String?, animated : Bool = true)
   {
      if isNilOrEmpty(addressString)
      {
         hideAddressString(animated: animated)
         return
      }
      
      if addressLabel.text == addressString, addressViewHeight.constant > 0 { return }
      
      addressLabel.text = addressString
      addressLabel.layoutIfNeeded()
      
      if addressViewHeight.constant == 0
      {
         UIView.animateIgnoringInherited(withDuration: (animated ? 0.3 : 0), animations:
         {
            self.addressLabel.alpha = 1
            self.addressViewHeight.constant = 47 * WidthRatio
            self.view.layoutIfNeeded()
         })
      }
      else
      {
         UIView.transitionIgnoringInherited(with: addressLabel, duration: (animated ? 0.5 : 0), options: .transitionFlipFromBottom, animations:
         {
            self.addressLabel.alpha = 1
            self.view.layoutIfNeeded()
         },
         completion: nil)
      }
   }
   
   func hideAddressString(animated : Bool = true)
   {
      UIView.animateIgnoringInherited(withDuration: (animated ? 0.3 : 0), animations:
      {
         self.addressViewHeight.constant = 0
         self.view.layoutIfNeeded()
      })
   }
   
   private var geolocationRequestCoordinate : CLLocationCoordinate2D?
   func getAddress(for coordinate : CLLocationCoordinate2D)
   {
      UIView.animateIgnoringInherited(withDuration: 0.2) {
         self.addressLabel.alpha = 0.5
      }
      
      GMSGeocoder().reverseGeocodeCoordinate(coordinate)
      {
         [weak self]
         (response, error) in
         guard let strongSelf = self else { return }
         guard coordinate == strongSelf.geolocationRequestCoordinate else { return }
         
         if let gmsAddress = response?.firstResult(), let addressString = gmsAddress.addressString(), !addressString.isEmpty
         {
            let address = Address()
            address.city = gmsAddress.locality ?? ""
            if address.city == "Saint Petersburg" {
               address.city = "Санкт-Петербург"
            }
            
            let parsed = strongSelf.parseThoroughfare(gmsAddress.thoroughfare ?? "")
            address.street = parsed.street
            address.house = parsed.house
            address.block = parsed.block
            
            address.coordinate = Coordinate(coordinate)
            
            strongSelf.selectedUserAddress = address
            strongSelf.updateButtonEnabled()
            strongSelf.showAddressString(addressString.capitalizingFirstLetter())
         }
         else
         {
            strongSelf.geolocationRequestCoordinate = nil
            let errorMessage = error?.localizedDescription ?? "Ошибка определения адреса"
            dlog(errorMessage)
            //AlertManager.showAlert(errorMessage)
         }
      }
   }
   
   func parseThoroughfare(_ thoroughfare : String) -> (street : String, house : String, block : String?)
   {
      let searchedString = thoroughfare as NSString
      
      // http://regexr.com/3g3h6
      guard let regexp = try? NSRegularExpression(pattern: "(.+),\\s*((д|д\\.|дом)*\\s*(\\d+[^,к\\s\\n]*)(,?\\s*(корпус|корп|к)\\.?\\s*(\\d+.*))?)", options: .caseInsensitive) else { return ("", "", nil) }
      guard let match = regexp.firstMatch(in: thoroughfare, range: NSMakeRange(0, searchedString.length)) else { return (thoroughfare, "", nil) }
      
      for i in 0..<match.numberOfRanges
      {
         let range = match.range(at: i)
         if range.location != NSNotFound {
            print("\(i): \(searchedString.substring(with: range))")
         }
      }
      
      if match.numberOfRanges >= 8 // must be 8 for regexp above
      {
         var street = thoroughfare
         var house = ""
         var block : String? = nil
         
         var range = match.range(at: 1)
         if range.location != NSNotFound
         {
            street = searchedString.substring(with: range)
            street = street.replacingOccurrences(of: "улица", with: "")
               .replacingOccurrences(of: "Улица", with: "")
               .replacingOccurrences(of: "ул.", with: "")
               .replacingOccurrences(of: "ё", with: "е").replacingOccurrences(of: "Ё", with: "Е")
               .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
               .replacingOccurrences(of: "  ", with: " ")
            
            if (street.hasPrefix("Проспект ") || street.hasPrefix("проспект ")) && !street.contains("Ветеранов") {
               street = String(street["проспект ".endIndex..<street.endIndex]).capitalizingFirstLetter() + " проспект"
            }
         }
         
         range = match.range(at: 4)
         if range.location != NSNotFound {
            house = searchedString.substring(with: range)
         }
         
         range = match.range(at: 7)
         if range.location != NSNotFound {
            block = searchedString.substring(with: range)
         }
         
         return (street, house, block)
      }
      else
      {
         return (thoroughfare, "", nil)
      }
   }
   
   /// checks if coordinate is in delivery area
   public func inDeliveryArea(_ coordinate : CLLocationCoordinate2D) -> Bool
   {
      return coordinate.inDeliveryArea(pizzeriaRegions: self.pizzeriaRegions)
   }
   
   public func goBack(userConfirmedSelection : Bool)
   {
      if onCompletion(self, userConfirmedSelection) {
         _ = navigationController?.popViewController(animated: true)
      }
   }
   
   override func navigationBackTap()
   {
      goBack(userConfirmedSelection: false)
   }
   
   //MARK: - GMSMapViewDelegate
   
   func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition)
   {
      updateSelectedRegion()
      
//      if showingPizzeriaPopup, let position = selectedPizzeria?.coordinate?.coordinate2D
//      {
//         let point = mapView.projection.point(for: position)
//         pizzeriaPopupView.origin = CGPoint(x: point.x - pizzeriaPopupView.width / 2, y: point.y - pizzeriaPopupView.height - 10)
//      }
   }
   
   func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool
   {
      guard let pizzeria = marker.userData as? Pizzeria, !pizzeria.isInvalidated else { return false }
      selectPizzeria(pizzeria)
      return true
   }
   
   func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D)
   {
      if selectingPizzeria {
         deselectPizzeria()
      }
   }
   
   func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition)
   {
      if !selectingPizzeria
      {
         let coordinate = self.centerCoordinate
         if let requestCoordinate = geolocationRequestCoordinate, GMSGeometryDistance(requestCoordinate, coordinate) < 20 { return }
         
         geolocationRequestCoordinate = coordinate
         getAddress(for: coordinate)
      }
   }
   
//   func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView?
//   {
//      guard let pizzeria = marker.userData as? Pizzeria, !pizzeria.isInvalidated else { return nil }
//      selectedPizzeria = pizzeria
//      pizzeriaPopupNameLabel.text = pizzeria.addressString.uppercased()
//      pizzeriaPopupPhoneButton.setTitle(pizzeria.phoneLongString, for: .normal)
//      pizzeriaPopupTimeLabel.setTextKeepingAttributes(pizzeria.workingTime)
//      pizzeriaPopupView.layoutIfNeeded()
//      return pizzeriaPopupView
//   }
   
   //MARK: - Actions
   
   @IBAction func pizzeriaPhoneTap() {
      selectedPizzeria?.call()
   }
   
   @IBAction func pizzeriaPopupCloseTap() {
      deselectPizzeria()
   }
   
   @IBAction func selectButtonTap() {
      goBack(userConfirmedSelection: true)
   }
}


extension GMSAddress
{
   func addressString() -> String?
   {
      if !isNilOrEmpty(thoroughfare) { return thoroughfare! }
      
      var componentsArray : [String] = []
      if !isNilOrEmpty(subLocality) { componentsArray.append(subLocality!) }
      if !isNilOrEmpty(locality) { componentsArray.append(locality!) }
      if !isNilOrEmpty(administrativeArea) { componentsArray.append(administrativeArea!) }
      if !isNilOrEmpty(country) { componentsArray.append(country!) }
      if componentsArray.isEmpty { return nil }
      
      var str = ""
      var usedComponentsCount = 0
      for component in componentsArray
      {
         if component == str { continue }
         
         if usedComponentsCount == 0 { str = component }
         else { str = str + ", " + component }
         
         usedComponentsCount += 1
         if usedComponentsCount == 2 { return str }
      }
      
      return str.isEmpty ? nil : str
   }
}

extension CLLocationCoordinate2D : Equatable
{
   public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool
   {
      return (lhs.latitude == rhs.latitude) && (lhs.longitude == rhs.longitude)
   }
   
   func distance(to otherCoordinate: CLLocationCoordinate2D) -> CLLocationDistance
   {
      let firstLoc = CLLocation(latitude: self.latitude, longitude: self.longitude)
      let secondLoc = CLLocation(latitude: otherCoordinate.latitude, longitude: otherCoordinate.longitude)
      return firstLoc.distance(from: secondLoc)
   }
}

