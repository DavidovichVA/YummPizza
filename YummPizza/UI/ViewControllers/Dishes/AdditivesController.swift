//
//  AdditivesController.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/18/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class AdditivesController: UIViewController, YPSegmentedViewDelegate, UITableViewDelegate, UITableViewDataSource
{
   @IBOutlet weak var nameLabel: UILabel!
   @IBOutlet weak var variantsTypeLabel: UILabel!
   @IBOutlet weak var variantsSegmentedView: YPSegmentedView!
   @IBOutlet weak var doughLabel: UILabel!
   @IBOutlet weak var doughSegmentedView: YPSegmentedView!
   @IBOutlet weak var cheeseBorderButton: YPCheckButton!   
   @IBOutlet weak var cheeseBorderLabel: UILabel!
   @IBOutlet weak var cheeseBorderPriceLabel: UILabel!
   @IBOutlet weak var toppingsLabel: UILabel!
   @IBOutlet weak var toppingsTableView: UITableView!
   
   @IBOutlet weak var toppingsToCheeseBorderConstraint: NSLayoutConstraint!
   @IBOutlet weak var toppingsToDoughConstraint: NSLayoutConstraint!
   @IBOutlet weak var toppingsToVariantsConstraint: NSLayoutConstraint!
   @IBOutlet weak var cheeseBorderToDoughConstraint: NSLayoutConstraint!
   @IBOutlet weak var cheeseBorderToVariantsConstraint: NSLayoutConstraint!
   
   @IBOutlet weak var totalPriceLabel: UILabel!
   @IBOutlet weak var totalPriceViewHeight: NSLayoutConstraint!
   @IBOutlet weak var countLabel: UILabel!
   @IBOutlet weak var minusButton: ExtendedButton!
   @IBOutlet weak var plusButton: ExtendedButton!
   @IBOutlet weak var confirmLabel: UILabel!
   
   var mode : DishViewMode = .add
   
   var cartItem : CartItem!
   {
      didSet {
         _ = self.view
         updateForCartItem()
      }
   }
   
   let dishList = DishList.list
   private var selectedDoughName : String?
   private var cheeseBorderSelected : Bool?
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      
      switch mode
      {
      case .add: confirmLabel.text = "В КОРЗИНУ"
      case .edit: confirmLabel.text = "ГОТОВО"
      }
      
      toppingsTableView.rowHeight = 36 * WidthRatio
      if isIPhone4 {
         totalPriceViewHeight.constant = 48 * WidthRatio
      }
      variantsSegmentedView.delegate = self
      doughSegmentedView.delegate = self
   }
   
   override func viewDidLayoutSubviews()
   {
      super.viewDidLayoutSubviews()
      let spaceBetweenButtons = plusButton.left - minusButton.right
      minusButton.margin = spaceBetweenButtons / 2
      plusButton.margin = spaceBetweenButtons / 2
   }
   
   // MARK: - Methods
   
   func updateForCartItem()
   {
      switch cartItem.dish.type
      {
      case .combo: backNavTitle = "КОМБО НАБОР"
      case .desserts: backNavTitle = "ДЕСЕРТ"
      case .drinks: backNavTitle = "НАПИТОК"
      case .hotDishes: backNavTitle = "ГОРЯЧЕЕ БЛЮДО"
      case .pizza: backNavTitle = "ПИЦЦА"
      case .snacks: backNavTitle = "ЗАКУСКА"
      }
      
      nameLabel.text = cartItem.dish.name
      variantsTypeLabel.text = cartItem.dish.dishVariantsType + ":"
      
      var segments : [YPSegment] = []
      var selectedIndex : Int? = nil
      for (i, dishVariant) in cartItem.dish.variants.enumerated()
      {
         let segment = YPSegment(dishVariant.name)
         segment.value = dishVariant
         segments.append(segment)
         
         if dishVariant == cartItem.dishVariant {
            selectedIndex = i
         }
      }
      variantsSegmentedView.segments = segments
      variantsSegmentedView.selectedIndex = selectedIndex

      selectedDoughName = cartItem.dough?.name
      cheeseBorderSelected = nil
      updateDoughVariants()
      updateCheeseBorder()
      toppingsTableView.reloadData()
      
      updateViewsVisibility()
      updateCount()
   }
   
   func updateCheeseBorder()
   {
      if let borderSelected = cheeseBorderSelected
      {
         cartItem.modifyWithTransactionIfNeeded {
            cartItem.cheeseBorder = (borderSelected && cartItem.dough?.name == "Тонкое") ? cartItem.dishVariant.cheeseBorder : nil
         }
      }
      else
      {
         if cartItem.dough?.name != "Тонкое"
         {
            cartItem.modifyWithTransactionIfNeeded {
               cartItem.cheeseBorder = nil
            }
         }
         cheeseBorderSelected = (cartItem.cheeseBorder != nil)
      }
      
      if let border = cartItem.cheeseBorder
      {
         cheeseBorderButton.isChecked = true
         cheeseBorderPriceLabel.text = "\(border.price.value) Р"
      }
      else
      {
         cheeseBorderButton.isChecked = false
         cheeseBorderPriceLabel.text = nil
      }
   }
   
   func updateDoughVariants()
   {
      if cartItem.dough == nil || !cartItem.dishVariant.doughVariants.contains(cartItem.dough!)
      {
         if let dough = cartItem.dishVariant.doughVariants.first(where: { $0.name == selectedDoughName })
         {
            cartItem.modifyWithTransactionIfNeeded {
               cartItem.dough = dough
            }
         }
         else
         {
            cartItem.modifyWithTransactionIfNeeded {
               cartItem.dough = cartItem.dishVariant.defaultDough
            }
            selectedDoughName = cartItem.dough?.name
         }
      }
      
      var segments : [YPSegment] = []
      var selectedIndex : Int? = nil
      for (i, dough) in cartItem.dishVariant.doughVariants.enumerated()
      {
         let segment = YPSegment(dough.name)
         segment.value = dough
         segments.append(segment)
         
         if dough.name == selectedDoughName {
            selectedIndex = i
         }
      }
      doughSegmentedView.segments = segments
      doughSegmentedView.selectedIndex = selectedIndex
   }
   
   func updateViewsVisibility()
   {
      doughLabel.isHidden = cartItem.dishVariant.doughVariants.isEmpty
      doughSegmentedView.isHidden = doughLabel.isHidden
      
      cheeseBorderLabel.isHidden = (cartItem.dishVariant.cheeseBorder == nil || cartItem.dough?.name != "Тонкое")
      cheeseBorderButton.isHidden = cheeseBorderLabel.isHidden
      cheeseBorderPriceLabel.isHidden = cheeseBorderLabel.isHidden
      
      toppingsLabel.isHidden = cartItem.dish.toppings.isEmpty
      toppingsTableView.isHidden = toppingsLabel.isHidden
      
      if cheeseBorderLabel.isHidden
      {
         toppingsToCheeseBorderConstraint.priority = UILayoutPriority(rawValue: 1)
         
         if doughLabel.isHidden
         {
            toppingsToVariantsConstraint.priority = UILayoutPriority(rawValue: 999)
            toppingsToDoughConstraint.priority = UILayoutPriority(rawValue: 1)
         }
         else
         {
            toppingsToVariantsConstraint.priority = UILayoutPriority(rawValue: 1)
            toppingsToDoughConstraint.priority = UILayoutPriority(rawValue: 999)
         }
      }
      else
      {
         toppingsToCheeseBorderConstraint.priority = UILayoutPriority(rawValue: 999)
         toppingsToDoughConstraint.priority = UILayoutPriority(rawValue: 1)
         toppingsToVariantsConstraint.priority = UILayoutPriority(rawValue: 1)
      }
      
      if doughLabel.isHidden
      {
         cheeseBorderToVariantsConstraint.priority = UILayoutPriority(rawValue: 999)
         cheeseBorderToDoughConstraint.priority = UILayoutPriority(rawValue: 1)
      }
      else
      {
         cheeseBorderToVariantsConstraint.priority = UILayoutPriority(rawValue: 1)
         cheeseBorderToDoughConstraint.priority = UILayoutPriority(rawValue: 999)
      }
   }
   
   func updatePrice() {
      totalPriceLabel.text = "\(cartItem.price) Р"
   }
   
   func updateCount()
   {
      countLabel.text = String(cartItem.count)
      updatePrice()
   }
   
   // MARK: - Segmented view
   
   func segmentedViewSelectionChanged(_ segmentedView : YPSegmentedView)
   {
      if segmentedView === variantsSegmentedView
      {
         cartItem.modifyWithTransactionIfNeeded {
            cartItem.dishVariant = variantsSegmentedView.selectedSegment?.value as? DishVariant ?? cartItem.dish.defaultVariant
         }
         updateDoughVariants()
         updateCheeseBorder()
         updateViewsVisibility()
         updatePrice()
      }
      else
      {
         if let dough = doughSegmentedView.selectedSegment?.value as? Dough, cartItem.dishVariant.doughVariants.contains(dough)
         {
            cartItem.modifyWithTransactionIfNeeded {
               cartItem.dough = dough
            }
         }
         else
         {
            cartItem.modifyWithTransactionIfNeeded {
               cartItem.dough = cartItem.dishVariant.defaultDough
            }
         }
         selectedDoughName = cartItem.dough?.name
         updateCheeseBorder()
         updateViewsVisibility()
         updatePrice()
      }
   }
   
   // MARK: - Table view
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return cartItem.dish.toppings.count
   }

   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let cell = tableView.dequeueReusableCell(withIdentifier: "ToppingCell", for: indexPath) as! ToppingCell
      cell.additivesController = self
      cell.topping = cartItem.dish.toppings[indexPath.row]
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
   
   // MARK: - Actions
   
   @IBAction func cheeseBorderTap(_ sender: YPCheckButton)
   {
      cheeseBorderSelected = sender.isChecked
      updateCheeseBorder()
      updatePrice()
   }
   
   @IBAction func countMinusTap()
   {
      cartItem.addCount(-1)
      updateCount()
   }
   
   @IBAction func countPlusTap()
   {
      cartItem.addCount(1)
      updateCount()
   }
   
   @IBAction func confirmTap()
   {
      switch mode
      {
      case .add:
         let itemToAdd = CartItem(copyOf: cartItem)
         Cart.addItem(itemToAdd)
         
         cartItem.modifyWithTransactionIfNeeded {
            cartItem.count = 1
         }
         updateCount()
         
         let message : String = (cartItem.dish.type == .pizza) ? "Пицца “\(cartItem.dish.name)” добавлена в корзину" : "Товар “\(cartItem.dish.name)” добавлен в корзину"
         AlertManager.showAlert(message)
         
      case .edit:
         navigationController?.popToRootViewController(animated: true)
      }
   }
}


class ToppingCell : UITableViewCell
{
   @IBOutlet weak var nameLabel: UILabel!
   @IBOutlet weak var priceLabel: UILabel!
   @IBOutlet weak var countLabel: UILabel!
   @IBOutlet weak var minusButton: ExtendedButton!
   @IBOutlet weak var plusButton: ExtendedButton!
   
   weak var additivesController : AdditivesController!
   
   var topping : Topping!
   {
      didSet
      {
         nameLabel.text = topping.fullName
         priceLabel.text = topping.priceString
         updateCount()
      }
   }
   
   override func layoutSubviews()
   {
      super.layoutSubviews()
      let spaceBetweenButtons = plusButton.left - minusButton.right
      minusButton.margin = spaceBetweenButtons / 2
      plusButton.margin = spaceBetweenButtons / 2
   }
   
   func updateCount()
   {
      let count = additivesController.cartItem.toppingCount(topping)
      countLabel.text = String(count)
   }
   
   @IBAction func minusTap()
   {
      additivesController.cartItem.addToppingCount(topping, -1)
      updateCount()
      additivesController.updatePrice()
   }
   
   @IBAction func plusTap()
   {
      additivesController.cartItem.addToppingCount(topping, 1)
      updateCount()
      additivesController.updatePrice()
   }
}
