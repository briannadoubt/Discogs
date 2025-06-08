import Foundation

/// Dependency container for managing service dependencies
public actor DependencyContainer {
    private var dependencies: [String: Any] = [:]
    
    /// Register a dependency
    public func register<T>(_ dependency: T, for type: T.Type) {
        let key = String(describing: type)
        dependencies[key] = dependency
    }
    
    /// Resolve a dependency
    public func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return dependencies[key] as? T
    }
    
    /// Resolve a required dependency (throws if not found)
    public func requireResolve<T>(_ type: T.Type) throws -> T {
        guard let dependency = resolve(type) else {
            throw DependencyError.dependencyNotFound(String(describing: type))
        }
        return dependency
    }
}

/// Errors that can occur during dependency resolution
/// 
/// This enum represents errors that can happen when resolving dependencies
/// from the dependency container.
public enum DependencyError: Error, LocalizedError {
    /// The requested dependency was not found in the container
    /// - Parameter String: The name of the missing dependency type
    case dependencyNotFound(String)
    
    /// Get a localized error description
    /// - Returns: A user-friendly error message
    public var errorDescription: String? {
        switch self {
        case .dependencyNotFound(let typeName):
            return "Dependency not found for type: \(typeName)"
        }
    }
}

/// Global dependency container instance
/// 
/// This is a shared dependency container that can be used throughout the application
/// for dependency injection. It provides a centralized way to manage dependencies.
public let Dependencies = DependencyContainer()
