import UIKit

class YPRadioButton: RadioButton
{
   override func awakeFromNib()
   {
      super.awakeFromNib()
      borderWidth = 2
      updateColor()
   }
   
   override func layoutSubviews()
   {
      super.layoutSubviews()
      cornerRadius = bounds.width / 2
   }
   
   func updateColor()
   {
      if isEnabled
      {
         if isSelected {
            backgroundColor = YPColorBlueDefault
         }
         else {
            backgroundColor = UIColor.white
         }
         borderColor = YPColorBlueDefault
      }
      else
      {
         backgroundColor = UIColor.white
         borderColor = YPColorDisabled
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
   
   override func setButtonSelected(_ selected: Bool, distinct : Bool = false, sendControlEvent : Bool)
   {
      super.setButtonSelected(selected, distinct: distinct, sendControlEvent: sendControlEvent)
      updateColor()
   }
}
