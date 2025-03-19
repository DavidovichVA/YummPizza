//
//  RestorationCodeController.swift
//  YummPizza
//
//  Created by Blaze Mac on 4/11/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class RestorationCodeController: UIViewController, UITextFieldDelegate
{
   @IBOutlet weak var codeField: UITextField!
   @IBOutlet weak var confirmButton: UIButton!
   @IBOutlet weak var resendButton: UIButton!
   
   var timer: Timer?
   
   override func viewDidLoad()
   {
      super.viewDidLoad()      
      let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboardTap))
      view.addGestureRecognizer(tapRecognizer)
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
   
   //MARK: - Methods
   
   @objc private func hideKeyboardTap() {
      view.endEditing(true)
   }
   
   @objc func updateButtonEnabled()
   {
      confirmButton.isEnabled = !isNilOrEmpty(codeField.text)
      if (-lastPhoneCodeSentTime.timeIntervalSinceNow >= 60)
      {
         resendButton.alpha = 1
         resendButton.isUserInteractionEnabled = true
      }
      else
      {
         resendButton.alpha = 0.3
         resendButton.isUserInteractionEnabled = false
      }
   }
   
   func sendCode(_ code : String)
   {
      RequestManager.restorePassword(phoneNumber: registrationPhoneNumber, smsCode: code,
      success:
      {
         smsToken in
         registrationSmsToken = smsToken
         self.performSegue(withIdentifier: "NewPassword", sender: self)
      },
      failure:
      {
         errorDescription in
         switch errorDescription
         {
         case "ERROR_NO_SUCH_USER": AlertManager.showAlert("Пользователь с этими данными не зарегистрирован")
         case "ERROR_INVALID_DATA": AlertManager.showAlert("Не указан телефонный номер")
         case "ERROR_INVALID_PHONE_INPUT": AlertManager.showAlert("Неверный формат телефонного номера")
         case "ERROR_WRONG_SMS_CODE": AlertManager.showAlert("Неверный смс код")
         case "ERROR_SERVER_INTERNAL": AlertManager.showAlert("Ошибка при отправке смс")
         default: AlertManager.showAlert(errorDescription)
         }
      })
   }
   
   func resendPhone()
   {
      RequestManager.restorePassword(phoneNumber: registrationPhoneNumber,
      success:
      {
         AlertManager.showAlert("Код отправлен в СМС")
         lastPhoneCodeSentTime = Date()
         self.updateButtonEnabled()
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
   }
   
   //MARK: - TextField
   
   @IBAction func textFieldEditingChanged(_ sender: UITextField)
   {
      updateButtonEnabled()
   }
   
   //MARK: - Actions
   
   @IBAction func confirmTap()
   {
      if let code = codeField.text, !code.isEmpty {
         sendCode(code)
      }
   }
   
   @IBAction func resendTap()
   {
      resendPhone()
   }
}
