import Flutter
import UIKit
import SystemConfiguration
import Network

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var eventSink: FlutterEventSink?
  private var reachability: SCNetworkReachability?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller = window?.rootViewController as! FlutterViewController
    let networkChannel = FlutterMethodChannel(name: "network_service", binaryMessenger: controller.binaryMessenger)
    
    networkChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "isConnectedToWifiOrEthernet":
        result(self?.isConnectedToWifiOrEthernet() ?? false)
      case "getNetworkType":
        result(self?.getNetworkType() ?? "none")
      case "isConnected":
        result(self?.isConnected() ?? false)
      case "startNetworkMonitoring":
        self?.startNetworkMonitoring()
        result(nil)
      case "stopNetworkMonitoring":
        self?.stopNetworkMonitoring()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    // Event channel setup
    let eventChannel = FlutterEventChannel(name: "network_service/events", binaryMessenger: controller.binaryMessenger)
    eventChannel.setStreamHandler(self)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func isConnectedToWifiOrEthernet() -> Bool {
    let networkType = getNetworkType()
    return networkType == "wifi" || networkType == "ethernet"
  }
  
  private func getNetworkType() -> String {
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    zeroAddress.sin_family = sa_family_t(AF_INET)
    
    guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        SCNetworkReachabilityCreateWithAddress(nil, $0)
      }
    }) else {
      return "none"
    }
    
    var flags: SCNetworkReachabilityFlags = []
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
      return "none"
    }
    
    let isReachable = flags.contains(.reachable)
    let needsConnection = flags.contains(.connectionRequired)
    let isNetworkReachable = isReachable && !needsConnection
    
    if !isNetworkReachable {
      return "none"
    }
    
    // Check if it's WiFi
    if flags.contains(.isWWAN) {
      return "mobile"
    } else {
      // On iOS, we primarily have WiFi for non-cellular connections
      // Ethernet detection is more complex and mainly relevant for iOS devices with adapters
      return "wifi"
    }
  }
  
  private func isConnected() -> Bool {
    let networkType = getNetworkType()
    return networkType != "none"
  }
  
  private func startNetworkMonitoring() {
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    zeroAddress.sin_family = sa_family_t(AF_INET)
    
    guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        SCNetworkReachabilityCreateWithAddress(nil, $0)
      }
    }) else {
      return
    }
    
    reachability = defaultRouteReachability
    
    var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
    context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    
    let callback: SCNetworkReachabilityCallBack = { (reachability, flags, info) in
      guard let info = info else { return }
      let appDelegate = Unmanaged<AppDelegate>.fromOpaque(info).takeUnretainedValue()
      appDelegate.sendNetworkUpdate()
    }
    
    if SCNetworkReachabilitySetCallback(reachability!, callback, &context) {
      SCNetworkReachabilityScheduleWithRunLoop(reachability!, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    }
    
    // Send initial state
    sendNetworkUpdate()
  }
  
  private func stopNetworkMonitoring() {
    if let reachability = reachability {
      SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
      self.reachability = nil
    }
  }
  
  private func sendNetworkUpdate() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self, let eventSink = self.eventSink else { return }
      
      let networkData: [String: Any] = [
        "isConnected": self.isConnected(),
        "isWifiOrEthernet": self.isConnectedToWifiOrEthernet(),
        "networkType": self.getNetworkType(),
        "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
      ]
      
      eventSink(networkData)
    }
  }
}

extension AppDelegate: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
