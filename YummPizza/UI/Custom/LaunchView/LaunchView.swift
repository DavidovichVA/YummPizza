//
//  LaunchView.swift
//  YummPizza
//
//  Created by Blaze Mac on 4/6/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class LaunchView: UIView
{
   static weak private(set) var instance : LaunchView?
   
   private static var view : LaunchView
   {
      if let inst = instance {
         return inst
      }
      let inst = Bundle.main.loadNibNamed("LaunchView", owner: nil, options: nil)![0] as! LaunchView
      inst.layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
      instance = inst
      return inst
   }
   
   var imageView: UIImageView! {
      return subviews.first as? UIImageView
   }
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      imageView.image = UIImage.animatedImageNamed("splash", duration: 1)
   }
   
   class func show(animated : Bool = false)
   {
      let launchView = view
      
      if launchView.superview == nil
      {
         launchView.frame = AppWindow.bounds
         AppWindow.addSubview(launchView)
      }
      
      if animated
      {
         launchView.alpha = 0
         UIView.animateIgnoringInherited(withDuration: 0.3) {
            launchView.alpha = 1
         }
      }
      else
      {
         launchView.alpha = 1
      }
      
      launchView.imageView.startAnimating()
   }
   
   class func hide(animated : Bool = true)
   {
      guard let launchView = instance else { return }
      
      if animated
      {
         UIView.animateIgnoringInherited(withDuration: 0.3, animations: { 
            launchView.alpha = 0
         },
         completion:
         {
            finished in
            launchView.removeFromSuperview()
            launchView.imageView.stopAnimating()
         })
      }
      else
      {
         launchView.removeFromSuperview()
         launchView.imageView.stopAnimating()
      }
   }
}
