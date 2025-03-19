//
//  DeliveryAddressController.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/24/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class DeliveryAddressController: UIViewController, YPPairedButtonDelegate, UITextFieldDelegate, UITextViewDelegate
{
   @IBOutlet weak var scrollview: UIScrollView!
   @IBOutlet weak var headerButton: YPPairedButton!
   @IBOutlet weak var addressLabel: UILabel!
   
   @IBOutlet weak var commentTextView: UITextView!
   @IBOutlet weak var paymentButton: UIButton!
   
   let textFieldNormalBorderColor = rgb(171, 171, 171)
   
   let pizzeriaList = PizzeriaList.list
   
   var showUserAddress : Bool { return headerButton.selectionState == .left }
   var showPizzeria : Bool { return headerButton.selectionState == .right }
   
   var selectedDeliveryAddress : Address?
   {
      didSet
      {
         updateDisplayedAddress()
         if let user = User.current, let address = selectedDeliveryAddress, address.realm != nil
         {
            user.modifyWithTransactionIfNeeded {
               user.lastSelectedDeliveryAddress = selectedDeliveryAddress
               user.mainAddress = selectedDeliveryAddress
            }
         }
      }
   }

   var selectedPizzeria : Pizzeria?
   {
      didSet
      {
         updateDisplayedAddress()
         if let user = User.current
         {
            user.modifyWithTransactionIfNeeded {
               user.lastSelectedPizzeria = selectedPizzeria
            }
         }
      }
   }
   
   //MARK: - Lifecycle
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      headerButton.delegate = self
      commentTextView.setTextKeepingAttributes(OrderComment ?? "")
      setupForKeyboard()
      
      if let user = User.current
      {
         selectedDeliveryAddress = user.lastSelectedDeliveryAddress ?? user.deliveryAddresses.first
         selectedPizzeria = user.lastSelectedPizzeria ?? pizzeriaList.pizzerias.first
      }
      else
      {
         selectedDeliveryAddress = nil
         selectedPizzeria = nil
      }
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      pizzeriaList.update()
      updateButtonEnabled()
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?)
   {
      if segue.identifier == "Payment"
      {
         if let address = sender as? Address
         {
            OrderAddress = .user(address: address)
            dlog(address.streetHouseString)
         }
         else if let pizzeria = sender as? Pizzeria
         {
            OrderAddress = .pizzeria(pizzeria: pizzeria)
            dlog(pizzeria.addressString)
         }
         OrderComment = commentTextView.text
      }
   }
   
   //MARK: - Keyboard
   
   private var keyboardObserver : NSObjectProtocol?
   private var activeInputView : UIView?
   private var hideKeyboardRecognizer : UITapGestureRecognizer!
   private func setupForKeyboard()
   {
      hideKeyboardRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboardTap))
      hideKeyboardRecognizer.cancelsTouchesInView = false
      hideKeyboardRecognizer.isEnabled = false
      view.addGestureRecognizer(hideKeyboardRecognizer)
      
      keyboardObserver = NotificationCenter.default.addObserver(forName: .UIKeyboardWillChangeFrame, object: nil, queue: OperationQueue.main)
      {
         [unowned self]
         notification in
         let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
         let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
         let curve = UIViewAnimationCurve(rawValue: (notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).intValue)!
         
         let keyboardWillHide = (keyboardRect.origin.y >= ScreenHeight)
         
         UIView.beginAnimations(nil, context: nil)
         UIView.setAnimationDuration(duration)
         UIView.setAnimationCurve(curve)
         
         if keyboardWillHide {
            self.scrollview.contentInset = UIEdgeInsets.zero
            self.hideKeyboardRecognizer.isEnabled = false
         }
         else
         {
            self.scrollview.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardRect.size.height, right: 0)
            if let activeView = self.activeInputView {
               self.scrollview.scrollViewToVisible(activeView, animated: false)
            }
            self.hideKeyboardRecognizer.isEnabled = true
         }
         
         UIView.commitAnimations()
      }
   }
   
   @objc private func hideKeyboardTap() {
      view.endEditing(true)
   }
   
   deinit {
      if keyboardObserver != nil {
         NotificationCenter.default.removeObserver(keyboardObserver!)
      }
   }
   
   //MARK: - Methods
   
   func updateDisplayedAddress()
   {
      if showPizzeria {
         addressLabel.text = selectedPizzeria?.addressString
      }
      else {
         addressLabel.text = selectedDeliveryAddress?.streetHouseString
      }
      updateButtonEnabled()
   }
   
   func updateButtonEnabled()
   {
      if showPizzeria {
         paymentButton.isEnabled = (selectedPizzeria != nil)
      }
      else {
         paymentButton.isEnabled = (selectedDeliveryAddress != nil)
      }
   }
   
   func changeAddress()
   {
      if showUserAddress
      {
         let addressListController = Storyboard.instantiateViewController(withIdentifier: "AddressListController") as! AddressListController
         addressListController.mode = .select(onCompletion:
         {
            selectedAddress in
            if let address = selectedAddress {
               self.selectedDeliveryAddress = address
            }
         })
         navigationController?.pushViewController(addressListController, animated: true)
      }
      else
      {
         let pizzeriasController = Storyboard.instantiateViewController(withIdentifier: "PizzeriasController") as! PizzeriasController
         pizzeriasController.mode = .select(onCompletion:
         {
            selectedPizzeria in
            if let pizzeria = selectedPizzeria {
               self.selectedPizzeria = pizzeria
            }
         })
         navigationController?.pushViewController(pizzeriasController, animated: true)
      }
   }
   
   //MARK: - TextView
   
   func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
   {
      activeInputView = textView
      hideKeyboardRecognizer?.isEnabled = true
      return true
   }
   
   public func textViewDidEndEditing(_ textView: UITextView)
   {
      if activeInputView === textView {
         activeInputView = nil
         hideKeyboardRecognizer?.isEnabled = false
      }
   }
   
   func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
   {
      let charLimit = 200
      var newText = ((textView.text ?? "") as NSString).replacingCharacters(in: range, with: text)
      let numberOfChars = newText.characters.count
      if numberOfChars <= charLimit {
         return true
      }
      else {
         newText = String(newText.characters.prefix(charLimit))
         textView.setTextKeepingAttributes(newText)
         return false
      }
   }
   
   // MARK: - Actions
   
   func pairedButton(_ button : YPPairedButton, didSelect state : YPPairedButtonSelectionState)
   {
      view.endEditing(true)
      updateDisplayedAddress()
   }
   
   @IBAction func changeAddressTap() {
      changeAddress()
   }
   
   @IBAction func paymentTap()
   {
      if showPizzeria
      {
         guard let pizzeria = selectedPizzeria, !pizzeria.isInvalidated else { return }
         performSegue(withIdentifier: "Payment", sender: pizzeria)
      }
      else
      {
         guard let address = selectedDeliveryAddress, !address.isInvalidated else { return }
         
         if let coordinate = address.coordinate?.coordinate2D,
            !coordinate.inDeliveryArea(),
            let pizzeria = coordinate.closestPizzeria()
         {
            let alertController = UIAlertController(title: nil, message: "Адрес находится вне зоны доставки. Вы можете забрать заказ из ближайшей к вам пиццерии по адресу “\(pizzeria.addressString)”", preferredStyle: .actionSheet)
            
            let useAddress = UIAlertAction(title: "Продолжить с выбранным адресом", style: .default, handler:
            {
               _ in
               self.performSegue(withIdentifier: "Payment", sender: address)
            })
            
            let takeFromPizzeria = UIAlertAction(title: "Забрать из пиццерии", style: .default, handler:
            {
               _ in
               self.headerButton.selectionState = .right
               self.selectedPizzeria = pizzeria
               self.performSegue(withIdentifier: "Payment", sender: pizzeria)
            })
            let cancel = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
            
            alertController.addAction(takeFromPizzeria)
            alertController.addAction(useAddress)
            alertController.addAction(cancel)
            
            AlertManager.showAlert(alertController)
         }
         else
         {
            performSegue(withIdentifier: "Payment", sender: address)
         }
      }
   }
}
