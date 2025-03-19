import UIKit

class YPCheckButton: ExtendedButton
{
   var isChecked : Bool
   {
      get { return isSelected }
      set { isSelected = newValue }
   }
   
   internal override init(frame: CGRect)
   {
      super.init(frame: frame)
      if !allTargets.contains(self) {
         super.addTarget(self, action: #selector(onTouchUpInside), for: .touchUpInside)
      }
   }
   
   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
   }
   
   internal override func awakeFromNib()
   {
      super.awakeFromNib()
      if !allTargets.contains(self) {
         super.addTarget(self, action: #selector(onTouchUpInside), for: .touchUpInside)
      }
      cornerRadius = 2
      borderWidth = 2
      updateColor()
   }
   
   internal override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControlEvents)
   {
      if !allTargets.contains(self) {
         super.addTarget(self, action: #selector(onTouchUpInside), for: .touchUpInside)
      }
      super.addTarget(target, action: action, for: controlEvents)
   }
   
   @objc private func onTouchUpInside()
   {
      isSelected = !isSelected
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
   
   override var isSelected:  Bool
   {
      get { return super.isSelected }
      set {
         super.isSelected = newValue
         updateColor()
      }
   }
}
