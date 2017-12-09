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
    var previous_longitude: CLLocationDegrees!
    var previous_latitude: CLLocationDegrees!
    var gpsAuthorized: Bool = false
    var serverAccessSkipCount = 0
    var nearairTexts:Array<String> = []
    var nearairTexts_index = 0
    var nearairPreviousTexts: String = ""
    var gpsUpdateTime: String = ""
    var backgroundUpdateTime: String = ""
    var nearAirUpdateTime: String = ""

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        locationManager = CLLocationManager()
        locationManager.delegate = self
        gpsOff()

        WKExtension.shared().delegate = self

        getNearAir()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        update_display()
        getNearAir()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func update_display() {
        if nearairTexts.count > 0 {
            self.nearairText.setText("B" + backgroundUpdateTime + " S" + nearAirUpdateTime + " G" + gpsUpdateTime + "/" + nearairTexts[nearairTexts_index])
            nearairTexts_index += 1
            if nearairTexts.count - 1 < nearairTexts_index {
                nearairTexts_index = 0
            }
        }
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                let formatter = DateFormatter()
                formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "HH:mm", options: 0, locale: Locale(identifier: "ja_JP"))
                self.backgroundUpdateTime = formatter.string(from: Date())
                
                backgroundTask.setTaskCompletedWithSnapshot(false)
                getNearAir()
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
            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "HH:mm", options: 0, locale: Locale(identifier: "ja_JP"))
            nearAirUpdateTime = formatter.string(from: Date())

            if nearairPreviousTexts != string {
                nearairTexts.removeAll()
                string!.enumerateLines { (line, stop) -> () in
                    if line != "" {
                        self.nearairTexts.append(self.nearAirUpdateTime + " " + line)
                    }
                }
                if nearairTexts.count > 0 {
                    update_display()
                    getGeoLocation(latitude: latitude,longitude: longitude)
                    nearairTexts_index = 0
                    previous_longitude = longitude
                    previous_latitude = latitude
                }
                nearairPreviousTexts = string!
            }
        } catch {
        }
    }
    
    func getNearAir() {
        if getDistanceFromPreviousLocation(latitude: self.latitude, longitude: self.longitude) > 10 || serverAccessSkipCount > 10{
            let config = URLSessionConfiguration.ephemeral
            config.waitsForConnectivity = true
            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            let task = session.downloadTask(with: URL(string: "https://entatonic.sakura.ne.jp/nearair/airwatch.php?latitude=" + String(format: "%.6f", latitude) + "&longitude=" + String(format: "%.6f", longitude))!)
            task.resume()

            serverAccessSkipCount = 0
        }else{
            serverAccessSkipCount += 1
        }
        
        scheduleNextUpdate()
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
        
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "HH:mm", options: 0, locale: Locale(identifier: "ja_JP"))
        gpsUpdateTime = formatter.string(from: Date())
        
        getNearAir()
        gpsOn()
    }
    
    func getDistanceFromPreviousLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> (Double){
        let currentLocation = CLLocation(latitude: latitude, longitude: longitude)
        let previousLocation = CLLocation(latitude: self.previous_latitude, longitude: self.previous_longitude)
        return previousLocation.distance(from:currentLocation)
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
        previous_longitude = longitude
        previous_latitude = latitude
        gpsAuthorized = false
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
