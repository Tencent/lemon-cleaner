# Uncomment the next line to define a global platform for your project
#source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.11'

install! 'cocoapods', :disable_input_output_paths => true

workspace 'Lemon'

project 'Lemon.xcodeproj'
project 'Tools/LemonMonitor/LemonMonitor.xcodeproj'
project 'Tools/LemonDaemon/LemonDaemon.xcodeproj'
project 'Tools/PrivacyProtect/PrivacyProtect.xcodeproj'

#use_frameworks!
def available_pods
    pod 'AFNetworking', '= 3.2.1'
    pod 'QMUICommon',:path => './localPod/QMUICommon'
    pod 'QMCoreFunction',:path => './localPod/QMCoreFunction'
    pod 'Masonry', '= 1.1.0'
    pod 'FMDB', '= 2.7.5'
end
target 'Lemon' do
   use_frameworks!
   inherit! :search_paths
  project 'Lemon.xcodeproj'
  available_pods
  pod 'QMAppLoginItemManage',:path => './localPod/QMAppLoginItemManage'
  pod 'LemonSpaceAnalyse',:path => './localPod/LemonSpaceAnalyse'
  pod 'LemonSpaceAnalyse',:path => './localPod/LemonSpaceAnalyse'
  pod 'LemonBigOldFile',:path => './localPod/LemonBigOldFile'
  pod 'LemonPhotoClean',:path => './localPod/LemonPhotoClean'
  pod 'LemonDuplicateFile',:path => './localPod/LemonDuplicateFile'
  pod 'LemonPrivacyClean',:path => './localPod/LemonPrivacyClean'
  pod 'LemonUninstaller',:path => './localPod/LemonUninstaller'
  pod 'LemonLoginItemManager',:path => './localPod/LemonLoginItemManager'
  pod 'LemonFileMove',:path => './localPod/LemonFileMove'
  pod 'LemonFileManager',:path => './localPod/LemonFileManager'

end

target 'LemonMonitor' do
    use_frameworks!
    inherit! :search_paths
    project 'Tools/LemonMonitor/LemonMonitor.xcodeproj'
    available_pods
    pod 'LemonStat',:path => './localPod/LemonStat'
    pod 'LemonUninstaller',:path => './localPod/LemonUninstaller'
    pod 'LemonHardware',:path => './localPod/LemonHardware'
    pod 'LemonNetSpeed',:path => './localPod/LemonNetSpeed'
    pod 'LemonFileMove',:path => './localPod/LemonFileMove'
end

target 'LemonDaemon' do
    inherit! :search_paths
    project 'Tools/LemonDaemon/LemonDaemon.xcodeproj'
end

target 'LemonClener' do
    use_frameworks!
    inherit! :search_paths
    project 'LemonClener/LemonClener.xcodeproj'
    pod 'LemonFileMove',:path => './localPod/LemonFileMove'
    available_pods
end

target 'PrivacyProtect' do
    use_frameworks!
    inherit! :search_paths
    project 'Tools/PrivacyProtect/PrivacyProtect.xcodeproj'
    available_pods
end

post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
            config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.11'
        end
    end
end
