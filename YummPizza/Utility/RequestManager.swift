import Alamofire
import RealmSwift
import SwiftyJSON
import CoreLocation


public let GoogleApiKey = ""
public var ServerBaseUrl : URL { return URL(string: "http://\(ServerHostName)/")! }
private var ApiBaseUrl : String { return "http://\(ServerHostName)/api/" }
private var ServerHostName : String { return "" }

private let ApiMethodLogin = "loginUser"
private let ApiMethodRegistrationSMS = "sendRegistrationSms"
private let ApiMethodRegistrationCode = "checkRegistrationSmsCode"
private let ApiMethodRegistrationProfile = "registration"
private let ApiMethodRestorePasswordSMS = "sendPassRecoverySms"
private let ApiMethodRestorePasswordCode = "checkPassRecoverySmsCode"
private let ApiMethodRestorePasswordChange = "passRecovery"
private let ApiMethodLogout = "logout"
private let ApiMethodGetUserInfo = "getUserInfo"
private let ApiMethodChangeUserInfo = "updateUserInfo"
private let ApiMethodBonusHistory = "getBonusHistory"
private let ApiMethodMenuHash = "getMenuHash"
private let ApiMethodMenu = "getMenu"
private let ApiMethodDishRecommendations = "getRecommendItem"
private let ApiMethodAllSales = "getAllSales"
private let ApiMethodPotentialSales = "getAllPotentialSales"
private let ApiMethodCheckDeliveryAddress = "checkAddressOnDelivery"
private let ApiMethodFeedbackOrder = "addFeedback"
private let ApiMethodAddOrder = "addOrder"
private let ApiMethodAddOrderUnregistered = "addAnonymousOrder"
private let ApiMethodActiveOrders = "getActiveOrders"
private let ApiMethodOrdersStatus = "getOrdersStatus"
private let ApiMethodOrdersHistory = "getOrderHistory"
private let ApiMethodBonusSumForOrder = "getBonusForOrderSum"
private let ApiMethodPizzeriasHash = "getPizzeriasHash"
private let ApiMethodPizzeriasList = "getAllRestaurantsForMap"
private let ApiMethodStreetsHash = "getStreetsInformationHash"
private let ApiMethodStreetList = "getStreetsInformation"
private let ApiMethodCommonValues = "getSettings"
private let ApiMethodPushToken = "changeDeviceId"
private let ApiMethodGetCurrentUser = "getUserInfo"
private let ApiMethodChangePassword = "changePass"


typealias SuccessCallback = () -> Void
typealias FailureCallback = (_ errorDescription : String) -> Void
typealias UserCallback = (_ user : User) -> Void

// Reachability
let serverReachabilityManager: NetworkReachabilityManager? = {
   let manager = NetworkReachabilityManager(host: ServerHostName)
   manager?.startListening()
   return manager
}()
let networkReachabilityManager: NetworkReachabilityManager? = {
   let manager = NetworkReachabilityManager()
   manager?.startListening()
   return manager
}()

var isServerConnection : Bool {
   return serverReachabilityManager?.isReachable ?? false
}
var isServerWiFiConnection : Bool {
   return serverReachabilityManager?.isReachableOnEthernetOrWiFi ?? false
}
var isInternetConnection : Bool {
   return networkReachabilityManager?.isReachable ?? false
}
var isInternetWiFiConnection : Bool {
   return networkReachabilityManager?.isReachableOnEthernetOrWiFi ?? false
}

final class RequestManager
{
   class func startReachability() {
      _ = serverReachabilityManager
      _ = networkReachabilityManager
   }
   
   // MARK: - General functions for API
   
   static var sessionManager : SessionManager =
   {
      let configuration = URLSessionConfiguration.default
      configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
      
      let manager = SessionManager(configuration: configuration)
      manager.adapter = UserTokenAdapter()
      
      return manager
   }()
   
   @discardableResult
   private class func genericRequest(method : String,
                                     httpMethod : HTTPMethod = .get,
                                     params : [String : Any]? = nil,
                                     headers: HTTPHeaders? = nil,
                                     responseDataType : Type = .dictionary,
                                     showSpinner : Bool = false,
                                     dispatchQueue : DispatchQueue = DispatchQueue.main,
                                     success: @escaping (_ responseData: [String : JSON]) -> Void = {_ in },
                                     failure: @escaping FailureCallback = {error in AlertManager.showAlert(title: "Ошибка", message: error)}) -> DataRequest
   {
      if showSpinner
      {
         performOnMainThread {
            showAppSpinner()
         }
      }
      
      let urlString = ApiBaseUrl + method
      
      let encoding : ParameterEncoding
      switch httpMethod
      {
      case .get, .head, .delete: encoding = URLEncoding.default
      default: encoding = JSONEncoding.default
      }
      
      return sessionManager.request(urlString, method: httpMethod, parameters: params, encoding: encoding, headers : headers).responseJSON(queue: dispatchQueue, completionHandler:
      {
         response in
         
         let handled = handleGenericResponse(response, responseDataType: responseDataType)
         
         if showSpinner
         {
            performOnMainThread {
               hideAppSpinner()
            }
         }
         
         if let error = handled.error
         {
            failure(error)
            return
         }
         
         let data = handled.data ?? [:]
         success(data)
      })
   }
   
   private class func handleGenericResponse(_ response : DataResponse<Any>, responseDataType : Type = .dictionary) -> (error : String?, data : [String : JSON]?)
   {
      guard response.result.isSuccess else
      {
         var errorDescription : String
         
         if !isInternetConnection {
            errorDescription = "Отсутствует соединение с интернетом"
         }
         else if !isServerConnection {
            errorDescription = "Отсутствует соединение с сервером"
         }
         else if let code = response.response?.statusCode, ((code == 400) || (500...504 ~= code))
         {
            if code == 400 {
               errorDescription = "Некорректный запрос"
            }
            else {
               errorDescription = "Сервис временно недоступен"
            }
         }
         else if let localizedDescription = response.result.error?.localizedDescription {
            errorDescription = localizedDescription
         }
         else {
            errorDescription = "Ошибка соединения"
         }
         
         return (errorDescription, nil)
      }
      
      guard let value = response.result.value else {
         return ("Не получено данных", nil)
      }
      let json = JSON(value)
      
      if json.type != .dictionary {
         return ("Ошибка в полученных данных", nil)
      }
      
      let status = json["status"].stringValue
      if status != "SUCCESS"
      {
         var errorDescription = json["errorMessage"].stringValue
         if errorDescription.isEmpty {
            errorDescription = "Ошибка сервера"
         }
         else if errorDescription == "ERROR_WRONG_TOKEN"
         {
            errorDescription = "Ошибка авторизации"
            if let user = User.getCurrent(), !user.isDefault
            {
               dlog("logout due to authorization error")
               performOnMainThread {
                  AppDelegate.logout()
               }
            }
         }
         return (errorDescription, nil)
      }
      
      if responseDataType == .null {
         return (nil, [:])
      }
      
      let responseData = json["response"]
      let type = responseData.type

      if type != responseDataType {
         return ("Ошибка в полученных данных", nil)
      }
      
      switch type
      {
         case .dictionary: return (nil, responseData.dictionary)
         case .null, .unknown : return (nil, [:])
         default : return (nil, ["value" : responseData])
      }
   }
   
   // MARK: - Authorization
   
   class func login(phoneNumber : String, password : String, success: @escaping UserCallback, failure : @escaping FailureCallback)
   {
      var params : [String : String] = ["phone": phoneNumber,
                                        "password": password,
                                        "deviceType": "IOS"]
      if let pushToken = AppDelegate.pushToken {
         params["deviceId"] = pushToken
      }
      
      genericRequest(method: ApiMethodLogin, httpMethod: .post, params: params, showSpinner: true,
      success:
      {
         responseData in
         
         let token = responseData["token"]?.stringValue ?? ""
         if token.isEmpty {
            failure("Ошибка в полученных данных")
            return
         }
         
         let user = User.user(phoneNumber)!
         user.modifyWithTransactionIfNeeded {
            user.token = token
         }
         
         success(user)
      },
      failure: failure)
   }
   
   class func registration(phoneNumber : String, success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      let params : [String : String] = ["phone": phoneNumber]
      genericRequest(method: ApiMethodRegistrationSMS, httpMethod: .post, params: params, responseDataType : .null, showSpinner: true,
      success:
      {
         _ in
         success()
      },
      failure: failure)
   }
   
   class func registration(phoneNumber : String, smsCode : String, success: @escaping (_ smsToken : String) -> Void, failure : @escaping FailureCallback)
   {
      let params : [String : String] = ["phone": phoneNumber,
                                        "smsCode" : smsCode]
      genericRequest(method: ApiMethodRegistrationCode, httpMethod: .post, params: params, showSpinner: true,
      success:
      {
         responseData in
         
         let smsToken = responseData["smsToken"]?.stringValue ?? ""
         if smsToken.isEmpty {
            failure("Ошибка в полученных данных")
            return
         }
         
         success(smsToken)
      },
      failure: failure)
   }
   
   class func registration(name : String, smsToken : String, gender : Gender, birthday : DMYDate?, email : String, password : String, success: @escaping (_ userToken : String) -> Void, failure : @escaping FailureCallback)
   {
      var params : [String : String] = ["name": name,
                                        "smsToken" : smsToken,
                                        "sex" : gender.rawValue,
                                        "birthday" : birthday?.description ?? "",
                                        "email" : email,
                                        "password" : password,
                                        "deviceType" : "IOS"]
      if let pushToken = AppDelegate.pushToken {
         params["deviceId"] = pushToken
      }
      
      genericRequest(method: ApiMethodRegistrationProfile, httpMethod: .post, params: params, showSpinner: true,
      success:
      {
         responseData in
         
         let userToken = responseData["token"]?.stringValue ?? ""
         if userToken.isEmpty {
            failure("Ошибка в полученных данных")
            return
         }
         
         success(userToken)
      },
      failure: failure)
   }
   
   class func restorePassword(phoneNumber : String, success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      let params : [String : String] = ["phone": phoneNumber]
      genericRequest(method: ApiMethodRestorePasswordSMS, httpMethod: .post, params: params, responseDataType : .null, showSpinner: true,
      success:
      {
         _ in
         success()
      },
      failure: failure)
   }
   
   class func restorePassword(phoneNumber : String, smsCode : String, success: @escaping (_ smsToken : String) -> Void, failure : @escaping FailureCallback)
   {
      let params : [String : String] = ["phone": phoneNumber,
                                        "smsCode" : smsCode]
      genericRequest(method: ApiMethodRestorePasswordCode, httpMethod: .post, params: params, showSpinner: true,
      success:
      {
         responseData in
         
         let smsToken = responseData["smsToken"]?.stringValue ?? ""
         if smsToken.isEmpty {
            failure("Ошибка в полученных данных")
            return
         }
         
         success(smsToken)
      },
      failure: failure)
   }
   
   class func restorePassword(smsToken : String, newPassword : String, success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      let params : [String : String] = ["smsToken": smsToken,
                                        "newPassword" : newPassword]
      genericRequest(method: ApiMethodRestorePasswordChange, httpMethod: .post, params: params, responseDataType : .null, showSpinner: true,
      success:
      {
         _ in
         success()
      },
      failure: failure)
   }
   
   class func logout()
   {
      let urlString = ApiBaseUrl + ApiMethodLogout
      sessionManager.request(urlString, method: .get, parameters: nil, encoding: JSONEncoding.default).responseJSON
      {
         response in
         
         let handled = handleGenericResponse(response, responseDataType : .null)
         if let error = handled.error {
            dlog(error)
         }
      }
   }
   
   // MARK: - User
   
   ///updates current user info from server
   class func updateUserInfo(showSpinner : Bool = false, success: @escaping SuccessCallback = {}, failure : @escaping FailureCallback = { errorDescription in dlog(errorDescription) })
   {
      guard let userPhone = User.currentUserPhone else { failure("Пользователь не авторизован"); return }
      
      genericRequest(method: ApiMethodGetUserInfo, showSpinner: showSpinner,
      success:
      {
         responseData in
         guard let user = User.user(userPhone) else { failure("Пользователь не авторизован"); return }
         RequestModelHelper.updateUserData(user, responseData)
         success()
      },
      failure: failure)
   }
   
   ///changes current user info on server
    class func changeUserInfo(name : String? = nil, email : String? = nil, birthdayString : String? = nil, gender : Gender? = nil, pushEnabled : Bool? = nil, showSpinner : Bool = false, success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      var params : [String : Any] = [:]
      if let str = name { params["name"] = str }
      if let str = email { params["email"] = str }
      if let str = birthdayString { params["birthday"] = str }
      if let gender = gender { params["sex"] = gender.rawValue }
      if let bool = pushEnabled { params["pushEnabled"] = bool }
    
      if params.isEmpty { success(); return }
      
      let userPhone = User.currentUserPhone
      
      genericRequest(method: ApiMethodChangeUserInfo, httpMethod: .post, params: params, showSpinner: showSpinner,
      success:
      {
         responseData in
         if let user = User.user(userPhone) {
            RequestModelHelper.updateUserData(user, responseData)
         }
         success()
      },
      failure: failure)
   }
   
   /// change password
   class func changePassword(currentPassword : String, newPassword : String, success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      let params = ["oldPassword" : currentPassword,
                    "newPassword" : newPassword]
      
      genericRequest(method: ApiMethodChangePassword, httpMethod: .post, params: params, responseDataType : .null, showSpinner: true,
      success:
      {
          responseData in
          success()
      },
      failure: failure)
   }

   class func updateBonusHistory(success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      let userPhone = User.currentUserPhone
      
      genericRequest(method: ApiMethodBonusHistory,
      success:
      {
         responseData in
         if let array = responseData["list"]?.array, let user = User.user(userPhone) {
            RequestModelHelper.updateUserBonuses(user, array)
         }
         success()
      },
      failure: failure)
   }
   
   // MARK: - Dishes
   
   class func getMenuHash(success: @escaping (_ hash : String) -> Void, failure : @escaping FailureCallback)
   {
      genericRequest(method: ApiMethodMenuHash, responseDataType: .string,
      success:
      {
         responseData in
         if let string = responseData["value"]?.string, !string.isEmpty {
            success(string)
         }
         else {
            failure("Ошибка в полученных данных")
         }
      },
      failure: failure)
   }
   
   class func updateDishListIfNeeded(success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      getMenuHash(
      success:
      {
         hash in
         let dishList = DishList.list
         if dishList.dishesHash != hash
         {
            updateDishList(success: success, failure: failure)
         }
         else
         {
            dishList.modifyWithTransactionIfNeeded {
               dishList.lastUpdate = Date()
            }
            success()
         }
      },
      failure: failure)
   }
   
   class func updateDishList(success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      genericRequest(method: ApiMethodMenu,
      success:
      {
         responseData in
         let updated = RequestModelHelper.updateDishList(responseData)
         if updated {
            success()
         }
         else {
            failure("Ошибка в полученных данных")
         }
      },
      failure: failure)
   }
   
   @discardableResult
   class func getDishRecommendations(_ dishTypeId : Int, success: @escaping (_ dishes : [Dish]) -> Void, failure : @escaping FailureCallback) -> DataRequest
   {
      let params = ["categoryId" : dishTypeId]
      return genericRequest(method: ApiMethodDishRecommendations, params: params,
      success:
      {
         responseData in
         if let array = responseData["list"]?.array {
            let recommendations = RequestModelHelper.recommendationsFromData(array)
            success(recommendations)
         }
         else {
            failure("Ошибка в полученных данных")
         }
      },
      failure: failure)
   }
   
   // MARK: - Sales
   
   @discardableResult
   class func getPotentialSales(_ dishes : [String : Int], success: @escaping (_ sales : [Sale]) -> Void, failure : @escaping FailureCallback) -> DataRequest
   {
      let params = ["products" : dishes]
      return genericRequest(method: ApiMethodPotentialSales, httpMethod: .post, params: params,
      success:
      {
         responseData in
         if let array = responseData["list"]?.array {
            let sales = RequestModelHelper.salesFromData(array)
            success(sales)
         }
         else {
            failure("Ошибка в полученных данных")
         }
      },
      failure: failure)
   }
   
   class func updateSalesList(showSpinner : Bool = false, success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      genericRequest(method: ApiMethodAllSales, showSpinner: showSpinner,
      success:
      {
         responseData in
         if let array = responseData["list"]?.array {
            RequestModelHelper.updateSalesList(array)
            success()
         }
         else {
            failure("Ошибка в полученных данных")
         }
      },
      failure: failure)
   }
   
   // MARK: - Orders
   
   class func checkDeliveryAddress(city : String = "Санкт-Петербург", street : String, house : String, showSpinner : Bool = false, success: @escaping (Bool) -> Void, failure : @escaping FailureCallback)
   {
      let params : [String : String] = ["city" : city, "street" : street, "home" : house]
      genericRequest(method: ApiMethodCheckDeliveryAddress, httpMethod: .post, params: params, showSpinner: showSpinner,
      success:
      {
         responseData in
         if let bool = responseData["deliverable"]?.bool {
            success(bool)
         }
         else {
            failure("Ошибка в полученных данных")
         }
      },
      failure: failure)
   }
   
   class func sendOrderFeedback(orderId : Int64, text : String, showSpinner : Bool = true, success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      let params : [String : Any] = ["orderId" : orderId, "text" : text]
      genericRequest(method: ApiMethodFeedbackOrder, httpMethod: .post, params: params, responseDataType: .null, showSpinner: showSpinner, success: { _ in success() }, failure: failure)
   }
   
   class func addOrder(success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      let isRegisteredUser = (User.current?.isDefault == false)
      let params = RequestModelHelper.createOrderParams(isRegistered: isRegisteredUser)
      let method : String = isRegisteredUser ? ApiMethodAddOrder : ApiMethodAddOrderUnregistered
      
      genericRequest(method: method, httpMethod: .post, params: params, showSpinner: true,
      success:
      {
         responseData in
         if let id = responseData["id"]?.int64, id != 0, let addressType = OrderAddress
         {
            let phoneBlock : (String) -> Void =
            {
               operatorPhone in
               let realm = Realm.main
               realm.writeWithTransactionIfNeeded
               {
                  if let order = realm.object(ofType: Order.self, forPrimaryKey: id)
                  {
                     if order.operatorPhoneNumber != operatorPhone {
                        order.operatorPhoneNumber = operatorPhone
                     }
                  }
                  else
                  {
                     let order = Order()
                     order.id = id
                     order.operatorPhoneNumber = operatorPhone
                     realm.add(order)
                  }
               }
            }
            
            switch addressType
            {
            case .user(let address):
               
               if let coordinate = address.coordinate?.coordinate2D, CLLocationCoordinate2DIsValid(coordinate)
               {
                  if let pizzeria = coordinate.closestPizzeria() {
                     phoneBlock(pizzeria.phone)
                  }
               }
               else
               {
                  address.autoFillCoordinate(success:
                  {
                     coordinate in
                     if let pizzeria = coordinate.closestPizzeria() {
                        phoneBlock(pizzeria.phone)
                     }
                  })
               }
               
            case .pizzeria(let pizzeria):
               phoneBlock(pizzeria.phone)
            }
         }
         success()
      },
      failure: failure)
   }
   
   class func getActiveOrders(showSpinner : Bool = false, success: @escaping ([Order]) -> Void, failure : @escaping FailureCallback)
   {
      print("getActiveOrders")
      genericRequest(method: ApiMethodActiveOrders, httpMethod: .post, showSpinner: showSpinner,
      success:
      {
         responseData in
         if let array = responseData["list"]?.array
         {
            let orders = RequestModelHelper.ordersFromData(array)
            success(orders)
         }
         else {
            failure("Ошибка в полученных данных")
         }
      },
      failure: failure)
   }
   
   @discardableResult
   class func updateOrdersStatus(_ orders : [Order], success: @escaping (_ ordersListChanged : Bool) -> Void, failure : @escaping FailureCallback) -> DataRequest
   {
      print("updateOrdersStatus")
      let params = ["orderIdList" : orders.map({$0.id})]
      return genericRequest(method: ApiMethodOrdersStatus, httpMethod: .post, params: params,
      success:
      {
         responseData in
         if let array = responseData["list"]?.array
         {
            let ordersListChanged = RequestModelHelper.updateOrdersStatus(orders: orders, statusesData: array)
            success(ordersListChanged)
         }
         else {
            failure("Ошибка в полученных данных")
         }
      },
      failure: failure)
   }
   
   class func updateHistoryOrders(showSpinner : Bool = false, success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      print("updateHistoryOrders")
      let userPhone = User.currentUserPhone
      genericRequest(method: ApiMethodOrdersHistory, httpMethod: .post, showSpinner: showSpinner,
      success:
      {
         responseData in
         if let array = responseData["list"]?.array, let user = User.user(userPhone) {
            RequestModelHelper.updateOrdersHistory(user, array)
         }
         success()
      },
      failure: failure)
   }
   
   @discardableResult
   class func getBonusSumForOrderDishes(_ dishes : [String : Int], success: @escaping (_ sum : Decimal) -> Void, failure : @escaping FailureCallback) -> DataRequest
   {
      let params = ["products" : dishes]
      return genericRequest(method: ApiMethodBonusSumForOrder, httpMethod: .post, params: params,
      success:
      {
         responseData in
         if let sum = responseData["bonusSum"]?.number {
            success(sum.decimalValue)
         }
         else {
            failure("Ошибка в полученных данных")
         }
      },
      failure: failure)
   }
   
   // MARK: - Pizzerias
   
   class func getPizzeriasHash(showSpinner : Bool = false, success: @escaping (_ hash : String) -> Void, failure : @escaping FailureCallback)
   {
      genericRequest(method: ApiMethodPizzeriasHash, responseDataType: .string, showSpinner: showSpinner,
      success:
      {
         responseData in
         if let string = responseData["value"]?.string, !string.isEmpty {
            success(string)
         }
         else {
            failure("Ошибка в полученных данных")
         }
      },
      failure: failure)
   }
   
   class func updatePizzeriasListIfNeeded(showSpinner : Bool = false, success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      getPizzeriasHash(showSpinner: showSpinner,
      success:
      {
         hash in         
         let pizzeriaList = PizzeriaList.list
         if pizzeriaList.pizzeriasHash != hash {
            updatePizzeriasList(success: success, failure: failure)
         }
         else {
            success()
         }
      },
      failure: failure)
   }
   
   class func updatePizzeriasList(showSpinner : Bool = false, success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      genericRequest(method: ApiMethodPizzeriasList, showSpinner: showSpinner,
      success:
      {
         responseData in         
         let updated = RequestModelHelper.updatePizzeriasList(responseData)
         if updated {
            success()
         }
         else {
            failure("Ошибка в полученных данных")
         }
      },
      failure: failure)
   }
   
   // MARK: - Streets
   
   class func getStreetsHash(showSpinner : Bool = false, success: @escaping (_ hash : String) -> Void, failure : @escaping FailureCallback)
   {
      genericRequest(method: ApiMethodStreetsHash, responseDataType: .string, showSpinner: showSpinner,
      success:
      {
         responseData in
         if let string = responseData["value"]?.string, !string.isEmpty {
            success(string)
         }
         else {
            failure("Ошибка в полученных данных")
         }
      },
      failure: failure)
   }
   
   class func updateStreetListIfNeeded(showSpinner : Bool = false, success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      getStreetsHash(showSpinner: showSpinner,
      success:
      {
         hash in
         let streetList = StreetList.list
         if streetList.streetsHash != hash {
            updateStreetList(success: success, failure: failure)
         }
         else {
            success()
         }
      },
      failure: failure)
   }
   
   class func updateStreetList(showSpinner : Bool = false, success: @escaping SuccessCallback, failure : @escaping FailureCallback)
   {
      genericRequest(method: ApiMethodStreetList, showSpinner: showSpinner,
      success:
      {
         responseData in
         UtilityQueue.async
         {
            let updated = RequestModelHelper.updateStreetList(responseData)
            MainQueue.async
            {
               if updated {
                  success()
               }
               else {
                  failure("Ошибка в полученных данных")
               }
            }
         }
      },
      failure: failure)
   }
   
   // MARK: - App
   
   class func updateCommonValues(showSpinner : Bool = false, success: @escaping SuccessCallback = {}, failure : @escaping FailureCallback = { errorDescription in dlog(errorDescription) })
   {
      genericRequest(method: ApiMethodCommonValues, showSpinner: showSpinner,
      success:
      {
         responseData in

         let updated = RequestModelHelper.updateCommonValues(responseData)
         if updated {
            success()
         }
         else {
            failure("Ошибка в полученных данных")
         }
      },
      failure: failure)
   }
   
   class func sendPushToken(_ token : String, success: @escaping SuccessCallback = {}, failure : @escaping FailureCallback = { errorDescription in dlog(errorDescription) })
   {
      let params : [String : String] = ["deviceId": token,
                                        "deviceType": "IOS"]
      
      genericRequest(method: ApiMethodPushToken, httpMethod: .post, params: params, responseDataType: .null,
      success: { _ in success() }, failure: failure)
   }
   
   // MARK: - Other
   
   @discardableResult
   class func downloadData(_ link : String, to fileURL : URL, excludeFromBackup : Bool = true, progress: @escaping Request.ProgressHandler = {_ in }, success: @escaping SuccessCallback, failure : @escaping FailureCallback = {_ in }) -> DownloadRequest
   {
      let destination: DownloadRequest.DownloadFileDestination =
      {
         _, _ in
         return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
      }
      
      return Alamofire.download(link, to: destination).downloadProgress(closure: progress).response
      {
         response in
         
         if let error = response.error
         {
            failure(error.localizedDescription)
            return
         }
         
         guard let destinationURL = response.destinationURL, FileManager.default.isReadableFile(atPath: destinationURL.relativePath) else
         {
            failure("Не удалось скачать файл")
            return
         }
         
         if excludeFromBackup {
            exlcudeFromBackup(destinationURL)
         }
         
         success()
      }
   }
   
   class func googleGeocode(_ addressString : String, success: @escaping (CLLocationCoordinate2D) -> (), failure : @escaping FailureCallback = {_ in })
   {
      //https://developers.google.com/maps/documentation/geocoding/intro
      
      let params : [String : String] = ["address" : addressString,
                                        "key" : GoogleApiKey]
      
      let urlString = "https://maps.googleapis.com/maps/api/geocode/json"
      Alamofire.request(urlString, method: .get, parameters: params).responseJSON
      {
         response in
         
         guard response.result.isSuccess else
         {
            var errorDescription : String
            if !isInternetConnection {
               errorDescription = "Отсутствует соединение с интернетом"
            }
            else if let code = response.response?.statusCode, ((code == 400) || (500...504 ~= code))
            {
               if code == 400 {
                  errorDescription = "Некорректный запрос"
               }
               else {
                  errorDescription = "Сервис временно недоступен"
               }
            }
            else if let localizedDescription = response.result.error?.localizedDescription {
               errorDescription = localizedDescription
            }
            else {
               errorDescription = "Ошибка соединения"
            }
            
            failure(loc(errorDescription))
            return
         }
         
         guard let value = response.result.value else {
            failure(loc("Не получено данных"))
            return
         }
         let json = JSON(value)
         
         if json.type != .dictionary {
            failure(loc("Ошибка в полученных данных"))
            return
         }
         
         let status = json["status"].stringValue
         guard status == "OK" else
         {
            var errorDescription : String = json["error_message"].stringValue
            if errorDescription.isEmpty {
               errorDescription = loc(status)
            }
            if errorDescription.isEmpty {
               errorDescription = "Ошибка в полученных данных"
            }
            failure(errorDescription)
            return
         }
         
         guard let results = json["results"].array else {
            failure(loc("Ошибка в полученных данных"))
            return
         }
         guard !results.isEmpty else {
            failure("Местоположение не определено")
            return
         }
         
         if let lat = results[0]["geometry"]["location"]["lat"].double,
            let lng = results[0]["geometry"]["location"]["lng"].double
         {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            if CLLocationCoordinate2DIsValid(coordinate) {
               success(coordinate)
            }
            else {
               failure(loc("Ошибка в полученных данных"))
               return
            }
         }
         else {
            failure(loc("Ошибка в полученных данных"))
            return
         }
      }
   }
}


class UserTokenAdapter: RequestAdapter
{
   func adapt(_ urlRequest: URLRequest) throws -> URLRequest
   {
      var urlRequest = urlRequest
      if let token = User.currentUserToken, !token.isEmpty {
         urlRequest.setValue(User.currentUserToken, forHTTPHeaderField: "token")
      }
      urlRequest.setValue(PersistentDeviceId.getId(), forHTTPHeaderField: "anonDeviceUuid")
      return urlRequest
   }
}
