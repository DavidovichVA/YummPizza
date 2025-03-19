//
//  AboutDeliveryController.swift
//  YummPizza
//
//  Created by Blaze Mac on 6/19/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class AboutDeliveryController: UIViewController
{
   @IBOutlet weak var deliveryLabel: UILabel!
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      update()
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      
      RequestManager.updateCommonValues(
      success:
      {
         [weak self] in
         self?.update()
      },
      failure:
      {
         errorDescription in
         dlog(errorDescription)
         AlertManager.showAlert(errorDescription, buttonTitle: "Закрыть")
      })
   }
   
   func update()
   {
      let sumForFreeDelivery = CommonValue.sumForFreeDelivery
      deliveryLabel.setTextKeepingAttributes("Бесплатная доставка осуществляется при минимальной сумме заказа от \(sumForFreeDelivery) Р.")
   }
}
