//
//  RegistrationProfileController.swift
//  YummPizza
//
//  Created by Blaze Mac on 4/11/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import AKMaskField

class RegistrationProfileController: UIViewController, UITextFieldDelegate
{
   @IBOutlet weak var scrollview: UIScrollView!
   @IBOutlet weak var phoneField: AKMaskField!
   @IBOutlet weak var nameField: UITextField!
   @IBOutlet weak var nameErrorLabel: UILabel!
   @IBOutlet weak var emailField: UITextField!
   @IBOutlet weak var emailErrorLabel: UILabel!
   @IBOutlet weak var passwordField: UITextField!
   @IBOutlet weak var passwordErrorLabel: UILabel!
   @IBOutlet weak var passwordRepeatField: UITextField!
   @IBOutlet weak var passwordRepeatErrorLabel: UILabel!
   @IBOutlet weak var birthdayField: UITextField!
   @IBOutlet weak var birthdayTapButtonLimitToIcon: NSLayoutConstraint!
   @IBOutlet weak var genderMaleRadioButton: YPRadioButton!
   @IBOutlet weak var genderFemaleRadioButton: YPRadioButton!
   @IBOutlet weak var registerButton: UIButton!
   
   private typealias FieldWithLabel = (textField : UITextField, label : UILabel)
   private var inputFieldName : FieldWithLabel!
   private var inputFieldEmail : FieldWithLabel!
   private var inputFieldPassword : FieldWithLabel!
   private var inputFieldRepeatPassword : FieldWithLabel!
   
   private var birthdayDate : DMYDate?
   {
      didSet
      {
         if let date = birthdayDate {
            birthdayField?.text = String(format: "%02d/%02d/%d", date.day, date.month, date.year)
            birthdayField?.clearButtonMode = .always
            birthdayField?.isUserInteractionEnabled = true
            birthdayTapButtonLimitToIcon?.priority = UILayoutPriority(rawValue: 999)
         }
         else {
            birthdayField?.text = nil
            birthdayField.clearButtonMode = .never
            birthdayField?.isUserInteractionEnabled = false
            birthdayTapButtonLimitToIcon?.priority = UILayoutPriority(rawValue: 1)
         }
      }
   }
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      setupForKeyboard()
      updateButtonEnabled()
      
      phoneField.text = registrationPhoneNumber
      
      inputFieldName = (nameField, nameErrorLabel)
      inputFieldEmail = (emailField, emailErrorLabel)
      inputFieldPassword = (passwordField, passwordErrorLabel)
      inputFieldRepeatPassword = (passwordRepeatField, passwordRepeatErrorLabel)
      
      setInputFieldError(inputFieldName, isError: false, animated: false)
      setInputFieldError(inputFieldEmail, isError: false, animated: false)
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
      registerButton.isEnabled = !isNilOrEmpty(passwordField.text) && !isNilOrEmpty(passwordRepeatField.text)
   }
   
   func validateInput() -> Bool
   {
      var isErrors = false
      
      if let name = nameField.text, !name.isEmpty
      {
         if name.characters.count < 2 {
            setInputFieldError(inputFieldName, "Минимальное количество символов 2")
            isErrors = true
         }
         else if name.characters.count > 50 {
            setInputFieldError(inputFieldName, "Максимальное количество символов 50")
            isErrors = true
         }
         else if name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            setInputFieldError(inputFieldName, "Недопустимое имя")
            isErrors = true
         }
      }
      
      if let email = emailField.text, !email.isEmpty
      {
         if !email.isValidEmail {
            setInputFieldError(inputFieldEmail, "Некорректный адрес электронной почты")
            isErrors = true
         }
      }
  
      if let password = passwordField.text, !password.isEmpty
      {
         if password.characters.count < 6 {
            setInputFieldError(inputFieldPassword, "Минимальное количество символов 6")
            isErrors = true
         }
         else if password.characters.count > 20 {
            setInputFieldError(inputFieldPassword, "Максимальное количество символов 20")
            isErrors = true
         }
         else if password.contains(" ") {
            setInputFieldError(inputFieldPassword, "Недопустимый пароль")
            isErrors = true
         }
         else
         {
            if let repeatPassword = passwordRepeatField.text, !repeatPassword.isEmpty
            {
               if repeatPassword != password
               {
                  setInputFieldError(inputFieldRepeatPassword, "Пароль не совпадает")
                  isErrors = true
               }
            }
            else
            {
               setInputFieldError(inputFieldRepeatPassword, "Подтвердите введенный пароль")
               isErrors = true
            }
         }
         
      }
      else
      {
         setInputFieldError(inputFieldPassword, "Введите пароль")
         isErrors = true
      }
      
      return !isErrors
   }
   
   func register(name: String, email: String, password: String, gender: Gender)
   {
      view.isUserInteractionEnabled = false
      AppDelegate.registerForPushNotifications
      {
         registered in
         self.view.isUserInteractionEnabled = true
         
         let birthday = self.birthdayDate
         RequestManager.registration(name: name, smsToken: registrationSmsToken, gender: gender, birthday: birthday, email: email, password: password,
         success:
         {
            userToken in
            let user = User.user(registrationPhoneNumber)!
            user.modifyWithTransactionIfNeeded
            {
               user.token = userToken
               user.email = email
               user.name = name
               user.birthday = birthday
               user.gender = gender
            }
            AppDelegate.login(user)
         },
         failure:
         {
            errorDescription in
            switch errorDescription
            {
            case "ERROR_INVALID_DATA": AlertManager.showAlert("Неверные данные")
            case "ERROR_WEAK_PASSWORD": AlertManager.showAlert("Слишком простой пароль")
            case "ERROR_NO_SUCH_SMS_TOKEN": AlertManager.showAlert("Отсутствует указанный вами смс код")
            case "ERROR_CREATING_USER": AlertManager.showAlert("Ошибка при создании пользователя")
            case "ERROR_CREATING_IIKO_USER": AlertManager.showAlert("Ошибка при создании пользователя в системе IIKO")
            default: AlertManager.showAlert(errorDescription)
            }
         })
      }
   }
   
   //MARK: - TextField
   
   func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
   {
      if textField === birthdayField {
         return false
      }
      activeInputView = textField
      return true
   }
   
   func textFieldDidEndEditing(_ textField: UITextField)
   {
      if activeInputView === textField {
         activeInputView = nil
      }
   }
   
   func textFieldShouldClear(_ textField: UITextField) -> Bool
   {
      if textField === birthdayField
      {
         birthdayDate = nil
         return false
      }
      return true
   }
   
   func textFieldShouldReturn(_ textField: UITextField) -> Bool
   {
      let textFields : [UITextField] = [nameField, emailField, passwordField, passwordRepeatField]
      
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
      if sender === nameField {
         setInputFieldError(inputFieldName, isError: false)
      }
      else if sender === emailField {
         setInputFieldError(inputFieldEmail, isError: false)
      }
      else if sender === passwordField {
         setInputFieldError(inputFieldPassword, isError: false)
         
      }
      else if sender === passwordRepeatField {
         setInputFieldError(inputFieldRepeatPassword, isError: false)
      }
      
      updateButtonEnabled()
   }
   
   //MARK: - Actions
   
   @IBAction func birthdayTap()
   {
      let dateController = Storyboard.instantiateViewController(withIdentifier: "DatePickerController") as! DatePickerController
      dateController.date = birthdayDate?.getDate() ?? Date()
      dateController.onCompletion =
      {
         date in
         self.birthdayDate = DMYDate(fromDate: date)
      }
      present(dateController, animated: true, completion: nil)
   }
   
   @IBAction func registerTap()
   {
      guard validateInput() else { return }
      
      let gender: Gender
      if let selectedRadioButton = genderMaleRadioButton.selectedButton
      {
         switch selectedRadioButton
         {
         case genderMaleRadioButton: gender = .male
         case genderFemaleRadioButton: gender = .female
         default: gender = .unknown
         }
      }
      else {
         gender = .unknown
      }
      
      register(name: nameField.text ?? "", email: emailField.text ?? "", password: passwordField.text ?? "", gender: gender)
   }
}
