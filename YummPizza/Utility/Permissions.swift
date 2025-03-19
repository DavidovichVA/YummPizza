import UIKit
import Photos
import AVFoundation

typealias AccessGrantedCallback = (_ accessGranted : Bool) -> Void

enum PermissionState {
   case allowed
   case forbidden
   case undetermined
}


var galleryPermission : PermissionState
{
   let authStatus = PHPhotoLibrary.authorizationStatus()
   switch authStatus
   {
      case .authorized: return .allowed
      case .denied, .restricted: return .forbidden
      case .notDetermined: return .undetermined
   }
}
var galleryAccessAllowed : Bool {
   return (galleryPermission == .allowed)
}

var cameraPermission : PermissionState
{
   let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
   switch authStatus
   {
      case .authorized: return .allowed
      case .denied, .restricted: return .forbidden
      case .notDetermined: return .undetermined
   }
}
var cameraAccessAllowed : Bool {
   return (cameraPermission == .allowed)
}

var microphonePermission : PermissionState
{
   let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
   switch authStatus
   {
      case .authorized: return .allowed
      case .denied, .restricted: return .forbidden
      case .notDetermined: return .undetermined
   }
}
var microphoneAccessAllowed : Bool {
   return (microphonePermission == .allowed)
}

func checkGalleryAccess(_ completion : @escaping AccessGrantedCallback)
{
   let authStatus = PHPhotoLibrary.authorizationStatus()
   
   switch authStatus
   {
      case .authorized: completion(true)
      
      case .denied, .restricted:
         let title = "Фото недоступны"
         let message = locInfo("NSPhotoLibraryUsageDescription", defaultValue: "Разрешите Ямм Пицца доступ к Фото")
         
         let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
         
         let cancel = UIAlertAction(title: "Отмена", style: .cancel)
         alertController.addAction(cancel)
         
         let settings = UIAlertAction(title: "Настройки", style: .default, handler: { _ in
            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
         })
         alertController.addAction(settings)
         
         AlertManager.showAlert(alertController)
         completion(false)
      
      case .notDetermined:
         PHPhotoLibrary.requestAuthorization
         {
            status in
            performOnMainThread { completion(status == .authorized) }
         }
   }
}

func checkCameraAccess(_ completion : @escaping AccessGrantedCallback)
{
   let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
   
   switch authStatus
   {
      case .authorized: completion(true)
      
      case .denied, .restricted:
         let title = "Камера недоступна"
         let message = locInfo("NSCameraUsageDescription", defaultValue: "Разрешите Ямм Пицца доступ к камере")
         
         let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
         
         let cancel = UIAlertAction(title: "Отмена", style: .cancel)
         alertController.addAction(cancel)
         
         let settings = UIAlertAction(title: "Настройки", style: .default, handler: { _ in
            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
         })
         alertController.addAction(settings)
         
         AlertManager.showAlert(alertController)
         completion(false)
         
      case .notDetermined:
         AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
         {
            granted in
            performOnMainThread { completion(granted) }
         })
   }
}

func checkMicrophoneAccess(_ completion : @escaping AccessGrantedCallback)
{
   let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
   
   switch authStatus
   {
   case .authorized: completion(true)
      
   case .denied, .restricted:
      let title = "Микрофон недоступен"
      let message = locInfo("NSMicrophoneUsageDescription", defaultValue: "Разрешите Ямм Пицца доступ к микрофону")
      
      let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      
      let cancel = UIAlertAction(title: "Отмена", style: .cancel)
      alertController.addAction(cancel)
      
      let settings = UIAlertAction(title: "Настройки", style: .default, handler: { _ in
         UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
      })
      alertController.addAction(settings)
      
      AlertManager.showAlert(alertController)
      completion(false)
      
   case .notDetermined:
      AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler:
      {
         granted in
         performOnMainThread { completion(granted) }
      })
   }
}

func checkCameraAndMicrophoneAccess(_ completion : @escaping AccessGrantedCallback)
{
   checkCameraAccess
   {
      cameraAccess in
      
      guard cameraAccess else {
         completion(false)
         return
      }
      
      checkMicrophoneAccess
      {
         microphoneAccess in
         completion(true) // we can capture video even without sound
      }
   }
}
