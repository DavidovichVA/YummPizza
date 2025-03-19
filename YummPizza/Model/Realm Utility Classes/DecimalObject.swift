import RealmSwift

class DecimalObject: Object
{
   @objc dynamic var decimalString = ""
   
   var value : Decimal
   {
      get { return Decimal(string: decimalString) ?? Decimal(0) }
      set { decimalString = newValue.description }
   }
   
   override class func ignoredProperties() -> [String] {
      return ["value"]
   }
   
   convenience init(_ decimal: Decimal) {
      self.init()
      self.value = decimal
   }
   convenience init(string: String) {
      self.init()
      self.decimalString = string
   }
   convenience init(double: Double) {
      self.init()
      self.value = Decimal(double)
   }
   convenience init(int: Int) {
      self.init()
      self.value = Decimal(int)
   }
   convenience init(number: NSNumber) {
      self.init()
      self.value = number.decimalValue
   }
   
   override var description: String {
      return decimalString
   }
}


extension Optional where Wrapped: DecimalObject
{
   var decimalString : String { return self?.decimalString ?? "" }
   var value : Decimal { return self?.value ?? Decimal(0) }
}

public func *(lhs: Decimal, rhs: Int) -> Decimal {
   return lhs * Decimal(rhs)
}

public func *=(lhs: inout Decimal, rhs: Int) {
   lhs = lhs * rhs
}


extension Decimal
{
   func round(_ mode: NSDecimalNumber.RoundingMode = .plain, fractionalDigits: Int = 0) -> Decimal
   {
      var value = self
      var result = self
      NSDecimalRound(&result, &value, fractionalDigits, mode)
      return result
   }
}
