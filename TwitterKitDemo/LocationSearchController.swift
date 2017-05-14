//
//  LocationSearchController.swift
//  TwitterKitDemo
//
//  credit belongs to
//  https://www.thorntech.com/2016/01/how-to-search-for-location-using-apples-mapkit/
//
//  Created by Alex Truong on 5/14/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit
import MapKit

protocol LocationSearchDelegate: class {
    func localtionSearch(didSelectWithMapItem item: MKMapItem)
}

class LocationSearchController: UITableViewController {
    var delegate: LocationSearchDelegate?
    
    var matchingItems:[MKMapItem] = []
    var mapView: MKMapView? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath)

        // Configure the cell...
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = parseAddress(item: selectedItem)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingItems[indexPath.row]
        delegate?.localtionSearch(didSelectWithMapItem: selectedItem)
        dismiss(animated: true)
    }
    
    // parse address
    func parseAddress(item: MKPlacemark) -> String {
        var address = ""
        var precedented = false

        // street number
        if let subThoroughfare = item.subThoroughfare {
            address.append("\(subThoroughfare)")
            precedented = true
        }

        // street name
        if let thoroughfare = item.thoroughfare {
            if precedented {
                address.append(" ")
            }
            
            address.append("\(thoroughfare)")
            precedented = true
        }

        // city
        if let locality = item.locality {
            if precedented {
                address.append(", ")
            }
            
            address.append("\(locality)")
            precedented = true
        }
        
        // state
        if let administrativeArea = item.administrativeArea {
            if precedented {
                address.append(", ")
            }
            address.append("\(administrativeArea)")
        }
        
        return address
    }
}

extension LocationSearchController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView,
            let searchText = searchController.searchBar.text else { return }
        
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchText
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        
        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
}
