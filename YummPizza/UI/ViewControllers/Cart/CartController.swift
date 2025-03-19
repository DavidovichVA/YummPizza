//
//  CartController.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/15/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import Alamofire
import Kingfisher

class CartController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate
{
   @IBOutlet weak var tableView: UITableView!
   @IBOutlet weak var promoCodeView: UIView!
   @IBOutlet weak var promoCodeField: UITextField!
   @IBOutlet weak var totalPriceLabel: UILabel!
   @IBOutlet weak var checkoutButton: UIButton!
   @IBOutlet weak var bottomViewSpace: NSLayoutConstraint!
   
   var sales : [Sale] = []
   {
      didSet {
         giftBarButtonItem?.badgeNumber = sales.count
      }
   }
   
   var giftBarButtonItem : GiftBarButtonItem!
   weak var giftController : GiftController?
   
   private let promoViewTranslucentAlpha : CGFloat = 0.75
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      tableView.rowHeight = 264 * WidthRatio
      tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 54 * WidthRatio, right: 0)
      
      giftBarButtonItem = GiftBarButtonItem.item(sales.count, target: self, action: #selector(onGiftTap))
      let negativeSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
      negativeSpace.width = -15
      navigationItem.rightBarButtonItems = [negativeSpace, giftBarButtonItem]
      
      let promoCodeFieldFont = UIFont(name: FontNameYPNeutraBold, size: 20 * WidthRatio)!
      let placeHolderFont = UIFont(name: FontNameYPNeutraBold, size: 14 * WidthRatio)!
      promoCodeField.font = promoCodeFieldFont
      let paragraphStyle = (promoCodeField.defaultTextAttributes[NSAttributedStringKey.paragraphStyle.rawValue] as! NSParagraphStyle).mutableCopy() as! NSMutableParagraphStyle
      paragraphStyle.minimumLineHeight = (promoCodeFieldFont.lineHeight + placeHolderFont.lineHeight) / 2
      promoCodeField.attributedPlaceholder = NSAttributedString(string:"   ВВЕСТИ ПРОМО-КОД...", attributes:[NSAttributedStringKey.font : placeHolderFont, NSAttributedStringKey.foregroundColor: rgb(255, 169, 0), NSAttributedStringKey.paragraphStyle : paragraphStyle])
    
      setupForKeyboard()
      setupCartItemsObserver()
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      tableView.reloadData()
      updateSalesAndPrice()
      updateButtonEnabled()
   }
    
   override func viewDidLayoutSubviews()
   {
      super.viewDidLayoutSubviews()
      updatePromoCodeView()
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?)
   {
      if segue.identifier == "PresentGift", let controller = segue.destination as? GiftController
      {
         giftController = controller
         controller.sales = sales
      }
      else if segue.identifier == "SelectDish",
          let cell = sender as? CartCell, let dishController = segue.destination as? DishController
      {
         if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
         }
         dishController.mode = .edit
         dishController.cartItem = cell.item
         dishController.backNavTitle = "КОРЗИНА"
      }
   }
   
   //MARK: - Cart Items Observer
   
   private var cartItemsObserver : NSObjectProtocol?
   
   private func setupCartItemsObserver()
   {
      cartItemsObserver = NotificationCenter.default.addObserver(forName: .YPCartItemsChangedFromValidation, object: nil, queue: OperationQueue.main)
      {
         [unowned self]
         notification in
         self.tableView.reloadData()
         self.updateSalesAndPrice()
         self.updateButtonEnabled()
      }
   }
   
   //MARK: - Methods
   
   func updateSalesAndPrice()
   {
      updateSales()
      totalPriceLabel.text = "\(Cart.totalPrice) Р"
   }
   
   func updateButtonEnabled()
   {
      checkoutButton.isEnabled = !Cart.isEmpty
   }
   
   func deleteItem(_ item : CartItem)
   {
      if let index = Cart.removeItem(item)
      {
         tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
         updateSalesAndPrice()
         updateButtonEnabled()
         
         if Cart.isEmpty {
            giftBarButtonItem.badgeNumber = 0
         }
      }
   }
   
   private var salesRequest : DataRequest?
   func updateSales()
   {
      var dishesWithCount : [String : Int] = [:]
      for item in Cart.items {
         dishesWithCount[item.dishVariant.id] = (dishesWithCount[item.dishVariant.id] ?? 0) + item.count
      }
      
      salesRequest?.cancel()
      salesRequest = RequestManager.getPotentialSales(dishesWithCount,
      success:
      {
         [weak self]
         sales in
         guard let strongSelf = self else { return }
         strongSelf.sales = sales
         if let controller = strongSelf.giftController
         {
            if sales.isEmpty {
               controller.dismiss(animated: true, completion: nil)
            }
            else {
               controller.sales = sales
            }
         }
      },
      failure:
      {
         errorDescription in
         dlog(errorDescription)
      })
   }
   
   func checkout()
   {
      let time = Date()
      let hour = calendar.dateComponents([.hour], from: time).hour!
      if hour >= 11 && hour < 23
      {
         OrderPromoCode = promoCodeField.text
         performSegue(withIdentifier: "DeliveryAddress", sender: self)
      }
      else
      {
         let alertController = UIAlertController(title: "Время работы пиццерий с 11:00 до 23:00, ваш заказ может быть получен в течении 1 часа после открытия", message: nil, preferredStyle: .alert)

         let proceed = UIAlertAction(title: "Продолжить", style: .default, handler: { _ in
            OrderPromoCode = self.promoCodeField.text
            self.performSegue(withIdentifier: "DeliveryAddress", sender: self)
         })
         alertController.addAction(proceed)
         let cancel = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
         alertController.addAction(cancel)
         
         AlertManager.showAlert(alertController)
      }
   }
   
  //MARK: - Keyboard
   
   private var keyboardObserver : NSObjectProtocol?
   private func setupForKeyboard()
   {
      let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboardTap))
      tapRecognizer.cancelsTouchesInView = false
      tapRecognizer.isEnabled = false
      view.addGestureRecognizer(tapRecognizer)
      
      keyboardObserver = NotificationCenter.default.addObserver(forName: .UIKeyboardWillChangeFrame, object: nil, queue: OperationQueue.main)
      {
         [unowned self]
         notification in
         let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
         let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
         let curve = UIViewAnimationCurve(rawValue: (notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).intValue)!
         
         let keyboardWillHide = (keyboardRect.origin.y >= ScreenHeight)
         
         UIView.beginAnimations(nil, context: nil)
         UIView.setAnimationDuration(duration)
         UIView.setAnimationCurve(curve)
         
         if keyboardWillHide {
            self.bottomViewSpace.constant = 0
            tapRecognizer.isEnabled = false
            self.promoCodeView.alpha = self.promoViewTranslucentAlpha
         }
         else {
            self.bottomViewSpace.constant = keyboardRect.size.height
            tapRecognizer.isEnabled = true
            self.promoCodeView.alpha = 1
         }
         self.view.layoutIfNeeded()
         
         UIView.commitAnimations()
      }
   }
   
   @objc private func hideKeyboardTap() {
      view.endEditing(true)
   }
   
   deinit
   {
      if keyboardObserver != nil {
         NotificationCenter.default.removeObserver(keyboardObserver!)
      }
      if cartItemsObserver != nil {
         NotificationCenter.default.removeObserver(cartItemsObserver!)
      }
   }
   
   // MARK: - Text Field
   
   public func textFieldShouldReturn(_ textField: UITextField) -> Bool
   {
      view.endEditing(true)
      return true
   }
   
   // MARK: - Table view

   func updatePromoCodeView()
   {
      if promoCodeField.isFirstResponder
      {
         promoCodeView.alpha = 1
      }
      else
      {
         let scrollTotalDistance = max(0, (tableView.contentSize.height + tableView.contentInset.height - tableView.bounds.height))
         promoCodeView.alpha = minmax(promoViewTranslucentAlpha, 1 + ((tableView.contentOffset.y - scrollTotalDistance) / tableView.contentInset.bottom) * promoViewTranslucentAlpha, 1)
      }
   }
   
   public func scrollViewDidScroll(_ scrollView: UIScrollView)
   {
      updatePromoCodeView()
      if let scrollIndicator = scrollView.subviews.last as? UIImageView, scrollIndicator.image !== scrollIndicatorImage
      {
         scrollIndicator.image = scrollIndicatorImage
         scrollIndicator.cornerRadius = 1
         scrollIndicator.clipsToBounds = true
         scrollIndicator.backgroundColor = UIColor.clear
      }

   }
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
   {
      return Cart.itemsCount
   }

   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let cell = tableView.dequeueReusableCell(withIdentifier: "CartCell", for: indexPath) as! CartCell
      
      cell.cartController = self
      if let item = Cart.item(indexPath.row)
      {
         cell.item = item
      }
      cell.bottomSeparator.isHidden = (indexPath.row == Cart.itemsCount - 1)

      return cell
   }
   
   // MARK: - Actions
   
   @objc func onGiftTap()
   {
      if sales.count > 0 {
         performSegue(withIdentifier: "PresentGift", sender: self)
      }
   }
   
   @IBAction func checkoutTap()
   {
      checkout()
   }
}


class CartCell: UITableViewCell
{
   static let paragraphStyle : NSParagraphStyle =
   {
      let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
      style.lineSpacing = 5
      style.lineBreakMode = .byTruncatingTail
      return style
   }()
   
   static let descTitleAttrs = [NSAttributedStringKey.font : UIFont(name: FontNameYPNeutraBold, size: 14.0 * WidthRatio)!, NSAttributedStringKey.paragraphStyle : paragraphStyle]
   
   static let descAttrs = [NSAttributedStringKey.font : UIFont(name: FontNameHelveticaNeueCyrRoman, size: 14.0 * WidthRatio)!, NSAttributedStringKey.paragraphStyle : paragraphStyle]
   
   
   @IBOutlet weak var nameLabel: UILabel!
   @IBOutlet weak var imageContainerView: UIView!
   @IBOutlet weak var dishImageView: UIImageView!
   @IBOutlet weak var dishVariantLabel: UILabel!
   @IBOutlet weak var doughLabel: UILabel!
   @IBOutlet weak var toppingsLabel: UILabel!
   @IBOutlet weak var priceLabel: UILabel!
   @IBOutlet weak var countLabel: UILabel!
   @IBOutlet weak var bottomSeparator: UIView!
   @IBOutlet weak var overlayView: UIView!
   
   weak var cartController : CartController!
   
   var item : CartItem!
   {
      didSet
      {
         guard item != nil, !item.isInvalidated else { return }
         
         nameLabel.text = item.dish.name
         countLabel.text = String(item.count)
         priceLabel.text = "\(item.price) Р"
         dishImageView.kf.setImage(with: item.dish.imageLink)
         
         dishVariantLabel.attributedText = attributedDesc(item.dish.dishVariantsType, item.dishVariant.name)
         if item.dish.type == .pizza
         {
            if let dough = item .dough {
               doughLabel.attributedText = attributedDesc("ТЕСТО", dough.name)
            }
            else {
               doughLabel.text = nil
            }
            
            if item.toppingCounts.isEmpty {
               toppingsLabel.text = nil
            }
            else
            {
               let toppingsText = item.toppingCounts.reduce("", { (str, toppingCount) in
                  if str.isEmpty { return toppingCount.topping.name }
                  else if toppingCount.topping.name.isEmpty { return str }
                  else { return str + ", " + toppingCount.topping.name }
               })
               toppingsLabel.attributedText = attributedDesc("ТОППИНГИ", toppingsText)
            }
         }
         else
         {
            doughLabel.text = nil
            toppingsLabel.text = nil
         }
      }
   }
   
   func attributedDesc(_ title : String, _ desc : String) -> NSAttributedString
   {
      let str = NSMutableAttributedString(string: title + ":   ", attributes: CartCell.descTitleAttrs)
      str.append(NSMutableAttributedString(string: desc, attributes: CartCell.descAttrs))
      return str as NSAttributedString
   }
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      imageContainerView.layer.masksToBounds = false
      imageContainerView.layer.shadowOpacity = 0.15
      imageContainerView.layer.shadowOffset = CGSize(width: 0, height: 7 * WidthRatio)
      imageContainerView.layer.shadowRadius = 5 * WidthRatio
      imageContainerView.layer.shadowColor = UIColor.black.cgColor
   }
   
   override func prepareForReuse()
   {
      super.prepareForReuse()
      dishImageView.kf.cancelDownloadTask()
   }
    
   // MARK: - Selection
    
   private var _isSelected = false
   override func setSelected(_ selected: Bool, animated: Bool)
   {
      _isSelected = selected
      UIView.animate(withDuration: (animated ? 0.3 : 0)) {
         self.updateOverlay()
      }
   }
    
   private var _isHighlighted = false
   override func setHighlighted(_ highlighted: Bool, animated: Bool)
   {
      _isHighlighted = highlighted
      UIView.animate(withDuration: (animated ? 0.3 : 0)) {
         self.updateOverlay()
      }
   }
    
   override var isSelected: Bool
   {
      get { return _isSelected }
      set {
         _isSelected = newValue
         updateOverlay()
      }
   }
    
   override var isHighlighted: Bool
   {
      get { return _isHighlighted }
      set {
         _isHighlighted = newValue
         updateOverlay()
      }
   }
    
   func updateOverlay()
   {
      if isSelected { overlayView.alpha = 0.3 }
      else if isHighlighted { overlayView.alpha = 0.15 }
      else { overlayView.alpha = 0 }
   }
    
   // MARK: - Count
    
   func updateCount()
   {
      countLabel.text = String(item.count)
      priceLabel.text = "\(item.price) Р"
      cartController.updateSalesAndPrice()
   }
   
   @IBAction func minusCountTap()
   {
      if item.count > 1
      {
         item.addCount(-1)
         updateCount()
      }
      else
      {
         let alertController = UIAlertController(title: "Вы действительно хотите удалить товар из корзины?", message: nil, preferredStyle: .alert)
         let itemToDelete = self.item!
         let delete = UIAlertAction(title: "Удалить", style: .destructive, handler: { _ in
            self.cartController.deleteItem(itemToDelete)
         })
         alertController.addAction(delete)
         let cancel = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
         alertController.addAction(cancel)
         
         AlertManager.showAlert(alertController)
      }
   }
   
   @IBAction func plusCountTap()
   {
      item.addCount(1)
      updateCount()
   }
   
   @IBAction func deleteTap() {
      cartController.deleteItem(self.item)
   }
}

