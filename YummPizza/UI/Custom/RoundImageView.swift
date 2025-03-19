import UIKit

class RoundImageView: UIImageView
{
   override func layoutSubviews()
   {
      super.layoutSubviews()
      layer.cornerRadius = bounds.height / 2
      clipsToBounds = true
      isOpaque = false
   }
}
