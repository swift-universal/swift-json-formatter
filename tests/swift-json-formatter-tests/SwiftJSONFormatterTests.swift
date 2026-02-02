import Foundation
import Testing

@testable import SwiftJSONFormatter

struct SwiftJSONFormatterTests {
  @Test func formatsAndWritesCanonicalJSON() throws {
    let fileManager = FileManager.default
    let temporaryDirectory = fileManager.temporaryDirectory.appendingPathComponent(
      UUID().uuidString)
    try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    defer { try? fileManager.removeItem(at: temporaryDirectory) }

    let fileURL = temporaryDirectory.appendingPathComponent("sample.json")
    let input = "{\"b\":1,\"a\":2,\"url\":\"https://example.com\"}"
    try input.write(to: fileURL, atomically: true, encoding: .utf8)

    let result = SwiftJSONFormatter.format(paths: [fileURL.path], check: false, writeTo: nil)
    #expect(result.errorCount == 0)

    let output = try String(contentsOf: fileURL, encoding: .utf8)
    let expected = """
      {
        "a" : 2,
        "b" : 1,
        "url" : "https://example.com"
      }
      """
    #expect(output == expected + "\n")
  }

  @Test func checkModeDetectsChanges() throws {
    let fileManager = FileManager.default
    let temporaryDirectory = fileManager.temporaryDirectory.appendingPathComponent(
      UUID().uuidString)
    try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    defer { try? fileManager.removeItem(at: temporaryDirectory) }

    let fileURL = temporaryDirectory.appendingPathComponent("sample.json")
    let input = "{\"b\":1,\"a\":2}"
    try input.write(to: fileURL, atomically: true, encoding: .utf8)

    let result = SwiftJSONFormatter.format(paths: [fileURL.path], check: true, writeTo: nil)
    #expect(result.changedCount == 1)
  }
}
