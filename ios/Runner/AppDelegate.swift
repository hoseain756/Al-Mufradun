import Flutter
import UIKit
import UserNotifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let prayerSchedulerChannelName = "com.hussein.almufradun.prayer/scheduler"
  private let prayerRefreshTaskIdentifier = "com.hussein.almufradun.prayer.refresh"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register for local notifications (iOS 10+)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: prayerRefreshTaskIdentifier,
      frequency: NSNumber(value: 12 * 60 * 60)
    )

    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: prayerSchedulerChannelName,
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "refreshIOSPrayerWindow":
          guard
            let arguments = call.arguments as? [String: Any],
            let rawRequests = arguments["requests"] as? [[String: Any]]
          else {
            result(
              FlutterError(
                code: "bad_args",
                message: "requests is required",
                details: nil
              )
            )
            return
          }

          let requests = rawRequests.compactMap { item -> PrayerNotificationRequest? in
            guard
              let id = item["id"] as? Int,
              let title = item["title"] as? String,
              let body = item["body"] as? String
            else {
              return nil
            }

            let triggerAtMillis: TimeInterval
            if let value = item["triggerAtMillis"] as? NSNumber {
              triggerAtMillis = value.doubleValue
            } else if let value = item["triggerAtMillis"] as? Int {
              triggerAtMillis = TimeInterval(value)
            } else {
              return nil
            }

            return PrayerNotificationRequest(
              id: id,
              title: title,
              body: body,
              triggerAtMillis: triggerAtMillis
            )
          }

          PrayerScheduler.shared.refreshSchedule(requests: requests) { error in
            if let error = error {
              result(
                FlutterError(
                  code: "ios_schedule_failed",
                  message: error.localizedDescription,
                  details: nil
                )
              )
            } else {
              result(nil)
            }
          }

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}
