//
//  SideMenuController.swift
//  YummPizza
//
//  Created by Blaze Mac on 4/6/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

enum AppSection
{
   case saleDishes // special case
   case allDishes // special case
   case combo
   case pizza
   case drinks
   case hotDishes
   case snacks
   case desserts
   case sales
   case cart
   case personal
   case pizzerias
   case about
   case exit
}

class SideMenuController: UITableViewController
{
   let topSections : [AppSection] = [.combo, .pizza, .drinks, .hotDishes, .snacks, .desserts]
   var bottomSections : [AppSection]
   {
      if User.current?.isDefault == false {
         return [AppSection.sales, AppSection.cart, AppSection.personal, AppSection.pizzerias, AppSection.about, AppSection.exit]
      }
      else {
         return [AppSection.sales, AppSection.cart, AppSection.personal, AppSection.pizzerias, AppSection.about]
      }
   }
   
   func updateSelectedAppSection()
   {
      _ = self.view //load view if needed
      
      switch currentAppSection
      {
      case .saleDishes, .allDishes, .exit:
         if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: false)
         }
      default:
         let indexPath = self.indexPath(for: currentAppSection)
         tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
      }
   }
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      tableView.rowHeight = 47 * WidthRatio
      setupCartItemsObserver()
   }
   
   private func appSection(for indexPath : IndexPath) -> AppSection
   {
      if indexPath.section == 0 {
         return topSections[indexPath.row]
      }
      else {
         return bottomSections[indexPath.row]
      }
   }
   
   private func indexPath(for appSection : AppSection) -> IndexPath?
   {
      if let index = topSections.index(of: appSection) {
         return IndexPath(row: index, section: 0)
      }
      else if let index = bottomSections.index(of: appSection) {
         return IndexPath(row: index, section: 1)
      }
      
      return nil
   }
   
   //MARK: - Cart Items Observer
   
   private var cartItemsObserver : NSObjectProtocol?
   
   private func setupCartItemsObserver()
   {
      cartItemsObserver = NotificationCenter.default.addObserver(forName: .YPCartItemsCountChanged, object: nil, queue: OperationQueue.main)
      {
         [unowned self]
         notification in

         if let cartIndexPath = self.indexPath(for: .cart), let cell = self.tableView.cellForRow(at: cartIndexPath) as? AppSectionCell
         {
            cell.badgeNumber = Cart.itemsCount
         }
      }
   }
   
   deinit
   {
      if cartItemsObserver != nil {
         NotificationCenter.default.removeObserver(cartItemsObserver!)
      }
   }
   
   // MARK: - Table view
   override func numberOfSections(in tableView: UITableView) -> Int {
      return 2
   }

   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
   {
      if section == 0 {
         return topSections.count
      }
      else {
         return bottomSections.count
      }
   }
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let cell = tableView.dequeueReusableCell(withIdentifier: "AppSectionCell", for: indexPath) as! AppSectionCell
      let section = appSection(for: indexPath)
      switch section
      {
      case .saleDishes, .allDishes: break
      case .combo:
         cell.sectionImageView.image = #imageLiteral(resourceName: "menuIconCombo")
         cell.sectionTitleLabel.text = "КОМБО НАБОРЫ"
         cell.badgeNumber = 0
      case .pizza:
         cell.sectionImageView.image = #imageLiteral(resourceName: "menuIconPizza")
         cell.sectionTitleLabel.text = "ПИЦЦА"
         cell.badgeNumber = 0
      case .drinks:
         cell.sectionImageView.image = #imageLiteral(resourceName: "menuIconDrinks")
         cell.sectionTitleLabel.text = "НАПИТКИ"
         cell.badgeNumber = 0
      case .hotDishes:
         cell.sectionImageView.image = #imageLiteral(resourceName: "menuIconHotDishes")
         cell.sectionTitleLabel.text = "ГОРЯЧИЕ БЛЮДА"
         cell.badgeNumber = 0
      case .snacks:
         cell.sectionImageView.image = #imageLiteral(resourceName: "menuIconSnacks")
         cell.sectionTitleLabel.text = "ЗАКУСКИ И САЛАТЫ"
         cell.badgeNumber = 0
      case .desserts:
         cell.sectionImageView.image = #imageLiteral(resourceName: "menuIconDesserts")
         cell.sectionTitleLabel.text = "ДЕСЕРТЫ"
         cell.badgeNumber = 0
      case .sales:
         cell.sectionImageView.image = #imageLiteral(resourceName: "menuIconSale")
         cell.sectionTitleLabel.text = "АКЦИИ"
         cell.badgeNumber = 0
      case .cart:
         cell.sectionImageView.image = #imageLiteral(resourceName: "menuIconCart")
         cell.sectionTitleLabel.text = "КОРЗИНА"
         cell.badgeNumber = Cart.itemsCount
      case .personal:
         cell.sectionImageView.image = #imageLiteral(resourceName: "menuIconPersonal")
         cell.sectionTitleLabel.text = "ЛИЧНЫЙ КАБИНЕТ"
         cell.badgeNumber = 0
      case .pizzerias:
         cell.sectionImageView.image = #imageLiteral(resourceName: "menuIconPizzerias")
         cell.sectionTitleLabel.text = "ПИЦЦЕРИИ"
         cell.badgeNumber = 0
      case .about:
         cell.sectionImageView.image = #imageLiteral(resourceName: "menuIconAbout")
         cell.sectionTitleLabel.text = "О КОМПАНИИ"
         cell.badgeNumber = 0
      case .exit:
         cell.sectionImageView.image = #imageLiteral(resourceName: "menuIconExit")
         cell.sectionTitleLabel.text = "ВЫЙТИ"
         cell.badgeNumber = 0
      }

      return cell
   }
   
   override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
   {
      let section = appSection(for: indexPath)
      AppDelegate.goToAppSection(section)
   }
   
   let footerView : UIView =
   {
      let view = UIView()
      view.backgroundColor = UIColor.clear
      return view
   }()
   
   override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
      return section == 0 ? footerView : nil
   }
   
   override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
      return section == 0 ? 47 * WidthRatio : 0
   }
}


class AppSectionCell : UITableViewCell
{
   static let normalColor: UIColor = rgb(4, 18, 45)
   static let selectedColor: UIColor = rgb(255, 7, 23)
   static let highlightedColor: UIColor = selectedColor.withAlphaComponent(0.5)
   static let iconScaleTransform = CGAffineTransform(scaleX: WidthRatio, y: WidthRatio)
   
   @IBOutlet weak var sectionImageView: UIImageView!   
   @IBOutlet weak var sectionTitleLabel: UILabel!
   
   @IBOutlet weak var badgeView: UIView!
   @IBOutlet weak var badgeLabel: UILabel!
   
   var badgeNumber : Int = 0
   {
      didSet
      {
         if badgeNumber > 0
         {
            badgeLabel.text = String(badgeNumber)
            badgeView.isHidden = false
         }
         else
         {
            badgeLabel.text = nil
            badgeView.isHidden = true
         }
      }
   }
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      sectionImageView.transform = AppSectionCell.iconScaleTransform
   }
   
   override func setHighlighted(_ highlighted: Bool, animated: Bool)
   {
      let color = highlighted ? AppSectionCell.highlightedColor : UIColor.clear
      UIView.animate(withDuration: (animated ? 0.3 : 0)) {
         self.contentView.backgroundColor = color
      }
   }
   
   override func setSelected(_ selected: Bool, animated: Bool)
   {
      let color = selected ? AppSectionCell.selectedColor : AppSectionCell.normalColor
      UIView.animate(withDuration: (animated ? 0.3 : 0)) {
         self.backgroundColor = color
      }
   }
}
