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
    pod 'LemonFileManager',:path => './localPod/LemonFileManager'
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
            config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
        end
    end

    # Xcode 26+: AFNetworking 3.x 引用了 netinet6/in6.h 私有模块头文件，
    # 新版 Xcode 严格检查会报错。netinet/in.h 已包含 IPv6 定义，直接删除该行。
    af_dir = File.join(installer_representation.sandbox.root, 'AFNetworking', 'AFNetworking')
    Dir.glob(File.join(af_dir, '*.m')).each do |af_file|
        content = File.read(af_file)
        if content.match?(/^.*netinet6\/in6\.h.*$/)
            patched = content.gsub(/^.*netinet6\/in6\.h.*\n/, '')
            File.chmod(0644, af_file)
            File.write(af_file, patched)
            puts "[Podfile] Patched #{File.basename(af_file)}: removed netinet6/in6.h line"
        end
    end
end
