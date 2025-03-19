import RealmSwift

let DMYDateFormatter : DateFormatter =
{
   let dateFormatter = DateFormatter()
   dateFormatter.calendar = calendar   
   dateFormatter.timeZone = calendar.timeZone
   dateFormatter.locale = locale
   dateFormatter.dateFormat = "dd/MM/y"
   return dateFormatter
}()

fileprivate let DMYCalendarComponents : Set<Calendar.Component> = [.year, .month, .day]

/// Day-Month-Year Date components
class DMYDate: Object, Comparable
{
   @objc dynamic var id = 0
   @objc dynamic var day = 0
   @objc dynamic var month = 0
   @objc dynamic var year = 0
   
   override var description: String {
      return String(format: "%d-%02d-%02d", year, month, day)
   }
   
   //MARK: - Date conversion
   
   func getDate() -> Date
   {
      let dateComponents = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: year, month: month, day: day)
      return calendar.date(from: dateComponents)!
   }
   
   class func currentDate() -> DMYDate {
      return DMYDate(fromDate: Date())
   }
   
   convenience init(fromDate date: Date)
   {
      let dateComponents = calendar.dateComponents(DMYCalendarComponents, from: date)
      let day = dateComponents.day!
      let month = dateComponents.month!
      let year = dateComponents.year!
      self.init(day: day, month: month, year: year)
   }
   
   convenience init?(fromString dateString: String)
   {
      let components = dateString.components(separatedBy: "-")
      guard components.count == 3 else { return nil }
      
      if let year = Int(components[0]), year > 0, let month = Int(components[1]), 0...12 ~= month, let day = Int(components[2]), 0...31 ~= day
      {
         self.init(day: day, month: month, year: year)
      }
      else {
         return nil
      }
   }
   
   convenience init(day : Int, month : Int, year : Int)
   {
      self.init()
      self.day = day
      self.month = month
      self.year = year
      self.id = self.hash
   }
   
   //MARK: - Date functions
   
   func addDays(_ count : Int)
   {
      let date = getDate().addingDays(count)
      let dateComponents = calendar.dateComponents(DMYCalendarComponents, from: date)
      
      modifyWithTransactionIfNeeded
      {
         day = dateComponents.day!
         month = dateComponents.month!
         year = dateComponents.year!
         id = hash
      }
   }
   
   func addingDays(_ count : Int) -> DMYDate {
      return DMYDate(fromDate: getDate().addingDays(count))
   }
   
   //MARK: - Hash
   
   override var hash: Int {
      return year * 10000 + month * 100 + day
   }
   
   override var hashValue: Int {
      return hash
   }
   
   //MARK: - Comparable
   
   func compare(_ other: DMYDate) -> ComparisonResult
   {
      if self.year < other.year {
         return .orderedAscending
      }
      else if self.year > other.year {
         return .orderedDescending
      }
      
      if self.month < other.month {
         return .orderedAscending
      }
      else if self.month > other.month {
         return .orderedDescending
      }
      
      if self.day < other.day {
         return .orderedAscending
      }
      else if self.day > other.day {
         return .orderedDescending
      }
      
      return .orderedSame
   }
   
   override func isEqual(_ object: Any?) -> Bool
   {
      if let other = object as? DMYDate {
         return self == other
      } else {
         return false
      }
   }
   
   public static func ==(lhs: DMYDate, rhs: DMYDate) -> Bool {
      return lhs.compare(rhs) == .orderedSame
   }
   
   public static func <(lhs: DMYDate, rhs: DMYDate) -> Bool {
      return lhs.compare(rhs) == .orderedAscending
   }
   
   public static func <=(lhs: DMYDate, rhs: DMYDate) -> Bool {
      return lhs.compare(rhs) != .orderedDescending
   }

   public static func >=(lhs: DMYDate, rhs: DMYDate) -> Bool {
      return lhs.compare(rhs) != .orderedAscending
   }
   
   public static func >(lhs: DMYDate, rhs: DMYDate) -> Bool {
      return lhs.compare(rhs) == .orderedDescending
   }
}
