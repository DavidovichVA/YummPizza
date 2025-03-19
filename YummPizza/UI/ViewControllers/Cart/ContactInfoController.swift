//
//  ContactInfoController.swift
//  YummPizza
//
//  Created by v.davidovich on 9/14/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import AKMaskField

class ContactInfoController: UIViewController, UITextFieldDelegate, AKMaskFieldDelegate
{
   @IBOutlet weak var scrollview: UIScrollView!
   @IBOutlet weak var nameField: UITextField!
   @IBOutlet weak var phoneField: AKMaskField!
   @IBOutlet weak var confirmButton: UIButton!
   
   var phoneNumbers : [Character] {
      return phoneField?.text?.characters.filter({decimalDigits.contains($0)}) ?? []
   }
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      setupForKeyboard()
      phoneField.maskDelegate = self
      phoneField.jumpToPrevBlock = true
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      if let navController = self.navigationController
      {
         navController.navigationBar.isTranslucent = false
         navController.navigationBar.shadowImage = nil
         navController.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
      }
      updateButtonEnabled()
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?)
   {
      if segue.identifier == "Register"
      {
         AppDelegate.customLoginAction =
         {
            user in
            if let navController = self.navigationController
            {
               if user.isDefault
               {
                  navController.popToViewController(self, animated: true)
               }
               else
               {
                  var controllers : [UIViewController] = []
                  for controller in navController.viewControllers
                  {
                     if controller is ContactInfoController
                     {
                        controllers.append(Storyboard.instantiateViewController(withIdentifier: "OrderController"))
                        break
                     }
                     else {
                        controllers.append(controller)
                     }
                  }
                  navController.setViewControllers(controllers, animated: true)
               }
            }
         }
      }
   }
   
   //MARK: - Keyboard
   
   private var keyboardObserver : NSObjectProtocol?
   private var activeInputView : UIView?
   private func setupForKeyboard()
   {
      let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboardTap))
      tapRecognizer.cancelsTouchesInView = false
      tapRecognizer.isEnabled = false
      view.addGestureRecognizer(tapRecognizer)
      
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
            tapRecognizer.isEnabled = false
         }
         else
         {
            self.scrollview.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardRect.size.height, right: 0)
            if let activeView = self.activeInputView {
               self.scrollview.scrollViewToVisible(activeView, animated: false)
            }
            tapRecognizer.isEnabled = true
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
   
   func updateButtonEnabled()
   {
      confirmButton.isEnabled = !isNilOrEmpty(nameField.text) && (phoneField.maskStatus == .complete)
   }
   
   //MARK: - TextField
   
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
   
   func maskFieldShouldBeginEditing(_ maskField: AKMaskField) -> Bool
   {
      activeInputView = maskField
      return true
   }
   
   func maskFieldDidEndEditing(_ maskField: AKMaskField)
   {
      if activeInputView === maskField {
         activeInputView = nil
      }
   }
   
   func textFieldShouldReturn(_ textField: UITextField) -> Bool
   {
      if isNilOrEmpty(phoneField.text) {
         phoneField.becomeFirstResponder()
      }
      else {
         view.endEditing(true)
      }
      return true
   }
   
   func maskFieldShouldReturn(_ maskField: AKMaskField) -> Bool
   {
      if isNilOrEmpty(nameField.text) {
         nameField.becomeFirstResponder()
      }
      else {
         view.endEditing(true)
      }
      return true
   }

   func maskField(_ maskField: AKMaskField, didChangedWithEvent event: AKMaskFieldEvent)
   {
      updateButtonEnabled()
   }
   
   @IBAction func textFieldEditingChanged(_ sender: UITextField)
   {
      updateButtonEnabled()
   }
   
   //MARK: - Actions
   
   @IBAction func confirmTap()
   {
      OrderName = nameField.text
      OrderPhone = String(phoneNumbers)
      
      if OrderReceiveNotifications
      {
         AppDelegate.registerForPushNotifications
         {
            registered in
            OrderReceiveNotifications = registered
            self.performSegue(withIdentifier: "Order", sender: self)
         }
      }
      else {
         performSegue(withIdentifier: "Order", sender: self)
      }
   }
}
