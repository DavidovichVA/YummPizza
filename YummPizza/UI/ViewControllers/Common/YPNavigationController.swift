//
//  YPNavigationController.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/24/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class YPNavigationController: UINavigationController
{
   @IBInspectable var swipeToBack : Bool
   {
      get { return interactivePopGestureRecognizer?.isEnabled ?? false }
      set {
         if let recognizer = interactivePopGestureRecognizer {
            recognizer.isEnabled = newValue
         }
         else {
            MainQueue.async {
               self.interactivePopGestureRecognizer?.isEnabled = newValue
            }
         }
      }
   }
   
   @IBInspectable var hidesBottomLine : Bool = false
   {
      didSet
      {
         bottomLine?.isHidden = hidesBottomLine
      }
   }
   
   private var _bottomLine : UIView? = nil
   var bottomLine : UIView?
   {
      if _bottomLine == nil
      {
         _bottomLine = navigationBar.findSubview(criteria: {
            view in
            return view is UIImageView && view.bounds.height <= 1
         })
      }
      return _bottomLine
   }
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      bottomLine?.isHidden = hidesBottomLine
   }
   
   override var viewControllers: [UIViewController]
   {
      didSet
      {
         bottomLine?.isHidden = hidesBottomLine
      }
   }
   
   override func pushViewController(_ viewController: UIViewController, animated: Bool)
   {
      super.pushViewController(viewController, animated: animated)
      bottomLine?.isHidden = hidesBottomLine
   }
   
   override func popViewController(animated: Bool) -> UIViewController?
   {
      let controller = super.popViewController(animated: animated)
      bottomLine?.isHidden = hidesBottomLine
      return controller
   }
   
   override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]?
   {
      let controllers = super.popToViewController(viewController, animated: animated)
      bottomLine?.isHidden = hidesBottomLine
      return controllers
   }
   
   override func popToRootViewController(animated: Bool) -> [UIViewController]?
   {
      let controllers = super.popToRootViewController(animated: animated)
      bottomLine?.isHidden = hidesBottomLine
      return controllers
   }
   
   override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool)
   {
      super.setViewControllers(viewControllers, animated: animated)
      bottomLine?.isHidden = hidesBottomLine
   }
}
