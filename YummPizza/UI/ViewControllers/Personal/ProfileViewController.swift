//
//  ProfileViewController.swift
//  YummPizza
//
//  Created by Georgy Solovei on 5/31/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import AKMaskField
import ActionSheetPicker

class ProfileViewController: UIViewController, UITextFieldDelegate
{
   @IBOutlet weak var scrollview: UIScrollView!
   @IBOutlet weak var phoneNumberField: AKMaskField!
   @IBOutlet weak var nameField: UITextField!
   @IBOutlet weak var emailField: UITextField!
   @IBOutlet weak var birthdayField: UITextField!
   @IBOutlet weak var birthdayTapButtonLimitToIcon: NSLayoutConstraint!
   @IBOutlet weak var changePasswordButton: UIButton!
   @IBOutlet weak var addressButton: UIButton!
   @IBOutlet weak var addressLabel: UILabel!

   @IBOutlet weak var nameErrorLabel: UILabel!
   @IBOutlet weak var emailErrorLabel: UILabel!
  
   @IBOutlet weak var genderMaleRadioButton: YPRadioButton!
   @IBOutlet weak var genderFemaleRadioButton: YPRadioButton!
   @IBOutlet weak var pushNotificationsCheckButton: YPCheckButton!
   @IBOutlet weak var mainAddressView: UIView!
   @IBOutlet weak var expandImageView: UIImageView!
   @IBOutlet weak var showAddressPickerButton: UIButton!
    
   private typealias FieldWithLabel = (textField : UITextField, label : UILabel)
   private var inputFieldName : FieldWithLabel!
   private var inputFieldEmail : FieldWithLabel!
   
   var addressListIsEmpty : Bool = true
   {
      didSet
      {
         if addressListIsEmpty
         {
            addressLabel.text = nil
            addressButton.setTitle("Добавить", for: .normal)
         }
         else
         {
            addressLabel.text = mainAddress?.streetHouseString
            addressButton.setTitle("Редактировать адреса", for: .normal)
         }
      }
   }

   var mainAddress : Address?
   {
      didSet {
         addressLabel?.text = mainAddress?.streetHouseString
      }
   }
   
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

   // MARK: - Lifecycle
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      setupForKeyboard()

      updateWithUserData()
      RequestManager.updateUserInfo(showSpinner: true, success:
      {
         [weak self] in
         self?.updateWithUserData()
      },
      failure:
      {
         [weak self]
         errorDescription in
         dlog(errorDescription)
         guard self != nil else { return }
         AlertManager.showAlert(errorDescription, buttonTitle: "Закрыть")
      })
 
      inputFieldName = (nameField, nameErrorLabel)
      inputFieldEmail = (emailField, emailErrorLabel)
      setInputFieldError(inputFieldName,  isError: false, animated: false)
      setInputFieldError(inputFieldEmail, isError: false, animated: false)
   }
 
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      UIView.performWithoutAnimation
      {
         if (mainAddress?.isInvalidated ?? true) {
            mainAddress = User.current?.mainAddress
         }
         addressListIsEmpty = isNilOrEmpty(User.current?.deliveryAddresses)
         if let user = User.current, user.deliveryAddresses.count > 1
         {
            expandImageView.isHidden = false
            showAddressPickerButton.isEnabled = true
         }
         else
         {
            expandImageView.isHidden = true
            showAddressPickerButton.isEnabled = false
         }
         addressButton.layoutIfNeeded()
      }
   }

    
   //MARK: - Methods
   
   func updateWithUserData()
   {
      if let user = User.current
      {
         mainAddress = user.mainAddress
         phoneNumberField.text = user.phoneNumber
         birthdayDate = user.birthday
         genderMaleRadioButton.isSelected = (user.gender == .male)
         genderFemaleRadioButton.isSelected = (user.gender == .female)
         pushNotificationsCheckButton.isChecked = user.allowPushNotifications
         nameField.text = user.name
         emailField.text = user.email
      }
      else
      {
         mainAddress = nil
         phoneNumberField.text = nil
         birthdayDate = nil
         genderMaleRadioButton.isSelected = false
         genderFemaleRadioButton.isSelected = false
         pushNotificationsCheckButton.isChecked = false
         nameField.text = nil
         emailField.text = nil
      }
   }
   
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
 
      return !isErrors
   }
    
    
   // MARK: - Delegate methods
   
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
      switch textField
      {
      case nameField where isNilOrEmpty(emailField.text):
         emailField.becomeFirstResponder()
      case emailField where isNilOrEmpty(nameField.text):
         nameField.becomeFirstResponder()
      default: view.endEditing(true)
      }
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
   
   
   //MARK: - Actions
    
   @IBAction func birthdayTap()
   {
//      let dateController = Storyboard.instantiateViewController(withIdentifier: "DatePickerController") as! DatePickerController
//      dateController.date = birthdayDate.getDate()
//      dateController.onCompletion =
//      {
//         date in
//         self.birthdayDate = DMYDate(fromDate: date)
//      }
//      present(dateController, animated: true, completion: nil)
   }
    
   @IBAction func showAddressPicker(_ sender: UIButton)
   {
      guard let addresses = User.current?.deliveryAddresses, !addresses.isEmpty else { return }
      var deliveryAddresses : [String] = []
      for address in addresses.prefix(5) {
         deliveryAddresses.append(address.streetHouseString)
      }
      
      guard !deliveryAddresses.isEmpty else { return }
      
      let picker = ActionSheetStringPicker(title: nil,
                                           rows: deliveryAddresses,
                                           initialSelection: 0,
                                           doneBlock:
                                           {
                                             picker, index, value in
                                             if let user = User.current, index < user.deliveryAddresses.count {
                                                self.mainAddress = user.deliveryAddresses[index]
                                             }
                                           },
                                           cancel: nil,
                                           origin: sender)!
      picker.hideCancel = true
      picker.tapDismissAction = .cancel
      picker.show()
   }
    
   @IBAction func changeAddressesTapped(_ sender: UIButton)
   {
      if addressListIsEmpty
      {
         let addressController = Storyboard.instantiateViewController(withIdentifier: "AddressController") as! AddressController
         addressController.mode = .add
         navigationController?.pushViewController(addressController, animated: true)
      }
      else
      {
         let addressListController = Storyboard.instantiateViewController(withIdentifier: "AddressListController") as! AddressListController
         addressListController.mode = .edit
         navigationController?.pushViewController(addressListController, animated: true)
      }
   }
    
   @IBAction func saveChangesTapped(_ sender: UIButton)
   {
      guard validateInput() else { return }
        
      setInputFieldError(inputFieldName,  isError: false, animated: true)
      setInputFieldError(inputFieldEmail, isError: false, animated: true)

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
      
      view.endEditing(true)
      
      let name = nameField.text ?? ""
      let email = emailField.text ?? ""
      let birthday = birthdayDate
      let pushEnabled = pushNotificationsCheckButton.isChecked
      
      RequestManager.changeUserInfo(name: name, email: email, birthdayString : birthday?.description ?? "", gender : gender, pushEnabled : pushEnabled, showSpinner : true,
      success :
      {
         if let address = self.mainAddress, let user = User.current, user.mainAddress?.streetHouseString != address.streetHouseString
         {
            user.modifyWithTransactionIfNeeded
            {
               user.mainAddress = address
               user.name = name
               user.email = email
               user.birthday = birthday
               user.allowPushNotifications = pushEnabled
            }
         }
         AlertManager.showAlert("Данные профиля обновлены")
      },
      failure :
      {
         errorDescription in
         switch errorDescription
         {
         case "ERROR_INVALID_DATA": AlertManager.showAlert("Неверные данные")
         case "ERROR_CREATING_USER": AlertManager.showAlert("Ошибка при создании пользователя")
         case "ERROR_CREATING_IIKO_USER": AlertManager.showAlert("Ошибка при создании пользователя в системе IIKO")
         default: AlertManager.showAlert(errorDescription)
         }
      })
   }
}
