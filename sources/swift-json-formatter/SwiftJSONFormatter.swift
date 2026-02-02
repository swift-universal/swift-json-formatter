import Foundation
import SwiftFormattingCore
import WrkstrmFoundation
import WrkstrmMain

public enum JSONFormatEvent {
  case wouldChange(path: String)
  case formatted(path: String, destination: String?)
  case error(path: String, error: Error)
}

public struct JSONFormatResult {
  public var changedCount: Int
  public var errorCount: Int

  public init(changedCount: Int = 0, errorCount: Int = 0) {
    self.changedCount = changedCount
    self.errorCount = errorCount
  }
}

public enum SwiftJSONFormatter {
  public static func format(
    paths: [String],
    check: Bool,
    writeTo: String?,
    emit: ((JSONFormatEvent) -> Void)? = nil
  ) -> JSONFormatResult {
    var result = JSONFormatResult()
    let workingDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .standardizedFileURL
    for path in paths {
      do {
        let fileURL = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: fileURL)
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        let formatted = try JSONSerialization.data(
          withJSONObject: jsonObject,
          options: JSON.Formatting.humanOptions
        )
        if check {
          let existingContent =
            String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
          let formattedContent = String(decoding: formatted, as: UTF8.self)
          if existingContent != formattedContent {
            result.changedCount += 1
            emit?(.wouldChange(path: path))
          }
        } else {
          let destinationURL = FormattingPaths.destinationURL(
            for: path,
            writeTo: writeTo,
            workingDirectory: workingDirectory
          )
          try JSON.FileWriter.writeJSONObject(
            jsonObject,
            to: destinationURL,
            options: JSON.Formatting.humanOptions,
            atomic: true
          )
          emit?(.formatted(path: path, destination: writeTo == nil ? nil : destinationURL.path))
        }
      } catch {
        result.errorCount += 1
        emit?(.error(path: path, error: error))
      }
    }
    return result
  }

  public static func formatStdin(_ data: Data) throws -> Data {
    let jsonObject = try JSONSerialization.jsonObject(with: data)
    return try JSONSerialization.data(
      withJSONObject: jsonObject,
      options: JSON.Formatting.humanOptions
    )
  }
}
