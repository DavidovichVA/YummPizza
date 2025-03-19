//
//  GiftController.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/24/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import Kingfisher

class GiftController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource
{
   @IBOutlet var referenceGiftCell: GiftCell!
   @IBOutlet weak var giftView: UIView!
   @IBOutlet weak var collectionView: UICollectionView!
   @IBOutlet weak var collectionFlowLayout: UICollectionViewFlowLayout!
   @IBOutlet weak var collectionHeight: NSLayoutConstraint!
   @IBOutlet weak var pageControl : UIPageControl!
   @IBOutlet weak var pageContainerHeight: NSLayoutConstraint!

   var sales : [Sale] = []
   {
      didSet
      {
         _ = self.view
         updateForSales()
      }
   }
   
   private var collectionInnerHeight : CGFloat {
      return collectionView.bounds.height - (collectionFlowLayout.sectionInset.height + collectionView.contentInset.height)
   }
   
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      giftView.layer.masksToBounds = false
      giftView.layer.shadowOpacity = 0.15
      giftView.layer.shadowOffset = CGSize(width: 0, height: 7 * WidthRatio)
      giftView.layer.shadowRadius = 5 * WidthRatio
      giftView.layer.shadowColor = UIColor.black.cgColor
   }
   
   override func viewDidLayoutSubviews()
   {
      super.viewDidLayoutSubviews()
      collectionFlowLayout.itemSize = CGSize(width: collectionView.bounds.width,
                                             height: floor(collectionInnerHeight))
   }
   
   func updateForSales()
   {
      pageContainerHeight.constant = (sales.count > 1) ? 60 * WidthRatio : 0
      pageControl.numberOfPages = sales.count
      pageControl.currentPage = 0
      
      let width =  ScreenWidth - 16 * WidthRatio
      referenceGiftCell.frame = CGRect(x: 0, y: 0, width: width, height: 10000)
      var maxHeight = 218 * WidthRatio
      
      for sale in sales
      {
         referenceGiftCell.sale = sale
         referenceGiftCell.layoutIfNeeded()
         let neededHeight = referenceGiftCell.descriptionLabel.bottom + 19 * WidthRatio
         maxHeight = max(maxHeight, neededHeight)
      }
      
      collectionHeight.constant = ceil(maxHeight)
      view.layoutIfNeeded()
      collectionFlowLayout.itemSize = CGSize(width: width, height: min(maxHeight, floor(collectionInnerHeight)))
      view.layoutIfNeeded()
      collectionView.reloadData()
      collectionView.setContentOffset(.zero, animated: false)
   }
   
   //MARK: - Collection View
   
   private var scrollingStartedByUser = false
   
   public func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
   {
      scrollingStartedByUser = true
   }
   
   public func scrollViewDidScroll(_ scrollView: UIScrollView)
   {
      if scrollingStartedByUser
      {
         pageControl.currentPage = Int(round(collectionView.contentOffset.x / collectionFlowLayout.itemSize.width))
      }
   }
   
   public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
   {
       scrollingStartedByUser = false
   }
   
   public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
   {
      scrollingStartedByUser = false
   }
   
   public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return sales.count
   }
   
   public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
   {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GiftCell", for: indexPath) as! GiftCell
      let sale = sales[indexPath.row]
      cell.sale = sale
      
      return cell
   }
   
   //MARK: - Actions
   
   @IBAction func pageControlValueChanged()
   {
      scrollingStartedByUser = false
      let offset = CGPoint(x: collectionFlowLayout.itemSize.width * CGFloat(pageControl.currentPage), y: 0)
      collectionView.setContentOffset(offset, animated: true)
   }
   
   @IBAction func closeTap() {
      presentingViewController?.dismiss(animated: true, completion: nil)
   }
}



class GiftCell: UICollectionViewCell
{
   @IBOutlet weak var titleLabel: UILabel!
   @IBOutlet weak var descriptionLabel: UILabel!
   @IBOutlet weak var imageContainerView: UIView!
   @IBOutlet weak var saleImageView: UIImageView!
   
//   override func awakeFromNib()
//   {
//      super.awakeFromNib()
//      imageContainerView.layer.masksToBounds = false
//      imageContainerView.layer.shadowOpacity = 0.15
//      imageContainerView.layer.shadowOffset = CGSize(width: 0, height: 4 * WidthRatio)
//      imageContainerView.layer.shadowRadius = 6 * WidthRatio
//      imageContainerView.layer.shadowColor = UIColor.black.cgColor
//   }
   
   override func prepareForReuse()
   {
      super.prepareForReuse()
      saleImageView.kf.cancelDownloadTask()
   }
   
   var sale : Sale!
   {
      didSet
      {
         descriptionLabel.setTextKeepingAttributes(sale.saleDescription)
         
         if let imageLink = sale.imageLink, !imageLink.isEmpty {
            saleImageView.kf.setImage(with: imageLink)
         }
         else {
            saleImageView.image = nil
         }
      }
   }
}

