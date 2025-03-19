//
//  AddressController.swift
//  YummPizza
//
//  Created by Georgy Solovei on 6/9/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import CoreLocation

enum AddressControllerMode
{
   case add
   case edit(address : Address)
}

class AddressController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource
{
   @IBOutlet weak var streetField: UITextField!
   @IBOutlet weak var houseField: UITextField!
   @IBOutlet weak var blockField: UITextField!
   @IBOutlet weak var apartmentField: UITextField!
   @IBOutlet weak var confirmBarButton: UIBarButtonItem!
   @IBOutlet weak var suggestionsTableView: UITableView!
   @IBOutlet weak var suggestionsTableHeight: NSLayoutConstraint!
   
   var mode : AddressControllerMode = .add
   
   private var addressCoordinate : Coordinate?
   
   private var address : Address!
   {
      didSet {
         updateFieldsFromAddress(address)
      }
   }
   
   private var allStreets : [Street] = []
   private var suggestions : [Street] = []
   
   var showMapSuggestions = false
   
   // MARK: - Lifecycle

   override func viewDidLoad()
   {
      super.viewDidLoad()
      
      suggestionsTableView.rowHeight = 40 * WidthRatio
      
      switch mode
      {
      case .add: address = Address()
      case .edit(let address):
         self.address = address
         navigationItem.title = "РЕДАКТИРОВАТЬ"
         confirmBarButton.title = "Сохранить"
      }
      
      setupForKeyboard()
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      
      let streetList = StreetList.list
      if streetList.needsUpdate
      {
         streetList.update(
         success:
         {
            [weak self] in
            self?.populateStreets()
         },
         failure:
         {
            errorDescription in
            dlog(errorDescription)
            AlertManager.showAlert(errorDescription, buttonTitle: "Закрыть")
         })
      }
      else if allStreets.isEmpty {
         populateStreets()
      }
   }
   
   //MARK: - Keyboard
   
   private var keyboardObserver : NSObjectProtocol?
   private var activeInputView : UIView?
   private var tapRecognizer : UITapGestureRecognizer!
   private func setupForKeyboard()
   {
      tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboardTap))
      tapRecognizer.cancelsTouchesInView = false
      view.addGestureRecognizer(tapRecognizer)
      
      keyboardObserver = NotificationCenter.default.addObserver(forName: .UIKeyboardWillChangeFrame, object: nil, queue: OperationQueue.main)
      {
         [unowned self]
         notification in
         let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

         let keyboardWillHide = (keyboardRect.origin.y >= ScreenHeight)
         self.tapRecognizer.isEnabled = (!keyboardWillHide || self.suggestionsTableHeight.constant > 0)
      }
   }
   
   @objc private func hideKeyboardTap()
   {
      if activeInputView != nil {
         view.endEditing(true)
      }
      else {
         closeSuggestions()
      }
   }
   
   deinit {
      if keyboardObserver != nil {
         NotificationCenter.default.removeObserver(keyboardObserver!)
      }
   }
    
   //MARK: - Methods
   
   func updateFieldsFromAddress(_ address : Address?)
   {
      streetField.text = address?.street
      houseField.text  = address?.house
      blockField.text  = address?.block
      apartmentField.text = address?.apartment
      addressCoordinate = address?.coordinate
      
      streetField.borderColor = YPColorTextFieldBorderNormal
      houseField.borderColor = YPColorTextFieldBorderNormal
   }
   
   func validateInput() -> Bool
   {
      var isErrors = false
      
      if isNilOrEmpty(streetField.text)
      {
         streetField.borderColor = YPColorTextFieldBorderError
         isErrors = true
      }
      if isNilOrEmpty(houseField.text)
      {
         houseField.borderColor = YPColorTextFieldBorderError
         isErrors = true
      }
        
      return !isErrors
   }
   
   func populateStreets(_ completion : @escaping () -> Void = {})
   {
      UserInitiatedQueue.async
      {
         [weak self] in
         var streets : [Street] = []
         for street in StreetList.list.streets {
            streets.append(Street(value: street))
         }
         
         MainQueue.async
         {
            self?.allStreets = streets
            self?.updateSuggestions()
            completion()
         }
      }
   }
   
   private var updateSuggestionsKey = ""
   func updateSuggestions(_ animated : Bool = true)
   {
      guard !showMapSuggestions else { return }
      
      if let inputStreet = streetField.text, inputStreet.characters.count >= 2
      {
         updateSuggestionsKey = inputStreet
         
         UserInitiatedQueue.async
         {
            let uppercasedInput = inputStreet.uppercased()
            let suggs = self.allStreets.filter({$0.uppercasedName.hasPrefix(uppercasedInput)})
            
            MainQueue.async
            {
               if !self.showMapSuggestions, self.updateSuggestionsKey == inputStreet
               {
                  if suggs.count == 1, let sugg = suggs.first, sugg.name == self.streetField.text {
                     self.closeSuggestions(animated)
                  }
                  else if self.activeInputView != nil
                  {
                     self.suggestions = suggs
                     self.showSuggestions(animated)
                  }
               }
            }
         }
      }
      else
      {
         updateSuggestionsKey = ""
         closeSuggestions(animated)
      }
   }
   
   func showSuggestions(_ animated : Bool = true)
   {
      guard !suggestions.isEmpty else { closeSuggestions(animated); return }
      
      suggestionsTableView.reloadData()
      suggestionsTableHeight.constant = CGFloat(min(suggestions.count, (showMapSuggestions ? 8 : 5))) * suggestionsTableView.rowHeight
      UIView.animateIgnoringInherited(withDuration: (animated ? 0.2 : 0), animations: {
         self.suggestionsTableView.superview?.layoutIfNeeded()
      })
      tapRecognizer.isEnabled = true
   }
   
   func closeSuggestions(_ animated : Bool = true)
   {
      suggestionsTableHeight.constant = 0
      UIView.animateIgnoringInherited(withDuration: (animated ? 0.2 : 0), animations: {
         self.suggestionsTableView.superview?.layoutIfNeeded()
      },
      completion:
      {
         finished in
         if finished
         {
            self.suggestions.removeAll()
            self.suggestionsTableView.reloadData()
         }
         self.tapRecognizer.isEnabled = (self.activeInputView != nil)
      })
   }
   
   func onMapControllerCompletion(_ mapController : MapSelectionController, _ userConfirmedSelection : Bool) -> Bool
   {
      guard userConfirmedSelection else { return true }
      guard let selectedAddress = mapController.selectedUserAddress/*,
         let coordinate = selectedAddress.coordinate?.coordinate2D */ else { return true }
      
      updateFieldsFromAddress(selectedAddress)
      
      if selectedAddress.street.isEmpty { return true }
      
      showAppSpinner()
      showMapSuggestions = true
 
      UserInitiatedQueue.async
      {
         let startTime = Date()
         
         let streets = self.allStreets
         
         let selectedStreetName = selectedAddress.street
         let uppercasedStreetName = selectedStreetName.uppercased()
         if let street = streets.first(where: {$0.uppercasedName == uppercasedStreetName})
         {
            MainQueue.async
            {
               hideAppSpinner()
               self.streetField.text = street.name
            }
            return
         }
         
         let streetNamesArray : [String] = streets.map({$0.flattenedName})
         
         let flattenedStreetName = String(selectedStreetName.characters.filter({!Street.charsToFlatten.contains($0)})).uppercased()
         dlog(selectedAddress.street, flattenedStreetName)
         
         String.distances(from: flattenedStreetName, to: streetNamesArray)
         {
            distances in
            var suggs : [(street : Street, levDistance : Int)] = []
            for (i, street) in streets.enumerated() {
               suggs.append((street, distances[i]))
            }
            
            suggs = suggs.filter({$0.levDistance < 7}).sorted(by: { $0.levDistance < $1.levDistance })
            var suggestions = suggs.map({$0.street})
            
            for street in streets
            {
               if street.uppercasedName.hasPrefix(uppercasedStreetName),
                  !suggestions.contains(where: {$0.uppercasedName == uppercasedStreetName})
               {
                  suggestions.insert(street, at: 0)
               }
            }
            
            dlog(suggestions)
            print("time: \(-startTime.timeIntervalSinceNow)")
            
            MainQueue.async
            {
               self.streetField.borderColor = YPColorTextFieldBorderError
               hideAppSpinner()
               if self.showMapSuggestions
               {
                  self.suggestions = suggestions
                  self.showSuggestions()
               }
            }
         }
      }

      return true
      
      /*
      if mapController.inDeliveryArea(coordinate)
      {
         updateFieldsFromAddress(selectedAddress)
         return true
      }
      else // out of delivery area
      {
         let alertController = UIAlertController(title: "Внимание", message: "Адрес находится вне зоны доставки", preferredStyle: .alert)
         let addAddress = UIAlertAction(title: "Принять", style: .default, handler:
         {
            _ in
            self.updateFieldsFromAddress(selectedAddress)
            self.navigationController?.popToViewController(self, animated: true)
         })
         let cancel = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)

         alertController.addAction(addAddress)
         alertController.addAction(cancel)

         AlertManager.showAlert(alertController)
         return false
      }
      */
   }
   
   // MARK: - TableView
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return suggestions.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let cell = tableView.dequeueReusableCell(withIdentifier: "StreetSuggestionCell", for: indexPath) as! StreetSuggestionCell
      let suggestion = suggestions[indexPath.row]
      cell.streetField.text = suggestion.name
      return cell
   }
   
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
   {
      let suggestion = suggestions[indexPath.row]
      streetField.text = suggestion.name
      streetField.borderColor = YPColorTextFieldBorderNormal
      closeSuggestions()
   }
   
   // MARK: - TextField
   
   func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
   {
      activeInputView = textField
      return true
   }
   
   func textFieldDidEndEditing(_ textField: UITextField)
   {
      if activeInputView === textField {
         activeInputView = nil
      }
   }
   
   func textFieldShouldReturn(_ textField: UITextField) -> Bool
   {
      let textFields : [UITextField] = [streetField, houseField, blockField, apartmentField]
      
      guard let index = textFields.index(ofObjectIdenticalTo: textField) else { return true }
      
      var i : Int = (index == textFields.count - 1) ? 0 : index + 1
      while i != index
      {
         if isNilOrEmpty(textFields[i].text)
         {
            textFields[i].becomeFirstResponder()
            return true
         }
         i = (i == textFields.count - 1) ? 0 : i + 1
      }
      
      view.endEditing(true)
      return true
   }
   
   @IBAction func textFieldEditingChanged(_ sender: UITextField)
   {
      sender.borderColor = YPColorTextFieldBorderNormal
      addressCoordinate = nil
      showMapSuggestions = false
      
      if sender === streetField {
         updateSuggestions()
      }
   }

   // MARK: - IB actions
   @IBAction func addBarButtonTapped(_ sender: UIBarButtonItem)
   {
      guard validateInput() else { return }
      
      let finishBlock : (Bool) -> Void =
      {
         checkCoordinate in
         
         self.address.modifyWithTransactionIfNeeded
         {
            self.address.street = self.streetField.text!
            self.address.house  = self.houseField.text!
            self.address.block  = self.blockField.text
            self.address.apartment = self.apartmentField.text
            self.address.coordinate = self.addressCoordinate
         }
         
         let streetHouseString = self.address.streetHouseString
         
         switch self.mode
         {
         case .add:
            guard let user = User.current else { break }
            
            if let existingAddress = user.deliveryAddresses.first(where:
               { addr in return addr.streetHouseString == streetHouseString })
            {
               existingAddress.updateFrom(self.address)
            }
            else
            {
               user.modifyWithTransactionIfNeeded {
                  user.deliveryAddresses.insert(self.address, at: 0)
               }
            }
         case .edit: break
         }
         
         if self.address.coordinate == nil
         {
            self.address.autoFillCoordinate(
            success:
            {
               coordinate in
               if checkCoordinate, !coordinate.inDeliveryArea() {
                  AlertManager.showAlert(title: "Внимание", message: "Адрес \"\(streetHouseString)\" находится вне зоны доставки")
               }
               dlog(coordinate)
            },
            failure:
            {
               errorDescription in
               dlog(errorDescription)
            })
         }
         
         self.view.endEditing(true)
         self.navigationController?.popViewController(animated: true)
      }
      
      if isServerConnection
      {
         var houseString = houseField.text!
         if let blockValue = blockField.text, !blockValue.isEmpty {
            houseString += "к\(blockValue)"
         }
//         if let apartmentValue = apartmentField.text, !apartmentValue.isEmpty {
//            houseString += " кв. \(apartmentValue)"
//         }
         
         RequestManager.checkDeliveryAddress(street: streetField.text!, house: houseString, showSpinner: true,
         success:
         {
            inDeliveryArea in
            if inDeliveryArea {
               finishBlock(false)
            }
            else {
               AlertManager.showAlert("Адрес находится вне зоны доставки")
            }
         },
         failure:
         {
            errorDescription in
            dlog(errorDescription)
            finishBlock(true)
         })
      }
      else
      {
         finishBlock(true)
      }
   }
    
   @IBAction func findOnMapTaped(_ sender: UIButton)
   {
      let mapController = Storyboard.instantiateViewController(withIdentifier: "MapSelectionController") as! MapSelectionController
      mapController.selectingPizzeria = false
      mapController.onCompletion = self.onMapControllerCompletion(_:_:)
      navigationController?.pushViewController(mapController, animated: true)
   }
}


class StreetSuggestionCell: UITableViewCell
{
   @IBOutlet weak var streetField: UITextField!
}
