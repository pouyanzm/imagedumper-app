import Cocoa
import FlutterMacOS
import SystemConfiguration
import Network

class MainFlutterWindow: NSWindow {
  private var eventSink: FlutterEventSink?
  private var reachability: SCNetworkReachability?
  
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // Set up method channel for network service
    let networkChannel = FlutterMethodChannel(name: "network_service", binaryMessenger: flutterViewController.engine.binaryMessenger)
    
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
    let eventChannel = FlutterEventChannel(name: "network_service/events", binaryMessenger: flutterViewController.engine.binaryMessenger)
    eventChannel.setStreamHandler(self)

    super.awakeFromNib()
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
    
    // On macOS, detect network interface types
    return detectMacOSNetworkType()
  }
  
  private func detectMacOSNetworkType() -> String {
    // Check network interfaces using BSD sockets
    let interfaces = getNetworkInterfaces()
    
    // Priority: ethernet > wifi > other
    if interfaces.contains("ethernet") {
      return "ethernet"
    } else if interfaces.contains("wifi") {
      return "wifi"
    } else if !interfaces.isEmpty {
      return "wifi" // Default to wifi for active connections on macOS
    }
    
    return "none"
  }
  
  private func getNetworkInterfaces() -> [String] {
    var interfaces: [String] = []
    
    var ifaddrs: UnsafeMutablePointer<ifaddrs>?
    if getifaddrs(&ifaddrs) == 0 {
      var current = ifaddrs
      while current != nil {
        defer { current = current?.pointee.ifa_next }
        
        guard let addr = current?.pointee.ifa_addr,
              addr.pointee.sa_family == UInt8(AF_INET),
              let flags = current?.pointee.ifa_flags else { continue }
        
        // Check if interface is up and running
        if (flags & UInt32(IFF_UP)) != 0 && (flags & UInt32(IFF_RUNNING)) != 0 {
          if let name = current?.pointee.ifa_name {
            let interfaceName = String(cString: name)
            
            // Categorize interface types
            if interfaceName.hasPrefix("en") && !interfaceName.hasPrefix("en0") {
              // en1, en2, etc. are typically Ethernet on macOS
              interfaces.append("ethernet")
            } else if interfaceName.hasPrefix("en0") {
              // en0 is typically Wi-Fi on macOS
              interfaces.append("wifi")
            } else if interfaceName.hasPrefix("pdp_ip") || interfaceName.hasPrefix("cellular") {
              // Cellular interfaces
              interfaces.append("mobile")
            }
          }
        }
      }
      freeifaddrs(ifaddrs)
    }
    
    return interfaces
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
      let window = Unmanaged<MainFlutterWindow>.fromOpaque(info).takeUnretainedValue()
      window.sendNetworkUpdate()
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

extension MainFlutterWindow: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
