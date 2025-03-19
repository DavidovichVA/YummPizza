//
//  OrderFeedbackController.swift
//  YummPizza
//
//  Created by Blaze Mac on 7/6/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class OrderFeedbackController: UIViewController, UITextViewDelegate
{
   @IBOutlet weak var scrollview: UIScrollView!
   @IBOutlet weak var textView: PlaceholderTextView!
   @IBOutlet weak var sendButton: UIButton!
   
   var orderId : Int64 = 0
   
   private var feedbackText : String {
      return (textView?.text ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
   }
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      
      textView.placeholderFont = UIFont(name: FontNameHelveticaNeueCyrItalic, size: 16 * WidthRatio)
      textView.setTextKeepingAttributes("")
      updateButtonEnabled()
      setupForKeyboard()
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
            self.scrollview.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.textView.height/*keyboardRect.size.height*/, right: 0)
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
   
   func updateButtonEnabled() {
      sendButton.isEnabled = !feedbackText.isEmpty
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
   
   func textViewDidChange(_ textView: UITextView)
   {
      updateButtonEnabled()
   }
   
   //MARK: - Actions
   
   @IBAction func sendTap()
   {
      let text = (textView.text ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      guard !text.isEmpty else { return }
      textView.endEditing(true)
      RequestManager.sendOrderFeedback(orderId: orderId, text: text,
      success:
      {
         AlertManager.showAlert("Спасибо за ваш отзыв", completion : {
            self.navigationController?.popViewController(animated: true)
         })
      },
      failure:
      {
         errorDescription in
         dlog(errorDescription)
         switch errorDescription
         {
         case "ERROR_FEEDBACK_FOR_THE_ORDER_ALREADY_EXIST": AlertManager.showAlert("Для данного заказа уже был оставлен отзыв")
         case "ERROR_THE_ORDER_DOES_NOT_EXIST": AlertManager.showAlert("Заказ не найден")
         default: AlertManager.showAlert(title: "Не удалось отправить отзыв", message: errorDescription)
         }
      })
   }
}
