//
//  InterfaceController.swift
//  nearairwatch WatchKit Extension
//
//  Created by msum on 2017/09/25.
//  Copyright © 2017年 entatonic. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController,XMLParserDelegate {
    @IBOutlet var nearairText: WKInterfaceLabel!

    var currentElement:String = ""
    var parser = XMLParser()

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        let urlstr:String="https://entatonic.sakura.ne.jp/nearair/air.php?latitude=35.681382&longitude=139.766084"
        let url: URL = URL(string: urlstr)!
        
        parser = XMLParser(contentsOf: url)!
        parser.delegate = self

        let success:Bool = parser.parse()

        if success {
        } else {
        }
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        self.currentElement=elementName;
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if(self.currentElement=="text"){
            self.nearairText.setText(string)
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
