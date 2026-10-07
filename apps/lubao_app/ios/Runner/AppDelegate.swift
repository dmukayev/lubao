import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Кнопки push (042 п.1): «Да / Уехал», «Да / Нет». Push от FCM — не
  /// локальное уведомление, flutter_local_notifications его кнопки не видит,
  /// поэтому нажатие передаём в Dart сами (PushService, канал lubao/push_actions).
  private var pushActions: FlutterMethodChannel?
  private var pendingAction: [String: Any]?
  private static let actionIds: Set<String> = ["STILL_LOOKING_YES", "STILL_LOOKING_LEFT", "AGREED_YES", "AGREED_NO"]

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LubaoPushActions") else { return }
    let channel = FlutterMethodChannel(name: "lubao/push_actions", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      // Холодный старт по кнопке: Dart забирает нажатие, когда готов.
      if call.method == "pending" {
        result(self?.pendingAction)
        self?.pendingAction = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    pushActions = channel
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let info = response.notification.request.content.userInfo
    if AppDelegate.actionIds.contains(response.actionIdentifier), info["gcm.message_id"] != nil {
      let args: [String: Any] = [
        "action": response.actionIdentifier,
        "deepLink": info["deepLink"] as? String ?? "",
        "cargoId": info["cargoId"] as? String ?? "",
      ]
      if let channel = pushActions {
        channel.invokeMethod("action", arguments: args)
      } else {
        pendingAction = args
      }
    }
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
}
