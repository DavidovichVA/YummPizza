//
//  HighlightAlphaButton.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/17/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class HighlightAlphaButton: UIButton
{
   @IBOutlet public var highlightViews: [UIView] = []
   
   convenience init(highlightViews : [UIView] = [])
   {
      self.init(type: .custom)
      
      self.setTitle(nil, for: .normal)
      self.setImage(nil, for: .normal)
      self.backgroundColor = UIColor.clear
      self.highlightViews = highlightViews
      
      self.setContentHuggingPriority(UILayoutPriority(rawValue: 1), for: .horizontal)
      self.setContentHuggingPriority(UILayoutPriority(rawValue: 1), for: .vertical)
      self.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1), for: .horizontal)
      self.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1), for: .vertical)
      
      self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
   }
   
   override var isHighlighted: Bool
   {
      get { return super.isHighlighted }
      set {
         super.isHighlighted = newValue
         let alphaValue : CGFloat = newValue ? 0.5 : 1
         highlightViews.forEach({ $0.alpha = alphaValue })
      }
   }
}
