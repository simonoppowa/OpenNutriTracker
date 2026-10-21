import Flutter
import UIKit
import UniformTypeIdentifiers

/// The Files-app folder of the automatic backup (#99). Lets the user pick a
/// folder with the document picker (iCloud Drive, another app's folder, a
/// file provider) and keeps access to it as a security-scoped bookmark,
/// which the Dart side stores. Answers `pick`, `list`, `write`, `read` and
/// `delete` on its channel; every answer after `pick` carries a renewed
/// `bookmark` when iOS reported the stored one as stale. Reads, writes and
/// deletes are coordinated, so an iCloud file that is not downloaded yet is
/// fetched first. Error codes: `access_denied`, `not_found`, `busy`, `io`.
final class BackupFolderAccess: NSObject, UIDocumentPickerDelegate {
  static let channelName = "dev.theocloud.nutritracker/backup_folder"

  private var pendingPick: FlutterResult?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let access = BackupFolderAccess()
    channel.setMethodCallHandler(access.handle)
  }

  private enum FolderError: Error {
    case accessDenied
    case notFound
    case badArguments
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "pick" {
      pick(result: result)
      return
    }
    guard
      let arguments = call.arguments as? [String: Any],
      let bookmark = arguments["bookmark"] as? String,
      let bookmarkData = Data(base64Encoded: bookmark)
    else {
      result(FlutterError(code: "access_denied", message: "bookmark missing", details: nil))
      return
    }
    let method = call.method
    guard ["list", "write", "read", "delete"].contains(method) else {
      result(FlutterMethodNotImplemented)
      return
    }
    DispatchQueue.global(qos: .userInitiated).async {
      let answer: Any
      do {
        answer = try Self.withFolder(bookmarkData) { folder in
          switch method {
          case "list":
            return ["names": try Self.list(folder)]
          case "write":
            guard
              let name = arguments["name"] as? String,
              let bytes = arguments["bytes"] as? FlutterStandardTypedData
            else { throw FolderError.badArguments }
            try Self.write(bytes.data, to: folder.appendingPathComponent(try Self.safeName(name)))
            return [:]
          case "read":
            guard let name = arguments["name"] as? String else {
              throw FolderError.badArguments
            }
            let data = try Self.read(folder.appendingPathComponent(try Self.safeName(name)))
            return ["bytes": FlutterStandardTypedData(bytes: data)]
          default:
            guard let name = arguments["name"] as? String else {
              throw FolderError.badArguments
            }
            try Self.delete(folder.appendingPathComponent(try Self.safeName(name)))
            return [:]
          }
        }
      } catch FolderError.accessDenied {
        answer = FlutterError(code: "access_denied", message: nil, details: nil)
      } catch FolderError.notFound {
        answer = FlutterError(code: "not_found", message: nil, details: nil)
      } catch {
        answer = FlutterError(code: "io", message: error.localizedDescription, details: nil)
      }
      DispatchQueue.main.async { result(answer) }
    }
  }

  // MARK: Picking

  private func pick(result: @escaping FlutterResult) {
    guard pendingPick == nil else {
      result(FlutterError(code: "busy", message: nil, details: nil))
      return
    }
    guard let presenter = Self.topViewController() else {
      result(FlutterError(code: "io", message: "no window to present from", details: nil))
      return
    }
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    picker.allowsMultipleSelection = false
    picker.delegate = self
    pendingPick = result
    presenter.present(picker, animated: true)
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    guard let result = pendingPick else { return }
    pendingPick = nil
    guard let folder = urls.first else {
      result(nil)
      return
    }
    let accessing = folder.startAccessingSecurityScopedResource()
    defer {
      if accessing { folder.stopAccessingSecurityScopedResource() }
    }
    do {
      let bookmark = try folder.bookmarkData(
        options: [],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      result([
        "bookmark": bookmark.base64EncodedString(),
        "name": folder.lastPathComponent,
      ])
    } catch {
      result(FlutterError(code: "access_denied", message: error.localizedDescription, details: nil))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingPick?(nil)
    pendingPick = nil
  }

  private static func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window =
      scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
      ?? scenes.first?.windows.first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }

  // MARK: Folder access

  /// [name] as a file name inside the folder; one that would reach outside
  /// it is refused.
  private static func safeName(_ name: String) throws -> String {
    guard !name.isEmpty, !name.contains("/"), name != ".", name != ".." else {
      throw FolderError.badArguments
    }
    return name
  }

  /// Resolves the bookmark, opens the security scope for [body] and adds a
  /// renewed bookmark to its answer when the stored one was stale.
  private static func withFolder(
    _ bookmarkData: Data,
    _ body: (URL) throws -> [String: Any]
  ) throws -> [String: Any] {
    var stale = false
    let folder: URL
    do {
      folder = try URL(
        resolvingBookmarkData: bookmarkData,
        options: [],
        relativeTo: nil,
        bookmarkDataIsStale: &stale
      )
    } catch {
      throw FolderError.accessDenied
    }
    let accessing = folder.startAccessingSecurityScopedResource()
    defer {
      if accessing { folder.stopAccessingSecurityScopedResource() }
    }
    var answer = try body(folder)
    if stale,
      let renewed = try? folder.bookmarkData(
        options: [],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
    {
      answer["bookmark"] = renewed.base64EncodedString()
    }
    return answer
  }

  /// The file names in [folder]; an iCloud file that is not downloaded yet
  /// is listed under its own name, not as its hidden `.name.icloud`
  /// placeholder.
  private static func list(_ folder: URL) throws -> [String] {
    var names: [String] = []
    var failure: Error?
    var coordinationError: NSError?
    NSFileCoordinator().coordinate(
      readingItemAt: folder,
      options: [],
      error: &coordinationError
    ) { url in
      do {
        let entries = try FileManager.default.contentsOfDirectory(atPath: url.path)
        for entry in entries {
          if entry.hasPrefix(".") && entry.hasSuffix(".icloud") {
            names.append(String(entry.dropFirst().dropLast(".icloud".count)))
          } else if !entry.hasPrefix(".") {
            names.append(entry)
          }
        }
      } catch {
        failure = error
      }
    }
    if let error = coordinationError ?? failure { throw error }
    return names
  }

  private static func write(_ data: Data, to file: URL) throws {
    var failure: Error?
    var coordinationError: NSError?
    NSFileCoordinator().coordinate(
      writingItemAt: file,
      options: .forReplacing,
      error: &coordinationError
    ) { url in
      do {
        try data.write(to: url, options: .atomic)
      } catch {
        failure = error
      }
    }
    if let error = coordinationError ?? failure { throw error }
  }

  private static func read(_ file: URL) throws -> Data {
    var data: Data?
    var failure: Error?
    var coordinationError: NSError?
    NSFileCoordinator().coordinate(
      readingItemAt: file,
      options: [],
      error: &coordinationError
    ) { url in
      do {
        data = try Data(contentsOf: url)
      } catch CocoaError.fileReadNoSuchFile {
        failure = FolderError.notFound
      } catch {
        failure = error
      }
    }
    if let error = coordinationError ?? failure { throw error }
    guard let data else { throw FolderError.notFound }
    return data
  }

  private static func delete(_ file: URL) throws {
    var failure: Error?
    var coordinationError: NSError?
    NSFileCoordinator().coordinate(
      writingItemAt: file,
      options: .forDeleting,
      error: &coordinationError
    ) { url in
      do {
        try FileManager.default.removeItem(at: url)
      } catch CocoaError.fileNoSuchFile {
        failure = nil
      } catch {
        failure = error
      }
    }
    if let error = coordinationError ?? failure { throw error }
  }
}
