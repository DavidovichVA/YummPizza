//
//  DishController.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/18/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import Kingfisher

enum DishViewMode
{
   case add
   case edit
}

class DishController: UIViewController, YPSegmentedViewDelegate
{
   var mode : DishViewMode = .add
   
   var cartItem : CartItem!
   {
      didSet
      {
         if mode == .add
         {
            RequestManager.getDishRecommendations(cartItem.dish.typeInt,
            success:
            {
               [weak self]
               recommendations in
               self?.recommendations = recommendations
            },
            failure:
            {
               errorDescription in
               dlog(errorDescription)
            })
         }
      }
   }
   
   private var recommendations : [Dish] = []
   private var selectedDoughName : String?
   private var cheeseBorderSelected : Bool?
   
   private var canChooseAdditives : Bool
   {
      return !cartItem.dish.toppings.isEmpty || (cartItem.dish.variants.first(where: { ($0.doughVariants.count > 1) || $0.cheeseBorder != nil }) != nil)
   }
   
   @IBOutlet weak var scrollview: UIScrollView!
   @IBOutlet weak var imageContainerView: UIView!
   @IBOutlet weak var imageView: UIImageView!
   @IBOutlet weak var nameLabel: UILabel!   
   @IBOutlet weak var descriptionLabel: UILabel!
   @IBOutlet weak var nutritionalValueView: UIView!
   @IBOutlet var nutritionalValueHideConstraint: NSLayoutConstraint!
   @IBOutlet var nutritionLabelsHideConstraint: NSLayoutConstraint!
   @IBOutlet weak var scrollViewToDoughConstraint: NSLayoutConstraint!
   @IBOutlet weak var scrollViewToVariantsConstraint: NSLayoutConstraint!
   @IBOutlet weak var caloriesLabel: UILabel!
   @IBOutlet weak var proteinsLabel: UILabel!
   @IBOutlet weak var fatsLabel: UILabel!
   @IBOutlet weak var carbohydratesLabel: UILabel!
   @IBOutlet weak var doughSegmentedView: YPSegmentedView!
   @IBOutlet weak var variantsSegmentedView: YPSegmentedView!
   @IBOutlet weak var variantsWidth: NSLayoutConstraint!
   @IBOutlet weak var confirmButton: UIButton!
   @IBOutlet weak var recommendationsHeight: NSLayoutConstraint!
   
   let nutritionNumberFormatter : NumberFormatter =
   {
      let formatter = NumberFormatter()
      formatter.locale = locale
      formatter.numberStyle = .decimal
      formatter.decimalSeparator = ","
      formatter.maximumFractionDigits = 1
      return formatter
   }()
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      
      UIView.performWithoutAnimation
      {
         switch mode
         {
         case .add:
            recommendationsHeight.constant = 53
            confirmButton.setTitle("БЕРУ", for: .normal)
         case .edit:
            recommendationsHeight.constant = 0
            confirmButton.setTitle(canChooseAdditives ? "ДОБАВКИ" : "ГОТОВО", for: .normal)
         }
         confirmButton.layoutIfNeeded()
      }
      
      imageContainerView.layer.masksToBounds = false
      imageContainerView.layer.shadowOpacity = 0.15
      imageContainerView.layer.shadowOffset = CGSize(width: 0, height: 7 * WidthRatio)
      imageContainerView.layer.shadowRadius = 5 * WidthRatio
      imageContainerView.layer.shadowColor = UIColor.black.cgColor
      
      variantsSegmentedView.delegate = self
      doughSegmentedView.delegate = self
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      updateForCartItem()
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?)
   {
      if segue.identifier == "PizzaAdditives", let additivesController = segue.destination as? AdditivesController
      {
         additivesController.mode = self.mode
         additivesController.cartItem = cartItem
      }
      else if segue.identifier == "Recommendations", let recommendationsController = segue.destination as? RecommendationsController
      {
         recommendationsController.dish = cartItem.dish
         recommendationsController.recommendations = recommendations
      }
   }
   
   // MARK: - Methods
   
   func updateForCartItem()
   {
      nameLabel.setTextKeepingAttributes(cartItem.dish.name)
      descriptionLabel.setTextKeepingAttributes(cartItem.dish.dishDescription)
      imageView.kf.setImage(with: cartItem.dish.imageLink)
      
      updateNutrition()
      
      var segments : [YPSegment] = []
      var selectedIndex : Int? = nil
      for (i, dishVariant) in cartItem.dish.variants.enumerated()
      {
         let segment = YPSegment(dishVariant.priceString, dishVariant.name)
         segment.value = dishVariant
         segments.append(segment)
         if dishVariant == cartItem.dishVariant {
            selectedIndex = i
         }
      }
      variantsSegmentedView.segments = segments
      variantsSegmentedView.selectedIndex = selectedIndex
      variantsWidth.constant = 73 * WidthRatio * CGFloat(segments.count) + 2 * 53 * WidthRatio * 0.17
      
      selectedDoughName = cartItem.dough?.name
      cheeseBorderSelected = nil
      updateDoughVariants()
      updateCheeseBorder()
   }
   
   func updateNutrition()
   {
      if cartItem.dishVariant.hasNutritionalValue
      {
         caloriesLabel.text = "Калории - \(nutritionNumberFormatter.string(from: NSNumber(value: cartItem.dishVariant.calories)) ?? "0")ккал"
         proteinsLabel.text = "Белки - \(nutritionNumberFormatter.string(from: NSNumber(value: cartItem.dishVariant.proteins)) ?? "0")г."
         fatsLabel.text = "Жиры - \(nutritionNumberFormatter.string(from: NSNumber(value: cartItem.dishVariant.fats)) ?? "0")г."
         carbohydratesLabel.text = "Углеводы - \(nutritionNumberFormatter.string(from: NSNumber(value: cartItem.dishVariant.carbohydrates)) ?? "0")г."
         
         nutritionalValueView.isHidden = false
         nutritionalValueHideConstraint.isActive = false
      }
      else
      {
         nutritionalValueView.isHidden = true
         nutritionalValueHideConstraint.isActive = true
      }
   }
   
   func updateDoughVariants()
   {
      if cartItem.dough == nil || !cartItem.dishVariant.doughVariants.contains(cartItem.dough!)
      {
         if let dough = cartItem.dishVariant.doughVariants.first(where: { $0.name == selectedDoughName }) {
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
         let segment = YPSegment(dough.name + " тесто")
         segment.value = dough
         segments.append(segment)
         
         if dough.name == selectedDoughName {
            selectedIndex = i
         }
      }
      doughSegmentedView.segments = segments
      doughSegmentedView.selectedIndex = selectedIndex
      
      updateDoughVisibility()
   }
   
   func updateDoughVisibility()
   {
      doughSegmentedView.isHidden = cartItem.dishVariant.doughVariants.isEmpty
      
      if doughSegmentedView.isHidden
      {
         scrollViewToDoughConstraint.priority = UILayoutPriority(rawValue: 1)
         scrollViewToVariantsConstraint.priority = UILayoutPriority(rawValue: 999)
      }
      else
      {
         scrollViewToDoughConstraint.priority = UILayoutPriority(rawValue: 999)
         scrollViewToVariantsConstraint.priority = UILayoutPriority(rawValue: 1)
      }
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
   }
   
   // MARK: - Segmented view
   
   func segmentedViewSelectionChanged(_ segmentedView : YPSegmentedView)
   {
      if segmentedView === variantsSegmentedView
      {
         cartItem.modifyWithTransactionIfNeeded {
            cartItem.dishVariant = segmentedView.selectedSegment?.value as? DishVariant ?? cartItem.dish.defaultVariant
         }
         updateDoughVariants()
         updateCheeseBorder()
         updateNutrition()
      }
      else
      {
         if let dough = doughSegmentedView.selectedSegment?.value as? Dough, cartItem.dishVariant.doughVariants.contains(dough)
         {
            cartItem.modifyWithTransactionIfNeeded {
               cartItem.dough = dough
            }
         }
         else {
            cartItem.modifyWithTransactionIfNeeded {
               cartItem.dough = cartItem.dishVariant.defaultDough
            }
         }
         selectedDoughName = cartItem.dough?.name
         updateCheeseBorder()
      }
   }
   
   // MARK: - Actions
   
   @IBAction func expandTap(_ sender : UnderlinedExpandView)
   {
      sender.isExpanded = !sender.isExpanded
      UIView.animate(withDuration: 0.3)
      {
         if sender.isExpanded
         {
            sender.expandImageView.transform = CGAffineTransform(scaleX: 1, y: -1)
            self.nutritionLabelsHideConstraint.isActive = false
         }
         else
         {
            sender.expandImageView.transform = .identity
            self.nutritionLabelsHideConstraint.isActive = true
         }
         self.view.layoutIfNeeded()
         self.scrollview.scrollViewToVisible(self.nutritionalValueView, animated: false)
      }
   }
   
   @IBAction func confirmTap()
   {
      if canChooseAdditives {
         performSegue(withIdentifier: "PizzaAdditives", sender: self)
      }
      else
      {
         switch mode
         {
         case .add:
            let itemToAdd = CartItem(copyOf: cartItem)
            Cart.addItem(itemToAdd)
            let message : String = (cartItem.dish.type == .pizza) ? "Пицца “\(cartItem.dish.name)” добавлена в корзину" : "Товар “\(cartItem.dish.name)” добавлен в корзину"
            AlertManager.showAlert(message)
            
         case .edit:
            navigationController?.popViewController(animated: true)
         }
      }
   }
   
   @IBAction func recommendTap()
   {
      performSegue(withIdentifier: "Recommendations", sender: self)
   }
}


class UnderlinedExpandView: UIControl
{
   @IBOutlet weak var titleLabel: UILabel!
   @IBOutlet weak var expandImageView: UIImageView!
   
   var lineLayer : CAShapeLayer!
   var highlightLayer : CALayer!
   
   var isExpanded = false
   
   var margin : CGFloat = 20 * WidthRatio
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      
      lineLayer = CAShapeLayer()
      lineLayer.lineWidth = 1
      lineLayer.strokeColor = rgb(75, 75, 75).cgColor
      lineLayer.backgroundColor = UIColor.clear.cgColor
      lineLayer.frame = layer.bounds
      lineLayer.zPosition = 1
      layer.addSublayer(lineLayer)
      
      highlightLayer = CALayer()
      highlightLayer.backgroundColor = UIColor.clear.cgColor
      highlightLayer.frame = layer.bounds
      layer.addSublayer(highlightLayer)
   }
   
   override func layoutSubviews()
   {
      super.layoutSubviews()
      
      lineLayer.frame = layer.bounds
      var dashCount = (layer.bounds.width - 4) / 16
      dashCount = round(dashCount)
      let spaceWidth : Double = Double(layer.bounds.width / (4 * dashCount - 1))
      let dashWidth = spaceWidth * 3.0
      lineLayer.lineDashPattern = [NSNumber(floatLiteral: dashWidth), NSNumber(floatLiteral: spaceWidth)]
      
      let path = UIBezierPath()
      let y = layer.bounds.maxY - 1
      path.move(to: CGPoint(x: layer.bounds.minX, y: y))
      path.addLine(to: CGPoint(x: layer.bounds.maxX, y: y))
      lineLayer.path = path.cgPath
      
      highlightLayer.frame = layer.bounds//.insetBy(dx: -5, dy: -5)
      highlightLayer.cornerRadius = 5
   }
   
   override var isHighlighted: Bool
   {
      get { return super.isHighlighted }
      set {
         super.isHighlighted = newValue
         highlightLayer.backgroundColor = newValue ? titleLabel.textColor.withAlphaComponent(0.1).cgColor : UIColor.clear.cgColor
      }
   }
   
   override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
   {
      let area = bounds.insetBy(dx: -margin, dy: -margin)
      return area.contains(point)
   }
}
