//
//  YPPairedButton.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/30/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

enum YPPairedButtonSelectionState
{
   case left
   case right
}

protocol YPPairedButtonDelegate : AnyObject
{
   func pairedButton(_ button : YPPairedButton, didSelect state : YPPairedButtonSelectionState)
}

class YPPairedButton: UIView
{
   @IBInspectable var font : UIFont = UIFont(name: FontNameYPNeutraBold, size: 14 * WidthRatio)!
   @IBInspectable var textColorDefault : UIColor = rgb(4, 18, 45)
   @IBInspectable var textColorSelected : UIColor = rgb(0, 86, 168)
   @IBInspectable var borderColorDefault : UIColor = UIColor.clear
   @IBInspectable var borderColorSelected : UIColor = rgb(4, 18, 45)
   @IBInspectable var backgroundColorNormal : UIColor = rgb(240, 240, 240)
   @IBInspectable var backgroundColorHighlighted : UIColor = rgb(216, 216, 216)
   
   @IBInspectable var leftTitle : String = ""
   @IBInspectable var rightTitle : String = ""
   
   /// величина области за краями, нажатие в которой будет считаться нажатием кнопки
   @IBInspectable var margin : CGFloat = 15 * WidthRatio
   
   private var overlayView : UIView!
   private(set) var leftButton : YPPairButton!
   private(set) var rightButton : YPPairButton!
   
   weak var delegate : YPPairedButtonDelegate?
   
   var selectionState : YPPairedButtonSelectionState = .left
   {
      didSet
      {
         switch selectionState
         {
         case .left:
            leftButton.isSelected = true
            rightButton.isSelected = false
         case .right:
            leftButton.isSelected = false
            rightButton.isSelected = true
         }
         delegate?.pairedButton(self, didSelect: selectionState)
      }
   }
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      
      overlayView = UIView()
      overlayView.backgroundColor = backgroundColorNormal
      addSubview(overlayView)
      
      let halfWidth = bounds.width / 2
      leftButton = YPPairButton(frame: CGRect(x: 0, y: 0, width: halfWidth, height: bounds.height))
      rightButton = YPPairButton(frame: CGRect(x: halfWidth, y: 0, width: halfWidth, height: bounds.height))
      for button in [leftButton!, rightButton!]
      {
         button.pairedButton = self
         button.borderWidth = 2
         button.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
         addSubview(button)
      }
      leftButton.setTitle(leftTitle, for: .normal)
      rightButton.setTitle(rightTitle, for: .normal)
      leftButton.titleLabel?.font = font
      rightButton.titleLabel?.font = font
      leftButton.position = .left
      rightButton.position = .right
      leftButton.isSelected = true
      rightButton.isSelected = false
   }
   
   var isEnabled: Bool = true
   {
      didSet
      {
         leftButton.isEnabled = isEnabled
         rightButton.isEnabled = isEnabled
      }
   }
   
   override func layoutSubviews()
   {
      super.layoutSubviews()
      overlayView.frame = bounds.insetBy(dx: 0.5, dy: 0.5)
      overlayView.cornerRadius = overlayView.bounds.height / 2
      let halfWidth = bounds.width / 2
      leftButton.frame = CGRect(x: 0, y: 0, width: halfWidth, height: bounds.height)
      rightButton.frame = CGRect(x: halfWidth, y: 0, width: halfWidth, height: bounds.height)
      cornerRadius = bounds.height / 2
   }
   
   func updateColor()
   {
      leftButton.updateColor()
      rightButton.updateColor()
   }
   
   @objc func buttonTap(_ sender : YPPairButton)
   { 
      if sender === leftButton, selectionState != .left {
         selectionState = .left
      }
      else if sender === rightButton, selectionState != .right {
         selectionState = .right
      }
   }
   
   override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
   {
      let area = bounds.insetBy(dx: -margin, dy: -margin)
      return area.contains(point)
   }
   
   override func adjustForScreenSize()
   {
      for constraint in constraints
      {
         if constraint.firstItem === self, constraint.secondItem == nil {
            constraint.constant *= WidthRatio
         }
      }
   }
}


internal class YPPairButton : UIButton
{
   weak fileprivate(set) var pairedButton : YPPairedButton!
   fileprivate(set) var position : YPPairedButtonSelectionState = .left
   
   override var isEnabled: Bool
   {
      get { return super.isEnabled }
      set {
         super.isEnabled = newValue
         updateColor()
      }
   }
   
   override var isSelected: Bool
   {
      get { return super.isSelected }
      set {
         super.isSelected = newValue
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
   
   override func layoutSubviews()
   {
      super.layoutSubviews()
      cornerRadius = bounds.height / 2
   }
   
   override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
   {
      var area = bounds.insetBy(dx: 0, dy: -pairedButton.margin)
      area.size.width += pairedButton.margin
      if position == .left { area.origin.x -= pairedButton.margin }
      return area.contains(point)
   }
   
   func updateColor()
   {
      if isEnabled
      {
         switch (isSelected, isHighlighted)
         {
         case (true, true):
            backgroundColor = pairedButton.backgroundColorHighlighted
            borderColor = pairedButton.borderColorSelected
            setTitleColor(pairedButton.textColorSelected, for: .normal)
         case (true, false):
            backgroundColor = UIColor.clear
            borderColor = pairedButton.borderColorSelected
            setTitleColor(pairedButton.textColorSelected, for: .normal)
         case (false, true):
            backgroundColor = pairedButton.backgroundColorHighlighted
            borderColor = pairedButton.borderColorSelected.withAlphaComponent(0.4)
            setTitleColor(pairedButton.textColorSelected, for: .normal)
         case (false, false):
            backgroundColor = UIColor.clear
            borderColor = pairedButton.borderColorDefault
            setTitleColor(pairedButton.textColorDefault, for: .normal)
         }
      }
      else
      {
         backgroundColor = UIColor.clear
         borderColor = UIColor.clear
         setTitleColor(YPColorDisabledText, for: .normal)
      }
   }
}
