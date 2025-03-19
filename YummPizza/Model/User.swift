
import RealmSwift

enum Gender : String
{
   case unknown = "0"
   case male = "1"
   case female = "2"
}

/// пользователь приложения
class User: Object
{
   /// unique
   @objc dynamic var phoneNumber = ""
	
   var isDefault : Bool { return phoneNumber.isEmpty }
   
   /// токен API
   @objc dynamic var token = ""

   @objc dynamic var email = ""
   @objc dynamic var name = ""
   @objc dynamic var birthday: DMYDate?
   @objc dynamic var bonusPoints : DecimalObject?
   @objc dynamic var allowPushNotifications = true
   
   @objc dynamic private var genderString = Gender.unknown.rawValue
   var gender : Gender
   {
      get
      {
         if let gend = Gender(rawValue: genderString) {
            return gend
         }
         else {
            dlog("wrong gender string", genderString)
            return .unknown
         }
      }
      set
      {
         modifyWithTransactionIfNeeded {
            genderString = newValue.rawValue
         }
      }
   }
 
    
   public var mainAddress : Address?
   {
      get { return deliveryAddresses.first }
      set {
         if let address = newValue
         {
            let streetHouseString = address.streetHouseString
            modifyWithTransactionIfNeeded
            {
               if let existingAddressIndex = deliveryAddresses.index(where:
                  { addr in return addr.streetHouseString == streetHouseString })
               {
                  deliveryAddresses.move(from: existingAddressIndex, to: 0)
               }
               else
               {
                  deliveryAddresses.insert(address, at: 0)
               }
            }
         }
      }
   }

   let deliveryAddresses = List<Address>()
   @objc dynamic var lastSelectedDeliveryAddress : Address?
   @objc dynamic var lastSelectedPizzeria : Pizzeria?
   
   let bonuses = List<Bonus>()
   let ordersHistory = List<Order>()
   
   let cartItems = List<CartItem>()
   
   /// initial map or list on pizzerias controller
   @objc dynamic var prefersPizzeriasMap = true
   
   override class func primaryKey() -> String? {
      return "phoneNumber"
   }
   
   override class func ignoredProperties() -> [String] {
      return ["gender", "mainAddress"]
   }
   
    /// создает или получает существующего пользователя
   class func user(_ phoneNumber: String?) -> User?
   {
      guard let phone = phoneNumber else {
         return nil
      }
      
      let defaultRealm = Realm.main
      
      if let user = defaultRealm.object(ofType: User.self, forPrimaryKey: phone) {
         return user
      }
      
      let user = User()
      user.phoneNumber = phone
      user.bonusPoints = DecimalObject()
      defaultRealm.writeWithTransactionIfNeeded {
         defaultRealm.add(user)
      }
      return user
   }
   
   class func defaultUser() -> User {
      return user("")!
   }

   /// текущий пользователь, main thread
   public static var current : User? =
   {
      guard let phone = UserDefaults.standard.string(forKey: "lastUserPhone") else {
         return nil
      }
      
      if let user = Realm.main.object(ofType: User.self, forPrimaryKey: phone), !user.token.isEmpty
      {
         currentUserPhone = user.phoneNumber
         currentUserToken = user.token
         return user
      }
      else {
         return nil
      }
   }()
   {
      didSet {
         UserDefaults.standard.set(current?.phoneNumber ?? "", forKey: "lastUserPhone")
         currentUserPhone = current?.phoneNumber
         currentUserToken = current?.token
         NotificationCenter.default.post(name: .YPCartItemsCountChanged, object: self, userInfo: nil)
         sideMenuController?.tableView?.reloadData()
      }
   }
   
   //current thread
   static func getCurrent() -> User?
   {
      if let userPhone = currentUserPhone, let user = Realm.main.object(ofType: User.self, forPrimaryKey: userPhone) {
         return user
      }
      return nil
   }
   
   public static var currentUserPhone : String? = nil
   public static var currentUserToken : String? = nil
   
   public static var authorized : Bool {
      return currentUserPhone != nil
   }
}
