import UIKit

//MARK: - Adjustment for Screen Size

extension UIView
{
   @IBInspectable var adjustsForScreenSize : Bool
   {
      get {
         return false
      }
      set {
         if newValue {
            adjustForScreenSize()
         }
      }
   }
   
   @objc func adjustForScreenSize()
   {
      for constraint in constraints {
         constraint.constant *= WidthRatio
      }
      for subview in subviews {
         subview.adjustForScreenSize()
      }
   }
}

extension UILabel
{
   override func adjustForScreenSize()
   {
      if let currentFont = font {
         font = UIFont(name: currentFont.fontName, size: currentFont.pointSize * WidthRatio)
      }
      
      for constraint in constraints
      {
         if constraint.firstItem === self, constraint.secondItem == nil {
            constraint.constant *= WidthRatio
         }
      }
      
      invalidateIntrinsicContentSize()
   }
}
extension UITextField
{
   override func adjustForScreenSize()
   {
      if let currentFont = font {
         font = UIFont(name: currentFont.fontName, size: currentFont.pointSize * WidthRatio)
      }
      
      for constraint in constraints
      {
         if constraint.firstItem === self, constraint.secondItem == nil {
            constraint.constant *= WidthRatio
         }
      }
      
      invalidateIntrinsicContentSize()
   }
}
extension UITextView
{
   override func adjustForScreenSize()
   {
      if let currentFont = font {
         font = UIFont(name: currentFont.fontName, size: currentFont.pointSize * WidthRatio)
      }
      
      for constraint in constraints
      {
         if constraint.firstItem === self, constraint.secondItem == nil {
            constraint.constant *= WidthRatio
         }
      }
   }
}
extension UIButton
{
   override func adjustForScreenSize()
   {
      if let currentFont = titleLabel?.font {
         titleLabel?.font = UIFont(name: currentFont.fontName, size: currentFont.pointSize * WidthRatio)
      }
      
      imageView?.contentMode = .scaleAspectFit
      
      for constraint in constraints
      {
         if constraint.firstItem === self, constraint.secondItem == nil {
            constraint.constant *= WidthRatio
         }
      }
      
      invalidateIntrinsicContentSize()
   }
}

extension UISwitch
{
   override func adjustForScreenSize() {
      transform = CGAffineTransform(scaleX: WidthRatio, y: WidthRatio)
   }
}

extension UIPickerView
{
   override func adjustForScreenSize()
   {
      for constraint in constraints
      {
         if constraint.firstItem === self, constraint.secondItem == nil {
            constraint.constant *= WidthRatio
         }
      }
   }
}

extension UIDatePicker
{
   override func adjustForScreenSize()
   {
      for constraint in constraints
      {
         if constraint.firstItem === self, constraint.secondItem == nil {
            constraint.constant *= WidthRatio
         }
      }
   }
}

//extension UIStackView
//{
//   override func adjustForScreenSize()
//   {
//      for constraint in constraints
//      {
//         if constraint.firstItem === self, constraint.secondItem == nil {
//            constraint.constant *= WidthRatio
//         }
//      }
//   }
//}


/*
//MARK: - Localization

extension UILabel
{
   @IBInspectable var locKey : String
   {
      get {
         return ""
      }
      set {
         if !newValue.isEmpty {
            text = loc(newValue)
         }
      }
   }
}

extension UIButton
{
   @IBInspectable var locKey : String
   {
      get {
         return ""
      }
      set {
         if !newValue.isEmpty
         {
            UIView.performWithoutAnimation
            {
               setTitle(loc(newValue), for: .normal)
               layoutIfNeeded()
            }
         }
      }
   }
}

extension UINavigationItem
{
   @IBInspectable var locKey : String
   {
      get {
         return ""
      }
      set {
         if !newValue.isEmpty {
            title = loc(newValue)
         }
      }
   }
}

extension UIBarButtonItem
{
   @IBInspectable var locKey : String
   {
      get {
         return ""
      }
      set {
         if !newValue.isEmpty {
            title = loc(newValue)
         }
      }
   }
}

extension UITabBarItem
{
   @IBInspectable var locKey : String
   {
      get {
         return ""
      }
      set {
         if !newValue.isEmpty {
            title = loc(newValue)
         }
      }
   }
}
*/
