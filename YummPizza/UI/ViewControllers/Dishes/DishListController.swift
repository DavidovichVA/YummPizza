//
//  DishListController.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/15/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import RealmSwift
import Kingfisher

enum DishSection
{
   case saleDishes // special case
   case all // special case
   case combo
   case pizza
   case drinks
   case hotDishes
   case snacks
   case desserts
   
   static let allSections : [DishSection] = [combo, pizza, drinks, hotDishes, snacks, desserts]
}

class DishListController: UITableViewController, DishCellDelegate
{
   @IBOutlet var referenceNameLabel: UILabel!
   @IBOutlet var referenceDescriptionLabel: UILabel!
   let referenceNameLabelBounds = CGRect(x: 0, y: 0, width: ScreenWidth - 32, height: CGFloat.greatestFiniteMagnitude)
   let referenceDescriptionLabelBounds = CGRect(x: 0, y: 0, width: ScreenWidth - 30, height: CGFloat.greatestFiniteMagnitude)
   
   static var saleDishes = List<Dish>()
   
   let dishList = DishList.list
   private(set) var dishes = List<Dish>()
   
   var dishSection : DishSection = .all
   {
      didSet
      {
         switch dishSection
         {
         case .saleDishes, .all: navigationItem.title = "МЕНЮ"
         case .combo: navigationItem.title = "КОМБО НАБОРЫ"
         case .pizza: navigationItem.title = "ПИЦЦА"
         case .drinks: navigationItem.title = "НАПИТКИ"
         case .hotDishes: navigationItem.title = "ГОРЯЧИЕ БЛЮДА"
         case .snacks: navigationItem.title = "ЗАКУСКИ И САЛАТЫ"
         case .desserts: navigationItem.title = "ДЕСЕРТЫ"
         }
         dishes = dishList.all(dishSection)
         tableView?.reloadData()
      }
   }
   
   // dish.id : dishVariant.id
   var selectedVariants : [String : String] = [:]
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      setupDishListObserver()
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      if dishList.needsUpdate
      {
         showAppSpinner(animated: animated, dimBackground: false)
         dishList.update(
         success:
         {
            self.tableView.reloadData()
            hideAppSpinner()
         },
         failure:
         {
            errorDescription in
            dlog(errorDescription)
            hideAppSpinner()
            AlertManager.showAlert(errorDescription, buttonTitle: "Закрыть")
         })
      }
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?)
   {
      if segue.identifier == "SelectDish",
         let cell = sender as? DishCell, let dishController = segue.destination as? DishController
      {
         let cartItem = CartItem(dish: cell.dish, dishVariant: cell.variantsSegmentedView.selectedSegment?.value as? DishVariant)
         dishController.cartItem = cartItem
         dishController.backNavTitle = navigationItem.title ?? ""
      }
   }

   //MARK: - Dish List Observer
   
   private var dishListObserver : NSObjectProtocol?
   
   private func setupDishListObserver()
   {
      dishListObserver = NotificationCenter.default.addObserver(forName: .YPDishListUpdated, object: nil, queue: OperationQueue.main)
      {
         [unowned self]
         notification in
         self.tableView.reloadData()
      }
   }
   
   deinit
   {
      if dishListObserver != nil {
         NotificationCenter.default.removeObserver(dishListObserver!)
      }
   }
   
   // MARK: - Methods
   
   static func validateSaleDishes()
   {
      for (i, dish) in saleDishes.enumerated().reversed()
      {
         if dish.isInvalidated
         {
            saleDishes.remove(at: i)
            continue
         }
         
         for (j, variant) in dish.salesVariants.enumerated().reversed()
         {
            if variant.isInvalidated {
               dish.salesVariants.remove(at: j)
            }
         }
         
         if dish.salesVariants.isEmpty {
            saleDishes.remove(at: i)
         }
      }
   }
   
   @IBAction func refreshData(_ sender: UIRefreshControl)
   {
      dishList.update(onlyIfNeeded: false,
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
      return dishes.count
   }
   
   override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
   {
      let dish = dishes[indexPath.row]
      
      referenceNameLabel.setTextKeepingAttributes(dish.name)
      let nameHeight = referenceNameLabel.textRect(forBounds: referenceNameLabelBounds, limitedToNumberOfLines: 0).height
      referenceDescriptionLabel.setTextKeepingAttributes(dish.dishDescription)
      let descriptionHeight = referenceDescriptionLabel.textRect(forBounds: referenceDescriptionLabelBounds, limitedToNumberOfLines: 0).height
      
      return ceil(403 * WidthRatio + nameHeight + descriptionHeight)
   }
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let dish = dishes[indexPath.row]
      let cell = tableView.dequeueReusableCell(withIdentifier: "DishCell", for: indexPath) as! DishCell
      cell.delegate = self
      cell.dish = dish
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

protocol DishCellDelegate: AnyObject {
    var selectedVariants : [String : String] { get set }
}

class DishCell : UITableViewCell, YPSegmentedViewDelegate
{
   @IBOutlet weak var mainView: UIView!
   @IBOutlet weak var nameLabel: UILabel!
   @IBOutlet weak var descriptionLabel: UILabel!
   @IBOutlet weak var dishImageView: UIImageView!
   @IBOutlet weak var oldPriceView: CrossedPriceView!
   @IBOutlet weak var oldPriceLabel: UILabel!
   @IBOutlet weak var priceView: UIView!
   @IBOutlet weak var priceLabel: UILabel!
   @IBOutlet weak var priceViewToImageViewBottom: NSLayoutConstraint!
   @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
   @IBOutlet weak var bottomView: UIView!
   @IBOutlet weak var variantsSegmentedView: YPSegmentedView!
   @IBOutlet weak var overlayView: UIView!
   
   weak var delegate : DishCellDelegate?
   
   var dish : Dish!
   {
      didSet
      {
         nameLabel.setTextKeepingAttributes(dish.name)
         descriptionLabel.setTextKeepingAttributes(dish.dishDescription)
         
//         priceLabel.text = dish.priceString
//         
//         if let oldPrice = dish.oldPrice, oldPrice.value > 0
//         {
//            oldPriceView.isHidden = false
//            oldPriceLabel.text = dish.oldPriceString
//         }
//         else
//         {
//            oldPriceView.isHidden = true
//         }
         priceView.isHidden = true
         oldPriceView.isHidden = true
      
         dishImageView.kf.setImage(with: dish.imageLink)
         {
            [weak self]
            (image, error, cacheType, imageUrl) in
            self?.setNeedsLayout()
            self?.layoutIfNeeded()
         }
         
         var selectedVariant : DishVariant
         if let variantId = delegate?.selectedVariants[dish.id], let variant = dish.variants.first(where: {$0.id == variantId}) {
            selectedVariant = variant
         }
         else {
            selectedVariant = dish.defaultVariant
            delegate?.selectedVariants[dish.id] = selectedVariant.id
         }
         var segments : [YPSegment] = []
         var selectedIndex : Int? = nil
         for (i, dishVariant) in dish.variants.enumerated()
         {
            let segment = YPSegment(dishVariant.priceString, dishVariant.name)
            segment.value = dishVariant
            segments.append(segment)
            if dishVariant == selectedVariant {
               selectedIndex = i
            }
         }
         variantsSegmentedView.segments = segments
         variantsSegmentedView.selectedIndex = selectedIndex
         
         setNeedsLayout()
      }
   }
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      mainView.layer.masksToBounds = false
      mainView.layer.shadowOpacity = 0.3
      mainView.layer.shadowOffset = CGSize(width: 0, height: 5 * WidthRatio)
      mainView.layer.shadowRadius = 7 * WidthRatio
      mainView.layer.shadowColor = UIColor.black.cgColor
      variantsSegmentedView.delegate = self
   }
   
   override func prepareForReuse()
   {
      super.prepareForReuse()
      dishImageView.kf.cancelDownloadTask()
   }
   
   override func layoutSubviews()
   {
      super.layoutSubviews()
      updateViewsDependantOnImagePosition()
   }
   
   func updateViewsDependantOnImagePosition()
   {
      if let imageRect = dishImageView.imageRect {
         priceViewToImageViewBottom.constant = 5.67 * WidthRatio + max(0, (dishImageView.bounds.height - imageRect.maxY))
      }
      else {
         priceViewToImageViewBottom.constant = 5.67 * WidthRatio
      }
      
      bottomView.setNeedsLayout()
   }
   
   // MARK: - Segmented view
   
   func segmentedViewSelectionChanged(_ segmentedView : YPSegmentedView)
   {
      if let selectedVariant = segmentedView.selectedSegment?.value as? DishVariant, !selectedVariant.isInvalidated {
         delegate?.selectedVariants[dish.id] = selectedVariant.id
      }
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
      if isSelected { overlayView.alpha = 0.3 }
      else if isHighlighted { overlayView.alpha = 0.15 }
      else { overlayView.alpha = 0 }
   }
   
   @IBAction func takeTap()
   {
      let cartItem = CartItem(dish: dish, dishVariant: variantsSegmentedView.selectedSegment?.value as? DishVariant)
      Cart.addItem(cartItem)
      let message : String = (dish.type == .pizza) ? "Пицца “\(dish.name)” добавлена в корзину" : "Товар “\(dish.name)” добавлен в корзину"
      AlertManager.showAlert(message)
   }
}


class CrossedPriceView : UIView
{
   var lineLayer = CAShapeLayer()
   let lineColor = rgb(10, 10, 10)
   let linePaddingHorizontal : CGFloat = 14.0 / 249.0
   let linePaddingVertical : CGFloat = 13.0 / 95.0
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      layer.addSublayer(lineLayer)
      lineLayer.zPosition = 1000
      lineLayer.strokeColor = lineColor.cgColor
      lineLayer.lineWidth = 2.25 * WidthRatio
      lineLayer.lineCap = kCALineCapButt
   }
   
   override func layoutSubviews()
   {
      super.layoutSubviews()
      
      let horizontalPadding = bounds.width * linePaddingHorizontal
      let verticalPadding = bounds.height * linePaddingVertical

      let path = UIBezierPath()
      path.move(to: CGPoint(x: horizontalPadding, y: bounds.height - verticalPadding))
      path.addLine(to: CGPoint(x: bounds.width - horizontalPadding, y: verticalPadding))
      
      lineLayer.path = path.cgPath
   }
}
