import RealmSwift

class StringObject: Object
{
   @objc dynamic var value = ""
   
   convenience init(_ string: String) {
      self.init()
      self.value = string
   }
   
   override var description: String {
      return value
   }
}
