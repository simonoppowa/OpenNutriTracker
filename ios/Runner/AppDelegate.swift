import UIKit
import Flutter
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "NutritionTextRecognizer") {
      NutritionTextRecognizer.register(with: registrar)
    }
    if let registrar = self.registrar(forPlugin: "BackupFolderAccess") {
      BackupFolderAccess.register(with: registrar)
    }
    // Required by flutter_local_notifications so foreground notifications
    // are displayed instead of being silently dropped (#312).
    // FlutterAppDelegate already conforms to UNUserNotificationCenterDelegate,
    // so the direct assignment type-checks at compile time. The previous
    // shape used `self as? UNUserNotificationCenterDelegate`, which would
    // silently resolve to nil (and drop foreground notifications) if a
    // future Flutter / plugin reorganisation ever lost the conformance.
    // With the unconditional assignment, that scenario surfaces as a
    // compile error instead.
    UNUserNotificationCenter.current().delegate = self
    // Exclude the documents folder from iCloud backup.
    try! setExcludeFromiCloudBackup(isExcluded: true)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private func setExcludeFromiCloudBackup(isExcluded: Bool) throws {
    var fileOrDirectoryURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    var values = URLResourceValues()
    values.isExcludedFromBackup = isExcluded
    try fileOrDirectoryURL.setResourceValues(values)
}
