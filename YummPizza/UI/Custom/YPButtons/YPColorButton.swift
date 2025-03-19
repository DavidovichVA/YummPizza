import UIKit

internal class YPColorButton: UIButton
{
   var textColorDefault : UIColor { return YPColorText }
   var textColorHighlighted : UIColor { return YPColorText }
   var borderColorDefault : UIColor { return UIColor.clear }
   var borderColorHighlighted : UIColor { return UIColor.clear }
   var backgroundColorDefault : UIColor { return UIColor.white }
   var backgroundColorHighlighted : UIColor { return UIColor.white }
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      borderWidth = 2
      updateColor()
   }
   
   override func layoutSubviews()
   {
      super.layoutSubviews()
      cornerRadius = bounds.height / 2
   }
   
   func updateColor()
   {
      if isEnabled
      {
         if isHighlighted
         {
            backgroundColor = backgroundColorHighlighted
            borderColor = borderColorHighlighted
            setTitleColor(textColorHighlighted, for: .normal)
         }
         else
         {
            backgroundColor = backgroundColorDefault
            borderColor = borderColorDefault
            setTitleColor(textColorDefault, for: .normal)
         }
      }
      else
      {
         backgroundColor = YPColorDisabled
         borderColor = YPColorDisabled
         setTitleColor(YPColorDisabledText, for: .normal)
      }
   }
   
   override var isEnabled: Bool
   {
      get { return super.isEnabled }
      set {
         super.isEnabled = newValue
         updateColor()
      }
   }
   
   override var isHighlighted: Bool
   {
      get { return super.isHighlighted }
      set {
         super.isHighlighted = newValue
         updateColor()
      }
   }
}


internal class YPButtonRed: YPColorButton
{
   override var textColorDefault : UIColor { return UIColor.white }
   override var textColorHighlighted : UIColor { return UIColor.white }
   override var borderColorDefault : UIColor { return YPColorRedDefault }
   override var borderColorHighlighted : UIColor { return YPColorRedHighlighted }
   override var backgroundColorDefault : UIColor { return YPColorRedDefault }
   override var backgroundColorHighlighted : UIColor { return YPColorRedHighlighted }
}

internal class YPButtonBlue: YPColorButton
{
   override var textColorDefault : UIColor { return YPColorBlueDefault }
   override var textColorHighlighted : UIColor { return YPColorBlueHighlighted }
   override var borderColorDefault : UIColor { return YPColorBlueDefault }
   override var borderColorHighlighted : UIColor { return YPColorBlueHighlighted }
   override var backgroundColorDefault : UIColor { return UIColor.white }
   override var backgroundColorHighlighted : UIColor { return UIColor.white }
}




internal class YPTextImageColorButton : UIControl
{
   @IBInspectable var contentColorDefault : UIColor = UIColor.white
   @IBInspectable var contentColorHighlighted : UIColor = UIColor.white
   @IBInspectable var backgroundColorDefault : UIColor = YPColorRedDefault
   @IBInspectable var backgroundColorHighlighted : UIColor = YPColorRedHighlighted
   
   @IBOutlet weak var imageView : UIImageView!
   @IBOutlet weak var titleLabel : UILabel!
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      updateColor()
   }
   
   override func layoutSubviews()
   {
      super.layoutSubviews()
      cornerRadius = bounds.height / 2
   }
   
   func updateColor()
   {
      if let image = imageView.image, image.renderingMode != .alwaysTemplate {
         imageView.image = image.withRenderingMode(.alwaysTemplate)
      }
      
      if isEnabled
      {
         if isHighlighted
         {
            backgroundColor = backgroundColorHighlighted
            titleLabel.textColor = contentColorHighlighted
            imageView.tintColor = contentColorHighlighted
         }
         else
         {
            backgroundColor = backgroundColorDefault
            titleLabel.textColor = contentColorDefault
            imageView.tintColor = contentColorDefault
         }
      }
      else
      {
         backgroundColor = YPColorDisabled
         titleLabel.textColor = YPColorDisabledText
         imageView.tintColor = YPColorDisabledText
      }
   }
   
   override var isEnabled: Bool
   {
      get { return super.isEnabled }
      set {
         super.isEnabled = newValue
         updateColor()
      }
   }
   
   override var isHighlighted: Bool
   {
      get { return super.isHighlighted }
      set {
         super.isHighlighted = newValue
         updateColor()
      }
   }
}



