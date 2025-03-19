//
//  RegistrationPhoneController.swift
//  YummPizza
//
//  Created by Blaze Mac on 4/11/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import AKMaskField

class RegistrationPhoneController: UIViewController, AKMaskFieldDelegate
{
   @IBOutlet weak var phoneField: AKMaskField!
   @IBOutlet weak var checkButton: UIButton!
   
   var phoneNumbers : [Character] {
      return phoneField?.text?.characters.filter({decimalDigits.contains($0)}) ?? []
   }
   
   var timer: Timer?
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      
      phoneField.maskDelegate = self
      phoneField.jumpToPrevBlock = true
      
      let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboardTap))
      view.addGestureRecognizer(tapRecognizer)
      
      lastPhoneCodeSentTime = Date.distantPast
      updateButtonEnabled()
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
      updateButtonEnabled()
      timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateButtonEnabled), userInfo: nil, repeats: true)
   }
   
   override func viewWillDisappear(_ animated: Bool)
   {
      super.viewWillDisappear(animated)
      timer?.invalidate()
   }
   
   @objc private func hideKeyboardTap() {
      view.endEditing(true)
   }
   
   func register()
   {
      let phone = String(phoneNumbers)
      
      RequestManager.registration(phoneNumber: phone,
      success:
      {
         registrationPhoneNumber = phone
         lastPhoneCodeSentTime = Date()
         self.performSegue(withIdentifier: "RegistrationCode", sender: self)
      },
      failure:
      {
         errorDescription in
         
         switch errorDescription
         {
         case "ERROR_INVALID_DATA": AlertManager.showAlert("Не указан телефонный номер")
         case "ERROR_INVALID_PHONE_INPUT": AlertManager.showAlert("Неверный формат телефонного номера")
         case "ERROR_SERVER_INTERNAL": AlertManager.showAlert("Ошибка при отправке смс")
            
         case "ERROR_USER_WITH_THIS_PHONE_ALREADY_EXIST":
            let alertController = UIAlertController(title: "Номер уже зарегистрирован в системе", message: nil, preferredStyle: .alert)
            
            let cancel = UIAlertAction(title: "Отмена", style: .cancel)
            alertController.addAction(cancel)
            
            let enterPassword = UIAlertAction(title: "Ввести пароль", style: .default, handler:
            {
               _ in
               if let navController = self.navigationController, let loginController = navController.viewControllers.first as? LoginController
               {
                  loginController.updatePhoneString(String(self.phoneNumbers))
                  loginController.passwordField.text = ""
                  navController.popToRootViewController(animated: true)
               }
            })
            alertController.addAction(enterPassword)
            
            let restorePassword = UIAlertAction(title: "Восстановить пароль", style: .default, handler:
            {
               _ in
               RequestManager.restorePassword(phoneNumber: phone, success:
               {
                  registrationPhoneNumber = phone
                  lastPhoneCodeSentTime = Date()
                  self.performSegue(withIdentifier: "RestorationCode", sender: self)
               },
               failure:
               {
                  errorDescription in
                  switch errorDescription
                  {
                  case "ERROR_NO_SUCH_USER": AlertManager.showAlert("Пользователь с этими данными не зарегистрирован")
                  case "ERROR_INVALID_DATA": AlertManager.showAlert("Не указан телефонный номер")
                  case "ERROR_INVALID_PHONE_INPUT": AlertManager.showAlert("Неверный формат телефонного номера")
                  case "ERROR_SERVER_INTERNAL": AlertManager.showAlert("Ошибка при отправке смс")
                  default: AlertManager.showAlert(errorDescription)
                  }
               })
               
            })
            alertController.addAction(restorePassword)
            
            AlertManager.showAlert(alertController)
            
         default: AlertManager.showAlert(errorDescription)
         }
      })
   }
   
   @objc func updateButtonEnabled()
   {
      checkButton.isEnabled = (phoneField.maskStatus == .complete) &&
         (-lastPhoneCodeSentTime.timeIntervalSinceNow >= 60)
   }
   
   func maskField(_ maskField: AKMaskField, didChangedWithEvent event: AKMaskFieldEvent)
   {
      updateButtonEnabled()
   }
   
   @IBAction func checkTap()
   {
      view.endEditing(true)
      register()
   }
}
