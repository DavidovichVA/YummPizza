//
//  AddressListController.swift
//  YummPizza
//
//  Created by Georgy Solovei on 6/9/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

enum AddressListMode
{
   case edit
   case select(onCompletion : (Address?) -> ())
}

class AddressListController: UITableViewController
{
   @IBOutlet var changeBarButton: UIBarButtonItem!
   
   var mode : AddressListMode = .edit
   
   var addNewCellIndex : Int { return User.current?.deliveryAddresses.count ?? 0 }
   var addNewCellIndexPath : IndexPath { return IndexPath(row: addNewCellIndex, section: 0) }
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      tableView.estimatedRowHeight = 45 * WidthRatio
      tableView.rowHeight = UITableViewAutomaticDimension
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      tableView.reloadData()
      updateBarButton()
   }
   
   override var isEditing: Bool
   {
      get { return super.isEditing }
      set {
         super.isEditing = newValue
         updateBarButton()
      }
   }
   
   override func setEditing(_ editing: Bool, animated: Bool)
   {
      super.setEditing(editing, animated: animated)
      updateBarButton()
   }
   
   func updateBarButton()
   {
      switch mode
      {
      case .edit:
         if isEditing
         {
            changeBarButton.title = "Готово"
            changeBarButton.isEnabled = true
         }
         else
         {
            changeBarButton.title = "Изменить"
            changeBarButton.isEnabled = (User.current?.deliveryAddresses.isEmpty == false)
         }
         
      case .select:
         navigationItem.rightBarButtonItem = nil
      }
   }
   
   override func navigationBackTap()
   {
      if case .select(let onCompletion) = mode {
         onCompletion(nil)
      }
      navigationController?.popViewController(animated: true)
   }
   
   // MARK: - Table view data source

   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return (User.current?.deliveryAddresses.count ?? 0) + (isEditing ? 0 : 1)
   }

   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      if indexPath.row == addNewCellIndex
      {
         let cell = tableView.dequeueReusableCell(withIdentifier: "AddressListAddNewCell", for: indexPath) as! AddressListCell
         return cell
      }
      else
      {
         let cell = tableView.dequeueReusableCell(withIdentifier: "AddressListCell", for: indexPath) as! AddressListCell
         cell.addressLabel.setTextKeepingAttributes(User.current?.deliveryAddresses[indexPath.row].streetHouseString ?? "")
         switch mode {
         case .edit: cell.accessoryType = .disclosureIndicator
         case .select: cell.accessoryType = .none
         }
         return cell
      }
   }
 
   override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
      
      if indexPath.row == addNewCellIndex {
         return false
      }
      return isEditing
   }
    
   override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
   {
      if editingStyle == .delete
      {
         let index = indexPath.row
         if let user = User.current, index < user.deliveryAddresses.count
         {
            user.modifyWithTransactionIfNeeded
            {
               let address = user.deliveryAddresses[index]
               user.deliveryAddresses.remove(objectAtIndex: index)
               address.realm?.cascadeDelete(address)
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
            if user.deliveryAddresses.isEmpty {
               self.changeMode()
            }
         }
      }
   }
    
   override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath)
   {
      guard let user = User.current else { return }
      user.modifyWithTransactionIfNeeded
      {
         user.deliveryAddresses.move(from: fromIndexPath.row, to: to.row)
      }
   }
    
   override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool
   {
      return indexPath.row < addNewCellIndex
   }
   
   override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath
   {
      if proposedDestinationIndexPath.row < addNewCellIndex {
         return proposedDestinationIndexPath
      }
      else {
         return IndexPath(row: addNewCellIndex - 1, section: 0)
      }
   }
   
   override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
   {
      if isEditing && indexPath.row < addNewCellIndex {
         return nil
      }
      return indexPath
   }
   
   override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
   {
      switch mode
      {
      case .edit:
         let addressController = Storyboard.instantiateViewController(withIdentifier: "AddressController") as! AddressController
         if indexPath.row < addNewCellIndex
         {
            guard let user = User.current else { return }
            addressController.mode = .edit(address: user.deliveryAddresses[indexPath.row])
         }
         else {
            addressController.mode = .add
         }
         navigationController?.pushViewController(addressController, animated: true)
         
      case .select(let onCompletion):
         if indexPath.row < addNewCellIndex
         {
            onCompletion(User.current?.deliveryAddresses[indexPath.row])
            navigationController?.popViewController(animated: true)
         }
         else
         {
            let addressController = Storyboard.instantiateViewController(withIdentifier: "AddressController") as! AddressController
            addressController.mode = .add
            navigationController?.pushViewController(addressController, animated: true)
         }
      }
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
   
   // MARK: - Methods
    
   func changeMode()
   {
      self.setEditing(!isEditing, animated: true)
        
      if isEditing {
         tableView.deleteRows(at: [addNewCellIndexPath], with: .top)
      }
      else {
         tableView.insertRows(at: [addNewCellIndexPath], with: .top)
      }
   }
    
   // MARK: - IB actions

   @IBAction func changeAddressesTapped(_ sender: Any)
   {
      changeMode()
   }
}


class AddressListCell : UITableViewCell
{
   @IBOutlet weak var addressLabel: UILabel!
}
