import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    if let registrar = flutterViewController.registrar(forPlugin: "ICloudKV") {
      ICloudKVChannel.register(messenger: registrar.messenger)
    }

    super.awakeFromNib()
  }
}

/// Bridges Flutter to `NSUbiquitousKeyValueStore` (iCloud key-value sync).
/// Method channel `breathscape/icloud_kv` supports `get`/`set`; event channel
/// `breathscape/icloud_kv_changes` emits keys changed externally (other device).
class ICloudKVChannel: NSObject, FlutterStreamHandler {
  /// Strong reference so the handler outlives `register`.
  private static var shared: ICloudKVChannel?

  private var eventSink: FlutterEventSink?
  private let store = NSUbiquitousKeyValueStore.default

  static func register(messenger: FlutterBinaryMessenger) {
    let instance = ICloudKVChannel()
    shared = instance

    let methodChannel = FlutterMethodChannel(
      name: "breathscape/icloud_kv", binaryMessenger: messenger)
    methodChannel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }

    let eventChannel = FlutterEventChannel(
      name: "breathscape/icloud_kv_changes", binaryMessenger: messenger)
    eventChannel.setStreamHandler(instance)

    NotificationCenter.default.addObserver(
      instance,
      selector: #selector(storeDidChangeExternally(_:)),
      name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
      object: instance.store)
    instance.store.synchronize()
  }

  private func handle(_ call: FlutterMethodCall, result: FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "get":
      guard let key = args?["key"] as? String else {
        result(FlutterError(code: "bad_args", message: "missing key", details: nil))
        return
      }
      result(store.string(forKey: key))
    case "set":
      guard let key = args?["key"] as? String,
        let value = args?["value"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "missing key/value", details: nil))
        return
      }
      store.set(value, forKey: key)
      store.synchronize()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @objc private func storeDidChangeExternally(_ notification: Notification) {
    guard let sink = eventSink,
      let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
    else { return }
    for key in keys { sink(key) }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
