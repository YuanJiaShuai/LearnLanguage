platform :osx, '12.0'  # 最低支持 macOS 12.0

target 'LearnLanguage' do
  use_frameworks!
  
  # 网络库
  pod 'Alamofire', '~> 5.8'
  pod 'Moya', '~> 15.0'
  
  # UI 布局
  pod 'SnapKit', '~> 5.6'
  
  # 数据存储
  pod 'WCDB.swift', '~> 1.0'
  pod 'MMKV', '~> 1.3'
  
  # 快捷键
  pod 'HotKey', '~> 0.2.1'
  
  # 动画
  pod 'lottie-ios'
  
  # 数据可视化
  pod 'DGCharts', '~> 5.1'
end

# 关键：强制所有 Pod 依赖的最低版本也为 12.0
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
