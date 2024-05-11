import Cocoa
import FlutterMacOS
public class AppLinks {
  static public let shared = AppLinksMacosPlugin()

  private init() {}
}
public class AppLinksMacosPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, FlutterAppLifecycleDelegate {
  private var eventSink: FlutterEventSink?
  private var initialLink: String?
  private var latestLink: String?
  private var initialLinkSent = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = AppLinks.shared

    let methodChannel = FlutterMethodChannel(name: "com.llfbandit.app_links/messages", binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    let eventChannel = FlutterEventChannel(name: "com.llfbandit.app_links/events", binaryMessenger: registrar.messenger)
    eventChannel.setStreamHandler(instance)

    registrar.addApplicationDelegate(instance)
  }

  public func handleWillFinishLaunching(_ notification: Notification) {
    NSAppleEventManager.shared().setEventHandler(
      self,
      andSelector: #selector(handleEvent(_:with:)),
      forEventClass: AEEventClass(kInternetEventClass),
      andEventID: AEEventID(kAEGetURL)
    )
  }


  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "getInitialAppLink":
        result(initialLink)
        break
      case "getLatestAppLink":
        result(latestLink)
        break
      default:
        result(FlutterMethodNotImplemented)
        break
    }
  }

  // Universal Links
  public func application(
    _ application: NSApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void
  ) -> Bool {
 print("Activity Type: \(userActivity.activityType)")
    switch userActivity.activityType {
    case NSUserActivityTypeBrowsingWeb:
      if let url = userActivity.webpageURL {
        handleLink(link: url.absoluteString)
      }
      return false
    default: return false
    }
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink) -> FlutterError? {

    self.eventSink = events
      
    if (!initialLinkSent && initialLink != nil) {
      initialLinkSent = true
      events(initialLink!)
    }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }

  @objc
  private func handleEvent(
    _ event: NSAppleEventDescriptor,
    with replyEvent: NSAppleEventDescriptor) {

    if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
       let _ = URL(string: urlString) {
      handleLink(link: urlString)
    }
  }

  public func handleLink(link: String) {
    latestLink = link

    if (initialLink == nil) {
      initialLink = link
    }

    if let _eventSink = eventSink {
      initialLinkSent = true
      _eventSink(latestLink)
    }
  }
}
