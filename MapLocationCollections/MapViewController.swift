//
//  MAPVC.swift
//  MapLocationCollections
//
//  Created by Rehan Parkar on 2018-03-14.
//  Copyright © 2018 Rehan Parkar. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self

    }

    
    @IBAction func centerMapButtonPressed(_ sender: Any) {
    }
    
}

extension MapViewController: MKMapViewDelegate {
    
}

