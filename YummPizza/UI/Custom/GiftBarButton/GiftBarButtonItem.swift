//
//  GiftBarButtonItem.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/23/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class GiftBarButtonItem: UIBarButtonItem
{
   public var badgeNumber : Int = 0
   {
      didSet
      {
         if badgeNumber > 0
         {
            giftBarView.numberLabel.text = String(badgeNumber)
            giftBarView.numberView.isHidden = false
            
         }
         else
         {
            giftBarView.numberLabel.text = nil
            giftBarView.numberView.isHidden = true
         }
      }
   }
   
   private var giftBarView : GiftBarView { return customView as! GiftBarView }
   
   public class func item(_ number : Int = 0, target: Any?, action: Selector) -> GiftBarButtonItem
   {
      let giftBarView = Bundle.main.loadNibNamed("GiftBarView", owner: nil, options: nil)![0] as! GiftBarView
      giftBarView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
      giftBarView.addTarget(target, action: action, for: .touchUpInside)
      let barButtonItem = GiftBarButtonItem(customView: giftBarView)
      barButtonItem.width = GiftBarView.giftBarViewSize.width
      barButtonItem.badgeNumber = number
      return barButtonItem
   }
}


internal class GiftBarView : UIControl
{
   @IBOutlet weak var numberView: UIView!
   @IBOutlet weak var numberLabel: UILabel!
   
   static let giftBarViewSize : CGSize = CGSize(width: 44, height: 40)
   override var intrinsicContentSize: CGSize { return GiftBarView.giftBarViewSize }
   
   override var isHighlighted: Bool
      {
      get { return super.isHighlighted }
      set {
         super.isHighlighted = newValue
         self.alpha = isHighlighted ? 0.5 : 1
      }
   }
   
   /// величина области за краями, нажатие в которой будет считаться нажатием кнопки
   public var margin : CGFloat = 25
   override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
   {
      let area = bounds.insetBy(dx: -margin, dy: -margin)
      return area.contains(point)
   }
}

