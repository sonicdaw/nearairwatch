//
//  MapInterfaceController.swift
//  nearairwatch WatchKit Extension
//
//  Created by msum on 2017/12/10.
//  Copyright © 2017年 entatonic. All rights reserved.
//

import WatchKit
import Foundation


class MapInterfaceController: WKInterfaceController {

    @IBOutlet var mapView: WKInterfaceMap!
    var location: [String : Double] = [:]
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        guard let contextData = context else {
            popToRootController()
            return
        }
        
        self.location = contextData as! [String : Double]
        let latitude = location["latitude"]
        let longitude = location["longitude"]
        
        let mapLocation = CLLocationCoordinate2DMake(latitude!, longitude!)
        let coordinateSpan = MKCoordinateSpanMake(0.02, 0.02)
        
        self.mapView.addAnnotation(mapLocation, with: WKInterfaceMapPinColor.red)
        self.mapView.setRegion(MKCoordinateRegionMake(mapLocation, coordinateSpan))
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
