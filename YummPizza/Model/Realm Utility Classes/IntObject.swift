import RealmSwift

class IntObject: Object
{
   @objc dynamic var value = 0
   
   convenience init(_ int: Int) {
      self.init()
      self.value = int
   }
   
   override var description: String {
      return "\(value)"
   }
}
