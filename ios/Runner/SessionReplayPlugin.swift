import Flutter
import UIKit
import Mixpanel
import MixpanelSessionReplay

class SessionReplayPlugin: NSObject {
    private var sessionReplayInstance: MPSessionReplay?
    
    override init() {
        super.init()
    }
    
    func initializeSessionReplay() {
        guard let mixpanel = Mixpanel.mainInstance() else { return }
        
        let config = MPSessionReplayConfig(
            wifiOnly: false,
            recordSessionsPercent: 100.0
        )
        
        sessionReplayInstance = MPSessionReplay.initialize(
            token: mixpanel.apiToken,
            distinctId: mixpanel.distinctId,
            config: config
        )
        
        sessionReplayInstance?.loggingEnabled = true
    }
    
    func startRecording() {
        sessionReplayInstance?.startRecording()
    }
    
    func stopRecording() {
        sessionReplayInstance?.stopRecording()
    }
    
    func setUserIdentifier(userId: String) {
        sessionReplayInstance?.setUserIdentifier(userId)
    }
    
    func markViewAsSensitive(viewId: String) {
        // Implementation for marking views as sensitive
        // This would need to be implemented based on your view hierarchy
    }
    
    func markViewAsSafe(viewId: String) {
        // Implementation for marking views as safe
        // This would need to be implemented based on your view hierarchy
    }
}

@objc class SessionReplayPluginHandler: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.miniaturepaintfinder/session_replay",
            binaryMessenger: registrar.messenger()
        )
        let instance = SessionReplayPluginHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let plugin = SessionReplayPlugin()
        
        switch call.method {
        case "initializeSessionReplay":
            plugin.initializeSessionReplay()
            result(nil)
            
        case "startRecording":
            plugin.startRecording()
            result(nil)
            
        case "stopRecording":
            plugin.stopRecording()
            result(nil)
            
        case "setUserIdentifier":
            if let args = call.arguments as? [String: Any],
               let userId = args["userId"] as? String {
                plugin.setUserIdentifier(userId: userId)
                result(nil)
            } else {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Invalid arguments for setUserIdentifier",
                    details: nil
                ))
            }
            
        case "markViewAsSensitive":
            if let args = call.arguments as? [String: Any],
               let viewId = args["viewId"] as? String {
                plugin.markViewAsSensitive(viewId: viewId)
                result(nil)
            } else {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Invalid arguments for markViewAsSensitive",
                    details: nil
                ))
            }
            
        case "markViewAsSafe":
            if let args = call.arguments as? [String: Any],
               let viewId = args["viewId"] as? String {
                plugin.markViewAsSafe(viewId: viewId)
                result(nil)
            } else {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Invalid arguments for markViewAsSafe",
                    details: nil
                ))
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
} 