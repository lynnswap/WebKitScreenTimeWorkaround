#if os(iOS) && targetEnvironment(simulator)
import Foundation
import Testing
@testable import WebKitTestWorkarounds

@MainActor
@Suite(.serialized)
struct IntelligenceTasksWorkaroundTests {
    @Test
    func repeatedOperationsPreserveRegistrationAndRefreshTheNextSnapshot() throws {
        let job = LaunchdJob(path: "/runtime/first.plist")
        let service = IntelligenceTasksService(run: job.run)

        try service.stop()
        try service.stop()
        #expect(job.registeredPath == nil)
        try service.restore()
        try service.restore()
        #expect(job.registeredPath == "/runtime/first.plist")

        job.registeredPath = "/runtime/second.plist"
        try service.stop()
        try service.restore()
        #expect(job.registeredPath == "/runtime/second.plist")
    }

    @Test
    func anInitiallyAbsentServiceStaysAbsent() throws {
        let job = LaunchdJob(path: nil)
        let service = IntelligenceTasksService(run: job.run)

        try service.stop()
        try service.stop()
        try service.restore()
        #expect(job.registeredPath == nil)
    }

    @Test
    func failedBootstrapCanRestoreTheSavedRegistrationOnRetry() throws {
        let job = LaunchdJob(path: "/runtime/original.plist")
        let service = IntelligenceTasksService(run: job.run)
        try service.stop()
        job.failBootstrap = true

        #expect(throws: (any Error).self) { try service.restore() }
        #expect(job.registeredPath == nil)

        job.failBootstrap = false
        try service.restore()
        #expect(job.registeredPath == "/runtime/original.plist")
    }

    @Test
    func failedBootoutRetainsTheSnapshotAfterPartialRemoval() throws {
        let job = LaunchdJob(path: "/runtime/original.plist")
        let service = IntelligenceTasksService(run: job.run)
        job.failBootoutAfterRemoval = true

        #expect(throws: (any Error).self) { try service.stop() }
        #expect(job.registeredPath == nil)

        try service.restore()
        #expect(job.registeredPath == "/runtime/original.plist")
    }

    @Test
    func failedBootoutCanStopAndRestoreTheRegistrationOnRetry() throws {
        let job = LaunchdJob(path: "/runtime/original.plist")
        let service = IntelligenceTasksService(run: job.run)
        job.failBootoutBeforeRemoval = true

        #expect(throws: (any Error).self) { try service.stop() }
        #expect(job.registeredPath == "/runtime/original.plist")

        job.failBootoutBeforeRemoval = false
        try service.stop()
        #expect(job.registeredPath == nil)
        try service.restore()
        #expect(job.registeredPath == "/runtime/original.plist")
    }

    @Test
    func aServiceRestoredElsewhereIsNotRegisteredAgain() throws {
        let job = LaunchdJob(path: "/runtime/original.plist")
        let service = IntelligenceTasksService(run: job.run)
        try service.stop()
        job.registeredPath = "/runtime/external.plist"

        try service.restore()
        #expect(job.registeredPath == "/runtime/external.plist")

        try service.stop()
        try service.restore()
        #expect(job.registeredPath == "/runtime/external.plist")
    }

    @Test(arguments: [Int32(1), 113, 0])
    func anInvalidQueryPreservesTheSavedRegistration(exitStatus: Int32) throws {
        let job = LaunchdJob(path: "/runtime/original.plist")
        let service = IntelligenceTasksService(run: job.run)
        try service.stop()
        job.queryResult = .init(exitStatus: exitStatus, output: "Unexpected launchctl response")

        #expect(throws: (any Error).self) { try service.restore() }
        #expect(job.registeredPath == nil)

        job.queryResult = nil
        try service.restore()
        #expect(job.registeredPath == "/runtime/original.plist")
    }

    @Test
    func liveServiceStopAndRestorePreservesItsInitialRegistration() throws {
        let initial = try IntelligenceTasksService.run(["print", LaunchdJob.target])
        try #require(initial.exitStatus == 0 || initial.exitStatus == 113)
        let initialPath = registrationPath(in: initial.output)
        if initial.exitStatus == 0 {
            try #require(initialPath != nil)
        }
        defer {
            do {
                try IntelligenceTasksWorkaround.restore()
            } catch {
                Issue.record(error, "Failed to restore intelligencetasksd after the live test")
            }
        }

        try IntelligenceTasksWorkaround.stop()
        try IntelligenceTasksWorkaround.stop()
        let stopped = try IntelligenceTasksService.run(["print", LaunchdJob.target])
        #expect(stopped.exitStatus == 113)

        try IntelligenceTasksWorkaround.restore()
        try IntelligenceTasksWorkaround.restore()
        let restored = try IntelligenceTasksService.run(["print", LaunchdJob.target])
        #expect(restored.exitStatus == initial.exitStatus)
        #expect(registrationPath(in: restored.output) == initialPath)
    }

    private func registrationPath(in output: String) -> String? {
        output.split(separator: "\n").lazy.compactMap { line -> String? in
            let line = line.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("path = ") else { return nil }
            return String(line.dropFirst("path = ".count))
        }.first
    }
}

@MainActor
private final class LaunchdJob {
    static let domain = "user/foreground"
    static let target = "\(domain)/com.apple.intelligencetasksd"
    var registeredPath: String?
    var failBootstrap = false
    var failBootoutBeforeRemoval = false
    var failBootoutAfterRemoval = false
    var queryResult: IntelligenceTasksService.CommandResult?

    init(path: String?) {
        registeredPath = path
    }

    func run(_ arguments: [String]) throws -> IntelligenceTasksService.CommandResult {
        switch arguments.first {
        case "print":
            #expect(arguments == ["print", Self.target])
            if let queryResult { return queryResult }
            guard let registeredPath else {
                return .init(
                    exitStatus: 113,
                    output: "Could not find service \"com.apple.intelligencetasksd\" in domain for uid: 501"
                )
            }
            return .init(exitStatus: 0, output: "service = {\n\tpath = \(registeredPath)\n}")
        case "bootout":
            #expect(arguments == ["bootout", Self.target])
            if failBootoutBeforeRemoval {
                return .init(exitStatus: 1, output: "Boot-out failed")
            }
            registeredPath = nil
            return .init(
                exitStatus: failBootoutAfterRemoval ? 1 : 0,
                output: failBootoutAfterRemoval ? "Boot-out failed" : ""
            )
        case "bootstrap":
            guard arguments.count == 3 else { throw UnexpectedCommand() }
            #expect(arguments[1] == Self.domain)
            if failBootstrap {
                return .init(exitStatus: 1, output: "Bootstrap failed")
            }
            guard registeredPath == nil else { throw UnexpectedCommand() }
            registeredPath = arguments[2]
            return .init(exitStatus: 0, output: "")
        default:
            throw UnexpectedCommand()
        }
    }

    private struct UnexpectedCommand: Error {}
}
#endif
