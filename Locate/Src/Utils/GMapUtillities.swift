//
//  GMapUtillities.swift
//  GoogleMapIntApp
//
//  Created by Vasudevan Seshadri on 1/23/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import Foundation
import GoogleMaps



func drawPath()
{
    NSLog("drawPath:Enter")
    let path = GMSMutablePath()
    path.add(CLLocationCoordinate2DMake(41.781000, -88.206382))
    path.add(CLLocationCoordinate2DMake(41.799508, -88.076982))
    path.add(CLLocationCoordinate2DMake(41.808297, -88.007609))
    path.add(CLLocationCoordinate2DMake(41.878682, -87.640237))
    
    let rectangle           = GMSPolyline(path: path)
    rectangle.strokeWidth   = 2.0
    rectangle.map           = GLOBAL_MAP_VIEW
//    self.view = mapView
    
    
    NSLog("drawPath:Exit")
}

func drawTrack(originLocation: CLLocation, destinationlocation:CLLocation, color: String){
    let path = GMSMutablePath()
    
    let hue = GLOBAL_getHueCode(color: color)
    let color = UIColor(hue: hue, saturation: 1.0, brightness:1.0, alpha: 1.0)
    
    
    path.add(originLocation.coordinate)
    path.add(destinationlocation.coordinate)
    
    let line = GMSPolyline(path: path)
    line.strokeWidth    = 2
    line.geodesic       = true
    line.strokeColor    = color
    line.map            = GLOBAL_MAP_VIEW
}

func drawRouteMap(routes:[CLLocation]){
    
    let path = GMSMutablePath()
    for points in 0..<routes.count{
        path.add(routes[points].coordinate)
    }
    let line = GMSPolyline(path: path)
    line.strokeWidth = 1.0
    line.map = GLOBAL_MAP_VIEW
}

func drawRouteMap(routes:[LocationStruct]){
    
    let path = GMSMutablePath()
    for points in 0..<routes.count{
        let longitude = (routes[points].longitude! as NSString).doubleValue
        let latitude  = (routes[points].latitude! as NSString).doubleValue
        let location = CLLocation(latitude: latitude as CLLocationDegrees, longitude: longitude as CLLocationDegrees)
        path.add(location.coordinate)
    }
    let line = GMSPolyline(path: path)
    line.strokeWidth = 1.0
    line.map = GLOBAL_MAP_VIEW
}

func printAllGeoFenceMonitored(locationManager:CLLocationManager)
{
    for regions in locationManager.monitoredRegions {
        
            NSLog ("Region = \(regions.identifier)")
    }
}

func removeAllGeoFenceMonitored (locationManager:CLLocationManager) {
    for region in locationManager.monitoredRegions {
        locationManager.stopMonitoring(for: region)
    }

}

func setGeoFencePoint(locationManager:CLLocationManager,
                      location:CLLocation,
                      referencePoint: String) {
    
    NSLog("In setGeoFencePoint")
    // 1. check if system can monitor regions
    if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
        
        // 2. region data
        let title = referencePoint + GLOBAL_GEOFENCE_DISTANCE
        let inputcoordinate = location.coordinate
        let coordinate      = CLLocationCoordinate2DMake(inputcoordinate.latitude, inputcoordinate.longitude)
        
        let regionRadius = GLOBAL_getDistanceCodeMap(Distance: GLOBAL_GEOFENCE_DISTANCE )
        NSLog("regionRadius = \(regionRadius)")
        let geoFenceRadius = CLLocationDistance(regionRadius)
        
        // 3. setup region
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude), radius: geoFenceRadius, identifier: title)
        // locationManager.startMonitoring(for: region)
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
        {
         
            locationManager.startMonitoring(for: region)
            
        }
        else
        {
            //TODO: Create an alert telling the user that region tracking for this area is not available
            NSLog("Monitoring is not available for this region")
        }
        
        
        
        // 5. setup circle
        let circ = GMSCircle(position: coordinate, radius: geoFenceRadius)
        //let circle = MKCircle(centerCoordinate: coordinate, radius: regionRadius)
        
        circ.strokeColor = UIColor.blue
        circ.map = GLOBAL_MAP_VIEW
    }
    else {
        NSLog("System can't track regions")
    }
}

func locateOnMap(CurrTripDestination: TripDestination){
    NSLog("locate:Enter")
    CATransaction.begin()
    CATransaction.setValue(2, forKey: kCATransactionAnimationDuration)
    
    GLOBAL_MAP_VIEW.animate(to: GMSCameraPosition.camera(withTarget: CurrTripDestination.location, zoom: CurrTripDestination.zoom))
    
    let marker      = GMSMarker(position: CurrTripDestination.location)
    marker.title    = CurrTripDestination.name
    marker.snippet  = CurrTripDestination.snippet

    marker.map      = GLOBAL_MAP_VIEW
    CATransaction.commit()
    NSLog("locate:Exit")
}

func locateOnMapView(location: CLLocation){
    NSLog("locateOnMap using location: Enter")
    CATransaction.begin()
        CATransaction.setValue(2, forKey: kCATransactionAnimationDuration)
        let coordinate = CLLocationCoordinate2DMake(location.coordinate.latitude,location.coordinate.longitude)
        GLOBAL_MAP_VIEW.animate(to: GMSCameraPosition.camera(withTarget: coordinate, zoom: Float(GLOBAL_MAP_ZOOM)))
    CATransaction.commit()
    NSLog("locateOnMap using location: Exit")
    
}

func zoomMapView(){
    GLOBAL_MAP_VIEW.animate(toZoom: Float(GLOBAL_MAP_ZOOM))
}

func addMarker(location: CLLocation,  addressStr: String, color: String)
{
    CATransaction.begin()
    CATransaction.setValue(5, forKey: kCATransactionAnimationDuration)
        let coordinate = CLLocationCoordinate2DMake(location.coordinate.latitude,location.coordinate.longitude)
        let marker = GMSMarker(position: coordinate)
    
        marker.appearAnimation = kGMSMarkerAnimationPop
        marker.title = addressStr + " @ " + GLOBAL_GetCurrentTimeInStr()
        
        let hue     = GLOBAL_getHueCode(color: color)
        let color   = UIColor(hue: hue, saturation: 1.0, brightness:1.0, alpha: 1.0)
    
        marker.icon     = GMSMarker.markerImage(with: color)
        marker.opacity  = 0.8
    
        marker.map      = GLOBAL_MAP_VIEW
    let userLocation    = UserPinnedLocation(_userName: addressStr, _pinMarker: marker, _userLocation:location)
         GLOBAL_PINNED_LOCATION_LIST.append(userLocation)
    CATransaction.commit()

}

func removeMarker (_marker:GMSMarker){
    CATransaction.begin()
    CATransaction.setValue(5, forKey: kCATransactionAnimationDuration)
        _marker.map = nil
    CATransaction.commit()
}

func getLocation(withPlacemarks placemarks: [CLPlacemark]?, error: Error?) -> Any? {
    
    var location: CLLocation?
    var errorStr: String
    if let error = error {
        errorStr = "No result found "
        return errorStr
        
    } else {
        do{
            if let placemarks = placemarks, placemarks.count > 0 {
                location = placemarks.first?.location
            }
        
            if let location = location {
                //let coordinate = location.coordinate
               return location
            } else {
                
                errorStr = "No result found"
                return errorStr
            }
            
        }
        catch{
            errorStr = "No result found"
            return errorStr
        }
    }

}

func getLocationName(location: CLLocation) -> String {
print("Inside getLocationName")
    var placeName = "Unknown Location"
    CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
        print(location)
        
        if error != nil {
            print("Reverse geocoder failed with error" + (error?.localizedDescription)!)
            placeName = "Reverse geocoder failed with error"
            return
        }
        
        if placemarks!.count > 0 {
            let pm = placemarks![0] as! CLPlacemark
            print(pm.locality)
            placeName = pm.locality!
            
        }
        else {
            placeName = "Problem with the data received from geocoder"
            print("Problem with the data received from geocoder")
            
        }
    })
    print("Location Address = \(placeName)")
    return placeName
}

func getAddress(location: CLLocation, handler: @escaping (String) -> Void)
{
    var address: String = ""
    let geoCoder = CLGeocoder()
    
    print("location = \(location.coordinate.latitude)")
    
    //let location = CLLocation(latitude: selectedLat, longitude: selectedLon)
    //selectedLat and selectedLon are double values set by the app in a previous process
    
    geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
        
        print("In geoCoder.reverseGeocodeLocation")
        
        // Place details
        var placeMark: CLPlacemark?
        placeMark = placemarks?[0]
        
        print("placeMark.locality = \(placeMark?.locality)")
        print("placeMark = \(placeMark)")
        
        // Address dictionary
        //print(placeMark.addressDictionary ?? "")
        
        // Location name
        if let locationName = placeMark?.addressDictionary?["Name"] as? String {
            address += locationName + ", "
        }
        
        // Street address
        if let street = placeMark?.addressDictionary?["Thoroughfare"] as? String {
            address += street + ", "
        }
        
        // City
        if let city = placeMark?.addressDictionary?["City"] as? String {
            address += city + ", "
        }
        
        // Zip code
        if let zip = placeMark?.addressDictionary?["ZIP"] as? String {
            address += zip + ", "
        }
        
        // Country
        if let country = placeMark?.addressDictionary?["Country"] as? String {
            address += country
        }
        
        // Passing address back
        handler((placeMark?.locality)!)
    })
}




