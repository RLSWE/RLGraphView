//
//  ViewController.swift
//  GraphsExample
//
//  Created by Roni Leshes on 05/07/2017.
//  Copyright © 2017 Roni Leshes. All rights reserved.
//

import UIKit

class ViewController: UIViewController, RLGraphViewDataSource {
    
    @IBOutlet weak var graphView: RLGraphView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.graphView.dataSource = self
        self.graphView.xAxisDescriptionText = "Months"
        self.graphView.yAxisDescriptionText = "Weight (kg)"
        self.graphView.edgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //====================================
    //MARK: GraphView Datasource
    //====================================
    func yAxisValues(for graphView: RLGraphView!) -> [Any]! {
        return [0.0,0.5,1.0,1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0] //Kilograms
    }
    func xAxisValues(for graphView: RLGraphView!) -> [Any]! {
        return [1,2,3,4,5,6,7,8,9,10,11,12] //Months
    }
    func numberOfGraphLines(in graphView: RLGraphView!) -> Int {
        return 1
    }
    func graphView(_ graphView: RLGraphView!, dataArrayForGraphLineAt lineIndex: Int) -> [Any]! {
        
        return [0.2,0.4,0.5,0.8,0.9,1.1,1.3,1.6,1.9,2.4,2.7,3.2]
        
    }
    func shouldShowNumberLabels(in graphView: RLGraphView!) -> Bool {
        return true
    }
    func shouldDrawIdentifierAtTheOfLines(in graphView: RLGraphView!) -> Bool {
        return true
    }
    func graphView(_ graphView: RLGraphView!, graphLineAttributesForLineAt lineIndex: Int) -> [AnyHashable : Any]! {
        return [kGraphLineAttributeColor:UIColor.blue,
                kGraphLineAttributeWidth:2.0,
                kGraphLineAttributeIdentifier:"Mittens"]
    }
    func xAxisSeparatorInterval(for graphView: RLGraphView!) -> Int {//Draw thicker vertical line each interval
        return 2
    }
}

