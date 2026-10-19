import Flutter
import UIKit
import Vision

/// Recognizes the text of a photographed nutrition table on the device with
/// Apple Vision, for the label scan (#61). Answers the `recognizeText` call
/// on its channel with one entry per recognized line: the text, the
/// recognizer's confidence and a bounding box normalized to the image, with
/// the origin at the top left (see docs/nutrition-label-ocr.md).
final class NutritionTextRecognizer: NSObject {
  static let channelName = "dev.theocloud.nutritracker/text_recognition"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let recognizer = NutritionTextRecognizer()
    channel.setMethodCallHandler(recognizer.handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "recognizeText" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let arguments = call.arguments as? [String: Any],
      let path = arguments["path"] as? String
    else {
      result(FlutterError(code: "bad_arguments", message: "path missing", details: nil))
      return
    }
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let lines = try Self.recognize(path: path)
        DispatchQueue.main.async { result(lines) }
      } catch RecognitionError.unreadableImage {
        DispatchQueue.main.async {
          result(FlutterError(code: "unreadable_image", message: nil, details: nil))
        }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "recognition_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    }
  }

  private enum RecognitionError: Error {
    case unreadableImage
  }

  private static func recognize(path: String) throws -> [[String: Any]] {
    guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
      throw RecognitionError.unreadableImage
    }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    request.recognitionLanguages = ["de-DE", "en-US"]
    let handler = VNImageRequestHandler(
      cgImage: cgImage,
      orientation: CGImagePropertyOrientation(image.imageOrientation),
      options: [:]
    )
    try handler.perform([request])
    return (request.results ?? []).compactMap { observation in
      guard let candidate = observation.topCandidates(1).first else { return nil }
      let box = observation.boundingBox
      return [
        "text": candidate.string,
        "x": Double(box.minX),
        "y": Double(1 - box.maxY),
        "w": Double(box.width),
        "h": Double(box.height),
        "confidence": Double(candidate.confidence),
      ]
    }
  }
}

extension CGImagePropertyOrientation {
  /// The EXIF orientation matching a UIImage's, so Vision reads a photo the
  /// way it is shown.
  init(_ orientation: UIImage.Orientation) {
    switch orientation {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
