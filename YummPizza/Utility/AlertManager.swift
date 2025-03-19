import UIKit

final class AlertManager
{
   // MARK: - Public
   
   public static var isAlertDisplayed : Bool
   {
      var controller = rootController
      while let presentedController = controller.presentedViewController
      {
         if presentedController is UIAlertController {
            return true
         }
         controller = presentedController
      }
      return false
   }
   
   public class func showAlert (_ message : String, buttonTitle : String = "OK", completion: @escaping () -> Void = {}) {
      showAlert(title: nil, message: message, buttonTitle: buttonTitle, completion: completion)
   }
   
   public class func showAlert (title : String?, message : String, buttonTitle : String = "OK", style: UIAlertControllerStyle = .alert, completion: @escaping () -> Void = {})
   {
      let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
      let ok = UIAlertAction(title: buttonTitle, style: .default, handler: { _ in completion() })
      alertController.addAction(ok)
      
      showAlert(alertController)
   }
   
   public class func showAlert (_ controller : UIAlertController)
   {
      controllersToShow.append(controller)
      if !runningShow
      {
         runningShow = true
         performOnMainThread {
            showNextController()
         }
      }
   }
   
   // MARK: - Private
   
   private static var rootController : UIViewController {
      return AppWindow.rootViewController!
   }
   
   private static var controllersToShow : [UIAlertController] = []
   private static var runningShow = false
   
   private class func showNextController ()
   {
      guard let controller = controllersToShow.first else {
         runningShow = false
         return
      }
      
      var showsAlertController = false
      var presentingController = rootController
      while let presentedController = presentingController.presentedViewController
      {
         if presentedController is UIAlertController {
            showsAlertController = true
            break
         }
         presentingController = presentedController
      }
      
      if !showsAlertController
      {
         presentingController.present(controller, animated: true)
         controllersToShow.removeFirst()
         if controllersToShow.isEmpty
         {
            runningShow = false
            return
         }
      }
      
      delay(0.15) {
         showNextController()
      }
   }
}
