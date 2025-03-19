//
//  OrdersUnregisteredController.swift
//  YummPizza
//
//  Created by Blaze Mac on 9/13/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire

class OrdersUnregisteredController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
   @IBOutlet weak var tableView: UITableView!
   @IBOutlet var referenceDishCell: OrdersDishCell!
   
   var refreshControl : UIRefreshControl!
   
   public var startOrderId : Int64?
   private var activeOrders : [Order] = []
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      
      tableView.estimatedRowHeight = 480 * WidthRatio
      tableView.rowHeight = UITableViewAutomaticDimension
      
      refreshControl = UIRefreshControl()
      refreshControl.addTarget(self, action: #selector(updateActiveOrders), for: .valueChanged)
      tableView.addSubview(refreshControl)
      
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
            let indexPath = IndexPath(row: index, section: 0)
            strongSelf.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
         }
      }
      
      RequestManager.getActiveOrders(
      success:
      {
         [weak self]
         orders in
         guard let strongSelf = self else { return }
         strongSelf.activeOrders = orders
         strongSelf.tableView.reloadData()
         showStartOrderBlock()
         hideAppSpinner(for: strongSelf.view)
         delay(10) { self?.updateStatuses(true) }
      },
      failure:
      {
         [weak self]
         errorDescription in
         dlog(errorDescription)
         guard let strongSelf = self else { return }
         AlertManager.showAlert(errorDescription, buttonTitle: "Закрыть")
         showStartOrderBlock()
         hideAppSpinner(for: strongSelf.view)
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
         strongSelf.refreshControl.endRefreshing()
         strongSelf.activeOrders = orders
         strongSelf.tableView.reloadData()
         strongSelf.statusesRequest?.cancel()
         delay(10) { self?.updateStatuses(true) }
      },
      failure:
      {
         [weak self]
         errorDescription in
         dlog(errorDescription)
         self?.refreshControl.endRefreshing()
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
   
   // MARK: - Table view
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return activeOrders.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let cell = tableView.dequeueReusableCell(withIdentifier: "ActiveOrderCell", for: indexPath) as! ActiveOrderCell
      let order = activeOrders[indexPath.row]
      cell.referenceDishCell = self.referenceDishCell
      cell.order = order
      cell.bottomSeparator.isHidden = (indexPath.row == activeOrders.count - 1)
      return cell
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
}
