//
//  YPSegmentedView.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/18/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class YPSegmentedView: UIView
{
   static let normalColor : UIColor = rgb(240, 240, 240)
   static let normalTextColor : UIColor = UIColor.black
   static let selectedColor : UIColor = rgb(255, 169, 0)
   static let selectedTextColor : UIColor = UIColor.white
   static let highlightedTextColor : UIColor = UIColor.white
   
   let titleFont : UIFont = UIFont(name: FontNameHelveticaNeueCyrMedium, size: 18.67 * WidthRatio)!
   let subtitleFont: UIFont = UIFont(name: FontNameHelveticaNeueCyrRoman, size: 14 * WidthRatio)!
   let singleTitleFont: UIFont = UIFont(name: FontNameHelveticaNeueCyrRoman, size: 15.33 * WidthRatio)!
   
   weak var delegate : YPSegmentedViewDelegate?
   
   var segments: [YPSegment] = []
   {
      didSet
      {
         let lastSegmentIndex = segments.count - 1
         for (i, segment) in segments.enumerated()
         {
            if segment.singleTitle {
               segment.titleFont = singleTitleFont
            }
            else {
               segment.titleFont = titleFont
               segment.subtitleFont = subtitleFont
            }
            segment.view.segmentedView = self
            
            var position : YPSegmentPosition = []
            if i == 0 {
               position.insert(.left)
            }
            if i == lastSegmentIndex {
               position.insert(.right)
            }
            segment.view.segmentPosition = position
         }
         selectedIndex = segments.isEmpty ? nil : 0
         invalidateIntrinsicContentSize()
         setNeedsLayout()
      }
   }
   
   var selectedIndex : Int!
   {
      didSet {
         onSelectionChange()
      }
   }
   
   var selectedSegment : YPSegment!
   {
      if let index = selectedIndex, index >= 0, index < segments.count  {
         return segments[index]
      }
      else {
         return nil
      }
   }
   
   fileprivate func selectSegment(_ segment : YPSegment)
   {
      if let index = segments.index(ofObjectIdenticalTo: segment), index != selectedIndex
      {
         selectedIndex = index
         delegate?.segmentedViewSelectionChanged?(self)
      }
   }
   
   private func onSelectionChange()
   {
      if let segment = selectedSegment
      {
         for seg in segments {
            seg.view.isSelected = (seg === segment)
         }
      }
      else
      {
         for seg in segments {
            seg.view.isSelected = false
         }
      }
   }
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      backgroundColor = YPSegmentedView.normalColor
      clipsToBounds = true
   }
   
   override func layoutSubviews()
   {
      super.layoutSubviews()
      cornerRadius = bounds.height / 2
      
      for subview in subviews
      {
         if subview is YPSegmentView {
            subview.removeFromSuperview()
         }
      }
      
      guard !segments.isEmpty else { return }
      
      let margin = bounds.height * 0.17
      let segmentWidth = (bounds.width - margin * 2) / CGFloat(segments.count)
      let lastSegmentIndex = segments.count - 1
      
      for (i, segment) in segments.enumerated()
      {
         insertSubview(segment.view, at: i)
         
         var width = segmentWidth
         var x = CGFloat(i) * segmentWidth
         
         if i == 0 { width += margin }
         else { x += margin }
         
         if i == lastSegmentIndex { width += margin }
         
         segment.view.frame = CGRect(x: x, y: 0, width: width, height: bounds.height)
      }
   }
   
   override var intrinsicContentSize: CGSize
   {
      var maxWidth : CGFloat = 0
      var maxHeight : CGFloat = 0
      for segment in segments
      {
         maxWidth = max(maxWidth, segment.view.defaultIntrinsicContentSize.width)
         maxHeight = max(maxHeight, segment.view.defaultIntrinsicContentSize.height)
      }
      
      let margin = maxHeight * 0.17
      return CGSize(width: maxWidth * CGFloat(segments.count) + margin * 2, height: maxHeight)
   }
}

@objc protocol YPSegmentedViewDelegate
{
   @objc optional func segmentedViewSelectionChanged(_ segmentedView : YPSegmentedView)
}

extension YPSegmentedView
{
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

class YPSegment
{
   let singleTitle : Bool
   let title : String
   let subtitle : String?
   
   var value : Any? //attached value
   
   fileprivate let view : YPSegmentView
   fileprivate var titleFont : UIFont?
   {
      get { return view.titleLabel?.font }
      set {
         view.titleLabel?.font = newValue
         view.invalidateIntrinsicContentSize()
      }
   }
   fileprivate var subtitleFont : UIFont?
   {
      get { return view.subtitleLabel?.font }
      set {
         view.subtitleLabel?.font = newValue
         view.invalidateIntrinsicContentSize()
      }
   }
   
   
   init(_ title : String = "", _ subtitle : String? = nil)
   {
      self.title = title
      self.subtitle = subtitle
      self.singleTitle = isNilOrEmpty(subtitle)
      self.view = YPSegmentView.view(title: title, subtitle: subtitle, singleTitle: self.singleTitle)
      self.view.segment = self
   }
}


fileprivate struct YPSegmentPosition: OptionSet
{
   let rawValue: Int
   static let left = YPSegmentPosition(rawValue: 1)
   static let right = YPSegmentPosition(rawValue: 2)
}

fileprivate class YPSegmentView : UIControl
{
   var segmentPosition : YPSegmentPosition = []
   {
      didSet {
         setNeedsLayout()
         invalidateIntrinsicContentSize()
      }
   }
   
   var singleTitle : Bool = false
   var titleLabel : UILabel!
   var subtitleLabel : UILabel!
   
   weak var segmentedView : YPSegmentedView?
   weak var segment : YPSegment?
   
   static let defaultSingleTitleInsets : UIEdgeInsets = UIEdgeInsets(top: 0, left: 10 * WidthRatio, bottom: 0, right: 10 * WidthRatio)
   static let defaultTitleSubtitleInsets : UIEdgeInsets = UIEdgeInsets(top: 8 * WidthRatio, left: 10 * WidthRatio, bottom: 4 * WidthRatio, right: 10 * WidthRatio)
   var insets : UIEdgeInsets
   {
      var ins : UIEdgeInsets = singleTitle ? YPSegmentView.defaultSingleTitleInsets : YPSegmentView.defaultTitleSubtitleInsets
      if segmentPosition.contains(.left) {
         ins.left += bounds.height * 0.17
      }
      if segmentPosition.contains(.right) {
         ins.right += bounds.height * 0.17
      }
      return ins
   }
   
   class func view(title : String? = nil, subtitle : String? = nil, singleTitle : Bool) -> YPSegmentView
   {
      let view = YPSegmentView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
      view.singleTitle = singleTitle
      
      view.titleLabel = UILabel()
      view.titleLabel.backgroundColor = UIColor.clear
      view.titleLabel.textAlignment = .center
      view.titleLabel.adjustsFontSizeToFitWidth = true
      view.titleLabel.minimumScaleFactor = 0.5
      view.titleLabel.text = title
      view.addSubview(view.titleLabel)
      
      if !singleTitle
      {
         view.subtitleLabel = UILabel()
         view.subtitleLabel.backgroundColor = UIColor.clear
         view.subtitleLabel.textAlignment = .center
         view.subtitleLabel.adjustsFontSizeToFitWidth = true
         view.subtitleLabel.minimumScaleFactor = 0.5
         view.subtitleLabel.text = subtitle
         view.addSubview(view.subtitleLabel)
      }
      
      view.setNeedsLayout()
      
      view.updateColor()
      view.addTarget(view, action: #selector(onTap), for: .touchUpInside)
      
      return view
   }
   
   override func layoutSubviews()
   {
      let insets = self.insets
      
      if let label = titleLabel
      {
         if singleTitle
         {
            label.frame = CGRect(x: insets.left, y: insets.top, width: bounds.width - insets.width, height: bounds.height - insets.height)
         }
         else
         {
            label.frame = CGRect(x: insets.left, y: insets.top, width: bounds.width - insets.width, height: bounds.height / 2 - insets.top)
         }
      }
      if let label = subtitleLabel
      {
         label.frame = CGRect(x: insets.left, y: bounds.height / 2, width: bounds.width - insets.width, height: bounds.height / 2 - insets.bottom)
      }
   }
   
   var defaultIntrinsicContentSize: CGSize
   {
      var width : CGFloat = 0
      var height : CGFloat = 0
      
      let insets : UIEdgeInsets = singleTitle ? YPSegmentView.defaultSingleTitleInsets : YPSegmentView.defaultTitleSubtitleInsets
      
      if let label = titleLabel
      {
         let text = label.text ?? ""
         let rect = textSize(text, font: label.font)
         width = rect.width
         height = rect.height
      }
      if let label = subtitleLabel
      {
         let text = label.text ?? ""
         let rect = textSize(text, font: label.font)
         width = max(width, rect.width)
         height += rect.height
      }
      
      width += insets.width
      height += insets.height
      
      return CGSize(width: width, height: height)
   }
   
   override var intrinsicContentSize: CGSize
   {
      var size = defaultIntrinsicContentSize
      
      if segmentPosition.contains(.left) {
         size.width += size.height * 0.17
      }
      if segmentPosition.contains(.right) {
         size.width += size.height * 0.17
      }
      
      return size
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
   
   func updateColor()
   {
      if isSelected {
         backgroundColor = YPSegmentedView.selectedColor
         titleLabel?.textColor = YPSegmentedView.selectedTextColor
         subtitleLabel?.textColor = YPSegmentedView.selectedTextColor
      }
      else if isHighlighted {
         backgroundColor = YPSegmentedView.selectedColor.withAlphaComponent(0.5)
         titleLabel?.textColor = YPSegmentedView.highlightedTextColor
         subtitleLabel?.textColor = YPSegmentedView.highlightedTextColor
      }
      else {
         backgroundColor = UIColor.clear
         titleLabel?.textColor = YPSegmentedView.normalTextColor
         subtitleLabel?.textColor = YPSegmentedView.normalTextColor
      }
   }
   
   @objc func onTap()
   {
      if let seg = segment {
         segmentedView?.selectSegment(seg)
      }
   }
}
