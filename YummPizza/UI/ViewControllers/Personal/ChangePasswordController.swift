//
//  ChangePasswordController.swift
//  YummPizza
//
//  Created by Blaze Mac on 4/11/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class ChangePasswordController: UIViewController, UITextFieldDelegate
{
   @IBOutlet weak var scrollview: UIScrollView!
   @IBOutlet weak var currentPasswordField: UITextField!
   @IBOutlet weak var newPasswordField: UITextField!
   @IBOutlet weak var repeatPasswordField: UITextField!
   @IBOutlet weak var currentPasswordErrorLabel: UILabel!
   @IBOutlet weak var newPasswordErrorLabel: UILabel!
   @IBOutlet weak var repeatErrorLabel: UILabel!
   @IBOutlet weak var confirmButton: UIButton!
   
   private typealias FieldWithLabel = (textField : UITextField, label : UILabel)
   private var inputFieldCurrentPassword : FieldWithLabel!
   private var inputFieldNewPassword : FieldWithLabel!
   private var inputFieldRepeatPassword : FieldWithLabel!
    
   override func viewDidLoad()
   {
      super.viewDidLoad()
      setupForKeyboard()
      updateButtonEnabled()
      
      inputFieldCurrentPassword = (currentPasswordField, currentPasswordErrorLabel)
      inputFieldNewPassword = (newPasswordField, newPasswordErrorLabel)
      inputFieldRepeatPassword = (repeatPasswordField, repeatErrorLabel)
      
      setInputFieldError(inputFieldCurrentPassword, isError: false, animated: false)
      setInputFieldError(inputFieldNewPassword, isError: false, animated: false)
      setInputFieldError(inputFieldRepeatPassword, isError: false, animated: false)
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      if let navigationBar = navigationController?.navigationBar
      {
         navigationBar.isTranslucent = false
         navigationBar.shadowImage = nil
         navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
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
   
   private func setInputFieldError(_ inputField : FieldWithLabel, _ text : String = "", isError : Bool = true, animated : Bool = true)
   {
      if isError
      {
         inputField.textField.borderColor = YPColorTextFieldBorderError
         inputField.label.setTextKeepingAttributes(text)
      }
      else
      {
         inputField.textField.borderColor = YPColorTextFieldBorderNormal
         inputField.label.setTextKeepingAttributes("")
      }
      
      if animated
      {
         UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
         })
      }
   }
   
   func updateButtonEnabled()
   {
      confirmButton.isEnabled = !isNilOrEmpty(currentPasswordField.text) &&
         !isNilOrEmpty(newPasswordField.text) && !isNilOrEmpty(repeatPasswordField.text)
   }
   
   func validateInput() -> Bool
   {
      guard let currentPassword = currentPasswordField.text, !currentPassword.isEmpty else {
         setInputFieldError(inputFieldCurrentPassword, "Введите текущий пароль")
         return false
      }
      
      guard let newPassword = newPasswordField.text, !newPassword.isEmpty else {
         setInputFieldError(inputFieldNewPassword, "Введите новый пароль")
         return false
      }
      
      var errorDesc = ""
      
      if newPassword.characters.count < 6 {
         errorDesc = "Минимальное количество символов 6"
      }
      else if newPassword.characters.count > 20 {
         errorDesc = "Максимальное количество символов 20"
      }
      else if newPassword.contains(" ") {
         errorDesc = "Недопустимый пароль"
      }
      if !errorDesc.isEmpty
      {
         setInputFieldError(inputFieldNewPassword, errorDesc)
         return false
      }
      
      guard let repeatPassword = repeatPasswordField.text, !repeatPassword.isEmpty else {
         setInputFieldError(inputFieldRepeatPassword, "Подтвердите введенный пароль")
         return false
      }
      
      if repeatPassword != newPassword
      {
         setInputFieldError(inputFieldRepeatPassword, "Пароль не совпадает")
         return false
      }
      
      return true
   }
   
   func changePassword(currentPassword : String, newPassword : String)
   {
      RequestManager.changePassword(currentPassword : currentPassword, newPassword : newPassword,
      success:
      {
         AlertManager.showAlert("Пароль изменён", completion: {
            self.navigationController?.popViewController(animated: true)
         })
      },
      failure:
      {
         errorDescription in
         switch errorDescription
         {
         case "ERROR_NO_SUCH_USER": AlertManager.showAlert("Пользователь с этими данными не зарегистрирован")
         case "ERROR_INVALID_DATA": AlertManager.showAlert("Неверные данные")
         case "ERROR_WEAK_PASSWORD": AlertManager.showAlert("Слишком простой пароль")
         case "ERROR_WRONG_PASSWORD": AlertManager.showAlert("Неверный пароль")
         default: AlertManager.showAlert(errorDescription)
         }
      })
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
   
   func textFieldShouldReturn(_ textField: UITextField) -> Bool
   {
      let textFields : [UITextField] = [currentPasswordField, newPasswordField, repeatPasswordField]
      
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
      if sender === currentPasswordField {
         setInputFieldError(inputFieldCurrentPassword, isError: false)
      }
      else if sender === newPasswordField {
         setInputFieldError(inputFieldNewPassword, isError: false)
      }
      else if sender === repeatPasswordField {
         setInputFieldError(inputFieldRepeatPassword, isError: false)
      }
      
      updateButtonEnabled()
   }
   
   //MARK: - Actions
   
   @IBAction func confirmTap()
   {
      if validateInput() {
         changePassword(currentPassword : currentPasswordField.text!, newPassword : newPasswordField.text!)
      }
   }
}
