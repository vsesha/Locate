//
//  TripDestinations.swift
//  GoogleMapIntApp
//
//  Created by Vasudevan Seshadri on 1/23/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import GoogleMaps
import Foundation
class TripDestination: NSObject,CLLocationManagerDelegate {
    let name: String
    let snippet: String
    let location:CLLocationCoordinate2D
    let zoom: Float
    
    init(name: String, snippet: String, location:CLLocationCoordinate2D, zoom: Float) {
        self.name       = name
        self.snippet    = snippet
        self.location   = location
        self.zoom       = zoom
    }
}
/*
 fileprivate func initDestinations(){
 let zoom:Float = 15
 
 destinations += [TripDestination(  name: "Naperville", snippet: "Rt59",
 location: CLLocationCoordinate2DMake(41.781000, -88.206382),
 zoom: zoom)]
 
 destinations += [TripDestination(  name: "Lisle", snippet: "TrainStation",
 location: CLLocationCoordinate2DMake(41.799508, -88.076982),
 zoom: zoom)]
 
 destinations += [TripDestination(  name: "Downers Grove", snippet: "TrainStation",
 location: CLLocationCoordinate2DMake(41.808297, -88.007609),
 zoom: zoom)]
 
 destinations += [TripDestination(  name: "Chicago", snippet: "Union Station",
 location: CLLocationCoordinate2DMake(41.878682, -87.640237),
 zoom: zoom)]
 
 CurrTripDestination = destinations.first
 }
 */
