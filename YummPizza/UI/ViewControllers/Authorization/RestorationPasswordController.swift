//
//  RestorationPasswordController.swift
//  YummPizza
//
//  Created by Blaze Mac on 4/11/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class RestorationPasswordController: UIViewController, UITextFieldDelegate
{
   @IBOutlet weak var scrollview: UIScrollView!
   @IBOutlet weak var passwordField: UITextField!   
   @IBOutlet weak var repeatPasswordField: UITextField!
   @IBOutlet weak var passwordErrorLabel: UILabel!
   @IBOutlet weak var repeatErrorLabel: UILabel!
   @IBOutlet weak var confirmButton: UIButton!
   
   private typealias FieldWithLabel = (textField : UITextField, label : UILabel)
   private var inputFieldPassword : FieldWithLabel!
   private var inputFieldRepeatPassword : FieldWithLabel!
    
   override func viewDidLoad()
   {
      super.viewDidLoad()
      setupForKeyboard()
      updateButtonEnabled()
      
      inputFieldPassword = (passwordField, passwordErrorLabel)
      inputFieldRepeatPassword = (repeatPasswordField, repeatErrorLabel)
      
      setInputFieldError(inputFieldPassword, isError: false, animated: false)
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
      confirmButton.isEnabled = !isNilOrEmpty(passwordField.text) && !isNilOrEmpty(repeatPasswordField.text)
   }
   
   func validateInput() -> Bool
   {
      guard let password = passwordField.text, !password.isEmpty else {
         setInputFieldError(inputFieldPassword, "Введите пароль")
         return false
      }
      
      var errorDesc = ""
      
      if password.characters.count < 6 {
         errorDesc = "Минимальное количество символов 6"
      }
      else if password.characters.count > 20 {
         errorDesc = "Максимальное количество символов 20"
      }
      else if password.contains(" ") {
         errorDesc = "Недопустимый пароль"
      }
      if !errorDesc.isEmpty
      {
         setInputFieldError(inputFieldPassword, errorDesc)
         return false
      }
      
      guard let repeatPassword = repeatPasswordField.text, !repeatPassword.isEmpty else {
         setInputFieldError(inputFieldRepeatPassword, "Подтвердите введенный пароль")
         return false
      }
      
      if repeatPassword != password
      {
         setInputFieldError(inputFieldRepeatPassword, "Пароль не совпадает")
         return false
      }
      
      return true
   }
   
   func changePassword(newPassword : String)
   {
      RequestManager.restorePassword(smsToken: registrationSmsToken, newPassword: newPassword,
      success:
      {
         AlertManager.showAlert("Пароль изменен", completion:
         {
            RequestManager.login(phoneNumber: registrationPhoneNumber, password: newPassword,
            success:
            {
               user in
               AppDelegate.login(user)
            },
            failure:
            {
               errorDescription in
               switch errorDescription
               {
               case "ERROR_NO_SUCH_USER": AlertManager.showAlert("Пользователь с этими данными не зарегистрирован")
               case "ERROR_WRONG_PASSWORD": AlertManager.showAlert("Неверный телефон или пароль")
               default: AlertManager.showAlert(errorDescription)
               }
            })
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
         case "ERROR_NO_SUCH_SMS_TOKEN": AlertManager.showAlert("Отсутствует указанный вами смс код")
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
      switch textField {
      case passwordField:
         if isNilOrEmpty(repeatPasswordField.text) {
            repeatPasswordField.becomeFirstResponder()
         }
         else {
            view.endEditing(true)
         }
      case repeatPasswordField:
         if isNilOrEmpty(passwordField.text) {
            passwordField.becomeFirstResponder()
         }
         else {
            view.endEditing(true)
         }
      default: break;
      }
      
      return true
   }
   
   @IBAction func textFieldEditingChanged(_ sender: UITextField)
   {
      if sender === passwordField {
         setInputFieldError(inputFieldPassword, isError: false)
         
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
         changePassword(newPassword: passwordField.text!)
      }
   }
}
