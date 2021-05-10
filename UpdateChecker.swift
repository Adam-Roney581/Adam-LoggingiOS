//
//  UpdateChecker.swift
//  Logging
//
//  Created by John Bethancourt on 4/22/21.
//

import Foundation
import SwiftUI

class UpdateChecker {
    
    internal init(monitor: ConnectivityMonitor) {
        self.monitor = monitor
    }
    
    @Default(key: .lastReminded, initialValue: Date.init(timeIntervalSince1970: 0)) private var defaultLastReminded
    
    struct VersionInfo: Decodable {
        var latestVersion: String
        var updateMessage: String
        var showMessage: Bool
        
        init(data: Data) throws {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            self = try decoder.decode(VersionInfo.self, from: data)
        }
    }
    
    var monitor: ConnectivityMonitor
    
    func checkForUpdate(urlRequest: URLRequest = .version) {
        
        let hoursBetweenReminders = 24
        /// provide ample time for monitor to determine connectivity status.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            
            if !self.monitor.isConnected {
                print("not connected")
                return
            }
            print(#function)
            self.getVersionInfo (urlRequest: urlRequest) { [weak self] versionInfo in
                print(#function)
                if let self = self {
                    
                    if let versionInfo = versionInfo {
                        
                        let actualAppVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                        
                        if actualAppVersion?.compare(versionInfo.latestVersion, options: .numeric) == ComparisonResult.orderedAscending {
                            
                            if Date().timeIntervalSince(self.defaultLastReminded) > TimeInterval(hoursBetweenReminders) * 60 * 60 {
                                /// more than 24 hours since last reminded to update...
                                self.defaultLastReminded = Date()
                                
                                let okButton = Alert.Button.default(Text("Remind me later")) {
                                    // no - op
                                }
                                let howButton = Alert.Button.cancel(Text("Learn how to update")) {
                                    // This will never not be a valid URL, force unwrap okay.
                                    UIApplication.shared.open(URL(string: "https://airmencoders.us/projects/mqf/#how-do-i-update-the-app")!)
                                }
                                
                                // Append update message if there is one
                                var message = "Puckboard Logging Version \(versionInfo.latestVersion) is available and ready to install."
                                message += versionInfo.showMessage ? "\n\n What's New: \n \(versionInfo.updateMessage)" : ""
                                
                                let alert = Alert(title: Text("Update Available"), message: Text(message), primaryButton: okButton, secondaryButton: howButton)
                                
                                AlertProvider.shared.showAlert(alert)
                                
                            }
                            
                        }
                    }
                }
                
            }
        }
    }
    
    func getVersionInfo(urlRequest: URLRequest = .version, completion: @escaping (VersionInfo?) -> Void)  {
        print(#function)
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            print(#function)
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            completion(try? VersionInfo(data: data))
        }
        task.resume()
    }
    
    
}
