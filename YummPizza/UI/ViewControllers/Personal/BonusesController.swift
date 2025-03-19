//
//  BonusesController.swift
//  YummPizza
//
//  Created by Blaze Mac on 6/28/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import RealmSwift

class BonusesController: UITableViewController
{
   @IBOutlet weak var refresh: UIRefreshControl!
   
   var notificationToken: NotificationToken? = nil
   
   public var startBonusId : Int64?
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      tableView.rowHeight = 58 * WidthRatio
      
      var tableReloaded = false
      if let bonusId = startBonusId, let index = User.current?.bonuses.index(where: { $0.id == bonusId })
      {
         tableView.reloadData()
         tableReloaded = true
         let indexPath = IndexPath(row: index, section: 0)
         tableView.selectRow(at: indexPath, animated: false, scrollPosition: .top)
         tableView.deselectRow(at: indexPath, animated: true)
      }      
      if !tableReloaded { tableView.reloadData() }
      
      notificationToken = User.current?.bonuses.addNotificationBlock
      {
         [weak self]
         changes in
         
         guard let tableView = self?.tableView else { return }
         switch changes
         {
         case .initial: break
            
         case .update(_, let deletions, let insertions, let modifications):
            tableView.beginUpdates()
            tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }), with: .automatic)
            tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}), with: .automatic)
            tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }), with: .automatic)
            tableView.endUpdates()
            
         case .error(let error): dlog(error)
         }
      }
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      refreshData(refresh)
   }
   
   deinit {
      notificationToken?.stop()
   }
   
   @IBAction func refreshData(_ sender: UIRefreshControl)
   {
      RequestManager.updateBonusHistory(
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

   // MARK: - Table view

   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return User.current?.bonuses.count ?? 0
   }
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let cell = tableView.dequeueReusableCell(withIdentifier: "BonusCell", for: indexPath) as! BonusCell
      if let user = User.current
      {
         cell.bonus = user.bonuses[indexPath.row]
         cell.separator.isHidden = (indexPath.row == user.bonuses.count - 1)
      }      
      return cell
   }
   
   override func scrollViewDidScroll(_ scrollView: UIScrollView)
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


class BonusCell: UITableViewCell
{
   @IBOutlet weak var dateLabel: UILabel!
   @IBOutlet weak var orderPriceLabel: UILabel!
   @IBOutlet weak var bonusSumLabel: UILabel!
   @IBOutlet weak var separator: UIView!
   
   static let bonusDateFormatter : DateFormatter =
   {
      let dateFormatter = DateFormatter()
      dateFormatter.calendar = calendar
      dateFormatter.timeZone = calendar.timeZone
      dateFormatter.locale = locale
      dateFormatter.dateFormat = "dd MMMM y"
      return dateFormatter
   }()
   
   var bonus : Bonus!
   {
      didSet
      {
         if let date = bonus.date {
            dateLabel.text = BonusCell.bonusDateFormatter.string(from: date)
         }
         else {
            dateLabel.text = nil
         }
         
         orderPriceLabel.text = "Стоимость заказа: \(bonus.orderSum.decimalString) Р"
         bonusSumLabel.text = "\(bonus.bonusSum.decimalString) Р"
      }
   }
}
