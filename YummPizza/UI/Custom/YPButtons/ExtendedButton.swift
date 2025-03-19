//
//  ExtendedButton.swift
//

import UIKit

/// Button with extended touch area
class ExtendedButton: UIButton
{
   /// величина области за краями, нажатие в которой будет считаться нажатием кнопки
   @IBInspectable var margin : CGFloat = 20

   override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
   {
      let area = bounds.insetBy(dx: -margin, dy: -margin)
      return area.contains(point)
   }
   
   override func adjustForScreenSize()
   {
      super.adjustForScreenSize()
      margin *= WidthRatio
   }
}
