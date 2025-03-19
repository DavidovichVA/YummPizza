import Foundation
import UIKit

let YPColorRedDefault : UIColor = rgb(255, 7, 23)
let YPColorRedHighlighted : UIColor = rgb(161, 40, 48)
let YPColorBlueDefault : UIColor = rgb(0, 86, 168)
let YPColorBlueHighlighted : UIColor = rgb(0, 115, 219)
let YPColorDisabled : UIColor = rgb(205, 205, 205)
let YPColorDisabledText : UIColor = rgb(128, 128, 128)
let YPColorText : UIColor = UIColor.black
let YPColorTextError : UIColor = rgb(255, 7, 23)
let YPColorTextFieldBorderNormal : UIColor = rgb(137, 137, 137)
let YPColorTextFieldBorderError : UIColor = UIColor.red

let FontNameYPNeutraBold : String = "YPNeutra-Bold"
let FontNameYPExtraBold : String = "YP-ExtraBold"
let FontNameHelveticaNeueCyrMedium = "HelveticaNeueCyr-Medium"
let FontNameHelveticaNeueCyrRoman = "HelveticaNeueCyr-Roman"
let FontNameHelveticaNeueCyrItalic = "HelveticaNeueCyr-Italic"

let scrollIndicatorImage : UIImage =
{
   let rect = CGRect(x: 0, y: 0, width: 2.5, height: 2.5)
   UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
   let context = UIGraphicsGetCurrentContext()!
   
   context.setFillColor(YPColorRedDefault.cgColor)
   context.fill(rect)
   
   let image = UIGraphicsGetImageFromCurrentImageContext()!
   UIGraphicsEndImageContext()
   
   return image
}()

let mapPinPizzeriaImage = #imageLiteral(resourceName: "mapPinPizzeria").scaled(by: WidthRatio)




let DesignWidth : CGFloat = 414
let DesignHeight : CGFloat = 736
let WidthRatio : CGFloat = ScreenWidth / DesignWidth
let HeightRatio : CGFloat = ScreenHeight / DesignHeight

let ScreenWidth : CGFloat = UIScreen.main.bounds.size.width
let ScreenHeight : CGFloat = UIScreen.main.bounds.size.height
let isIPhone4 : Bool = (ScreenHeight == 480)


let AppName : String = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String
let AppVersion : String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
let AppBuild : String = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
let BundleId : String = Bundle.main.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as! String
let SystemVersion : String = UIDevice.current.systemVersion

let AppDelegate : YPAppDelegate = UIApplication.shared.delegate as! YPAppDelegate
let AppWindow : UIWindow = AppDelegate.window!


let BackgroundQueue : DispatchQueue = DispatchQueue.global(qos: .background)
let UtilityQueue : DispatchQueue = DispatchQueue.global(qos: .utility)
let UserInitiatedQueue : DispatchQueue = DispatchQueue.global(qos: .userInitiated)
let MainQueue : DispatchQueue = DispatchQueue.main

let cacheDirectory : NSString = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! as NSString
let documentsDirectory : NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as NSString
let tempDirectory : String = NSTemporaryDirectory()

func performOnMainThread(_ closure: @escaping () -> Void)
{
   if Thread.isMainThread {
      closure()
   }
   else {
      MainQueue.async(execute: closure)
   }
}


func dlog(_ object: Any, file: String = #file, line: Int = #line) {
   print("\((file as NSString).lastPathComponent), line \(line):", object)
}
func dlog(_ objects: Any..., file: String = #file, line: Int = #line) {
   print("\((file as NSString).lastPathComponent), line \(line):", objects)
}

func delay(_ delay: TimeInterval, queue : DispatchQueue = DispatchQueue.main, closure: @escaping () -> Void)
{
   let when = DispatchTime.now() + delay
   queue.asyncAfter(deadline: when, execute: closure)
}

/// Returns x, constrained to bounds [bound1, bound2]
func minmax<T : Comparable>(_ bound1: T, _ x: T, _ bound2: T) -> T {
   return bound1 <= bound2 ? min(max(bound1, x), bound2) : min(max(bound2, x), bound1)
}

func random(min: Int, max: Int) -> Int {
   return min + Int(arc4random_uniform(UInt32(max - min + 1)))
}
func randomBool() -> Bool {
   return arc4random_uniform(2) == 0
}

func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
   return rgba(red, green, blue, 1)
}
func rgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat) -> UIColor {
   return UIColor(red : red / 255, green : green / 255, blue : blue / 255, alpha : alpha)
}

func imageFromURL(_ urlString : String) -> UIImage? {
   if let url = URL(string: urlString), let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) {
      return image
   }
   return nil
}

extension Array where Element: Equatable
{
   func index(ofObjectEqualTo object: Element) -> Int? {
      return index(where: { $0 == object })
   }
   
   /// Remove first collection element that is equal to the given object
   mutating func removeObject(equalTo object: Element)
   {
      if let index = index(ofObjectEqualTo: object) {
         remove(at: index)
      }
   }
}

extension Array where Element: AnyObject
{
   func index(ofObjectIdenticalTo object: Element) -> Int? {
      return index(where: { $0 === object })
   }
   
   /// Remove first collection element that is identical to the given object
   mutating func removeObject(identicalTo object: Element)
   {
      if let index = index(ofObjectIdenticalTo: object) {
         remove(at: index)
      }
   }
}

extension Array
{
   func divide(parts : Int) -> [[Element]]
   {
      let itemsCount = self.count
      guard parts > 1, itemsCount > 1 else { return [self] }
      
      let partItemsCount = Double(itemsCount) / Double(parts)
      var result : [[Element]] = []
      var startIdx = 0
      var endIdx = 0
      
      for i in 1...parts
      {
         startIdx = endIdx
         endIdx = Int(round(partItemsCount * Double(i)))
         result.append(Array(self[startIdx..<endIdx]))
      }
      return result
   }
}

extension Dictionary {
   mutating func addEntries(_ other:Dictionary) {
      for (key,value) in other {
         self.updateValue(value, forKey:key)
      }
   }
}

extension NSLock
{
   func synchronized(_ block : () -> Void) {
      lock()
      block()
      unlock()
   }
}


func isNilOrEmpty(_ value : String?) -> Bool {
   return (value == nil) || value!.isEmpty
}
func isNilOrEmpty<T: Collection>(_ value : T?) -> Bool {
   return (value == nil) || value!.isEmpty
}

extension String
{
   func leftTrimmming(_ chars: Set<Character>) -> String
   {
      if let index = self.characters.index(where: {!chars.contains($0)}) {
         return String(self[index..<self.endIndex])
      } else {
         return ""
      }
   }
   
   func removingPrefix(_ prefix : String) -> String
   {
      if hasPrefix(prefix) {
         return String(self[prefix.endIndex..<self.endIndex])
      }
      else {
         return String(self)
      }
   }
   
   func index(of string: String, options: CompareOptions = .literal) -> Index? {
      return range(of: string, options: options)?.lowerBound
   }
   func endIndex(of string: String, options: CompareOptions = .literal) -> Index? {
      return range(of: string, options: options)?.upperBound
   }
   func indexes(of string: String, options: CompareOptions = .literal) -> [Index] {
      var result: [Index] = []
      var start = startIndex
      while let range = range(of: string, options: options, range: start..<endIndex) {
         result.append(range.lowerBound)
         start = range.upperBound
      }
      return result
   }
   func ranges(of string: String, options: CompareOptions = .literal) -> [Range<Index>] {
      var result: [Range<Index>] = []
      var start = startIndex
      while let range = range(of: string, options: options, range: start..<endIndex) {
         result.append(range)
         start = range.upperBound
      }
      return result
   }
   
   func capitalizingFirstLetter() -> String {
      let first = String(characters.prefix(1)).capitalized
      let other = String(characters.dropFirst())
      return first + other
   }
   
   mutating func capitalizeFirstLetter() {
      self = self.capitalizingFirstLetter()
   }
   
   subscript(index: Int) -> Character {
      return characters[characters.index(startIndex, offsetBy: index)]
   }
   
   subscript(range: Range<Int>) -> String
   {
      let firstIdx = characters.index(startIndex, offsetBy: range.lowerBound)
      let lastIdx = characters.index(startIndex, offsetBy: range.upperBound)
      return String(self[firstIdx..<lastIdx])
   }
}



func associatedObject<ValueType>(_ base: AnyObject, key: UnsafePointer<UInt8>) -> ValueType? {
   if let associated = objc_getAssociatedObject(base, key) as? ValueType {
      return associated
   }
   return nil
}
func associateObject<ValueType>(_ base: AnyObject, key: UnsafePointer<UInt8>, value: ValueType) {
   objc_setAssociatedObject(base, key, value, .OBJC_ASSOCIATION_RETAIN)
}
func removeAssociatedObject(_ base: AnyObject, key: UnsafePointer<UInt8>) {
   objc_setAssociatedObject(base, key, nil, .OBJC_ASSOCIATION_RETAIN)
}
func removeAssociatedObjects(_ base: AnyObject) {
   objc_removeAssociatedObjects(base)
}


extension String {
   var isValidEmail : Bool {
      let emailRegEx = "[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}"
      let emailTest = NSPredicate(format:"SELF MATCHES[c] %@", emailRegEx)
      return emailTest.evaluate(with: self)
   }
}

extension Date {
   mutating func addSeconds(_ count : Double) {
      addTimeInterval(count)
   }
   func addingSeconds(_ count : Double) -> Date {
      return addingTimeInterval(count)
   }
   
   mutating func addMinutes(_ count : Double) {
      addTimeInterval(count * 60)
   }
   func addingMinutes(_ count : Double) -> Date {
      return addingTimeInterval(count * 60)
   }
   
   mutating func addHours(_ count : Double) {
      addTimeInterval(count * 3600)
   }
   func addingHours(_ count : Double) -> Date {
      return addingTimeInterval(count * 3600)
   }
   
   mutating func addDays(_ count : Int) {
      self = calendar.date(byAdding: .day, value: count, to: self)!
   }
   func addingDays(_ count : Int) -> Date {
      return calendar.date(byAdding: .day, value: count, to: self)!
   }
}

func textSize(_ text : String, font : UIFont, width : CGFloat = CGFloat.greatestFiniteMagnitude) -> CGSize
{
   let attrText = NSAttributedString(string: text, attributes: [NSAttributedStringKey.font : font])
   let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
   let rect = attrText.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
   return rect.size
}

func exlcudeFromBackup(_ path : String)
{
   let url = URL(fileURLWithPath: path)
   exlcudeFromBackup(url)
}

func exlcudeFromBackup(_ url : URL)
{
   var url = url
   var resourceValues = URLResourceValues()
   resourceValues.isExcludedFromBackup = true
   try? url.setResourceValues(resourceValues)
}


func printAllFonts()
{
   for fontFamily in UIFont.familyNames
   {
      let fontNames = UIFont.fontNames(forFamilyName: fontFamily)
      print("\(fontFamily):\n\(fontNames)\n");
   }
}

// MARK: Kingfisher
import Kingfisher

extension String : Resource
{
   public var cacheKey: String { return self }
   public var downloadURL: URL { return URL(string: self/*, relativeTo: ServerBaseUrl*/) ?? ServerBaseUrl }
}

