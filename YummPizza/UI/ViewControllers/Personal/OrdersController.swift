//
//  OrdersController.swift
//  YummPizza
//
//  Created by Blaze Mac on 7/4/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire

class OrdersController: UIViewController, YPPairedButtonDelegate, UITableViewDelegate, UITableViewDataSource
{   
   @IBOutlet weak var headerButton: YPPairedButton!
   @IBOutlet weak var activeView: UIView!
   @IBOutlet weak var completedView: UIView!
   @IBOutlet weak var activeTableView: UITableView!
   @IBOutlet weak var completedTableView: UITableView!
   @IBOutlet var referenceDishCell: OrdersDishCell!
   
   var activeRefreshControl : UIRefreshControl!
   var completedRefreshControl : UIRefreshControl!
   
   var showActiveOrders : Bool { return headerButton.selectionState == .left }
   var showCompletedOrders : Bool { return headerButton.selectionState == .right }
   
   public var startOrderId : Int64?
   
   private var activeOrders : [Order] = []
   
   fileprivate var expandedOrdersIds : Set<Int64> = []
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      headerButton.delegate = self
      updateDisplayedState()
      
      activeTableView.estimatedRowHeight = 480 * WidthRatio
      activeTableView.rowHeight = UITableViewAutomaticDimension
      completedTableView.estimatedRowHeight = 150 * WidthRatio
      completedTableView.rowHeight = UITableViewAutomaticDimension
      
      activeRefreshControl = UIRefreshControl()
      activeRefreshControl.addTarget(self, action: #selector(updateActiveOrders), for: .valueChanged)
      activeTableView.addSubview(activeRefreshControl)
      
      completedRefreshControl = UIRefreshControl()
      completedRefreshControl.addTarget(self, action: #selector(updateCompletedOrders), for: .valueChanged)
      completedTableView.addSubview(completedRefreshControl)
      
      initialUpdate()
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      if statusesRequest == nil, !activeOrders.isEmpty {
         updateStatuses()
      }
   }
   
   
   // MARK: - Methods
   
   func initialUpdate()
   {
      showAppSpinner(addedTo: view, animated: true)
      
      let showStartOrderBlock =
      {
         [weak self] in
         guard let strongSelf = self, let orderId = strongSelf.startOrderId else { return }
         if let index = strongSelf.activeOrders.index(where: { $0.id == orderId })
         {
            strongSelf.headerButton.selectionState = .left
            strongSelf.activeTableView.reloadData()
            let indexPath = IndexPath(row: index, section: 0)
            strongSelf.activeTableView.scrollToRow(at: indexPath, at: .top, animated: false)
         }
         else if let index = User.current?.ordersHistory.index(where: { $0.id == orderId })
         {
            strongSelf.headerButton.selectionState = .right
            strongSelf.completedTableView.reloadData()
            let indexPath = IndexPath(row: index, section: 0)
            strongSelf.completedTableView.scrollToRow(at: indexPath, at: .top, animated: false)
         }
      }
      
      let updateCompletedOrdersBlock =
      {
         [weak self] in
         RequestManager.updateHistoryOrders(
         success:
         {
            guard let strongSelf = self else { return }
            strongSelf.completedTableView.reloadData()
            showStartOrderBlock()
            hideAppSpinner(for: strongSelf.view)
         },
         failure:
         {
            errorDescription in
            dlog(errorDescription)
            guard let strongSelf = self else { return }
            showStartOrderBlock()
            hideAppSpinner(for: strongSelf.view)
            if !AlertManager.isAlertDisplayed {
               AlertManager.showAlert(errorDescription, buttonTitle: "Закрыть")
            }
         })
      }
      
      RequestManager.getActiveOrders(
      success:
      {
         [weak self]
         orders in
         guard let strongSelf = self else { return }
         strongSelf.activeOrders = orders
         strongSelf.activeTableView.reloadData()
         delay(10) { self?.updateStatuses(true) }
         updateCompletedOrdersBlock()
      },
      failure:
      {
         errorDescription in
         dlog(errorDescription)
         AlertManager.showAlert(errorDescription, buttonTitle: "Закрыть")
         updateCompletedOrdersBlock()
      })
   }
   
   @objc func updateActiveOrders()
   {
      RequestManager.getActiveOrders(
      success:
      {
         [weak self]
         orders in
         guard let strongSelf = self else { return }
         strongSelf.activeRefreshControl.endRefreshing()
         strongSelf.activeOrders = orders
         strongSelf.activeTableView.reloadData()
         strongSelf.statusesRequest?.cancel()
         delay(10) { self?.updateStatuses(true) }
      },
      failure:
      {
         [weak self]
         errorDescription in
         dlog(errorDescription)
         self?.activeRefreshControl.endRefreshing()
         AlertManager.showAlert(errorDescription, buttonTitle: "Закрыть")
      })
   }
   
   @objc func updateCompletedOrders()
   {
      RequestManager.updateHistoryOrders(
      success:
      {
         [weak self] in
         guard let strongSelf = self else { return }
         strongSelf.completedRefreshControl.endRefreshing()
         strongSelf.completedTableView.reloadData()
      },
      failure:
      {
         [weak self]
         errorDescription in
         dlog(errorDescription)
         self?.completedRefreshControl.endRefreshing()
         AlertManager.showAlert(errorDescription, buttonTitle: "Закрыть")
      })
   }
   
   private var statusesRequest : DataRequest?
   func updateStatuses(_ forced : Bool = true)
   {
      guard !activeOrders.isEmpty else { return }
      if let request = statusesRequest, forced {
         request.cancel()
      }
      
      statusesRequest = RequestManager.updateOrdersStatus(activeOrders,
      success:
      {
         [weak self]
         ordersListChanged in
         if ordersListChanged {
            self?.updateActiveOrders()
         }
         else {
            delay(10) { self?.updateStatuses() }
         }
      },
      failure:
      {
         [weak self]
         errorDescription in
         dlog(errorDescription)
         delay(10) { self?.updateStatuses() }
      })
   }
   
   func updateDisplayedState()
   {
      activeView.isHidden = showCompletedOrders
      completedView.isHidden = !activeView.isHidden
   }
   
   // MARK: - Table view
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
   {
      if tableView === activeTableView {
         return activeOrders.count
      }
      else {
         return User.current?.ordersHistory.count ?? 0
      }
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      if tableView === activeTableView
      {
         let cell = tableView.dequeueReusableCell(withIdentifier: "ActiveOrderCell", for: indexPath) as! ActiveOrderCell
         let order = activeOrders[indexPath.row]
         cell.referenceDishCell = self.referenceDishCell
         cell.order = order
         cell.bottomSeparator.isHidden = (indexPath.row == activeOrders.count - 1)
         return cell
      }
      else
      {
         let cell = tableView.dequeueReusableCell(withIdentifier: "CompletedOrderCell", for: indexPath) as! CompletedOrderCell
         if let order = User.current?.ordersHistory[indexPath.row]
         {
            cell.controller = self
            cell.order = order
         }         
         return cell
      }
   }
   
   func scrollViewDidScroll(_ scrollView: UIScrollView)
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
   
   func pairedButton(_ button : YPPairedButton, didSelect state : YPPairedButtonSelectionState)
   {
      updateDisplayedState()
   }
}


class CompletedOrderCell: UITableViewCell, UITableViewDelegate, UITableViewDataSource, OrdersDishCellDelegate
{
   @IBOutlet weak var containerView: UIView!
   @IBOutlet var limitHeightConstraint: NSLayoutConstraint!
   @IBOutlet weak var orderView: OrderGradientView!
   @IBOutlet weak var dateLabel: UILabel!
   @IBOutlet weak var statusLabel: UILabel!
   @IBOutlet weak var totalSumLabel: UILabel!
   @IBOutlet weak var itemsTableView: UITableView!
   @IBOutlet weak var itemsTableHeight: NSLayoutConstraint!
   
   static let orderDateFormatter : DateFormatter =
   {
      let dateFormatter = DateFormatter()
      dateFormatter.calendar = calendar
      dateFormatter.timeZone = calendar.timeZone
      dateFormatter.locale = locale
      dateFormatter.dateFormat = "dd MMMM y"
      return dateFormatter
   }()
   
   private var orderChangeToken : NotificationToken?
   
   weak var controller : OrdersController!
   var order : Order!
   {
      didSet
      {
         updateForOrder()
         orderChangeToken = order.addNotificationBlock
         {
            [weak self]
            change in
            switch change
            {
            case .change: self?.updateForOrder()
            case .error(let error): dlog(error)
            case .deleted: dlog("The order was deleted")
            }
         }
      }
   }
   
   var isExpanded = false
   {
      didSet
      {
         limitHeightConstraint.isActive = !isExpanded
         self.setNeedsLayout()
         orderView.gradientLayer.opacity = (isExpanded || (order?.dishes.isEmpty ?? false)) ? 0 : 1
      }
   }
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      containerView.layer.masksToBounds = false
      containerView.layer.shadowOpacity = 0.15
      containerView.layer.shadowOffset = CGSize(width: 0, height: 4 * WidthRatio)
      containerView.layer.shadowRadius = 8 * WidthRatio
      containerView.layer.shadowColor = UIColor.black.cgColor
   }
   
   override func prepareForReuse()
   {
      super.prepareForReuse()
      orderChangeToken?.stop()
      orderChangeToken = nil
   }
   
   deinit {
      orderChangeToken?.stop()
   }
   
   func updateForOrder()
   {
      self.isExpanded = controller.expandedOrdersIds.contains(order.id)
      
      if let date = order.date {
         dateLabel.text = CompletedOrderCell.orderDateFormatter.string(from: date)
      }
      else {
         dateLabel.text = nil
      }
      
      statusLabel.text = order.status
      totalSumLabel.text = "\(order.sum.value) Р"
      
      itemsTableView.reloadData()
      itemsTableHeight.constant = itemsTableView.contentSize.height + itemsTableView.contentInset.height
      
      self.layoutIfNeeded()
   }
   
   func expandTapped(_ cell : OrdersDishCell)
   {
      isExpanded = !isExpanded
      UIView.animate(withDuration: 0.3)
      {
         cell.isExpanded = self.isExpanded
         self.layoutIfNeeded()
         
         if self.isExpanded {
            self.controller.expandedOrdersIds.insert(self.order.id)
         }
         else {
            self.controller.expandedOrdersIds.remove(self.order.id)
         }
         
         self.controller.completedTableView.beginUpdates()
         self.controller.completedTableView.endUpdates()
         
         if let indexPath = self.controller.completedTableView.indexPath(for: self) {
            self.controller.completedTableView.scrollToRow(at: indexPath, at: .top, animated: false)
         }
      }
   }
   
   @IBAction func repeatOrder()
   {
      var cartItems : [CartItem] = []
      for dish in order.dishes
      {
         if let cartItem = dish.cartItem {
            cartItems.append(cartItem)
         }
      }
      
      if !cartItems.isEmpty
      {
         Cart.removeAllItems()
         for cartItem in cartItems {
            Cart.addItem(cartItem)
         }
         
         AlertManager.showAlert("Добавлено в корзину")
      }
   }
   
   @IBAction func feedback()
   {
      let feedbackController = Storyboard.instantiateViewController(withIdentifier: "OrderFeedbackController") as! OrderFeedbackController
      feedbackController.orderId = order.id
      controller?.navigationController?.pushViewController(feedbackController, animated: true)
   }
   
   // MARK: Table view
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
   {
      return order.dishes.count
   }
   
   func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
   {
      let dish = order.dishes[indexPath.row]
      
      let referenceCell = controller.referenceDishCell!
      referenceCell.size = CGSize(width: tableView.bounds.width, height: 1000)
      referenceCell.showsExpandButton = (indexPath.row == 0)
      referenceCell.dish = dish
      referenceCell.layoutIfNeeded()
      
      let neededHeight = ceil(referenceCell.bottomSeparator.bottom)
      return neededHeight
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let cell = tableView.dequeueReusableCell(withIdentifier: "OrdersDishCell", for: indexPath) as! OrdersDishCell
      let dish = order.dishes[indexPath.row]
      cell.showsExpandButton = (indexPath.row == 0)
      cell.isExpanded = self.isExpanded
      cell.delegate = self
      cell.dish = dish
      return cell
   }
}

class OrderGradientView : UIView
{
   var gradientLayer : CAGradientLayer!
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      gradientLayer = CAGradientLayer()
      gradientLayer.colors = [UIColor.white.withAlphaComponent(0).cgColor, UIColor.white.withAlphaComponent(0.95).cgColor, UIColor.white.cgColor]
      gradientLayer.locations = [NSNumber(value: 0), NSNumber(value: 0.85), NSNumber(value: 1)]
      //gradientLayer.actions = ["opacity": NSNull()]
      layer.addSublayer(gradientLayer)
      gradientLayer.zPosition = 1000
      
   }
   
   override func layoutSubviews()
   {
      super.layoutSubviews()
      let gradientHeight = 20 * WidthRatio
      gradientLayer.frame = CGRect(x: 0, y: layer.bounds.maxY - gradientHeight, width: layer.bounds.width, height: gradientHeight)
   }
}


class ActiveOrderCell : UITableViewCell, UITableViewDelegate, UITableViewDataSource
{
   @IBOutlet weak var itemsTableView: UITableView!
   @IBOutlet weak var itemsTableHeight: NSLayoutConstraint!
   @IBOutlet weak var totalSumLabel: UILabel!
   @IBOutlet var statusImages: [UIImageView]!
   @IBOutlet var statusLines: [UIView]!
   @IBOutlet var statusLabels: [UILabel]!
   @IBOutlet weak var fiveStatusesConstraint: NSLayoutConstraint!
   @IBOutlet weak var sixStatusesConstraint: NSLayoutConstraint!
   @IBOutlet weak var callOperatorButton: UIButton!
   @IBOutlet weak var bottomSeparator: UIView!
   
   let uncheckedColor = rgb(232, 232, 232)
   let checkedColor = rgb(0, 86, 168)
   
   private var orderChangeToken : NotificationToken?
   
   var referenceDishCell : OrdersDishCell!
   var order : Order!
   {
      didSet
      {
         updateForOrder()
         orderChangeToken = order.addNotificationBlock
         {
            [weak self]
            change in
            switch change
            {
            case .change: self?.updateDisplayedStatus() //self?.updateForOrder()
            case .error(let error): dlog(error)
            case .deleted: dlog("The order was deleted")
            }
         }
      }
   }
   
   override func prepareForReuse()
   {
      super.prepareForReuse()
      orderChangeToken?.stop()
      orderChangeToken = nil
   }
   
   deinit {
      orderChangeToken?.stop()
   }
   
   func updateForOrder()
   {
      totalSumLabel.text = "\(order.sum.value) Р"
      
      if order.pickup
      {
         statusLabels[3].text = "Все готово. Ждем вас"
         statusLabels[4].text = "Приятного аппетита"
         statusLabels[5].isHidden = true
         statusImages[5].isHidden = true
         statusLines[4].isHidden = true
         fiveStatusesConstraint.priority = UILayoutPriority(rawValue: 999)
         sixStatusesConstraint.priority = UILayoutPriority(rawValue: 1)
      }
      else
      {
         statusLabels[3].text = "Все готово"
         statusLabels[4].text = "Везем"
         statusLabels[5].isHidden = false
         statusImages[5].isHidden = false
         statusLines[4].isHidden = false
         fiveStatusesConstraint.priority = UILayoutPriority(rawValue: 1)
         sixStatusesConstraint.priority = UILayoutPriority(rawValue: 999)
      }
      
      updateDisplayedStatus()
      updateCallButton()
      
      itemsTableView.reloadData()
      itemsTableHeight.constant = itemsTableView.contentSize.height + itemsTableView.contentInset.height
   }
   
   func updateDisplayedStatus()
   {
      let statusNum : Int
      
      switch order.displayedStatus
      {
      case .none: statusNum = 0
      case .accepted: statusNum = 1
      case .confirmed: statusNum = 2
      case .inProgress: statusNum = 3
      case .ready: statusNum = 4
      case .delivery: statusNum = (order.pickup ? 4 : 5)
      case .completed: statusNum = (order.pickup ? 5 : 6)
      }
      
      for i in 0..<statusImages.count
      {
         if i < statusNum
         {
            statusImages[i].image = #imageLiteral(resourceName: "checkBlue")
            statusLabels[i].alpha = 1
         }
         else
         {
            statusImages[i].image = nil
            statusLabels[i].alpha = 0.8
         }
      }
      for i in 0..<statusLines.count
      {
         statusLines[i].backgroundColor = (i < statusNum) ? checkedColor : uncheckedColor
      }
   }
   
   func updateCallButton() {
      callOperatorButton.isEnabled = order.canCallOperator
   }
   
   @IBAction func callOperatorTap() {
      order.callOperator()
   }
   
   // MARK: Table view
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
   {
      return order.dishes.count
   }
   
   func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
   {
      let dish = order.dishes[indexPath.row]
      
      referenceDishCell.size = CGSize(width: tableView.bounds.width, height: 1000)
      referenceDishCell.showsExpandButton = false
      referenceDishCell.dish = dish
      referenceDishCell.layoutIfNeeded()
      
      let neededHeight = ceil(referenceDishCell.bottomSeparator.bottom)
      return neededHeight
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let cell = tableView.dequeueReusableCell(withIdentifier: "OrdersDishCell", for: indexPath) as! OrdersDishCell
      let dish = order.dishes[indexPath.row]
      cell.showsExpandButton = false
      cell.dish = dish
      return cell
   }
}


extension Order
{
   enum OrderDisplayedStatus
   {
      case none
      case accepted
      case confirmed
      case inProgress
      case ready
      case delivery //только при доставке по адресу
      case completed
   }
   
   var displayedStatus : OrderDisplayedStatus
   {
      switch statusCode
      {
      case "NOT_EXIST", "NOT_CONFIRMED": return .accepted
      case "NEW": return .confirmed
      case "IN_PROGRESS": return .inProgress
      case "READY", "AWAITING_DELIVERY": return .ready
      case "ON_THE_WAY": return .delivery
      case "DELIVERED", "CLOSED": return .completed
      default: return .none
      }
   }
}


protocol OrdersDishCellDelegate : AnyObject
{
   func expandTapped(_ cell : OrdersDishCell)
}

class OrdersDishCell : UITableViewCell
{
   static let paragraphStyle : NSParagraphStyle =
   {
      let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
      style.lineSpacing = 5
      return style
   }()
   
   static let descTitleAttrs = [NSAttributedStringKey.font : UIFont(name: FontNameYPNeutraBold, size: 14.0 * WidthRatio)!, NSAttributedStringKey.paragraphStyle : paragraphStyle]
   
   static let descAttrs = [NSAttributedStringKey.font : UIFont(name: FontNameHelveticaNeueCyrRoman, size: 14.0 * WidthRatio)!, NSAttributedStringKey.paragraphStyle : paragraphStyle]
   
   @IBOutlet weak var expandView: UIView!
   @IBOutlet weak var expandImageView: UIImageView!
   @IBOutlet weak var nameLabel: UILabel!
   @IBOutlet weak var nameToSuperviewTrailing: NSLayoutConstraint! // 500/999
   @IBOutlet weak var nameToExpandTrailing: NSLayoutConstraint!
   @IBOutlet weak var dishVariantLabel: UILabel!
   @IBOutlet weak var doughLabel: UILabel!
   @IBOutlet weak var toppingsLabel: UILabel!   
   @IBOutlet weak var countLabel: UILabel!
   
   @IBOutlet weak var countToDishVariantVerticalConstraint: NSLayoutConstraint!
   @IBOutlet weak var countToDoughVerticalConstraint: NSLayoutConstraint!
   @IBOutlet weak var countToToppingsVerticalConstraint: NSLayoutConstraint!
   
   @IBOutlet weak var bottomSeparator: UIView!
   
   weak var delegate : OrdersDishCellDelegate?
   
   var showsExpandButton : Bool = true
   {
      didSet
      {
         if showsExpandButton
         {
            expandView.isHidden = false
            nameToSuperviewTrailing.priority = UILayoutPriority(rawValue: 500)
            nameToExpandTrailing.priority = UILayoutPriority(rawValue: 999)
         }
         else
         {
            expandView.isHidden = true
            nameToSuperviewTrailing.priority = UILayoutPriority(rawValue: 999)
            nameToExpandTrailing.priority = UILayoutPriority(rawValue: 500)
         }
      }
   }
   var isExpanded : Bool = false
   {
      didSet {
         expandImageView.transform = self.isExpanded ? CGAffineTransform(scaleX: 1, y: -1) : .identity
      }
   }
   
   var dish : OrderDish!
   {
      didSet
      {
         nameLabel.text = dish.name.isEmpty ? " " : dish.name
         dishVariantLabel.attributedText = attributedDesc(dish.variantType, dish.variantName)

         if let dough = dish.dough {
            doughLabel.attributedText = attributedDesc("ТЕСТО", dough.name)
         }
         else {
            doughLabel.text = nil
         }
         
         if dish.toppings.isEmpty {
            toppingsLabel.text = nil
         }
         else
         {
            let toppingsText = dish.toppings.reduce("", { (str, topping) in
               if str.isEmpty { return topping.name }
               else if topping.name.isEmpty { return str }
               else { return str + ", " + topping.name }
            })
            toppingsLabel.attributedText = attributedDesc("ТОППИНГИ", toppingsText)
         }
         
         countLabel.attributedText = attributedDesc("КОЛИЧЕСТВО", String(dish.count))
         
         countToDishVariantVerticalConstraint.priority = UILayoutPriority(rawValue: 1)
         countToDoughVerticalConstraint.priority = UILayoutPriority(rawValue: 1)
         countToToppingsVerticalConstraint.priority = UILayoutPriority(rawValue: 1)
         
         if !isNilOrEmpty(toppingsLabel.text) { countToToppingsVerticalConstraint.priority = UILayoutPriority(rawValue: 999) }
         else if !isNilOrEmpty(doughLabel.text) { countToDoughVerticalConstraint.priority = UILayoutPriority(rawValue: 999) }
         else { countToDishVariantVerticalConstraint.priority = UILayoutPriority(rawValue: 999) }
      }
   }
   
   func attributedDesc(_ title : String, _ desc : String) -> NSAttributedString
   {
      let str = NSMutableAttributedString(string: title + ":   ", attributes: OrderDishCell.descTitleAttrs)
      str.append(NSMutableAttributedString(string: desc, attributes: OrderDishCell.descAttrs))
      return str as NSAttributedString
   }
   
   @IBAction func expandTap()
   {
      delegate?.expandTapped(self)
   }
}
