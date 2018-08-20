# coding: utf-8
source 'https://github.com/hackinggate/Specs.git'
source 'https://github.com/CocoaPods/Specs.git'
inhibit_all_warnings!
use_frameworks!

target 'APN-Messages-Demo' do
       pod 'OpenSSL-Universal', :git => 'https://github.com/krzyzanowskim/OpenSSL.git', :branch => :master
       pod 'KBPGP'
end

pre_install do |installer|
	    # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
	    Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end