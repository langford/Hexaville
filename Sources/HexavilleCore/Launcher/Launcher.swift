//
//  main.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/16.
//
//

import Foundation
import AWSSDKSwift
import SwiftyJSON

public enum DeploymentStage {
    case staging
    case production
    case other(String)
    
    public init(string: String) {
        switch string {
        case DeploymentStage.staging.stringValue:
            self = .staging
        case DeploymentStage.production.stringValue:
            self = .production
        default:
            self = .other(string)
        }
    }
    
    public var stringValue: String {
        switch self {
        case .staging:
            return "staging"
        case .production:
            return "production"
        case .other(let stage):
            return stage
        }
    }
}

public enum LauncherError: Error {
    case swiftBuildFailed
    case cloudNotGenerateRoutingManifest
    case couldNotFindRootResource
    case missingRequiredParam(String)
}

public struct Routes {
    let endpoint: String
    let routes: [Route]
}

public struct Route {
    let method: [String]
    let resource: String
}

struct Resource {
    let pathPart: String
    let method: String?
    var apiGatewayResource: Apigateway.Resource?
    var apiGatewayParentResource: Apigateway.Resource?
}

struct DeployResult {
    let endpoint: String
}

public class Launcher {
    
    let provider: CloudLauncherProvider
    
    let hexavilleApplicationPath: String
    
    let executableTarget: String
    
    let deploymentStage: DeploymentStage
    
    let configuration: Configuration
    
    public init(hexavilleApplicationPath: String, executableTarget: String, configuration: Configuration, deploymentStage: DeploymentStage = .staging) {
        self.provider = configuration.createProvider()
        self.hexavilleApplicationPath = hexavilleApplicationPath
        self.executableTarget = executableTarget
        self.configuration = configuration
        self.deploymentStage = deploymentStage
    }
    
    public func showRoutes() throws {
        switch provider {
        case .aws(let launcher):
            let routes = try launcher.routes(deploymentStage: deploymentStage)
            print("Endpoint: \(routes.endpoint)")
            print("Routes:")
            for route in routes.routes {
                for method in route.method {
                    print("  \(method)    \(route.resource)")
                }
            }
        }
    }
    
    public func launch(debug: Bool = false, shouldDiscardCache: Bool = false) throws {
        switch provider {
        case .aws(let provider):
            try launchFor(aws: provider)
        }
    }
    
    private func swiftExecutablePath() -> String {
        if let home = ProcessInfo.processInfo.environment["SWIFT_HOME"] {
            return "\(home)/usr/bin/swift"
        }
        return "swift"
    }
    
    private func buildSwift() throws -> BuildResult {
        print("Building application....")
        let swiftBuildResult = Process.exec(swiftExecutablePath(), ["build", "--chdir", hexavilleApplicationPath])
        
        if swiftBuildResult.terminationStatus > 0 {
            throw LauncherError.swiftBuildFailed
        }
        
        print("Generating Routing Manifest file....")
        let genManifestResult = Process.exec("\(hexavilleApplicationPath)/.build/debug/\(executableTarget)", ["gen-routing-manif", hexavilleApplicationPath])
        
        if genManifestResult.terminationStatus > 0 {
            throw LauncherError.cloudNotGenerateRoutingManifest
        }
        print("Generated Routing Manifest file")
        
        let builder = SwiftBuilder()
        return try builder.build(config: configuration, hexavilleApplicationPath: hexavilleApplicationPath)
    }
    
    private func launchFor(aws provider: AWSLauncherProvider) throws {
        print("Start to build swift...")
        let result = try buildSwift()
        print("Build swift done.")
        
        let deployResult = try provider.deploy(
            deploymentStage: deploymentStage,
            buildResult: result,
            hexavilleApplicationPath: hexavilleApplicationPath,
            executableTarget: executableTarget
        )
        
        print("######################################################")
        print("Information")
        print("")
        print("ApplicationName: \(provider.appName)")
        print("Endpoint: \(deployResult.endpoint)")
        print("Stage: \(deploymentStage.stringValue)")
        print("")
        print("######################################################")
        
        print("All Done.")
    }
}


extension Configuration {
    func createProvider() -> CloudLauncherProvider {
        switch self.forPlatform {
        case .aws(let config):
            let provider = AWSLauncherProvider(
                appName: self.name,
                credential: config.credential,
                region: config.region,
                endpoints: config.endpoints,
                lambdaCodeConfig: config.lambdaCodeConfig
            )
            return .aws(provider)
        }
    }
}
