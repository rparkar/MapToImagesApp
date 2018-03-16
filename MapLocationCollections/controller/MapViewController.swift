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

    @IBOutlet weak var pullUpVIewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapViewBottomConstraint: NSLayoutConstraint!
    
    var locationManger = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    
    var spinner: UIActivityIndicatorView?
    var progressLabel: UILabel?
    var screenSize = UIScreen.main.bounds
    
    var collectionView: UICollectionView?
    var flowLayout = UICollectionViewFlowLayout() //needed when programticly making collectionview
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManger.delegate = self
        configureLocationService()
        addDoubleTap()

        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        
        pullUpView.addSubview(collectionView!)
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
    
    func addSwipe() {
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    
    
    func animateViewUp(){
        
        pullUpVIewHeightConstraint.constant = 300
        UIView.animate(withDuration: 0.3) {
            
             self.view.layoutIfNeeded() //redraws everthing again
        }
       
        
    }
    
    @objc func animateViewDown(){
        
        pullUpVIewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        

    }
    
    func addSpinner(){
        
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner(){
        
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLable(){
        progressLabel = UILabel()
        progressLabel?.frame = CGRect(x: (screenSize.width / 2) - 125 , y: 175, width: 250, height: 40)
        progressLabel?.font = UIFont(name: "AvenirNext", size: 18)
        progressLabel?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLabel?.textAlignment = .center
        progressLabel?.text = "x/y Photos Loaded"
        collectionView?.addSubview(progressLabel!)
        
    }
    
    func removeProgressLable(){
        
        if progressLabel != nil {
            progressLabel?.removeFromSuperview()
        }
    }
    
    @objc func dropPin(sender:UITapGestureRecognizer){
        removePin()
        removeSpinner()
        removeProgressLable() //to prevent multiple spinners and label
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLable()
        
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

extension MapViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell
        return cell!
    }
}






