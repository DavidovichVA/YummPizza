import UIKit

class RoundView: UIView
{
   override func layoutSubviews()
   {
      super.layoutSubviews()
      layer.cornerRadius = bounds.height / 2
      isOpaque = false
   }
}
