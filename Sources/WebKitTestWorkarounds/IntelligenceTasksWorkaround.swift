#if os(iOS) && targetEnvironment(simulator)

import Foundation
internal import WebKitTestWorkaroundsRuntime

/// Temporarily unregisters `intelligencetasksd` from the current launchd domain.
///
/// This affects the entire iOS Simulator device. Coordinate one stop/restore pair
/// across the test process; other processes do not share this type's saved
/// registration.
@MainActor
public enum IntelligenceTasksWorkaround {
    private static let service = IntelligenceTasksService()

    /// Stops the service, saving its registration for a later call to `restore()`.
    ///
    /// An unregistered service is left unchanged. Repeated calls preserve the
    /// first saved registration. No persistent enable/disable override is changed.
    ///
    /// Call `restore()` from teardown even if stopping or test execution throws.
    /// The service remains unregistered if this process exits without restoring it.
    ///
    /// - Throws: A launchctl or process error. If stopping partially completed,
    ///   the saved registration remains available for restoration or another stop.
    public static func stop() throws {
        try service.stop()
    }

    /// Restores the registration saved by `stop()`.
    ///
    /// If the service was originally absent, or is already registered, no service
    /// is added. Successful restoration clears the saved registration, so a later
    /// stop begins a new pair. This restores registration, not a previous PID.
    ///
    /// - Throws: A launchctl or process error. The saved registration is retained
    ///   so this method can be retried.
    public static func restore() throws {
        try service.restore()
    }
}

@MainActor
final class IntelligenceTasksService {
    struct CommandResult {
        let exitStatus: Int32
        let output: String

        func requireSuccess(_ arguments: [String]) throws {
            guard exitStatus == 0 else {
                throw NSError(
                    domain: "WebKitTestWorkarounds.IntelligenceTasks",
                    code: Int(exitStatus),
                    userInfo: [NSLocalizedDescriptionKey:
                        "launchctl \(arguments.joined(separator: " ")) failed (\(exitStatus)): \(output)"]
                )
            }
        }
    }

    private static let domain = "user/foreground"
    private static let name = "com.apple.intelligencetasksd"
    private static let target = "\(domain)/\(name)"
    private let runCommand: @MainActor ([String]) throws -> CommandResult
    private var originalPath: String?

    init(run: @escaping @MainActor ([String]) throws -> CommandResult = IntelligenceTasksService.run) {
        runCommand = run
    }

    func stop() throws {
        guard let path = try registrationPath() else { return }
        if originalPath == nil { originalPath = path }
        let arguments = ["bootout", Self.target]
        try runCommand(arguments).requireSuccess(arguments)
    }

    func restore() throws {
        guard let originalPath else { return }
        if try registrationPath() == nil {
            let arguments = ["bootstrap", Self.domain, originalPath]
            try runCommand(arguments).requireSuccess(arguments)
        }
        self.originalPath = nil
    }

    private func registrationPath() throws -> String? {
        let arguments = ["print", Self.target]
        let result = try runCommand(arguments)
        if result.exitStatus == 113,
           result.output.contains("Could not find service \"\(Self.name)\"") {
            return nil
        }
        try result.requireSuccess(arguments)
        for line in result.output.split(separator: "\n") {
            let value = line.trimmingCharacters(in: .whitespaces)
            if value.hasPrefix("path = ") {
                return String(value.dropFirst("path = ".count))
            }
        }
        throw NSError(
            domain: "WebKitTestWorkarounds.IntelligenceTasks", code: 0,
            userInfo: [NSLocalizedDescriptionKey:
                "launchctl print did not include the service registration path: \(result.output)"]
        )
    }

    static func run(_ arguments: [String]) throws -> CommandResult {
        let result = try WKTWLaunchctl.run(arguments: arguments)
        return CommandResult(exitStatus: result.exitStatus, output: String(decoding: result.output, as: UTF8.self))
    }
}

#endif
