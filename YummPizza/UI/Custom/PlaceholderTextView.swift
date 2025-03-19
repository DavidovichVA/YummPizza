import UIKit

class PlaceholderTextView: UITextView, NSTextStorageDelegate
{
   @IBInspectable var placeholder : String?
   {
      didSet { setNeedsDisplay() }
   }
   
   @IBInspectable var placeholderFont : UIFont? //IBInspectable font doesn't work :(
   {
      didSet { setNeedsDisplay() }
   }
   
   @IBInspectable var placeholderColor : UIColor?
   {
      didSet { setNeedsDisplay() }
   }
   
   
   public private(set) var showsPlaceholder : Bool = false
   
   private var phFont : UIFont {
      return placeholderFont ?? self.font ?? UIFont.systemFont(ofSize: 16)
   }
   
   private var phColor : UIColor {
      return placeholderColor ?? (self.textColor ?? UIColor.black).withAlphaComponent(0.6)
   }
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      self.textStorage.delegate = self
   }
   
   override func draw(_ rect: CGRect)
   {
      super.draw(rect)
      
      if self.text.isEmpty, let placeholder = self.placeholder, !placeholder.isEmpty
      {
         let textAreaSize = CGSize(width: bounds.width - (contentInset.width + textContainerInset.width + textContainer.lineFragmentPadding * 2),
                height: bounds.height - (contentInset.height + textContainerInset.height))
         let textAreaOrigin = bounds.origin + CGPoint(x: contentInset.left + textContainerInset.left + textContainer.lineFragmentPadding,
                                                      y: contentInset.top + textContainerInset.top)
         let textAreaRect = CGRect(origin: textAreaOrigin, size: textAreaSize)
         
         
         let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
         paragraphStyle.alignment = self.textAlignment
         
         let attributes = [NSAttributedStringKey.font : phFont,
                           NSAttributedStringKey.foregroundColor : phColor,
                           NSAttributedStringKey.paragraphStyle : paragraphStyle]
         
         (placeholder as NSString).draw(in: textAreaRect, withAttributes: attributes)
         
         showsPlaceholder = true
      }
      else
      {
         showsPlaceholder = false
      }
   }
   
   // MARK: - NSTextStorageDelegate
   
   public func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int)
   {
      if showsPlaceholder != self.text.isEmpty {
         setNeedsDisplay()
      }
   }
}
