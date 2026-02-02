import ArgumentParser
import Foundation
import SwiftFormattingCore
import SwiftFormattingCoreCLI
import SwiftJSONFormatter
import CommonLog

@main
struct SwiftJSONFormatterCLI: AsyncParsableCommand {
  private static let formatterLog = Log(system: "wrkstrm", category: "swift-json-formatter")

  static let configuration = CommandConfiguration(
    abstract: "Format JSON files using the Wrkstrm JSON policy",
    discussion:
      "Formats JSON with prettyPrinted, sortedKeys, and withoutEscapingSlashes. Writes atomically. Use --write-to to mirror outputs into a separate directory.",
    subcommands: [
      FormattingAuditCommand<JSONFormatRunner>.self,
      FormattingFixCommand<JSONFormatRunner>.self,
    ],
    defaultSubcommand: FormattingAuditCommand<JSONFormatRunner>.self
  )

  struct CommonFormatOptions: ParsableArguments {
    @Option(
      name: .customLong("file"), parsing: .upToNextOption,
      help: "Input JSON file(s). Repeatable."
    )
    var files: [String] = []

    @Option(
      name: .customLong("glob"), parsing: .upToNextOption,
      help: "Glob patterns to expand (e.g., '**/*.json'). Repeatable."
    )
    var globs: [String] = []

    @Flag(
      name: .customLong("stdin"),
      help: "Read JSON from stdin and write formatted JSON to stdout. Ignores files/globs."
    )
    var useStdin: Bool = false

    @Flag(
      name: .customLong("include-ai"),
      help: "Include ai/imports and ai/exports paths (excluded by default)."
    )
    var includeAI: Bool = false

    @Flag(
      name: .customLong("include-demos"),
      help: "Include demo sources under demos/ (excluded by default)."
    )
    var includeDemos: Bool = false

    @Flag(
      name: .customLong("quiet"),
      help: "Suppress per-file logs; print only summary or errors."
    )
    var quiet: Bool = false
  }

  private struct JSONFormatRunner: FormattingCommandRunner {
    typealias Options = CommonFormatOptions
    typealias FixOptions = FormattingWriteToOptions

    static let auditAbstract = "Audit JSON formatting (no writes; non-zero exit on changes)."
    static let fixAbstract = "Fix JSON formatting in place or under a mirrored directory."

    static func runFormat(
      options: CommonFormatOptions,
      mode: FormattingMode,
      writeTo: String?
    ) async throws {
      try await SwiftJSONFormatterCLI.runFormat(options: options, mode: mode, writeTo: writeTo)
    }
  }

  private static func runFormat(
    options: CommonFormatOptions,
    mode: FormattingMode,
    writeTo: String?
  ) async throws {
    if options.useStdin {
      guard mode == .fix && writeTo == nil else {
        throw ValidationError("--stdin cannot be combined with audit or --write-to")
      }
      let data = FileHandle.standardInput.readDataToEndOfFile()
      let formatted = try SwiftJSONFormatter.formatStdin(data)
      FileHandle.standardOutput.write(formatted)
      FileHandle.standardOutput.write("\n".data(using: .utf8)!)
      return
    }

    let inputs = try FormattingInputs(
      files: options.files,
      globs: options.globs,
      includeAI: options.includeAI,
      includeDemos: options.includeDemos
    )
    .resolve(defaultGlobs: [])

    let result = SwiftJSONFormatter.format(
      paths: inputs,
      check: mode.isCheck,
      writeTo: writeTo,
      emit: { event in
        switch event {
        case .wouldChange(let path):
          if !options.quiet { logInfo("json: would change \(path)") }
        case .formatted(let path, let destination):
          guard !options.quiet else { return }
          if let destination {
            logInfo("json: formatted \(path) -> \(destination)")
          } else {
            logInfo("json: formatted \(path)")
          }
        case .error(let path, let error):
          let message = "json: error formatting \(path): \(String(describing: error))\n"
          FileHandle.standardError.write(message.data(using: .utf8)!)
        }
      }
    )

    if mode.isCheck {
      if !options.quiet { logInfo("\(result.changedCount) file(s) would change") }
      if result.changedCount > 0 { throw ExitCode(1) }
    } else if !options.quiet {
      logInfo("json: done. errors=\(result.errorCount)")
    }
  }

  private static func logInfo(_ message: String) {
    formatterLog.info(.message(message))
  }
}
