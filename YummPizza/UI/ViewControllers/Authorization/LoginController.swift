//
//  LoginController.swift
//  YummPizza
//
//  Created by Blaze Mac on 4/10/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

let decimalDigits = "0123456789".characters
var registrationPhoneNumber : String = ""
var registrationSmsToken : String = ""
var lastPhoneCodeSentTime : Date = Date.distantPast

weak var loginController : LoginController?

class LoginController: UIViewController, UITextFieldDelegate
{   
   @IBOutlet weak var scrollview: UIScrollView!
   @IBOutlet weak var phoneField: UITextField!
   @IBOutlet weak var passwordField: UITextField!
   @IBOutlet weak var showPasswordButton: YPCheckButton!
   @IBOutlet weak var loginButton: UIButton!
   @IBOutlet weak var registerButton: UIButton!
   @IBOutlet weak var phoneWarningLabel: UILabel!
   @IBOutlet weak var acceptTermsCheckButton: YPCheckButton!
   @IBOutlet weak var termsAlertView: UIView!
   
   var acceptTerms : Bool
   {
      get { return acceptTermsCheckButton?.isChecked ?? false }
      set { acceptTermsCheckButton?.isChecked = newValue }
   }
   
   var phoneNumbers : [Character] {
      return phoneField?.text?.characters.filter({decimalDigits.contains($0)}) ?? []
   }
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      setupForKeyboard()
      updateButtonEnabled()
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      loginController = self
      if let navController = navigationController
      {
         let navigationBar = navController.navigationBar
         navigationBar.isTranslucent = true
         navigationBar.shadowImage = UIImage()
         navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
         
         if navController.viewControllers.first === self {
            navigationItem.leftBarButtonItems = []
         }
         else {
            self.backNavTitle = ""
         }
      }
   }
   
   override func navigationBackTap()
   {
      _ = navigationController?.popViewController(animated: true)
      AppDelegate.customLoginAction = nil
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?)
   {
      if segue.identifier == "Register"
      {
         let registerController = segue.destination as! RegistrationPhoneController
         _ = registerController.view
         registerController.phoneField.text = phoneField.text?.replacingOccurrences(of: " ", with: "")
      }
      else if segue.identifier == "RestorePassword"
      {
         let restoreController = segue.destination as! RestorationPhoneController
         _ = restoreController.view
         restoreController.phoneField.text = phoneField.text?.replacingOccurrences(of: " ", with: "")
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
      loginButton.isEnabled = !isNilOrEmpty(phoneField.text) && !isNilOrEmpty(passwordField.text)
   }
   
   public func updatePhoneString(_ string : String)
   {
      var phone = string.characters.reduce("")
      {
         (currentPhone, char) -> String in
         guard decimalDigits.contains(char) else { return currentPhone }
         
         let currentLength = currentPhone.characters.count as Int
         switch currentLength
         {
         case let x where x == 1 || x == 5 || (x >= 9 && x % 3 == 0):
            return currentPhone + " " + String(char)
         
         default:
            return currentPhone + String(char)
         }
      }
      
      if phone.isEmpty {
         phone = "+7"
      }
      else {
         phone = "+".appending(phone)
      }
 
      phoneField.text = phone
      //+7 905 555 55 55
   }
   
   func login()
   {
      let phone = String(phoneNumbers)
      guard let password = passwordField.text, !password.isEmpty, !phone.isEmpty else { return }
      
      RequestManager.login(phoneNumber: phone, password: password,
      success:
      {
         user in
         AppDelegate.registerForPushNotifications
         {
            registered in
            AppDelegate.login(user)
         }
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
   }
   
   func showTerms()
   {
      let webController = WebViewController()
      webController.backNavTitle = ""
      webController.navigationItem.title = ScreenWidth > 320 ? "ПОЛЬЗОВАТЕЛЬСКОЕ СОГЛАШЕНИЕ" : "СОГЛАШЕНИЕ"
      let urlString = CommonValue.forKey("TERMS_OF_USE")?.value ?? "https://yummpizza.ru/polzovatelskoe_soglashenie/"
      webController.url = URL(string: urlString)
      navigationController?.pushViewController(webController, animated: true)
   }
   
   private var onTermsConfirm : (() -> Void)?
   func showTermsAlert(animated : Bool = true, onConfirm: @escaping () -> Void = {})
   {
      onTermsConfirm = onConfirm
      UIView.animate(withDuration: (animated ? 0.3 : 0)) {
         self.termsAlertView.alpha = 1
      }
   }
   
   func hideTermsAlert(animated : Bool = true, completion: @escaping () -> Void = {})
   {
      UIView.animate(withDuration: (animated ? 0.3 : 0),
      animations: {
         self.termsAlertView.alpha = 0
      },
      completion: { _ in completion() })
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
      case phoneField:
         if isNilOrEmpty(passwordField.text) {
            passwordField.becomeFirstResponder()
         }
         else {
            view.endEditing(true)
         }
      case passwordField:
         if isNilOrEmpty(phoneField.text) {
            phoneField.becomeFirstResponder()
         }
         else {
            view.endEditing(true)
         }
      default: break;
      }
      
      return true
   }
   
   func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
   {
      guard textField === phoneField else { return true }
      
      phoneWarningLabel.isHidden = true
      phoneField.borderColor = YPColorTextFieldBorderNormal
      
      let oldString = (textField.text ?? "") as NSString
      let newString = oldString.replacingCharacters(in: range, with: string)
      
      if string.isEmpty
      {
         let removingString = oldString.substring(with: range)
         if removingString == " ", let newCursorPosition = textField.position(from: textField.beginningOfDocument, offset: range.location)
         {
            textField.selectedTextRange = textField.textRange(from: newCursorPosition, to: newCursorPosition)
            return false
         }
      }         
      
      if let selectedRange = textField.selectedTextRange
      {
         let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)
         
         updatePhoneString(newString)
         
         let newLength = (textField.text ?? "").characters.count as Int
         if let newCursorPosition = textField.position(from: textField.beginningOfDocument,
                                                       offset: cursorPosition + newLength - oldString.length)
         {
            textField.selectedTextRange = textField.textRange(from: newCursorPosition, to: newCursorPosition)
         }
      }
      else
      {
         updatePhoneString(newString)
      }
         
      return false
   }
   
   @IBAction func textFieldEditingChanged(_ sender: UITextField)
   {
      updateButtonEnabled()
   }
   
   //MARK: - Actions
   
   @IBAction func showPasswordTap(_ sender: YPCheckButton) {
      passwordField.isSecureTextEntry = !sender.isChecked
   }
   
   @IBAction func termsTap() {
      showTerms()
   }
   
   @IBAction func registerTap()
   {
      if acceptTerms {
         performSegue(withIdentifier: "Register", sender: self)
      }
      else {
         showTermsAlert(onConfirm: { self.performSegue(withIdentifier: "Register", sender: self) })
      }
   }
   
   @IBAction func continueTap()
   {
      AppDelegate.login(User.defaultUser())
   }
   
   @IBAction func forgotPasswordTap()
   {
      if acceptTerms {
         performSegue(withIdentifier: "RestorePassword", sender: self)
      }
      else {
         showTermsAlert(onConfirm: { self.performSegue(withIdentifier: "RestorePassword", sender: self) })
      }
   }
   
   @IBAction func termsAlertHideTap(_ sender: Any) {
      hideTermsAlert()
   }
   
   @IBAction func termsConfirmTap()
   {
      acceptTerms = true
      hideTermsAlert
      {
         self.onTermsConfirm?()
         self.onTermsConfirm = nil
      }
   }
   
   @IBAction func loginTap()
   {
      if phoneNumbers.count < 11
      {
         phoneWarningLabel.isHidden = false
         phoneField.borderColor = YPColorTextFieldBorderError
      }
      else
      {
         view.endEditing(true)
         if acceptTerms {
            login()
         }
         else {
            showTermsAlert(onConfirm: { self.login() })
         }
      }
   }
}
