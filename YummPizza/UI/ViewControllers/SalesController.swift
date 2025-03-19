//
//  SalesController.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/15/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import RealmSwift

class SalesController: UIViewController, YPPairedButtonDelegate, UITableViewDelegate, UITableViewDataSource
{
   @IBOutlet weak var headerButton: YPPairedButton!
   @IBOutlet weak var tableView: UITableView!
   var refreshControl : UIRefreshControl!
   
   var showsDeliverySales : Bool { return headerButton.selectionState == .left }
   var showsRestaurantSales : Bool { return headerButton.selectionState == .right }
   
   let deliverySales = SalesList.list.sales(withType: .delivery)
   let restaurantSales = SalesList.list.sales(withType: .restaurant)
   var displayedSales : Results<Sale> { return showsDeliverySales ? deliverySales : restaurantSales }
   
   var deliverySalesUpdateToken: NotificationToken? = nil
   var restaurantSalesUpdateToken: NotificationToken? = nil
   
   public var startSaleId : Int64?
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      
      tableView.estimatedRowHeight = 360 * WidthRatio
      tableView.rowHeight = UITableViewAutomaticDimension

      refreshControl = UIRefreshControl()
      refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
      tableView.addSubview(refreshControl)
      
      var tableReloaded = false
      if let saleId = startSaleId
      {
         if let index = deliverySales.index(where: { $0.id == saleId })
         {
            headerButton.selectionState = .left
            tableView.reloadData()
            tableReloaded = true
            let indexPath = IndexPath(row: index, section: 0)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .top)
            tableView.deselectRow(at: indexPath, animated: true)
         }
         else if let index = restaurantSales.index(where: { $0.id == saleId })
         {
            headerButton.selectionState = .right
            tableView.reloadData()
            tableReloaded = true
            let indexPath = IndexPath(row: index, section: 0)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .top)
            tableView.deselectRow(at: indexPath, animated: true)
         }
      }
      
      if !tableReloaded { tableView.reloadData() }
      
      headerButton.delegate = self
      
      deliverySalesUpdateToken = deliverySales.addNotificationBlock
      {
         [weak self]
         changes in
         guard (self?.showsDeliverySales ?? false), let tableView = self?.tableView else { return }
         switch changes
         {
         case .initial: break
            
         case .update(_, let deletions, let insertions, let modifications):
            tableView.beginUpdates()
            tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }), with: .automatic)
            tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}), with: .automatic)
            tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }), with: .automatic)
            tableView.endUpdates()
            
         case .error(let error):
            dlog(error)
         }
      }
      
      restaurantSalesUpdateToken = restaurantSales.addNotificationBlock
      {
         [weak self]
         changes in
         guard (self?.showsRestaurantSales ?? false), let tableView = self?.tableView else { return }
         switch changes
         {
         case .initial: break
            
         case .update(_, let deletions, let insertions, let modifications):
            tableView.beginUpdates()
            tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }), with: .automatic)
            tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}), with: .automatic)
            tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }), with: .automatic)
            tableView.endUpdates()
            
         case .error(let error):
            dlog(error)
         }
      }
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      SalesList.list.update(
      failure:
      {
         errorDescription in
         dlog(errorDescription)
         AlertManager.showAlert(errorDescription, buttonTitle: "Закрыть")
      })
   }
   
   deinit
   {
      deliverySalesUpdateToken?.stop()
      restaurantSalesUpdateToken?.stop()
   }
   
   // MARK: - Methods
   
   @objc func refreshData(_ sender: UIRefreshControl)
   {
      SalesList.list.update(onlyIfNeeded: false,
      success:
      {
         sender.endRefreshing()
      },
      failure:
      {
         errorDescription in
         dlog(errorDescription)
         sender.endRefreshing()
         AlertManager.showAlert(errorDescription, buttonTitle: "Закрыть")
      })
   }
   
   func showDishes(of sale : Sale)
   {
      var saleDishes : [Dish] = []
      for saleDish in sale.dishes
      {
         if let dish = saleDish.dish {
            saleDishes.append(dish)
         }
      }
      
      saleDishes.sort(by: { (d1, d2) in d1.sortValue < d2.sortValue })
      let dishes = List<Dish>()
      dishes.append(objectsIn: saleDishes)
      
      let dishesCount = dishes.count
      if dishesCount == 1
      {
         let dishController = Storyboard.instantiateViewController(withIdentifier: "DishController") as! DishController
         dishController.cartItem = CartItem(dish: dishes[0])
         dishController.backNavTitle = navigationItem.title ?? ""
         navigationController?.pushViewController(dishController, animated: true)
      }
      else if dishesCount > 1
      {
         DishListController.saleDishes = dishes
//         AppDelegate.goToAppSection(.saleDishes)
         let dishListController = Storyboard.instantiateViewController(withIdentifier: "DishListController") as! DishListController
         dishListController.dishSection = .saleDishes
         dishListController.menuBarButton = false
         dishListController.backNavTitle = navigationItem.title ?? ""
         dishListController.navigationItem.title = nil
         navigationController?.pushViewController(dishListController, animated: true)
      }
   }
   
   // MARK: - Table view

   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
   {
      return displayedSales.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let cell = tableView.dequeueReusableCell(withIdentifier: "SaleCell", for: indexPath) as! SaleCell
      cell.sale = displayedSales[indexPath.row]
      return cell
   }
   
   func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool
   {
      let sale = displayedSales[indexPath.row]
      return !sale.dishes.isEmpty
   }
   
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
   {
      tableView.deselectRow(at: indexPath, animated: true)
      let sale = displayedSales[indexPath.row]
      showDishes(of: sale)
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
   
   func pairedButton(_ button : YPPairedButton, didSelect state : YPPairedButtonSelectionState)
   {
      tableView.reloadData()
      if !displayedSales.isEmpty {
         tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
      }      
   }
}


import Kingfisher

class SaleCell : UITableViewCell
{
   @IBOutlet weak var imageContainerView: UIView!
   @IBOutlet weak var saleImageView: UIImageView!
   @IBOutlet weak var saleImageHeight: NSLayoutConstraint!
   @IBOutlet weak var descriptionLabel: UILabel!
   @IBOutlet weak var overlayView: UIView!
   
   var sale : Sale!
   {
      didSet
      {
         descriptionLabel.setTextKeepingAttributes(sale.saleDescription)
         saleImageHeight.constant = (ScreenWidth - 16) / CGFloat(sale.imageAspectRatio)
         
         if let imageLink = sale.imageLink, !imageLink.isEmpty {
            saleImageView.kf.setImage(with: imageLink)
         }
         else {
            saleImageView.image = nil
         }         
      }
   }
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      imageContainerView.layer.masksToBounds = false
      imageContainerView.layer.shadowOpacity = 0.15
      imageContainerView.layer.shadowOffset = CGSize(width: 0, height: 4 * WidthRatio)
      imageContainerView.layer.shadowRadius = 6 * WidthRatio
      imageContainerView.layer.shadowColor = UIColor.black.cgColor
   }
   
   override func prepareForReuse()
   {
      super.prepareForReuse()
      saleImageView.kf.cancelDownloadTask()
   }
   
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
      if isSelected { overlayView.alpha = 0.4 }
      else if isHighlighted { overlayView.alpha = 0.2 }
      else { overlayView.alpha = 0 }
   }
}
