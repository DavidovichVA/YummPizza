//
//  CartBarButtonItem.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/16/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class CartBarButtonItem: UIBarButtonItem
{
   public var badgeNumber : Int = 0
   {
      didSet
      {
         if badgeNumber > 0
         {
            cartBarView.numberLabel.text = String(badgeNumber)
            cartBarView.numberView.isHidden = false
            
         }
         else
         {
            cartBarView.numberLabel.text = nil
            cartBarView.numberView.isHidden = true
         }
      }
   }
   
   private var cartBarView : CartBarView { return customView as! CartBarView }
   
   public class func item() -> CartBarButtonItem
   {
      let cartBarView = Bundle.main.loadNibNamed("CartBarView", owner: nil, options: nil)![0] as! CartBarView
      cartBarView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
      let barButtonItem = CartBarButtonItem(customView: cartBarView)
      barButtonItem.width = CartBarView.cartBarViewSize.width
      barButtonItem.setupCartItemsObserver()
      return barButtonItem
   }
   
   //MARK: - Cart Items Observer
   
   private var cartItemsObserver : NSObjectProtocol?
   
   private func setupCartItemsObserver()
   {
      badgeNumber = Cart.itemsCount
      cartItemsObserver = NotificationCenter.default.addObserver(forName: .YPCartItemsCountChanged, object: nil, queue: OperationQueue.main)
      {
         [unowned self]
         notification in
         self.badgeNumber = Cart.itemsCount
      }
   }
   
   deinit
   {
      if cartItemsObserver != nil {
         NotificationCenter.default.removeObserver(cartItemsObserver!)
      }
   }
}

internal class CartBarView : UIControl
{
   @IBOutlet weak var numberView: UIView!
   @IBOutlet weak var numberLabel: UILabel!
   
   static let cartBarViewSize : CGSize = CGSize(width: 44, height: 40)
   override var intrinsicContentSize: CGSize { return CartBarView.cartBarViewSize }
   
   override func awakeFromNib() {
      super.awakeFromNib()
      addTarget(self, action: #selector(onTap), for: .touchUpInside)
   }
   
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
   
   @objc private func onTap()
   {
      AppDelegate.goToAppSection(.cart)
   }
}

