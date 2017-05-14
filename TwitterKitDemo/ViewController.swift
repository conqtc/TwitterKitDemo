//
//  ViewController.swift
//  TwitterKitDemo
//
//  Search controller is based on: 
//  https://www.thorntech.com/2016/01/how-to-search-for-location-using-apples-mapkit/
//
//  Created by Alex Truong on 5/14/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit
import MapKit
import TwitterKit

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    
    var curAnnotation: MKPointAnnotation?
    var curCoordinate: CLLocationCoordinate2D?
    var curSearchText: String = ""
    let regionRadius: CLLocationDistance = 1000
    
    var searchController: UISearchController? = nil
    var searchBar: UISearchBar?
    var savedTitleView: UIView?
    var savedSearchButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        mapView.delegate = self
        
        // search controller
        let locationSearchTable = storyboard?.instantiateViewController(withIdentifier: "LocationSearchController") as! LocationSearchController
        searchController = UISearchController(searchResultsController: locationSearchTable)
        searchController?.searchResultsUpdater = locationSearchTable
        
        locationSearchTable.mapView = mapView
        locationSearchTable.delegate = self
        
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true

        searchBar = searchController?.searchBar
        searchBar?.sizeToFit()
        searchBar?.placeholder = "Search location"
        searchBar?.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func locateCurrentLocation(_ sender: UIBarButtonItem) {
        locationManager.startUpdatingLocation()
    }
    
    func centerMapOnLocation(_ location: CLLocation?) {
        if let location = location {
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                      regionRadius,
                                                                      regionRadius)
            mapView.setRegion(coordinateRegion, animated: true)
        }
    }

    @IBAction func search(_ sender: UIBarButtonItem) {
        savedTitleView = navigationItem.titleView
        savedSearchButton = navigationItem.rightBarButtonItem
        navigationItem.rightBarButtonItem = nil
        navigationItem.titleView = searchBar
        searchBar?.becomeFirstResponder()
    }
    
    func restoreNavigationTitleView() {
        navigationItem.titleView = savedTitleView
        navigationItem.rightBarButtonItem = savedSearchButton
    }
}

extension ViewController: LocationSearchDelegate {
    func localtionSearch(didSelectWithMapItem item: MKMapItem) {
        mapView.removeAnnotations(mapView.annotations)
        
        curAnnotation = MKPointAnnotation()
        curCoordinate = item.placemark.coordinate
        
        curAnnotation?.coordinate = item.placemark.coordinate
        curSearchText = item.placemark.name ?? ""
        
        curAnnotation?.title = item.placemark.name
        if let city = item.placemark.locality, let state = item.placemark.administrativeArea {
            curAnnotation?.subtitle = "\(city), \(state)"
        }
        mapView.addAnnotation(curAnnotation!)

        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(item.placemark.coordinate, span)
        
        mapView.setRegion(region, animated: true)
        mapView.selectAnnotation(curAnnotation!, animated: true)
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        restoreNavigationTitleView()
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let kAnnotationViewReuseIdentifier = "CurrentLocationAnnotationView"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: kAnnotationViewReuseIdentifier)
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier:kAnnotationViewReuseIdentifier)
        }
        
        annotationView?.annotation = annotation
        annotationView?.canShowCallout = true
        annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        performSegue(withIdentifier: "displayTweets", sender: self)
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = locations.first {
            curCoordinate = location.coordinate
            centerMapOnLocation(location)
            locationManager.stopUpdatingLocation()

            mapView.removeAnnotations(mapView.annotations)
            
            curAnnotation = MKPointAnnotation()
            curAnnotation?.coordinate = location.coordinate
            curAnnotation?.title = "You are here"
            curAnnotation?.subtitle = "Click to view nearby tweets"
            curSearchText = ""
            
            mapView.addAnnotation(curAnnotation!)
            mapView.selectAnnotation(curAnnotation!, animated: true)
        }
    }
}

extension ViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? SearchTweetsViewController {
            controller.latitude = curCoordinate?.latitude ?? 0
            controller.longitude = curCoordinate?.longitude ?? 0
            controller.searchText = curSearchText
        }
    }
}
