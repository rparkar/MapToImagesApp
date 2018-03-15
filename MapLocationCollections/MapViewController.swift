//
//  MAPVC.swift
//  MapLocationCollections
//
//  Created by Rehan Parkar on 2018-03-14.
//  Copyright © 2018 Rehan Parkar. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var locationManger = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManger.delegate = self
        configureLocationService()
        addDoubleTap()

    }

    
    @IBAction func centerMapButtonPressed(_ sender: Any) {
        
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            
            centerMapOnUserLocation()
        }
    }
    
    func addDoubleTap(){
        let doubleTap = UITapGestureRecognizer(target:self , action: #selector(dropPin))
        doubleTap.numberOfTapsRequired = 2
        //doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    @objc func dropPin(sender:UITapGestureRecognizer){
        removePin()
        //
        let touchPoint = sender.location(in: mapView) //cordinates on screen where u touch
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView) //converts to GPS coordinates
        
        //custpm subclass of
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        print("pin dropped")
    }
    
    func removePin () {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    
    //custpmise pin with custom color
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation { //if annot is users location
            return nil
        } else {
            let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
            pinAnnotation.pinTintColor = #colorLiteral(red: 0.9896476865, green: 0.6665952206, blue: 0.3434123397, alpha: 1)
            pinAnnotation.animatesDrop = true
            
            return pinAnnotation
        }
        

    }
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManger.location?.coordinate else {return}
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func configureLocationService(){
        
        if authorizationStatus == .notDetermined {
            locationManger.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}
