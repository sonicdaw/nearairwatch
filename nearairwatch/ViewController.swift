//
//  ViewController.swift
//  nearairwatch
//
//  Created by msum on 2017/09/25.
//  Copyright © 2017年 entatonic. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var gpsText: UILabel!

    var locationManager: CLLocationManager! = nil
    var longitude: CLLocationDegrees!
    var latitude: CLLocationDegrees!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self.locationManager.requestAlwaysAuthorization()
            break
        case .authorizedWhenInUse:
            self.gpsText.text = "GPS When In Use"
            self.locationManager.startUpdatingLocation()
            if #available(iOS 9.0, *) {
                locationManager.requestLocation()
            }
            break
        case .authorizedAlways:
            self.gpsText.text = "GPS Always"
            self.locationManager.startUpdatingLocation()
            if #available(iOS 9.0, *) {
                locationManager.requestLocation()
            }
            break
        case .denied:
            self.gpsText.text = "GPS Not Authorized"
            break
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        let location = locations.first
        self.longitude = location?.coordinate.longitude
        self.latitude = location?.coordinate.latitude
        self.gpsText.text = String(format: "%.6f", latitude) + "," + String(format: "%.6f", longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.gpsText.text = "GPS Error"
    }
}

