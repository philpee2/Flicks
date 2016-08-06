//
//  ImageUtils.swift
//  Flicks
//
//  Created by phil_nachum on 8/4/16.
//  Copyright © 2016 phil_nachum. All rights reserved.
//

import Foundation
import UIKit
import AFNetworking

func getImageUrl(posterPath: String, isSmall: Bool = false) -> String {
    let size = isSmall ? "92" : "500"
    let baseImageUrl = "http://image.tmdb.org/t/p/w\(size)"
    return baseImageUrl + posterPath
}

func setImage(posterPath: String, posterView: UIImageView) {
    let smallImageRequest = NSURLRequest(URL: NSURL(string: getImageUrl(posterPath, isSmall: true))!)
    let largeImageRequest = NSURLRequest(URL: NSURL(string: getImageUrl(posterPath, isSmall: false))!)

    posterView.setImageWithURLRequest(
        smallImageRequest,
        placeholderImage: nil,
        success: { (smallImageRequest, smallImageResponse, smallImage) -> Void in

            // smallImageResponse will be nil if the smallImage is already available
            // in cache (might want to do something smarter in that case).
            posterView.alpha = 0.0
            posterView.image = smallImage

            UIView.animateWithDuration(0.3, animations: { () -> Void in

                posterView.alpha = 1.0

                }, completion: { (sucess) -> Void in

                    // The AFNetworking ImageView Category only allows one request to be sent at a time
                    // per ImageView. This code must be in the completion block.
                    posterView.setImageWithURLRequest(
                        largeImageRequest,
                        placeholderImage: smallImage,
                        success: { (largeImageRequest, largeImageResponse, largeImage) -> Void in

                            posterView.image = largeImage

                        },
                        failure: { (request, response, error) -> Void in
                    })
            })
        },
        failure: { (request, response, error) -> Void in
    })
}

func fetchDataHelper(url: String, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
    let request = NSURLRequest(
        URL: NSURL(string: url)!,
        cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
        timeoutInterval: 10)
    
    let session = NSURLSession(
        configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
        delegate: nil,
        delegateQueue: NSOperationQueue.mainQueue()
    )
    
    let task: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: completionHandler)
    task.resume()
}

func formatDate(dateString: String, inputFormat: String, outputFormat: String) -> String {
    // Copied from http://stackoverflow.com/a/32104865/4318086
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = inputFormat
    let date = dateFormatter.dateFromString(dateString)
    
    dateFormatter.dateFormat = outputFormat
    dateFormatter.timeZone = NSTimeZone(name: "UTC")
    return dateFormatter.stringFromDate(date!)
}