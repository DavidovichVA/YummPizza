//
//  AboutController.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/15/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import MessageUI

class AboutController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate
{
   @IBOutlet weak var tableView: UITableView!
   @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
   @IBOutlet weak var contentLabel: UILabel!
   
   private enum CellType
   {
      case qualityControl(phone : String, displayedPhone : String)
      case feedback(emails : [String])
      case delivery
   }
   
   private var cellTypes : [CellType] = []
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      tableView.rowHeight = 57 * WidthRatio
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
      var types : [CellType] = []

      if var phoneDigits = CommonValue.forKey("QUALITY_CONTROL")?.value.characters.filter({decimalDigits.contains($0)}), !phoneDigits.isEmpty
      {
         if phoneDigits.count == 7 {
            phoneDigits = "7812".characters + phoneDigits
         }
         else if phoneDigits.count == 10 {
            phoneDigits = "7".characters + phoneDigits
         }
         
         let displayedPhone = "+" + phoneDigits.reduce("")
         {
            (currentPhone, char) -> String in
            
            let currentLength = currentPhone.characters.count as Int
            if currentLength % 4 == 1 {
               return currentPhone + " " + String(char)
            }
            else {
               return currentPhone + String(char)
            }
         }
         
         types.append(.qualityControl(phone: String(phoneDigits), displayedPhone : displayedPhone))
      }
      if let feedbackEmails = CommonValue.forKey("EMAILS_FOR_FEEDBACK")?.value, !feedbackEmails.isEmpty
      {
         var emails : [String] = []
         for email in feedbackEmails.replacingOccurrences(of: " ", with: "").components(separatedBy: ",")
         {
            if email.isValidEmail {
               emails.append(email)
            }
         }
         
         if !emails.isEmpty {
            types.append(.feedback(emails: emails))
         }
      }
      types.append(.delivery)
      
      tableViewHeight.constant = CGFloat(types.count) * tableView.rowHeight
      cellTypes = types
      tableView.reloadData()
      
      contentLabel.setTextKeepingAttributes(CommonValue.forKey("ABOUT_US")?.value ?? "")
   }
   
   // MARK: - Table view
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return cellTypes.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let cell = tableView.dequeueReusableCell(withIdentifier: "AboutCell", for: indexPath) as! AboutCell
      let cellType = cellTypes[indexPath.row]
      switch cellType
      {
      case .qualityControl(_, let displayedPhone):
         cell.aboutImageView.image = #imageLiteral(resourceName: "aboutIconPhone")
         cell.aboutTitleLabel.text = "СЛУЖБА КОНТРОЛЯ КАЧЕСТВА:"
         cell.aboutSubtitleLabel.text = displayedPhone
         
      case .feedback(let emails):
         cell.aboutImageView.image = #imageLiteral(resourceName: "aboutIconMail")
         cell.aboutTitleLabel.text = "ОБРАТНАЯ СВЯЗЬ:"
         cell.aboutSubtitleLabel.text = emails.joined(separator: ", ")
         
      case .delivery:
         cell.aboutImageView.image = #imageLiteral(resourceName: "aboutIconCart")
         cell.aboutTitleLabel.text = "ОПЛАТА И ДОСТАВКА"
         cell.aboutSubtitleLabel.text = nil
      }
      return cell
   }
   
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
   {
      let cellType = cellTypes[indexPath.row]
      switch cellType
      {
      case .qualityControl(let phone, _):
         let phoneString = "telprompt://\(phone)"
         if let url = URL(string: phoneString) {
            Application.openURL(url)
         }
         
      case .feedback(let emails):
         let mailComposeVC = MFMailComposeViewController()
         mailComposeVC.mailComposeDelegate = self
         mailComposeVC.setToRecipients(emails)
         mailComposeVC.setSubject("Ямм Пицца - отзыв")
         if MFMailComposeViewController.canSendMail(){
            present(mailComposeVC, animated: true, completion: nil)
         }
         
      case .delivery:
         performSegue(withIdentifier: "AboutDelivery", sender: self)
      }
      tableView.deselectRow(at: indexPath, animated: true)
   }
   
   // MARK: - Feedback
   
   func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
   {
      switch result
      {
      case .sent:
         controller.dismiss(animated: true, completion: {
            AlertManager.showAlert("Спасибо за ваш отзыв")
         })
      case .failed:
         controller.dismiss(animated: true, completion:
         {
            if let errorDescription = error?.localizedDescription, !errorDescription.isEmpty {
               AlertManager.showAlert(title: "Не удалось отправить отзыв", message: errorDescription)
            }
            else {
               AlertManager.showAlert("Не удалось отправить отзыв")
            }
         })
         
      default: controller.dismiss(animated: true, completion: nil)
      }
   }
}


class AboutCell: UITableViewCell
{
   @IBOutlet weak var aboutImageView: UIImageView!
   @IBOutlet weak var aboutTitleLabel: UILabel!
   @IBOutlet weak var aboutSubtitleLabel: UILabel!
   
   static let scaleTransform = CGAffineTransform(scaleX: WidthRatio, y: WidthRatio)
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      aboutImageView.transform = AboutCell.scaleTransform
   }
}
