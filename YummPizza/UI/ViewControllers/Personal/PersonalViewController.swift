//
//  PersonalViewController.swift
//  YummPizza
//
//  Created by v.davidovich on 9/13/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class PersonalViewController: UITableViewController
{
   enum CellType
   {
      case profile
      case ordersRegistered
      case ordersUnregistered
      case bonuses
      case register
   }
   
   var cellTypes : [CellType] = []
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      if let navigationBar = navigationController?.navigationBar
      {
         navigationBar.isTranslucent = false
         navigationBar.shadowImage = nil
         navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
      }
      
      if User.current?.isDefault == false {
         cellTypes = [.profile, .ordersRegistered, .bonuses]
      }
      else {
         cellTypes = [.register, .ordersUnregistered]
      }
      tableView.reloadData()
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?)
   {
      if segue.identifier == "Register"
      {
         AppDelegate.customLoginAction =
         {
            _ in
            self.navigationController?.popToViewController(self, animated: true)
         }
      }
   }
   
   // MARK: - Table view

   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return cellTypes.count
   }
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let cell = tableView.dequeueReusableCell(withIdentifier: "PersonalCell", for: indexPath) as! PersonalCell
      let cellType = cellTypes[indexPath.row]
      switch cellType
      {
      case .profile: cell.label.text = "ПРОФИЛЬ"
      case .ordersRegistered: cell.label.text = "МОИ ЗАКАЗЫ"
      case .ordersUnregistered: cell.label.text = "ТЕКУЩИЕ ЗАКАЗЫ"
      case .bonuses: cell.label.text = "БОНУСЫ"
      case .register: cell.label.text = "АВТОРИЗАЦИЯ"
      }
      return cell
   }
   
   override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
   {
      let cellType = cellTypes[indexPath.row]
      switch cellType
      {
      case .profile: performSegue(withIdentifier: "Profile", sender: self)
      case .ordersRegistered: performSegue(withIdentifier: "OrdersRegistered", sender: self)
      case .ordersUnregistered: performSegue(withIdentifier: "OrdersUnregistered", sender: self)
      case .bonuses: performSegue(withIdentifier: "Bonuses", sender: self)
      case .register: performSegue(withIdentifier: "Register", sender: self)
      }
   }
}

class PersonalCell : UITableViewCell
{
   @IBOutlet weak var label: UILabel!
}
