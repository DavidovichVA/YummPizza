//
//  PaymentSettingsController.swift
//  YummPizza
//
//  Created by Blaze Mac on 6/16/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import Alamofire

class PaymentSettingsController: UIViewController, UITextFieldDelegate
{
   @IBOutlet weak var scrollview: UIScrollView!
   @IBOutlet weak var paymentByCashButton: YPRadioButton!
   @IBOutlet weak var paymentByCardButton: YPRadioButton!
   @IBOutlet weak var useBonusesButton: YPCheckButton!
   @IBOutlet weak var useBonusesLabel: UILabel!
   @IBOutlet weak var useBonusesBigButton: UIButton!
   @IBOutlet weak var bonusesDescriptionLabel: UILabel!
   @IBOutlet weak var payBonusesView: UIView!
   @IBOutlet weak var payBonusesField: UITextField!
   @IBOutlet weak var descriptionLabelToReceivedBonusesConstraint: NSLayoutConstraint!
   @IBOutlet weak var payBonusesToReceivedBonusesConstraint: NSLayoutConstraint!
   @IBOutlet weak var receivedBonusesView: UIView!
   @IBOutlet weak var receivedBonusesLabel: UILabel!
   @IBOutlet weak var receivePushNotificationsButton: YPCheckButton!
   
   var receivedBonusSum : Decimal = 0
   var maxSumPaidWithBonuses : Decimal = 0
   var sumPaidWithBonuses : Decimal = 0 {
      didSet { updateDisplayedReceivedBonusSum() }
   }
   var payWithBonuses = false {
      didSet { updateDisplayedReceivedBonusSum() }
   }
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      setupForKeyboard()
      receivedBonusesView.isHidden = true
      payWithBonuses = OrderPaymentWithBonuses > 0
      if let user = User.current, user.isDefault {
         OrderReceiveNotifications = user.allowPushNotifications
      }
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
      
      maxSumPaidWithBonuses = Cart.maxSumPaidWithBonuses
      OrderPaymentWithBonuses = min(OrderPaymentWithBonuses, maxSumPaidWithBonuses)
      payWithBonuses = OrderPaymentWithBonuses > 0
      sumPaidWithBonuses = OrderPaymentWithBonuses
      
      update()
      
      if User.current?.isDefault == false
      {
         RequestManager.updateUserInfo(
         success:
         {
            [weak self] in
            self?.update()
         })
         
         RequestManager.updateCommonValues(
         success:
         {
            [weak self] in
            self?.update()
         })
         
         updateReceivedBonusSum()
      }
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?)
   {
      if segue.identifier == "Order"
      {
         if payWithBonuses {
            OrderPaymentWithBonuses = min(maxSumPaidWithBonuses, sumPaidWithBonuses)
         }
         else {
            OrderPaymentWithBonuses = 0
         }
      }
      else if segue.identifier == "ContactInfo"
      {
         OrderPaymentWithBonuses = 0
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
   
   deinit
   {
      bonusSumRequest?.cancel()
      if keyboardObserver != nil {
         NotificationCenter.default.removeObserver(keyboardObserver!)
      }
   }
   
   //MARK: - Methods
   
   func update()
   {
      paymentByCashButton.isSelected = OrderPaymentByCash
      receivePushNotificationsButton.isChecked = OrderReceiveNotifications
      if let user = User.current, !user.isDefault
      {
         useBonusesButton.isHidden = false
         useBonusesLabel.isHidden = false
         useBonusesBigButton.isHidden = false
         
         let bonusPoints = user.bonusPoints.value
         if bonusPoints > 0
         {
            maxSumPaidWithBonuses = Cart.maxSumPaidWithBonuses
            if maxSumPaidWithBonuses > 0
            {
               let bonusesText = "У вас накоплено \(bonusPoints) Р бонусов. Вы можете оплатить бонусами до \(maxSumPaidWithBonuses) Р заказа."
               bonusesDescriptionLabel.setTextKeepingAttributes(bonusesText)
               useBonusesButton.isEnabled = true
               sumPaidWithBonuses = min(sumPaidWithBonuses, maxSumPaidWithBonuses)
               payWithBonuses = sumPaidWithBonuses > 0
            }
            else
            {
               let bonusesText = "У вас накоплено \(bonusPoints) Р бонусов."
               bonusesDescriptionLabel.setTextKeepingAttributes(bonusesText)
               useBonusesButton.isEnabled = false
               payWithBonuses = false
               OrderPaymentWithBonuses = 0
            }
         }
         else
         {
            useBonusesButton.isEnabled = false
            payWithBonuses = false
            OrderPaymentWithBonuses = 0
            bonusesDescriptionLabel.setTextKeepingAttributes("У вас пока нет бонусов")
         }
         useBonusesButton.isChecked = payWithBonuses
         updatePayBonusesView()
         updateDisplayedReceivedBonusSum()
      }
      else
      {
         useBonusesButton.isHidden = true
         useBonusesLabel.isHidden = true
         useBonusesBigButton.isHidden = true
         
         useBonusesButton.isEnabled = false
         payWithBonuses = false
         OrderPaymentWithBonuses = 0
         bonusesDescriptionLabel.setTextKeepingAttributes("")
         useBonusesButton.isChecked = false
         updatePayBonusesView()
         updateDisplayedReceivedBonusSum()
      }
   }
   
   private weak var bonusSumRequest : DataRequest?
   func updateReceivedBonusSum()
   {
      var dishesWithCount : [String : Int] = [:]
      for item in Cart.items {
         dishesWithCount[item.dishVariant.id] = (dishesWithCount[item.dishVariant.id] ?? 0) + item.count
      }
      
      bonusSumRequest?.cancel()
      bonusSumRequest = RequestManager.getBonusSumForOrderDishes(dishesWithCount, success:
      {
         [weak self] sum in
         guard let strongSelf = self else { return }
         strongSelf.receivedBonusSum = sum
         strongSelf.updateDisplayedReceivedBonusSum()
      },
      failure:
      {
         errorDescription in
         dlog(errorDescription)
      })
   }
   
   func updateDisplayedReceivedBonusSum()
   {
      guard User.current?.isDefault == false else
      {
         receivedBonusesLabel.setTextKeepingAttributes(" ")
         receivedBonusesView.isHidden = true
         return
      }
      
      let displayedSum: Decimal
      if payWithBonuses {
         displayedSum = (receivedBonusSum * (max(0, Cart.totalPrice - sumPaidWithBonuses) / Cart.totalPrice)).round(.down)
      }
      else {
         displayedSum = receivedBonusSum
      }
      
      if displayedSum > 0
      {
         receivedBonusesLabel.setTextKeepingAttributes("При заказе вы получите \(displayedSum) Р бонусов.")
         receivedBonusesView.isHidden = false
      }
      else
      {
         receivedBonusesLabel.setTextKeepingAttributes(" ")
         receivedBonusesView.isHidden = true
      }
   }
   
   func updatePayBonusesView()
   {
      if payWithBonuses
      {
         descriptionLabelToReceivedBonusesConstraint.priority = UILayoutPriority(rawValue: 1)
         payBonusesToReceivedBonusesConstraint.priority = UILayoutPriority(rawValue: 999)
         payBonusesField.text = "\(sumPaidWithBonuses)"
         payBonusesView.isHidden = false
      }
      else
      {
         descriptionLabelToReceivedBonusesConstraint.priority = UILayoutPriority(rawValue: 999)
         payBonusesToReceivedBonusesConstraint.priority = UILayoutPriority(rawValue: 1)
         payBonusesView.isHidden = true
      }
   }
   
   func updateOrderReceiveNotificationsFromButton()
   {
      OrderReceiveNotifications = receivePushNotificationsButton.isChecked
      if let user = User.current, user.isDefault
      {
         user.modifyWithTransactionIfNeeded {
            user.allowPushNotifications = OrderReceiveNotifications
         }
      }
   }
   
   // MARK: - TextField
   
   func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
   {
      for char in string.characters
      {
         if !decimalDigits.contains(char) {
            return false
         }
      }
      
      let oldString = (textField.text ?? "") as NSString
      let newString = oldString.replacingCharacters(in: range, with: string)
      
      if newString.isEmpty
      {
         sumPaidWithBonuses = 0
         return true
      }
      
      if let value = Decimal(string: newString)?.round(.down) {
         sumPaidWithBonuses = min(value, maxSumPaidWithBonuses)
      }
      else {
         sumPaidWithBonuses = 0
      }
      textField.text = "\(sumPaidWithBonuses)"
      return false
   }
   
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
      textField.resignFirstResponder()
      return true
   }
   
   // MARK: - Actions
   
   @IBAction func cashTap()
   {
      paymentByCashButton.isSelected = true
      OrderPaymentByCash = true
   }
   
   @IBAction func cardTap()
   {
      paymentByCardButton.isSelected = true
      OrderPaymentByCash = false
   }
   
   @IBAction func bonusesTap()
   {
      if useBonusesButton.isEnabled
      {
         useBonusesButton.isChecked = !useBonusesButton.isChecked
         payWithBonuses = useBonusesButton.isChecked
         updatePayBonusesView()
      }
   }
   
   @IBAction func notificationsTap()
   {
      receivePushNotificationsButton.isChecked = !receivePushNotificationsButton.isChecked
      updateOrderReceiveNotificationsFromButton()
   }
   
   @IBAction func paymentRadioButtonsValueChanged()
   {
      OrderPaymentByCash = paymentByCashButton.isSelected
   }
   
   @IBAction func useBonusesChecked()
   {
      payWithBonuses = useBonusesButton.isChecked
      updatePayBonusesView()
   }
   
   @IBAction func receiveNotificationsChecked() {
      updateOrderReceiveNotificationsFromButton()
   }
   
   @IBAction func nextTap()
   {
      if let user = User.current, !user.isDefault {
         performSegue(withIdentifier: "Order", sender: self)
      }
      else {
         performSegue(withIdentifier: "ContactInfo", sender: self)
      }
   }
}
