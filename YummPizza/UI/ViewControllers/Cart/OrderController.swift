//
//  OrderController.swift
//  YummPizza
//
//  Created by Blaze Mac on 6/16/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

enum OrderAddresType
{
   case user(address : Address)
   case pizzeria(pizzeria : Pizzeria)
}

var OrderPromoCode : String?
var OrderComment : String?
var OrderPaymentByCash : Bool = true
var OrderPaymentWithBonuses : Decimal = 0
var OrderReceiveNotifications : Bool = true
var OrderAddress : OrderAddresType!

//for unregistered user
var OrderName : String?
var OrderPhone : String?

class OrderController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
   @IBOutlet weak var tableView: UITableView!
   @IBOutlet weak var totalPriceLabel: UILabel!
   
   private enum CellType
   {
      case address(type: OrderAddresType)
      case delivery(free: Bool)
      case payment(byCash: Bool)
      case bonuses(amount: Decimal)
      case space
      case orderTitle
      case cartItem(item: CartItem)
   }
   
   private var cellTypes : [CellType] = []
   private var sumForFreeDelivery : Decimal = CommonValue.sumForFreeDelivery
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      tableView.rowHeight = UITableViewAutomaticDimension
      updateData()
      setupCartItemsObserver()
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      if let navController = self.navigationController
      {
         navController.navigationBar.isTranslucent = false
         navController.navigationBar.shadowImage = nil
         navController.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
      }
      
      RequestManager.updateCommonValues(
      success:
      {
         [weak self] in
         guard let strongSelf = self else { return }
         if CommonValue.sumForFreeDelivery != strongSelf.sumForFreeDelivery {
            strongSelf.updateData()
         }
      },
      failure:
      {
         [weak self]
         errorDescription in
         dlog(errorDescription)
         guard self != nil else { return }
         AlertManager.showAlert(errorDescription, buttonTitle: "Закрыть")
      })
   }
   
   //MARK: - Cart Items Observer
   
   private var cartItemsObserver : NSObjectProtocol?
   
   private func setupCartItemsObserver()
   {
      cartItemsObserver = NotificationCenter.default.addObserver(forName: .YPCartItemsChanged, object: nil, queue: OperationQueue.main)
      {
         [unowned self]
         notification in
         self.updateData()
      }
   }
   
   deinit
   {
      if cartItemsObserver != nil {
         NotificationCenter.default.removeObserver(cartItemsObserver!)
      }
   }
   
   //MARK: - Methods
   
   func updateData()
   {
      var types : [CellType] = [.address(type: OrderAddress)]
      
      if case .user = OrderAddress!, sumForFreeDelivery > 0 {
         types.append(.delivery(free: Cart.totalPrice >= sumForFreeDelivery))
      }
      
      types.append(.payment(byCash: OrderPaymentByCash))
      
      let maxSumPaidWithBonuses = Cart.maxSumPaidWithBonuses
      OrderPaymentWithBonuses = min(OrderPaymentWithBonuses, maxSumPaidWithBonuses)
      if OrderPaymentWithBonuses > 0
      {
         types.append(.bonuses(amount: OrderPaymentWithBonuses))
         totalPriceLabel.text = "\(max(0, Cart.totalPrice - OrderPaymentWithBonuses)) Р"
      }
      else
      {
         totalPriceLabel.text = "\(Cart.totalPrice) Р"
      }
      
      if Cart.itemsCount > 0
      {
         types.append(.space)
         types.append(.orderTitle)
         for item in Cart.items {
            types.append(.cartItem(item: item))
         }
      }
      cellTypes = types
      tableView.reloadData()
   }
   
   func addOrder()
   {
      RequestManager.addOrder(
      success:
      {
         OrderPromoCode = nil
         OrderComment = nil
         OrderName = nil
         OrderPhone = nil
         OrderPaymentWithBonuses = 0
         Cart.removeAllItems()
         AppDelegate.goToOrders()
      },
      failure:
      {
         errorDescription in
         switch errorDescription
         {
         case "ERROR_IIKO_USER_DOES_NOT_EXIST": AlertManager.showAlert("Пользователя с данным телефонным номером нет в системе IIKO")
         case "ERROR_INVALID_DATA": AlertManager.showAlert("Некорректные контактные данные")
         default: AlertManager.showAlert(errorDescription)
         }
      })
   }
   
   // MARK: - Table view
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
   {
      return cellTypes.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let cellType = cellTypes[indexPath.row]
      switch cellType
      {
      case .address(let type):
         let cell = tableView.dequeueReusableCell(withIdentifier: "OrderGeneralCell", for: indexPath) as! OrderGeneralCell
         switch type
         {
         case .user(let address): cell.set(title: "АДРЕС", text: address.streetHouseString)
         case .pizzeria(let pizzeria): cell.set(title: "ПИЦЦЕРИЯ", text: pizzeria.addressString)
         }
         cell.showsInfoButton = false
         return cell
         
      case .delivery(let free):
         let cell = tableView.dequeueReusableCell(withIdentifier: "OrderGeneralCell", for: indexPath) as! OrderGeneralCell
         cell.set(title: "ДОСТАВКА", text: (free ? "Бесплатная" : "Платная"))
         cell.showsInfoButton = true
         return cell
         
      case .payment(let byCash):
         let cell = tableView.dequeueReusableCell(withIdentifier: "OrderGeneralCell", for: indexPath) as! OrderGeneralCell
         cell.set(title: "ОПЛАТА", text: (byCash ? "Наличными" : "Банковской карточкой"))
         cell.showsInfoButton = false
         return cell
         
      case .bonuses(let amount):
         let cell = tableView.dequeueReusableCell(withIdentifier: "OrderGeneralCell", for: indexPath) as! OrderGeneralCell
         cell.set(title: "ОПЛАТА БОНУСАМИ", text: "\(amount) Р")
         cell.showsInfoButton = false
         return cell
      
      case .space:
         let cell = tableView.dequeueReusableCell(withIdentifier: "OrderGeneralCell", for: indexPath) as! OrderGeneralCell
         cell.label.text = ""
         cell.showsInfoButton = false
         return cell
         
      case .orderTitle:
         let cell = tableView.dequeueReusableCell(withIdentifier: "OrderGeneralCell", for: indexPath) as! OrderGeneralCell
         cell.set(title: "ЗАКАЗ", text: "")
         cell.showsInfoButton = false
         return cell
         
      case .cartItem(let cartItem):
         let cell = tableView.dequeueReusableCell(withIdentifier: "OrderDishCell", for: indexPath) as! OrderDishCell
         cell.item = cartItem
         cell.bottomSeparator.isHidden = (indexPath.row == cellTypes.count - 1)
         return cell
      }
   }
   
   func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
   {
      let cellType = cellTypes[indexPath.row]
      switch cellType
      {
      case .cartItem: return 120 * WidthRatio
      default: return 30 * WidthRatio
      }
   }
   
   func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath)
   {
      dlog(indexPath)
   }
   
   public func scrollViewDidScroll(_ scrollView: UIScrollView)
   {
      if let scrollIndicator = scrollView.subviews.last as? UIImageView, scrollIndicator.image !== scrollIndicatorImage
      {
         scrollIndicator.image = scrollIndicatorImage
         scrollIndicator.cornerRadius = 1
         scrollIndicator.clipsToBounds = true
         scrollIndicator.backgroundColor = UIColor.clear
      }
   }
   
   // MARK: - Actions
   
   @IBAction func confirmTap()
   {
      addOrder()
   }
}


class OrderGeneralCell : UITableViewCell
{
   static let paragraphStyle : NSParagraphStyle =
   {
      let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
      style.lineSpacing = 5
      return style
   }()
   
   static let descTitleAttrs = [NSAttributedStringKey.font : UIFont(name: FontNameYPNeutraBold, size: 16.0 * WidthRatio)!, NSAttributedStringKey.paragraphStyle : paragraphStyle]
   
   static let descAttrs = [NSAttributedStringKey.font : UIFont(name: FontNameHelveticaNeueCyrRoman, size: 16.0 * WidthRatio)!, NSAttributedStringKey.paragraphStyle : paragraphStyle]
   
   
   @IBOutlet weak var label: UILabel!
   @IBOutlet weak var infoIcon: UIImageView!
   @IBOutlet weak var infoButton: UIButton!
   @IBOutlet weak var labelToInfoConstraint: NSLayoutConstraint!
   @IBOutlet weak var labelToSuperviewConstraint: NSLayoutConstraint!
   
   var showsInfoButton : Bool = true
   {
      didSet
      {
         if showsInfoButton
         {
            infoIcon.isHidden = false
            infoButton.isEnabled = true
            labelToInfoConstraint.priority = UILayoutPriority(rawValue: 999)
            labelToSuperviewConstraint.priority = UILayoutPriority(rawValue: 1)
         }
         else
         {
            infoIcon.isHidden = true
            infoButton.isEnabled = false
            labelToInfoConstraint.priority = UILayoutPriority(rawValue: 1)
            labelToSuperviewConstraint.priority = UILayoutPriority(rawValue: 999)
         }
      }
   }
   
   func set(title : String, text : String)
   {
      let str = NSMutableAttributedString(string: title + ":  ", attributes: OrderGeneralCell.descTitleAttrs)
      str.append(NSMutableAttributedString(string: text, attributes: OrderGeneralCell.descAttrs))
      label.attributedText = str
   }
}


class OrderDishCell : UITableViewCell
{
   static let paragraphStyle : NSParagraphStyle =
   {
      let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
      style.lineSpacing = 5
      return style
   }()
   
   static let descTitleAttrs = [NSAttributedStringKey.font : UIFont(name: FontNameYPNeutraBold, size: 14.0 * WidthRatio)!, NSAttributedStringKey.paragraphStyle : paragraphStyle]
   
   static let descAttrs = [NSAttributedStringKey.font : UIFont(name: FontNameHelveticaNeueCyrRoman, size: 14.0 * WidthRatio)!, NSAttributedStringKey.paragraphStyle : paragraphStyle]
   
   @IBOutlet weak var nameLabel: UILabel!
   @IBOutlet weak var dishVariantLabel: UILabel!
   @IBOutlet weak var doughLabel: UILabel!
   @IBOutlet weak var toppingsLabel: UILabel!
   @IBOutlet weak var countLabel: UILabel!
   @IBOutlet weak var countToDishVariantVerticalConstraint: NSLayoutConstraint!
   @IBOutlet weak var countToDoughVerticalConstraint: NSLayoutConstraint!
   @IBOutlet weak var countToToppingsVerticalConstraint: NSLayoutConstraint!
   @IBOutlet weak var priceLabel: UILabel!
   @IBOutlet weak var bottomSeparator: UIView!
   
   var item : CartItem!
   {
      didSet
      {
         nameLabel.text = item.dish.name
         dishVariantLabel.attributedText = attributedDesc(item.dish.dishVariantsType, item.dishVariant.name)
         
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
         
         countToDishVariantVerticalConstraint.priority = UILayoutPriority(rawValue: 1)
         countToDoughVerticalConstraint.priority = UILayoutPriority(rawValue: 1)
         countToToppingsVerticalConstraint.priority = UILayoutPriority(rawValue: 1)
         
         if !isNilOrEmpty(toppingsLabel.text) { countToToppingsVerticalConstraint.priority = UILayoutPriority(rawValue: 999) }
         else if !isNilOrEmpty(doughLabel.text) { countToDoughVerticalConstraint.priority = UILayoutPriority(rawValue: 999) }
         else { countToDishVariantVerticalConstraint.priority = UILayoutPriority(rawValue: 999) }

         countLabel.attributedText = attributedDesc("КОЛИЧЕСТВО", String(item.count))
         priceLabel.text = "\(item.price) Р"
      }
   }
   
   func attributedDesc(_ title : String, _ desc : String) -> NSAttributedString
   {
      let str = NSMutableAttributedString(string: title + ":   ", attributes: OrderDishCell.descTitleAttrs)
      str.append(NSMutableAttributedString(string: desc, attributes: OrderDishCell.descAttrs))
      return str as NSAttributedString
   }
}
