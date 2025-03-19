//
//  RecommendationsController.swift
//  YummPizza
//
//  Created by Blaze Mac on 6/22/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import Alamofire

class RecommendationsController: UITableViewController
{
   var dish : Dish!
   var recommendations : [Dish] = []
   {
      didSet {
         tableView?.reloadData()
         recommendationsRequest?.cancel()
         recommendationsRequest = nil
      }
   }
   
   private var recommendationsRequest : DataRequest?
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      tableView.rowHeight = 156 * WidthRatio
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      
      if recommendations.isEmpty, recommendationsRequest == nil {
         updateRecommendations()
      }
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?)
   {
      if segue.identifier == "SelectDish",
         let cell = sender as? RecommendationCell, let dishController = segue.destination as? DishController
      {
         let cartItem = CartItem(dish: cell.dish)
         dishController.cartItem = cartItem
         dishController.backNavTitle = "РЕКОМЕНДАЦИИ"
      }
   }
   
   func updateRecommendations(_ sender: UIRefreshControl? = nil)
   {
      recommendationsRequest = RequestManager.getDishRecommendations(dish.typeInt,
      success:
      {
         [weak self]
         recommendations in
         self?.recommendations = recommendations
         sender?.endRefreshing()
      },
      failure:
      {
         [weak self]
         errorDescription in
         dlog(errorDescription)
         self?.recommendationsRequest = nil
         sender?.endRefreshing()
         AlertManager.showAlert(errorDescription, buttonTitle : "Закрыть")
      })
   }
   
   @IBAction func refreshData(_ sender: UIRefreshControl)
   {
      updateRecommendations(sender)
   }

   // MARK: - Table view
   
   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return recommendations.count
   }
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let recommendation = recommendations[indexPath.row]
      let cell = tableView.dequeueReusableCell(withIdentifier: "RecommendationCell", for: indexPath) as! RecommendationCell
      cell.dish = recommendation
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

class RecommendationCell : UITableViewCell
{
   @IBOutlet weak var mainView: UIView!
   @IBOutlet weak var nameLabel: UILabel!
   @IBOutlet weak var priceLabel: UILabel!
   @IBOutlet weak var dishImageView: UIImageView!
   @IBOutlet weak var overlayView: UIView!
   
   weak var delegate : DishCellDelegate?
   
   var dish : Dish!
   {
      didSet
      {
         nameLabel.setTextKeepingAttributes(dish.name)
         priceLabel.text = dish.priceString
         dishImageView.kf.setImage(with: dish.imageLink)
      }
   }
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      mainView.layer.masksToBounds = false
      mainView.layer.shadowOpacity = 0.25
      mainView.layer.shadowOffset = CGSize(width: 0, height: 2.5 * WidthRatio)
      mainView.layer.shadowRadius = 3.5 * WidthRatio
      mainView.layer.shadowColor = UIColor.black.cgColor
   }
   
   override func prepareForReuse()
   {
      super.prepareForReuse()
      dishImageView.kf.cancelDownloadTask()
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
      let cartItem = CartItem(dish: dish)
      Cart.addItem(cartItem)
      let message : String = (dish.type == .pizza) ? "Пицца “\(dish.name)” добавлена в корзину" : "Товар “\(dish.name)” добавлен в корзину"
      AlertManager.showAlert(message)
   }
}
