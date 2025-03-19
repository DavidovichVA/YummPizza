
import Foundation

extension String
{
   ///Levenshtein distance
   static func distance(_ lhs : String, _ rhs : String) -> Int
   {
      if lhs.isEmpty || rhs.isEmpty {
         return Swift.max(lhs.characters.count, rhs.characters.count)
      }
      
      let lhsChars = Array(lhs.characters)
      let rhsChars = Array(rhs.characters)
      
      let lhsCount = lhsChars.count
      let rhsCount = rhsChars.count
      
      var v0 : [Int] = Array<Int>(0...lhsCount)
      var v1 : [Int] = Array<Int>(repeating: 0, count: lhsCount+1)
      
      var substitutionCost : Int
      
      for j in 1...rhsCount
      {
         v1[0] = j
         
         for i in 1...lhsCount
         {
            substitutionCost = (lhsChars[i-1] == rhsChars[j-1]) ? 0 : 1
            v1[i] = Swift.min(v0[i] + 1, v1[i-1] + 1, v0[i-1] + substitutionCost)
         }
         
         swap(&v0, &v1)
      }
      
      return v0[lhsCount]
   }
   
   ///Levenshtein distances
   static func distances(from sourceString : String, to strArray : [String]) -> [Int]
   {
      if sourceString.isEmpty {
         return strArray.map({ $0.characters.count })
      }
      
      let sourceChars = Array(sourceString.characters)
      let sourceCharsCount = sourceChars.count
      var distances : [Int] = []
      
      var substitutionCost : Int
      var v0 : [Int] = Array<Int>(0...sourceCharsCount)
      var v1 : [Int] = Array<Int>(repeating: 0, count: sourceCharsCount+1)
      
      for str in strArray
      {
         if str.isEmpty {
            distances.append(sourceCharsCount)
            continue
         }
         
         let strChars = Array(str.characters)
         let strCharsCount = strChars.count
         
         for ind in 0...sourceCharsCount {
            v0[ind] = ind
         }
         
         for j in 1...strCharsCount
         {
            v1[0] = j
            
            for i in 1...sourceCharsCount
            {
               substitutionCost = (sourceChars[i-1] == strChars[j-1]) ? 0 : 1
               v1[i] = Swift.min(v0[i] + 1, v1[i-1] + 1, v0[i-1] + substitutionCost)
            }
            
            swap(&v0, &v1)
         }
         
         distances.append(v0[sourceCharsCount])
      }
      
      return distances
   }
   
   ///Levenshtein distances
   static func distances(from sourceString : String, to objArray : [AnyObject], forKeyPath : String) -> [Int]
   {
      let strArray : [String] = objArray.map({ $0.value(forKeyPath: forKeyPath) as! String })
      return distances(from: sourceString, to: strArray)
   }
   
   ///Concurrently counts Levenshtein distances
   static func distances(from sourceString : String, to strArray : [String],
                         queue : DispatchQueue = UserInitiatedQueue, qos : DispatchQoS = .userInitiated,
                         concurrentCount : Int = 4, completion : @escaping ([Int]) -> Void )
   {
      let dispatchGroup = DispatchGroup()
      let strSubArrays : [[String]] = strArray.divide(parts: concurrentCount)
      var subDistances : [[Int]] = Array<Array<Int>>(repeating: [], count: concurrentCount)
      
      for (ind, subArray) in strSubArrays.enumerated()
      {
         queue.async(group: dispatchGroup, qos: qos) {
            subDistances[ind] = distances(from: sourceString, to: subArray)
         }
      }
      
      dispatchGroup.notify(queue: MainQueue)
      {
         completion(Array(subDistances.joined()))
      }
   }
   
   ///Concurrently counts Levenshtein distances
   static func distances(from sourceString : String, to objArray : [AnyObject], forKeyPath : String,
                         queue : DispatchQueue = UserInitiatedQueue, qos : DispatchQoS = .userInitiated,
                         concurrentCount : Int = 4, completion : @escaping ([Int]) -> Void )
   {
      let strArray : [String] = objArray.map({ $0.value(forKeyPath: forKeyPath) as! String })
      distances(from: sourceString, to: strArray, queue: queue, qos: qos, concurrentCount: concurrentCount, completion: completion)
   }
}
