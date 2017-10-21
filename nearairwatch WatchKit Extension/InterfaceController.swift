//
//  InterfaceController.swift
//  nearairwatch WatchKit Extension
//
//  Created by msum on 2017/09/25.
//  Copyright © 2017年 entatonic. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController,XMLParserDelegate, WKExtensionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    @IBOutlet var nearairText: WKInterfaceLabel!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        getNearAir()
        WKExtension.shared().delegate = self
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: 30/*sec*/), userInfo: nil) { (error: Error?) in
            if let error = error {
                self.nearairText.setText("scheduleBackgroundRefresh error: \(error.localizedDescription)")
            }
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                getNearAir()
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let data = try Data(contentsOf: location)
            let string = String(data: data, encoding: .utf8)
            let formatter = DateFormatter()
            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "dMMMHH:mm", options: 0, locale: Locale(identifier: "ja_JP"))
            self.nearairText.setText(formatter.string(from: Date()) + "\r" + string!)
        } catch {
        }
    }
    
    func getNearAir() {
        let config = URLSessionConfiguration.background(withIdentifier: "nearairSessionIdentifier")
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: URL(string: "https://entatonic.sakura.ne.jp/nearair/airwatch.php?latitude=35.681382&longitude=139.766084")!)
        task.resume()
    }
}
