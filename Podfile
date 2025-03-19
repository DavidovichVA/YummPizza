platform :ios, '8.0'

target 'YummPizza' do

# Comment the next line if you're not using Swift and don't want to use dynamic frameworks
use_frameworks!

pod 'Fabric'
pod 'Crashlytics'
pod 'RealmSwift'
pod 'Alamofire'
pod 'SwiftyJSON'
pod 'Kingfisher'
pod 'MBProgressHUD'
pod 'AKMaskField'
pod 'GoogleMaps'
pod 'ActionSheetPicker'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = ‘4.0’
    end
  end
end
