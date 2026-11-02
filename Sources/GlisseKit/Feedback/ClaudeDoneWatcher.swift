//
//  ClaudeDoneWatcher.swift
//  GlisseKit
//
//  Taps the trackpad when a Claude Code task finishes, so you feel it under
//  your finger without looking at the terminal. Reads the status file written
//  by the Claude Status hook (github.com/zacfink/claude-status):
//  ~/.claude-status/status.json, {"state": "running" | "waiting" | "done" | ...}.
//
//  Polls once a second instead of watching the file: the hook replaces the file
//  on every write, which breaks a file-descriptor watch.
//

import Foundation

public final class ClaudeDoneWatcher {

    public static let defaultURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude-status/status.json")

    private let url: URL
    private let onDone: () -> Void
    private var timer: Timer?
    private var lastState: String?

    public init(url: URL = ClaudeDoneWatcher.defaultURL, onDone: @escaping () -> Void) {
        self.url = url
        self.onDone = onDone
    }

    /// Only a task that was seen working and then finished counts. A "done"
    /// already on disk at launch, or one that stays "done", never taps.
    public static func shouldTick(previous: String?, current: String?) -> Bool {
        current == "done" && (previous == "running" || previous == "waiting")
    }

    public static func readState(at url: URL) -> String? {
        guard let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return obj["state"] as? String
    }

    public func start() {
        guard timer == nil else { return }
        lastState = Self.readState(at: url)
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in self?.poll() }
        t.tolerance = 0.2
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let state = Self.readState(at: url)
        if Self.shouldTick(previous: lastState, current: state) { onDone() }
        if state != nil { lastState = state }
    }
}
