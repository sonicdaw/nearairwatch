//
//  InterfaceController.swift
//  nearairwatch WatchKit Extension
//
//  Created by msum on 2017/09/25.
//  Copyright © 2017年 entatonic. All rights reserved.
//

import WatchKit
import Foundation
import CoreLocation

class InterfaceController: WKInterfaceController,XMLParserDelegate, WKExtensionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate, CLLocationManagerDelegate {
    @IBOutlet var nearairText: WKInterfaceLabel!
    @IBOutlet var nearairLocation: WKInterfaceLabel!
    
    var locationManager: CLLocationManager! = nil
    var longitude: CLLocationDegrees!
    var latitude: CLLocationDegrees!
    var gpsAuthorized: Bool = false

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        locationManager = CLLocationManager()
        locationManager.delegate = self
        gpsOff()

        WKExtension.shared().delegate = self

        getNearAir()
        scheduleNextUpdate()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        getNearAir()
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
                scheduleNextUpdate()
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(true)
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
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: URL(string: "https://entatonic.sakura.ne.jp/nearair/airwatch.php?latitude=" + String(format: "%.6f", latitude) + "&longitude=" + String(format: "%.6f", longitude))!)
        task.resume()
    }
    
    func scheduleNextUpdate(){
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: 60/*sec*/), userInfo: nil) { (error: Error?) in
            if let error = error {
                self.nearairText.setText("scheduleBackgroundRefresh error: \(error.localizedDescription)")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self.locationManager.requestAlwaysAuthorization()
            gpsOff()
            break
        case .authorizedWhenInUse:
            self.locationManager.startUpdatingLocation()
            if #available(iOS 9.0, *) {
                locationManager.requestLocation()
            }
            gpsOn()
            break
        case .authorizedAlways:
            self.locationManager.startUpdatingLocation()
            if #available(iOS 9.0, *) {
                locationManager.requestLocation()
            }
            gpsOn()
            break
        case .denied:
            gpsOff()
            break
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        let location = locations.first
        self.longitude = location?.coordinate.longitude
        self.latitude = location?.coordinate.latitude
        getNearAir()
        getGeoLocation(latitude: latitude,longitude: longitude)
        gpsOn()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        gpsOff()
    }
    
    func gpsOn(){
        gpsAuthorized = true
    }
    
    func gpsOff(){
        longitude = 139.766084
        latitude = 35.681382
        gpsAuthorized = false
        getGeoLocation(latitude: latitude,longitude: longitude)
    }
    
    func getGeoLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees){
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            if error != nil {
                return
            }
            if placemarks!.count > 0 {
                let placemark = placemarks![0] as CLPlacemark
                if placemark.locality != nil {
                    if self.gpsAuthorized {
                        self.nearairLocation.setText(placemark.locality)
                    }else{
                        self.nearairLocation.setText("NoGPS " + placemark.locality!)
                    }
                }
            } else {
            }
        })
    }
}
