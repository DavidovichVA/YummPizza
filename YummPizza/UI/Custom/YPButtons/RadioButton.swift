import UIKit

class RadioButton: ExtendedButton
{
   @IBInspectable var emptySelectionAllowed : Bool = false
   
   /// Outlet collection of links to other buttons in the group.
   @IBOutlet public var groupButtons: [RadioButton]
   {
      get
      {
         var radioButtons : [RadioButton] = []
         for value in sharedLinks {
            if let rb = value.nonretainedObjectValue as? RadioButton {
               radioButtons.append(rb)
            }
         }
         return radioButtons
      }
      set(buttons)
      {
         var allButtons : Set<RadioButton> = []
         var allLinks : [NSValue] = []
         
         func addButton(_ button: RadioButton)
         {
            allButtons.insert(button)
            allLinks.append(NSValue(nonretainedObject: button))
            
            for value in button.sharedLinks
            {
               if let vrb = value.nonretainedObjectValue as? RadioButton, !allButtons.contains(vrb) {
                  addButton(vrb)
               }
            }
         }
         
         addButton(self)
         
         for rb in buttons {
            if !allButtons.contains(rb) {
               addButton(rb)
            }
         }
         
         for rb in allButtons {
            rb.sharedLinks = allLinks
         }
      }
   }
   
   /// Currently selected radio button in the group.
   /// If there are multiple buttons selected then it returns the first one.
   public var selectedButton : RadioButton?
   {
      if isSelected {return self}
      
      for value in sharedLinks {
         if let rb = value.nonretainedObjectValue as? RadioButton {
            if rb.isSelected {return rb}
         }
      }
      
      return nil
   }
   
   public override var isSelected: Bool
   {
      get {
         return super.isSelected
      }
      set {
         self.setButtonSelected(newValue, distinct: true, sendControlEvent: false)
      }
   }
   
   public func select(tag: Int)
   {
      if self.tag == tag {
         self.setButtonSelected(true, distinct: true, sendControlEvent: false)
      }
      else
      {
         for value in sharedLinks
         {
            if let rb = value.nonretainedObjectValue as? RadioButton, rb.tag == tag
            {
               rb.setButtonSelected(true, distinct: true, sendControlEvent: false)
               break
            }
         }
      }
   }
   
   public func deselectAllButtons()
   {
      for value in sharedLinks {
         if let rb = value.nonretainedObjectValue as? RadioButton {
            rb.setButtonSelected(false, sendControlEvent: false)
         }
      }
   }
   
   
   private var sharedLinks : [NSValue] = []
   
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
      if emptySelectionAllowed
      {
         setButtonSelected(!isSelected, distinct: true, sendControlEvent: true)
      }
      else
      {
         setButtonSelected(true, distinct: true, sendControlEvent: true)
      }
   }
   
   internal func setButtonSelected(_ selected: Bool, distinct : Bool = false, sendControlEvent : Bool)
   {
      let valueChanged = (isSelected != selected)
      super.isSelected = selected
      if valueChanged && sendControlEvent {
         sendActions(for: .valueChanged)
      }
      
      if distinct && (isSelected || (!emptySelectionAllowed && sharedLinks.count == 2))
      {
         for value in sharedLinks {
            if let rb = value.nonretainedObjectValue as? RadioButton, rb != self {
               rb.setButtonSelected(!selected, sendControlEvent: sendControlEvent)
            }
         }
      }
   }
   
   deinit
   {
      sharedLinks.removeAll()
   }
}
