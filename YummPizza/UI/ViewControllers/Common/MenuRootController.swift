//
//  MenuRootController.swift
//  YummPizza
//
//  Created by Blaze Mac on 4/4/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class MenuRootController: UIViewController, UIScrollViewDelegate
{
   @IBOutlet weak var scrollView: MenuScrollView!
   @IBOutlet weak var menuContainerView: UIView!
   @IBOutlet weak var contentContainerView: UIView!
   @IBOutlet var menuHideTapGecognizer: UITapGestureRecognizer!
   
   public var isEnabled : Bool
   {
      get { return scrollView?.isScrollEnabled ?? false }
      set { scrollView?.isScrollEnabled = newValue }
   }
   
   public var isShown : Bool
   {
      guard scrollView != nil else { return false }
      return scrollView.contentOffset.x < totalScrollDistance - 0.1
   }
   
   private var _menuController : UIViewController!
   var menuController : UIViewController!
   {
      get { return _menuController }
      set(newController)
      {
         _ = self.view
         if let oldVC = _menuController
         {
            guard oldVC != newController else { return }
            oldVC.willMove(toParentViewController: nil)
            oldVC.view.removeFromSuperview()
            oldVC.removeFromParentViewController()
         }
         
         _menuController = newController
         guard newController != nil else { return }
         
         addChildViewController(newController)
         newController.view.frame = menuContainerView.bounds
         menuContainerView.addSubview(newController.view)
         newController.didMove(toParentViewController: self)
      }
   }
   
   private var _contentController : UIViewController!
   var contentController : UIViewController!
   {
      get { return _contentController }
      set(newController)
      {
         _ = self.view
         if let oldVC = _contentController
         {
            guard oldVC != newController else { return }
            oldVC.willMove(toParentViewController: nil)
            oldVC.view.removeFromSuperview()
            oldVC.removeFromParentViewController()
         }
         
         _contentController = newController
         guard newController != nil else { return }
         
         addChildViewController(newController)
         newController.view.frame = contentContainerView.bounds
         contentContainerView.addSubview(newController.view)
         newController.didMove(toParentViewController: self)
      }
   }
   
   func showMenu(animated : Bool = true)
   {
      AppWindow.endEditing(true)
      
      if animated
      {
         scrollView.isUserInteractionEnabled = false
         scrollView.isPagingEnabled = false
         delay(0.5)
         {
            self.scrollView.isUserInteractionEnabled = true
            self.scrollView.isPagingEnabled = true
         }
      }
      
      scrollView.setContentOffset(CGPoint.zero, animated: animated)
   }
   
   func hideMenu(animated : Bool = true)
   {
      scrollView.setContentOffset(CGPoint(x: totalScrollDistance, y: 0), animated: animated)
   }
   
   //MARK: - Internal
   
   private var totalScrollDistance : CGFloat {
      return scrollView.contentSize.width - scrollView.width
   }
   private var currentScrolledFraction : CGFloat {
      return scrollView.contentOffset.x / totalScrollDistance
   }
   
   @IBAction func menuHideTap(_ sender: UITapGestureRecognizer)
   {
      hideMenu()
   }
   
   func scrollViewDidScroll(_ scrollView: UIScrollView)
   {
      menuHideTapGecognizer.isEnabled = scrollView.contentOffset.x < 0.1
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?)
   {
      super.prepare(for: segue, sender: sender)
      
      if segue.identifier == "EmbedMenu" {
         _menuController = segue.destination
      }
      else if segue.identifier == "EmbedContent" {
         _contentController = segue.destination
      }
   }
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      scrollView.addObserver(self, forKeyPath: "contentSize", options: [], context: nil)
   }
   
   override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
   {
      hideMenu(animated: false)
      scrollView.removeObserver(self, forKeyPath: "contentSize")
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      setNeedsStatusBarAppearanceUpdate()
   }
   
   override var preferredStatusBarStyle: UIStatusBarStyle
   {
      return contentController?.preferredStatusBarStyle ?? .default
   }
}


class MenuScrollView: UIScrollView, UIGestureRecognizerDelegate
{
   //scroll scrollview when dragging touch on its content
   override func touchesShouldCancel(in view: UIView) -> Bool
   {
      return !(view.superview is UINavigationBar)
   }
   
   func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
   {
      let touchContentLocation = touch.location(in: subviews[1])
      let shoudReceive = touchContentLocation.x < bounds.size.width * 1.1
      return shoudReceive
   }
}
