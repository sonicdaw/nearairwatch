//
//  InterfaceController.swift
//  nearairwatch WatchKit Extension
//
//  Created by msum on 2017/09/25.
//  Copyright © 2017年 entatonic. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    @IBOutlet var nearairText: WKInterfaceLabel!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        self.nearairText.setText("Hello NearAir")
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
