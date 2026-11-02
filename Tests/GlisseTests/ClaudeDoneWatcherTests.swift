//
//  ClaudeDoneWatcherTests.swift
//  GlisseTests
//
//  The Claude-done tick fires once, only when a task actually finishes.
//

import XCTest
@testable import GlisseKit

final class ClaudeDoneWatcherTests: XCTestCase {

    func testTicksWhenRunningTaskFinishes() {
        XCTAssertTrue(ClaudeDoneWatcher.shouldTick(previous: "running", current: "done"))
        XCTAssertTrue(ClaudeDoneWatcher.shouldTick(previous: "waiting", current: "done"))
    }

    func testNoTickOnLaunchWithOldDoneState() {
        XCTAssertFalse(ClaudeDoneWatcher.shouldTick(previous: nil, current: "done"))
    }

    func testNoRepeatWhileStillDone() {
        XCTAssertFalse(ClaudeDoneWatcher.shouldTick(previous: "done", current: "done"))
    }

    func testNoTickForStopsOrWork() {
        XCTAssertFalse(ClaudeDoneWatcher.shouldTick(previous: "running", current: "stopped"))
        XCTAssertFalse(ClaudeDoneWatcher.shouldTick(previous: "done", current: "running"))
        XCTAssertFalse(ClaudeDoneWatcher.shouldTick(previous: "running", current: nil))
    }

    func testReadsStateFromStatusFile() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        try #"{"state": "done", "task": "x"}"#.write(to: url, atomically: true, encoding: .utf8)
        XCTAssertEqual(ClaudeDoneWatcher.readState(at: url), "done")
        XCTAssertNil(ClaudeDoneWatcher.readState(at: url.appendingPathExtension("missing")))
    }
}
