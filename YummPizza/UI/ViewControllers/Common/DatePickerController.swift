//
//  DatePickerController.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/12/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit

class DatePickerController: UIViewController
{
   @IBOutlet weak var datePicker: UIDatePicker!
   
   var date : Date
   {
      get {
         _ = self.view
         return datePicker.date
      }
      set {
         _ = self.view
         datePicker.date = newValue
      }
   }
   
   var onCompletion : (_ date : Date) -> Void = { _ in }

   override func viewDidLoad()
   {
      super.viewDidLoad()
      datePicker.calendar = calendar
      datePicker.timeZone = calendar.timeZone
      datePicker.locale = locale      
      
      let currentDate = Date()
      datePicker.maximumDate = max(date, currentDate)
   }
   
   @IBAction func backgroundTap(_ sender: UITapGestureRecognizer)
   {
      presentingViewController?.dismiss(animated: true, completion: {
         self.onCompletion(self.datePicker.date)
      })
   }
}
