import Foundation
import Security
import UIKit

class PersistentDeviceId
{
    private static var deviceId : String?
    
    /// unique device id that persists after app reinstall
    class func getId() -> String
    {
        if let id = deviceId { return id }
        
        //keychain search for saved Id
      
        let typeString = "pdid"
        let typeBytes = typeString.utf8.map{ UInt8($0) }
        let typeUInt32 = UnsafePointer(typeBytes).withMemoryRebound(to: UInt32.self, capacity: 1) {
            $0.pointee
        }
        
        var dict : [String : Any] = [ kSecClass as String : kSecClassGenericPassword,
            kSecAttrType as String : NSNumber(value: typeUInt32),
            kSecAttrAccount as String : BundleId,
            kSecAttrService as String : "Persistent Device Id",
            kSecReturnAttributes as String : kCFBooleanTrue,
            kSecReturnData as String : kCFBooleanTrue]
        
        var result : AnyObject?
        let status = SecItemCopyMatching(dict as CFDictionary, &result)
        
        if status == errSecSuccess,
            let foundDict = result as? Dictionary<AnyHashable, Any>,
            let data = foundDict[kSecValueData as String] as? Data,
            let id = String(data: data, encoding: .utf8), !id.isEmpty
        {
            deviceId = id
            dlog(id)
            return id
        }
        
        //not found or incorrect, get new
        
        if let foundDict = result as? Dictionary<AnyHashable, Any> {
            SecItemDelete(foundDict as CFDictionary)
        }
      
        let id = (UIDevice.current.identifierForVendor ?? UUID()).uuidString.uppercased()
        if let data = id.data(using: .utf8)
        {
            dict[kSecValueData as String] = data
            dict[kSecAttrAccessible as String] = kSecAttrAccessibleAlwaysThisDeviceOnly
            let saveStatus = SecItemAdd(dict as CFDictionary, nil)
            dlog(saveStatus)
        }
        
        deviceId = id
        dlog(id)
        return id
    }
}
