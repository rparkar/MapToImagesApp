//
//  Constants.swift
//  MapLocationCollections
//
//  Created by Rehan Parkar on 2018-03-15.
//  Copyright © 2018 Rehan Parkar. All rights reserved.
//

import Foundation

typealias CompletionHandler = (_ success: Bool) -> ()

let API_KEY = "548335eec518c65ada3111b3f1bcb4bd"

func flickrURL(forApiKey key: String, withAnnotation annotation: DroppablePin, andNumberOfPhotos number: Int ) -> String{
    
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(API_KEY)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
    
}
