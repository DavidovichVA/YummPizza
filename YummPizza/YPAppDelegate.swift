//
//  AppDelegate.swift
//  YummPizza
//
//  Created by Blaze Mac on 3/30/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import SwiftyJSON
import Fabric
import Crashlytics
import UserNotifications
import GoogleMaps

let Storyboard = UIStoryboard(name: "Main", bundle: nil)
fileprivate(set) var Application : UIApplication!

var menuRootController : MenuRootController! { return AppWindow.rootViewController as? MenuRootController }
var sideMenuController : SideMenuController! { return (menuRootController?.menuController as? UINavigationController)?.viewControllers.first as? SideMenuController }
let loginBaseController : UINavigationController = Storyboard.instantiateViewController(withIdentifier: "LoginBaseController") as! UINavigationController
let contentBaseController : UINavigationController = Storyboard.instantiateViewController(withIdentifier: "ContentBaseController") as! UINavigationController

fileprivate(set) var currentAppSection : AppSection = .exit

@UIApplicationMain
class YPAppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate
{
   var window: UIWindow?
   var pushToken: String?
   
   typealias LoginAction = (_ user : User) -> ()
   var customLoginAction : LoginAction?
   
   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
   {
      Application = application
      
      Fabric.with([Crashlytics.self])
      
      RequestManager.startReachability()
      updateRealm()
      
      UITableView.appearance().tableHeaderView = UIView(frame: .zero)
      UITableView.appearance().tableFooterView = UIView(frame: .zero)
      if #available(iOS 10.0, *) {
         UNUserNotificationCenter.current().delegate = self
      }
      
      GMSServices.provideAPIKey(GoogleApiKey)
      
      var pushEvent : PushEventType? = nil
      if let remoteNotificationPayload = launchOptions?[.remoteNotification] as? Dictionary<AnyHashable, Any>,
         let pushEventType = PushEventType.fromNotificationInfo(remoteNotificationPayload)
      {
         pushEvent = pushEventType
      }
      
      if let user = User.current
      {
         LaunchView.show()
         
         let onUpdate =
         {
            if let pushEvent = pushEvent {
               self.goToPushDestination(pushEvent, animated: false)
            }
            else {
               self.login(user)
            }
            LaunchView.hide()
         }
         
         DishList.list.update(
         success: onUpdate,
         failure:
         {
            errorDescription in
            dlog(errorDescription)
            onUpdate()
         })
      }
      else
      {
         User.current = nil
         _ = menuRootController.view
         menuRootController.isEnabled = false
         loginBaseController.popToRootViewController(animated: false)
         menuRootController.contentController = loginBaseController
         currentAppSection = .exit
      }
      
      return true
   }

   func applicationWillResignActive(_ application: UIApplication) {
      // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
      // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
   }

   func applicationDidEnterBackground(_ application: UIApplication) {
      // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
      // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
   }

   func applicationWillEnterForeground(_ application: UIApplication) {
      // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
   }

   func applicationDidBecomeActive(_ application: UIApplication)
   {
      var askUserNotificationSettings = false
      if let user = User.current {
         askUserNotificationSettings = !user.isDefault && user.allowPushNotifications
      }

      if self.pushRegistrationCallbacks.isEmpty
      {
         registerForPushNotifications(askUserSettings: askUserNotificationSettings)
         {
            registered in
            if registered, let token = self.pushToken, !token.isEmpty
            {
               if askUserNotificationSettings {
                  RequestManager.sendPushToken(token)
               }
            }
         }
      }
      else
      {
         if !isNilOrEmpty(pushToken)
         {
            if askUserNotificationSettings {
               RequestManager.sendPushToken(pushToken!)
            }
            self.pushRegistrationCallbacks.forEach { $0(true) }
            self.pushRegistrationCallbacks.removeAll()
         }
         else if Application.isRegisteredForRemoteNotifications {
            Application.registerForRemoteNotifications()
         }
         else if askUserNotificationSettings && !notificationSystemAlertShown {
            askUserForNotificationsSettings()
         }
         else {
            self.pushRegistrationCallbacks.forEach { $0(false) }
            self.pushRegistrationCallbacks.removeAll()
         }
      }
      
      RequestManager.updateCommonValues()
   }

   func applicationWillTerminate(_ application: UIApplication) {
      // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
   }
   
   //MARK: - Functions
   
   func login(_ user : User, updateUserInfo : Bool = true, copyCartFromDefaultUser : Bool = true)
   {
      registrationPhoneNumber = ""
      registrationSmsToken = ""

      if copyCartFromDefaultUser, let currentUser = User.current, currentUser.isDefault, currentUser != user
      {
         Realm.main.writeWithTransactionIfNeeded
         {
            user.cartItems.realm?.delete(user.cartItems)
            user.cartItems.removeAll()
            user.cartItems.append(objectsIn: currentUser.cartItems)
            currentUser.cartItems.removeAll()
         }
      }
      
      User.current = user
      Cart.validateItems()
      
      if let action = customLoginAction
      {
         action(user)
         customLoginAction = nil
      }
      else
      {
         currentAppSection = .allDishes
         let dishListController = Storyboard.instantiateViewController(withIdentifier: "DishListController") as! DishListController
         dishListController.dishSection = .all
         contentBaseController.viewControllers = [dishListController]
         menuRootController.contentController = contentBaseController
         sideMenuController.updateSelectedAppSection()
      }
      
      if updateUserInfo, !user.isDefault {
         RequestManager.updateUserInfo()
      }
      
      menuRootController.isEnabled = true
      
      MainQueue.async
      {
         loginBaseController.popToRootViewController(animated: false)
         loginController?.passwordField.text = nil
         loginController?.phoneField.text = "+7"
      }
   }
   
   func logout()
   {
      RequestManager.logout()
      User.current = nil
      menuRootController?.isEnabled = false
      menuRootController?.hideMenu(animated: false)
      loginBaseController.popToRootViewController(animated: false)
      menuRootController.contentController = loginBaseController
   }
   
   func goToAppSection(_ section : AppSection, animated : Bool = true)
   {
      guard section != currentAppSection else { return }
      
      currentAppSection = section
      switch section
      {
      case .saleDishes:
         let dishListController = Storyboard.instantiateViewController(withIdentifier: "DishListController") as! DishListController
         dishListController.dishSection = .saleDishes
         contentBaseController.viewControllers = [dishListController]
      case .allDishes:
         let dishListController = Storyboard.instantiateViewController(withIdentifier: "DishListController") as! DishListController
         dishListController.dishSection = .all
         contentBaseController.viewControllers = [dishListController]
      case .combo:
         let dishListController = Storyboard.instantiateViewController(withIdentifier: "DishListController") as! DishListController
         dishListController.dishSection = .combo
         contentBaseController.viewControllers = [dishListController]
      case .pizza:
         let dishListController = Storyboard.instantiateViewController(withIdentifier: "DishListController") as! DishListController
         dishListController.dishSection = .pizza
         contentBaseController.viewControllers = [dishListController]
      case .drinks:
         let dishListController = Storyboard.instantiateViewController(withIdentifier: "DishListController") as! DishListController
         dishListController.dishSection = .drinks
         contentBaseController.viewControllers = [dishListController]
      case .hotDishes:
         let dishListController = Storyboard.instantiateViewController(withIdentifier: "DishListController") as! DishListController
         dishListController.dishSection = .hotDishes
         contentBaseController.viewControllers = [dishListController]
      case .snacks:
         let dishListController = Storyboard.instantiateViewController(withIdentifier: "DishListController") as! DishListController
         dishListController.dishSection = .snacks
         contentBaseController.viewControllers = [dishListController]
      case .desserts:
         let dishListController = Storyboard.instantiateViewController(withIdentifier: "DishListController") as! DishListController
         dishListController.dishSection = .desserts
         contentBaseController.viewControllers = [dishListController]
      case .sales: contentBaseController.viewControllers = [Storyboard.instantiateViewController(withIdentifier: "SalesController")]
      case .cart: contentBaseController.viewControllers = [Storyboard.instantiateViewController(withIdentifier: "CartController")]
      case .personal: contentBaseController.viewControllers = [Storyboard.instantiateViewController(withIdentifier: "PersonalController")]
      case .pizzerias: contentBaseController.viewControllers = [Storyboard.instantiateViewController(withIdentifier: "PizzeriasController")]
      case .about: contentBaseController.viewControllers = [Storyboard.instantiateViewController(withIdentifier: "AboutController")]
      case .exit: logout()
      }
      
      sideMenuController.updateSelectedAppSection()
      menuRootController.hideMenu(animated: animated)
   }
   
   func goToOrders(animated : Bool = true)
   {
      currentAppSection = .personal
      let personalController = Storyboard.instantiateViewController(withIdentifier: "PersonalController")
      
      if User.current?.isDefault == false
      {
         let ordersController = Storyboard.instantiateViewController(withIdentifier: "OrdersController")
         contentBaseController.viewControllers = [personalController, ordersController]
      }
      else
      {
         let ordersController = Storyboard.instantiateViewController(withIdentifier: "OrdersUnregisteredController")
         contentBaseController.viewControllers = [personalController, ordersController]
      }

      sideMenuController.updateSelectedAppSection()
      menuRootController.hideMenu(animated: animated)
   }
   
   //MARK: - Push Notifications
   
   private enum PushEventType
   {
      case orderStatusChanged(orderId : Int64)
      case newSale(saleId : Int64)
      case saleFulfilled(saleId : Int64)
      case addedBonuses(bonusId : Int64)
      case deletedBonuses
      case other
      
      static func fromNotificationInfo(_ info : Dictionary<AnyHashable, Any>) -> PushEventType?
      {
         let info = JSON(info)
         guard let destination = info["destination"].string else { return nil }
         
         switch destination
         {
         case "MyOrders": return .orderStatusChanged(orderId: info["orderId"].int64Value)
         case "Sales": return .newSale(saleId: info["saleId"].int64Value)
         case "Cart-Gift": return .saleFulfilled(saleId: info["saleId"].int64Value)
         case "MyProfile-Bonuses":
            let bonusId = info["bonusId"].int64Value
            if bonusId == 0 { return .deletedBonuses }
            else { return .addedBonuses(bonusId: bonusId) }
         default: return .other
         }
      }
   }
   
   private func goToPushDestination(_ pushEventType : PushEventType, animated : Bool = true)
   {
      if menuRootController.contentController != contentBaseController {
         menuRootController.contentController = contentBaseController
      }
      menuRootController.isEnabled = true
      
      
      switch pushEventType
      {
      case .orderStatusChanged(let orderId):
         currentAppSection = .personal
         let personalController = Storyboard.instantiateViewController(withIdentifier: "PersonalController")
         
         if User.current?.isDefault == false
         {
            let ordersController = Storyboard.instantiateViewController(withIdentifier: "OrdersController") as! OrdersController
            ordersController.startOrderId = orderId
            contentBaseController.viewControllers = [personalController, ordersController]
         }
         else
         {
            let ordersController = Storyboard.instantiateViewController(withIdentifier: "OrdersUnregisteredController") as! OrdersUnregisteredController
            ordersController.startOrderId = orderId
            contentBaseController.viewControllers = [personalController, ordersController]
         }
         
      case .newSale(let saleId), .saleFulfilled(let saleId):
         currentAppSection = .sales
         let salesController = Storyboard.instantiateViewController(withIdentifier: "SalesController") as! SalesController
         salesController.startSaleId = saleId
         contentBaseController.viewControllers = [salesController]
         
      case .addedBonuses(let bonusId):
         guard (User.current?.isDefault == false) else { return }
         currentAppSection = .personal
         let personalController = Storyboard.instantiateViewController(withIdentifier: "PersonalController")
         let bonusesController = Storyboard.instantiateViewController(withIdentifier: "BonusesController") as! BonusesController
         bonusesController.startBonusId = bonusId
         contentBaseController.viewControllers = [personalController, bonusesController]
         
      case .deletedBonuses:
         guard (User.current?.isDefault == false) else { return }
         currentAppSection = .personal
         let personalController = Storyboard.instantiateViewController(withIdentifier: "PersonalController")
         let bonusesController = Storyboard.instantiateViewController(withIdentifier: "BonusesController") as! BonusesController
         contentBaseController.viewControllers = [personalController, bonusesController]
         
      case .other:
         currentAppSection = .allDishes
         let dishListController = Storyboard.instantiateViewController(withIdentifier: "DishListController") as! DishListController
         dishListController.dishSection = .all
         contentBaseController.viewControllers = [dishListController]
      }
      
      sideMenuController.updateSelectedAppSection()
      menuRootController.hideMenu(animated: animated)
   }
   
   
   typealias PushRegistrationCallback = (_ registered : Bool) -> Void
   private var pushRegistrationCallbacks : [PushRegistrationCallback] = []
   
   var notificationSystemAlertShown : Bool
   {
      get { return UserDefaults.standard.bool(forKey: "NotificationSystemAlertShown") }
      set { UserDefaults.standard.set(newValue, forKey: "NotificationSystemAlertShown") }
   }
   
   func registerForPushNotifications(askUserSettings : Bool = true, completion : @escaping PushRegistrationCallback = { _ in })
   {
      if !isNilOrEmpty(pushToken)
      {
         completion(true)
         return
      }
      
      if Application.isRegisteredForRemoteNotifications
      {
         pushRegistrationCallbacks.append(completion)
         Application.registerForRemoteNotifications()
      }
      else if askUserSettings && !notificationSystemAlertShown
      {
         pushRegistrationCallbacks.append(completion)
         askUserForNotificationsSettings()
      }
      else
      {
         completion(false)
      }
   }
   
   private func askUserForNotificationsSettings()
   {
      if #available(iOS 10.0, *)
      {
         let authOptions : UNAuthorizationOptions = [.alert, .badge, .sound]
         UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler:
         {
            (granted, error) in
            if let error = error {
               dlog(error)
            }
            Application.registerForRemoteNotifications()
         })
      }
      else
      {
         let notificationTypes : UIUserNotificationType = [.alert, .badge, .sound]
         let notificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
         Application.registerUserNotificationSettings(notificationSettings)
         MainQueue.async { Application.registerForRemoteNotifications() }
      }
      notificationSystemAlertShown = true
   }
   
   func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
   {
      pushToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
      dlog(pushToken!)
      pushRegistrationCallbacks.forEach { $0(true) }
      pushRegistrationCallbacks.removeAll()
   }
   
   func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error)
   {
      dlog(error)
      pushRegistrationCallbacks.forEach { $0(false) }
      pushRegistrationCallbacks.removeAll()
   }
   
   public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any])
   {
      dlog(userInfo as NSDictionary)
      if application.applicationState == .active
      {
         //running in foreground
      }
      else
      {
         //user tapped notification while app was in background
         if let pushEvent = PushEventType.fromNotificationInfo(userInfo) {
            goToPushDestination(pushEvent)
         }
      }
   }
   
   @available(iOS 10.0, *)
   func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
   {
      dlog(notification.request.content.userInfo as NSDictionary)
      completionHandler([.alert, .badge])
//      completionHandler([]) //empty options mean that no system notification displayed
   }
   
   @available(iOS 10.0, *)
   public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
   {
      dlog(response.notification.request.content.userInfo)
      if response.actionIdentifier == UNNotificationDefaultActionIdentifier //user tapped the notification
      {
         if let pushEvent = PushEventType.fromNotificationInfo(response.notification.request.content.userInfo) {
            goToPushDestination(pushEvent)
         }
      }
      
      completionHandler()
   }
   
   //MARK: - Realm
   
   private func updateRealm()
   {
      let config = Realm.Configuration (
         schemaVersion: 40,
         migrationBlock:
         {
            migration, oldSchemaVersion in
            if oldSchemaVersion < 39
            {
               migration.enumerateObjects(ofType: DishList.className())
               {                  
                  oldDishList, newDishList in
                  newDishList!["dishesHash"] = ""
                  newDishList!["lastUpdate"] = nil
               }
            }
         }
      )
      
      Realm.Configuration.defaultConfiguration = config
      _ = Realm.main
   }
}

