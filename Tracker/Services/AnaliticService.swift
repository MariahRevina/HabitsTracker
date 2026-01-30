import Foundation
import AppMetricaCore

final class AnalyticsService {
    static func activate() {
        guard let configuration = AppMetricaConfiguration(apiKey: "427a86f5-f835-4bdc-adf0-4ea77d6e20b2") else { return }
        AppMetrica.activate(with: configuration)
    }

    static func report(event: String, screen: String, item: String? = nil) {
        var params: [AnyHashable: Any] = [
            "event": event,
            "screen": screen
        ]
        
        if let item = item {
            params["item"] = item
        }
        AppMetrica.reportEvent(name: "analytics_event", parameters: params, onFailure: { error in
            print("REPORT ERROR: \(error.localizedDescription)")
        })
        print("Analytics Event: \(params)")
    }
    
    static func reportMainScreenOpen() {
        report(event: "open", screen: "Main")
    }
    
    static func reportMainScreenClose() {
        report(event: "close", screen: "Main")
    }
    
    static func reportAddTrack() {
        report(event: "click", screen: "Main", item: "add_track")
    }
    
    static func reportTrackTap() {
        report(event: "click", screen: "Main", item: "track")
    }
    
    static func reportFilterTap() {
        report(event: "click", screen: "Main", item: "filter")
    }
    
    static func reportEditContext() {
        report(event: "click", screen: "Main", item: "edit")
    }
    
    static func reportDeleteContext() {
        report(event: "click", screen: "Main", item: "delete")
    }
    
}
