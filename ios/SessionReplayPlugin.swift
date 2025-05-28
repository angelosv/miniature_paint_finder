import Flutter
import UIKit
import Mixpanel
import MixpanelSessionReplay

class SessionReplayPlugin: NSObject {
    private var sessionReplayInstance: MPSessionReplayInstance?
    private let mixpanelToken = "570d806261b36af574266b6256137b0d"
    
    override init() {
        super.init()
    }
    
    func initializeSessionReplay() {
        print("🎬 Initializing Session Replay...")
        
        let mixpanel = Mixpanel.mainInstance()
        
        let config = MPSessionReplayConfig(
            wifiOnly: false,
            recordSessionsPercent: 100.0
        )
        
        print("🎬 Session Replay config created - WiFi only: false, Record %: 100")
        
        sessionReplayInstance = MPSessionReplay.initialize(
            token: mixpanelToken,
            distinctId: mixpanel.distinctId,
            config: config
        )
        
        if sessionReplayInstance != nil {
            print("✅ Session Replay initialized successfully")
            print("🎬 Distinct ID: \(mixpanel.distinctId)")
        } else {
            print("❌ Session Replay initialization failed")
        }
        
        // Enable logging if available
        #if DEBUG
        print("🎬 Debug mode - enabling logging")
        #endif
    }
    
    func startRecording() {
        print("🎬 Starting Session Replay recording...")
        
        guard let instance = MPSessionReplay.getInstance() else {
            print("❌ Session Replay: No instance found when trying to start recording")
            return
        }
        
        instance.startRecording()
        print("✅ Session Replay recording started")
        
        // Force a screenshot capture to test
        instance.captureScreenshot()
        print("📸 Manual screenshot captured")
    }
    
    func stopRecording() {
        print("🎬 Stopping Session Replay recording...")
        
        guard let instance = MPSessionReplay.getInstance() else {
            print("❌ Session Replay: No instance found when trying to stop recording")
            return
        }
        
        instance.stopRecording()
        print("✅ Session Replay recording stopped")
    }
    
    func setUserIdentifier(userId: String) {
        print("🎬 Setting user identifier: \(userId)")
        // Session Replay automatically uses the Mixpanel distinct ID
        // The user identification is handled by the main Mixpanel instance
    }
    
    func markViewAsSensitive(viewId: String) {
        print("🎬 Marking view as sensitive: \(viewId)")
        // Implementation for marking views as sensitive
        // This would need to be implemented based on your view hierarchy
    }
    
    func markViewAsSafe(viewId: String) {
        print("🎬 Marking view as safe: \(viewId)")
        // Implementation for marking views as safe
        // This would need to be implemented based on your view hierarchy
    }
    
    func getReplayId() -> String? {
        print("🎬 Getting Replay ID...")
        print("⚠️ getReplayId not available in this SDK version")
        return nil
    }
    
    func captureScreenshot() {
        print("📸 Manually capturing screenshot...")
        
        guard let instance = MPSessionReplay.getInstance() else {
            print("❌ Session Replay: No instance found when trying to capture screenshot")
            return
        }
        
        instance.captureScreenshot()
        print("✅ Manual screenshot captured")
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
            
        case "getReplayId":
            let replayId = plugin.getReplayId()
            result(replayId)
            
        case "captureScreenshot":
            plugin.captureScreenshot()
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
} 