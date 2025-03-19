import UIKit

extension UIView
{
   //MARK: - Layer Properties
   
   @IBInspectable var cornerRadius : CGFloat
   {
      get {
         return layer.cornerRadius
      }
      set {
         layer.cornerRadius = newValue
      }
   }
   
   @IBInspectable var borderWidth : CGFloat
   {
      get {
         return layer.borderWidth
      }
      set {
         layer.borderWidth = newValue
      }
   }
   
   @IBInspectable var borderColor : UIColor
   {
      get {
         if let layerBorderColor = layer.borderColor {
            return UIColor(cgColor: layerBorderColor)
         }
         else {
            return UIColor.black
         }
      }
      set {
         layer.borderColor = newValue.cgColor
      }
   }
   
   var shadowColor : UIColor
   {
      get {
         if let layerShadowColor = layer.shadowColor {
            return UIColor(cgColor: layerShadowColor)
         }
         else {
            return UIColor.black
         }
      }
      set {
         layer.shadowColor = newValue.cgColor
      }
   }
   
   //MARK: - Position & size
   
   var origin : CGPoint
   {
      get { return frame.origin }
      set { frame = CGRect(origin: newValue, size: size) }
   }
   
   var topLeft : CGPoint
   {
      get { return origin }
      set { origin = newValue }
   }
   
   var topRight : CGPoint
   {
      get { return CGPoint(x: right, y: y) }
      set { frame = CGRect(origin: CGPoint(x: newValue.x - width, y: newValue.y), size: size) }
   }
   
   var bottomLeft : CGPoint
   {
      get { return CGPoint(x: x, y: bottom) }
      set { frame = CGRect(origin: CGPoint(x: newValue.x, y: newValue.y - height), size: size) }
   }
   
   var bottomRight : CGPoint
   {
      get { return CGPoint(x: right, y: bottom) }
      set { frame = CGRect(origin: CGPoint(x: newValue.x - width, y: newValue.y - height), size: size) }
   }
   
   var size : CGSize
   {
      get { return frame.size }
      set { frame = CGRect(origin: origin, size: newValue) }
   }
   
   var x : CGFloat
   {
      get { return origin.x }
      set { frame = CGRect(origin: CGPoint(x: newValue, y: origin.y), size: size) }
   }
   
   var y : CGFloat
   {
      get { return origin.y }
      set { frame = CGRect(origin: CGPoint(x: origin.x, y: newValue), size: size) }
   }
   
   var width : CGFloat
   {
      get { return size.width }
      set { frame = CGRect(origin: origin, size: CGSize(width: newValue, height: size.height)) }
   }
   
   var height : CGFloat
   {
      get { return size.height }
      set { frame = CGRect(origin: origin, size: CGSize(width: size.width, height: newValue)) }
   }
   
   var left : CGFloat
   {
      get { return x }
      set { x = newValue }
   }
   
   var right : CGFloat
   {
      get { return x + width }
      set { x = newValue - width }
   }
   
   var top : CGFloat
   {
      get { return y }
      set { y = newValue }
   }
   
   var bottom : CGFloat
   {
      get { return y + height }
      set { y = newValue - height }
   }
}

extension UIEdgeInsets
{
   var width : CGFloat {
      return left + right
   }
   
   var height : CGFloat {
      return top + bottom
   }
}

func +(lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> UIEdgeInsets
{
   return UIEdgeInsets(top: lhs.top + rhs.top, left: lhs.left + rhs.left,
                       bottom: lhs.bottom + rhs.bottom, right: lhs.right + rhs.right)
}

func *(insets: UIEdgeInsets, mpl: CGFloat) -> UIEdgeInsets
{
   return UIEdgeInsets(top: insets.top * mpl, left: insets.left * mpl,
                       bottom: insets.bottom * mpl, right: insets.right * mpl)
}

//MARK: - Text

fileprivate var textAttributesKey : UInt8 = 125
extension UILabel
{
   func setTextKeepingAttributes(_ text : String)
   {
      if let attrText = self.attributedText, !attrText.string.isEmpty // empty string loses attributes
      {
         let attributes = attrText.attributes(at: 0, effectiveRange: nil)
         self.attributedText = NSAttributedString(string: text, attributes: attributes)
         associateObject(self, key: &textAttributesKey, value: attributes)
      }
      else if let attributes : [NSAttributedStringKey : Any] = associatedObject(self, key: &textAttributesKey) {
         self.attributedText = NSAttributedString(string: text, attributes: attributes)
      }
      else {
         self.text = text
      }
   }
}

extension UITextView
{
   func setTextKeepingAttributes(_ text : String)
   {
      if let attrText = self.attributedText, !attrText.string.isEmpty // empty string loses attributes
      {
         let attributes = attrText.attributes(at: 0, effectiveRange: nil)
         self.attributedText = NSAttributedString(string: text, attributes: attributes)
         associateObject(self, key: &textAttributesKey, value: attributes)
      }
      else if let attributes : [NSAttributedStringKey : Any] = associatedObject(self, key: &textAttributesKey) {
         self.attributedText = NSAttributedString(string: text, attributes: attributes)
      }
      else {
         self.text = text
      }
   }
}

extension UITextField
{
   @IBInspectable var placeHolderColor: UIColor
      {
      get{
         return attributedPlaceholder?.attribute(NSAttributedStringKey.foregroundColor, at: 0, effectiveRange: nil) as? UIColor ?? UIColor(white: 0.3, alpha: 1)
      }
      set {
         let placeholderText = placeholder ??  ""
         attributedPlaceholder = NSAttributedString(string:placeholderText, attributes:[NSAttributedStringKey.font : font!, NSAttributedStringKey.foregroundColor: newValue])
      }
   }
   
   func setTextKeepingAttributes(_ text : String)
   {
      if let attrText = self.attributedText, !attrText.string.isEmpty // empty string loses attributes
      {
         let attributes = attrText.attributes(at: 0, effectiveRange: nil)
         self.attributedText = NSAttributedString(string: text, attributes: attributes)
         associateObject(self, key: &textAttributesKey, value: attributes)
      }
      else if let attributes : [NSAttributedStringKey : Any] = associatedObject(self, key: &textAttributesKey) {
         self.attributedText = NSAttributedString(string: text, attributes: attributes)
      }
      else {
         self.text = text
      }
   }
}

//MARK: - Navigation

extension UIViewController
{
   /// back navigation arrow with optional title
   @IBInspectable var backNavTitle : String
   {
      get { return "" }
      set(title) {
         if title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
         {
            let barButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "navigationBack"), style: .plain, target: self, action: #selector(navigationBackTap))
            let negativeSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            negativeSpace.width = -5
            navigationItem.leftBarButtonItems = [negativeSpace, barButtonItem]
         }
         else
         {
            let height : CGFloat = 44
            
            let backNavImage = #imageLiteral(resourceName: "navigationBack")
            let imageView = UIImageView(image: backNavImage)
            imageView.backgroundColor = UIColor.clear
            let imageViewHeight = min(backNavImage.size.height, height)
            let imageViewWidth = backNavImage.size.width * (imageViewHeight / backNavImage.size.height)
            imageView.frame = CGRect(x: 10, y: (height - imageViewHeight) / 2, width: imageViewWidth, height: imageViewHeight)
            imageView.contentMode = .scaleAspectFit
            imageView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin]
            
            let titleLabel = UILabel()
            
            var font : UIFont! = UIFont(name: FontNameYPNeutraBold, size: 17)
            if font == nil
            {
               if #available(iOS 8.2, *) { font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.bold) }
               else { font = UIFont.systemFont(ofSize: 17) }
            }
            titleLabel.font = font
            
            titleLabel.backgroundColor = UIColor.clear
            titleLabel.text = title
            titleLabel.sizeToFit()
            titleLabel.origin = CGPoint(x: imageView.right + 5, y: (height - titleLabel.height) / 2)
            titleLabel.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth]
            
            let width = titleLabel.right + 10
            
            let customView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            customView.backgroundColor = UIColor.clear
            customView.addSubview(imageView)
            customView.addSubview(titleLabel)
            customView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            
            let clearButton = HighlightAlphaButton(highlightViews: [customView])
            clearButton.addTarget(self, action: #selector(navigationBackTap), for: .touchUpInside)
            clearButton.frame = customView.bounds
            customView.addSubview(clearButton)
            
            let barButtonItem = UIBarButtonItem(customView: customView)
            barButtonItem.width = width
            
            let negativeSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            negativeSpace.width = -15
            navigationItem.leftBarButtonItems = [negativeSpace, barButtonItem]
         }
      }
   }
   
   @objc func navigationBackTap()
   {
      _ = navigationController?.popViewController(animated: true)
   }
   
   
   /// left menu navigation button
   @IBInspectable var menuBarButton : Bool
   {
      get { return false }
      set {
         if newValue
         {
            let barButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "menuBarIcon"), style: .plain, target: self, action: #selector(menuBarButtonTap))
            let negativeSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            negativeSpace.width = -5
            navigationItem.leftBarButtonItems = [negativeSpace, barButtonItem]
         }
      }
   }
   
   @objc func menuBarButtonTap()
   {
      if menuRootController.isEnabled
      {
         if menuRootController.isShown {
            menuRootController.hideMenu(animated: true)
         }
         else {
            menuRootController.showMenu(animated: true)
         }
      }
   }
   
   /// right cart navigation button
   @IBInspectable var cartBarButton : Bool
   {
      get { return false }
      set {
         if newValue
         {
            let barButtonItem = CartBarButtonItem.item()
            let negativeSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            negativeSpace.width = -15
            navigationItem.rightBarButtonItems = [negativeSpace, barButtonItem]
         }
      }
   }
}

//MARK: - TableViewCell Separator Insets
extension UITableViewCell
{
   @IBInspectable var removedSeparatorInsets : Bool
   {
      get {
         return separatorInset == .zero &&
         preservesSuperviewLayoutMargins == false &&
         layoutMargins == .zero
      }
      set {
         if newValue {
            separatorInset = .zero
            preservesSuperviewLayoutMargins = false
            layoutMargins = .zero
         }
      }
   }
}

//MARK: - Scrollview scroll to make view visible
extension UIScrollView
{
   func scrollViewToVisible(_ view: UIView, animated: Bool)
   {
      let origin = convert(view.bounds.origin, from: view)
      scrollRectToVisible(CGRect(origin: origin, size: view.size), animated: animated)
   }
}

//MARK: - ImageView's image rect

extension UIImageView
{
   /// image rect in ImageView's coordinates
   var imageRect : CGRect?
   {
      guard let img = self.image, img.size.width > 0, img.size.height > 0 else { return nil }
      switch contentMode
      {
      case .scaleToFill, .redraw: return self.bounds
      case .scaleAspectFit: return img.size.byAspectFit(into: self.bounds)
      case .scaleAspectFill: return img.size.byAspectFill(into: self.bounds)
      case .center:
         let x = (bounds.width - img.size.width) / 2
         let y = (bounds.height - img.size.height) / 2
         return CGRect(x: x, y: y, width: img.size.width, height: img.size.height)
      case .top:
         let x = (bounds.width - img.size.width) / 2
         return CGRect(x: x, y: 0, width: img.size.width, height: img.size.height)
      case .bottom:
         let x = (bounds.width - img.size.width) / 2
         let y = bounds.height - img.size.height
         return CGRect(x: x, y: y, width: img.size.width, height: img.size.height)
      case .left:
         let y = (bounds.height - img.size.height) / 2
         return CGRect(x: 0, y: y, width: img.size.width, height: img.size.height)
      case .right:
         let x = bounds.width - img.size.width
         let y = (bounds.height - img.size.height) / 2
         return CGRect(x: x, y: y, width: img.size.width, height: img.size.height)
      case .topLeft:
         return CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
      case .topRight:
         let x = bounds.width - img.size.width
         return CGRect(x: x, y: 0, width: img.size.width, height: img.size.height)
      case .bottomLeft:
         let y = bounds.height - img.size.height
         return CGRect(x: 0, y: y, width: img.size.width, height: img.size.height)
      case .bottomRight:
         let x = bounds.width - img.size.width
         let y = bounds.height - img.size.height
         return CGRect(x: x, y: y, width: img.size.width, height: img.size.height)
      }
   }
}

//MARK: - ImageTweak
extension UIImage
{
   func resized(_ newWidth: CGFloat, _ newHeight : CGFloat, useDeviceScale : Bool = false) -> UIImage {
      return resized(CGSize(width: newWidth, height: newHeight), useDeviceScale : useDeviceScale)
   }
   
   func resized(_ newSize : CGSize, useDeviceScale : Bool = false) -> UIImage
   {
      UIGraphicsBeginImageContextWithOptions(newSize, false, (useDeviceScale ? UIScreen.main.scale : self.scale))
      draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
      let destImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
      return destImage.withRenderingMode(renderingMode)
   }
   
   func scaled(by ratio: CGFloat, useDeviceScale : Bool = false) -> UIImage
   {
      let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
      return resized(newSize, useDeviceScale : useDeviceScale)
   }
   
   func constrained(to size : CGSize, mode : UIViewContentMode, useDeviceScale : Bool = true) -> UIImage
   {
      let imageView = UIImageView(image: self)
      imageView.bounds = CGRect(origin: .zero, size: size)
      imageView.contentMode = mode
      imageView.backgroundColor = UIColor.clear
      
      UIGraphicsBeginImageContextWithOptions(size, false, (useDeviceScale ? UIScreen.main.scale : self.scale))
      imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
      let destImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
      return destImage.withRenderingMode(renderingMode)
   }
   
   func normalizingOrientation() -> UIImage
   {
      if imageOrientation == .up { return self }
      
      UIGraphicsBeginImageContextWithOptions(size, false, scale)
      draw(in: CGRect(origin: .zero, size: size))
      let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
      return normalizedImage.withRenderingMode(renderingMode)
   }
   
   func roundingCorners(_ radius : CGFloat) -> UIImage
   {
      UIGraphicsBeginImageContextWithOptions(size, false, scale)
      let rect = CGRect(origin: .zero, size: size)
      UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
      draw(in: rect)
      let corneredImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
      return corneredImage.withRenderingMode(renderingMode)
   }
   
   func tinted(_ color : UIColor) -> UIImage
   {
      let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
      imageView.tintColor = color;
      imageView.image = self.withRenderingMode(.alwaysTemplate)
      
      UIGraphicsBeginImageContextWithOptions(size, false, scale)
      imageView.layer.render(in: UIGraphicsGetCurrentContext()!)

      let tintedImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
      
      return tintedImage
   }
   
   ///1x1 pixel image of color
   class func pixelImage(_ color : UIColor) -> UIImage
   {
      let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
      UIGraphicsBeginImageContext(rect.size)
      let context = UIGraphicsGetCurrentContext()!
      
      context.setFillColor(color.cgColor)
      context.fill(rect)
      
      let image = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
      
      return image
   }
}

//MARK: - UIView animation
extension UIView
{
   class func animateIgnoringInherited(withDuration duration: TimeInterval, animations: @escaping () -> Void)
   {
      animateIgnoringInherited(withDuration: duration, animations: animations, completion: nil)
   }
   
   class func animateIgnoringInherited(withDuration duration: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil)
   {
      UIView.animate(withDuration: duration, delay: 0, options: [.overrideInheritedCurve, .overrideInheritedDuration, .overrideInheritedOptions], animations: animations, completion: completion)
   }
   
   class func animateIgnoringInherited(withDuration duration: TimeInterval, delay: TimeInterval, options: UIViewAnimationOptions = [], animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil)
   {
      let newOptions = options.union([.overrideInheritedCurve, .overrideInheritedDuration, .overrideInheritedOptions])
      UIView.animate(withDuration: duration, delay: delay, options: newOptions, animations: animations, completion: completion)
   }
   
   class func transitionIgnoringInherited(with view: UIView, duration: TimeInterval, options: UIViewAnimationOptions = [], animations: (() -> Void)?, completion: ((Bool) -> Void)? = nil)
   {
      let newOptions = options.union([.overrideInheritedCurve, .overrideInheritedDuration, .overrideInheritedOptions])
      UIView.transition(with: view, duration: duration, options: newOptions, animations: animations, completion: completion)
   }
   
   class func transitionIgnoringInherited(from fromView: UIView, to toView: UIView, duration: TimeInterval, options: UIViewAnimationOptions = [], completion: ((Bool) -> Void)? = nil)
   {
      let newOptions = options.union([.overrideInheritedCurve, .overrideInheritedDuration, .overrideInheritedOptions])
      UIView.transition(from: fromView, to: toView, duration: duration, options: newOptions, completion: completion)
   }
}

//MARK: - Find view
extension UIView
{
   func findSubview(onlyDirectSubviews : Bool = false, criteria : (UIView) -> Bool) -> UIView?
   {
      for subview in subviews
      {
         if criteria(subview) {
            return subview
         }
      }
      
      if !onlyDirectSubviews
      {
         for subview in subviews
         {
            if let foundView = subview.findSubview(onlyDirectSubviews: false, criteria: criteria) {
               return foundView
            }
         }
      }
      
      return nil
   }
   
   func findSubview(onlyDirectSubviews : Bool = false, ofClass searchedClass: AnyClass) -> UIView?
   {
      return findSubview(onlyDirectSubviews: onlyDirectSubviews, criteria: {
         return $0.isKind(of: searchedClass)
      })
   }
   
   func findSuperview(criteria : (UIView) -> Bool) -> UIView?
   {
      var view = self
      while true
      {
         if let superview = view.superview
         {
            if criteria(superview) {
               return superview
            }
            else {
               view = superview
            }
         }
         else
         {
            return nil
         }
      }
   }
   
   func findSuperview(ofClass searchedClass: AnyClass) -> UIView?
   {
      return findSuperview(criteria: {
         return $0.isKind(of: searchedClass)
      })
   }
}

//MARK: - CG Extensions
extension CGSize
{
   static func square(_ length: Int) -> CGSize {
      return CGSize(width: length, height: length)
   }
   static func square(_ length: CGFloat) -> CGSize {
      return CGSize(width: length, height: length)
   }
   static func square(_ length: Double) -> CGSize {
      return CGSize(width: length, height: length)
   }
   
   func byAspectFit(into boundingSize : CGSize) -> CGSize
   {
      let ratio = min(boundingSize.width / self.width, boundingSize.height / self.height)
      return CGSize(width: self.width * ratio, height: self.height * ratio)
   }
   
   func byAspectFill(into boundingSize : CGSize) -> CGSize
   {
      let ratio = max(boundingSize.width / self.width, boundingSize.height / self.height)
      return CGSize(width: self.width * ratio, height: self.height * ratio)
   }
   
   func byAspectFit(into boundingRect : CGRect) -> CGRect
   {
      let size = self.byAspectFit(into: boundingRect.size)
      let x = (boundingRect.width - size.width) / 2
      let y = (boundingRect.height - size.height) / 2
      return CGRect(x: x, y: y, width: size.width, height: size.height)
   }
   
   func byAspectFill(into boundingRect : CGRect) -> CGRect
   {
      let size = self.byAspectFill(into: boundingRect.size)
      let x = (boundingRect.width - size.width) / 2
      let y = (boundingRect.height - size.height) / 2
      return CGRect(x: x, y: y, width: size.width, height: size.height)
   }
}

public func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
   return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

public func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
   return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}
