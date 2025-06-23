// DiscogsEnvironment.swift
// Environment integration for Discogs API
import SwiftUI

private struct DiscogsKey: EnvironmentKey {
    static let defaultValue: Discogs? = nil
}

public extension EnvironmentValues {
    var discogs: Discogs! {
        get { self[DiscogsKey.self] }
        set { self[DiscogsKey.self] = newValue }
    }
}

/// A view modifier and helper to inject a Discogs instance into the environment
public extension View {
    /// Injects the given Discogs instance as an environment value for this view and its descendants
    /// - Parameter discogs: The Discogs API client to inject
    /// - Returns: A view with the Discogs instance in the environment
    func discogs(token: String) -> some View {
        environment(\.discogs, Discogs(token: token))
    }
}
