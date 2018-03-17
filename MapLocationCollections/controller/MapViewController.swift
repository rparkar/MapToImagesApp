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
import Alamofire
import AlamofireImage


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
    
    //array of URLs
    var imageURLArray = [String]()
    var imageArray = [UIImage]()
    
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
        collectionView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        //for 3D touch previewing
        registerForPreviewing(with: self, sourceView: collectionView!)
        
        pullUpView.addSubview(collectionView!)
    }

    
    @IBAction func centerMapButtonPressed(_ sender: Any) {
        
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            
            centerMapOnUserLocation()
        }
    }
    
    func addDoubleTap(){
        cancelAllSession()
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
       // progressLabel?.text = "x/y Photos Loaded"
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
        cancelAllSession() // remove the old pin session when a new pin is dropper
        
        //to remove and add images of new location
        imageURLArray = []
        imageArray = []
        collectionView?.reloadData()
        
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
        
        retrieveURLS(forAnnotation: annotation) { (finished) in
            
            if finished == true {
                self.retrieveImage(completionHandler: { (finished) in
                    
                    if finished{
                        self.spinner?.isHidden = true
                        self.removeProgressLable()
                        self.collectionView?.reloadData() //reload to show images
                        
                    }
                })
            }
            
        }
        
    }
    
    func removePin () {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func retrieveURLS(forAnnotation annotation: DroppablePin, completionHandler: @escaping CompletionHandler){
        
       // imageURLArray = []
        
        Alamofire.request(flickrURL(forApiKey: API_KEY, withAnnotation: annotation, andNumberOfPhotos: 40)).responseJSON { (response) in
            
            print(response)
            guard let json = response.result.value as? Dictionary<String, AnyObject> else {return}
            
            let photosDict = json["photos"] as! Dictionary<String, AnyObject>
            let photosDictArray = photosDict["photo"] as! [Dictionary<String, AnyObject>]
            
            for photo in photosDictArray {
                let postURL = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                self.imageURLArray.append(postURL)
            }
            
            completionHandler(true)
        }
        
    }
    
    func retrieveImage(completionHandler: @ escaping CompletionHandler){
       // imageArray = [] //clearing out previous images
        
        for url in imageURLArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                
                guard let image = response.result.value else {return}
                self.imageArray.append(image)
                self.progressLabel?.text = "\(self.imageArray.count)/40 images downloaded"
                
                //check if counts are equal in both arrays
                if self.imageArray.count == self.imageURLArray.count {
                    completionHandler(true)
                }
            })
            
        }
        
    }
    
    //cancel all the sessions when swipe down
    func cancelAllSession() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            
            sessionDataTask.forEach({$0.cancel() })
            downloadData.forEach({$0.cancel()})
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
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else {return UICollectionViewCell()}
        
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        cell.addSubview(imageView)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopViewController else {return}
        
        popVC.initData(image: imageArray[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
}

//3D touch class
extension MapViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexpath = collectionView?.indexPathForItem(at: location) else {return nil}
        guard let cell = collectionView?.cellForItem(at: indexpath) else {return nil}
        
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopViewController else {return nil}
        popVC.initData(image: imageArray[indexpath.row])
        
        previewingContext.sourceRect = cell.contentView.frame //show what actual image looks like
        return popVC
    
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        show(viewControllerToCommit, sender: self)
    }
}






