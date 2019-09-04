//
//  GeoHashing.swift
//  GeoHashingOnMapKit
//
//  Created by ogulcan keskin on 4.09.2019.
//  Copyright © 2019 ogulcan keskin. All rights reserved.
//

import Foundation

struct Center {
    let latitude: Double
    let longitude: Double
}

final class GeoHashUtil {
    
    
    public static let shared = GeoHashUtil()
    
    private init() {
        
    }
    
    
    func getQueriesForDocumentsAround(center: Center, radius: Double = 10 * 1000) {
        let queryBits = max(1, boundingBoxBits(coordinate: center, size: radius))
        let geohashPrecision = ceil(queryBits / g_BITS_PER_CHAR)
        let coordinates = boundingBoxCoordinates(center, radius)
        
    }
    
    private func geohashQuery(_ geohash: Double, _ bits: Double) {
        //        validateGeohash(geohash);
        var precision = ceil(bits/g_BITS_PER_CHAR);
        if (geohash.length < precision) {
            console.warn("geohash.length < precision: "+geohash.length+" < "+precision+" bits="+bits+" g_BITS_PER_CHAR="+g_BITS_PER_CHAR);
            return [geohash, geohash+"~"];
        }
        geohash = geohash.substring(0, precision);
        var base = geohash.substring(0, geohash.length - 1);
        var lastValue = g_BASE32.indexOf(geohash.charAt(geohash.length - 1));
        var significantBits = bits - (base.length*g_BITS_PER_CHAR);
        var unusedBits = (g_BITS_PER_CHAR - significantBits);
        /*jshint bitwise: false*/
        // delete unused bits
        var startValue = (lastValue >> unusedBits) << unusedBits;
        var endValue = startValue + (1 << unusedBits);
        /*jshint bitwise: true*/
        if (endValue >= g_BASE32.length) {
//            console.warn("endValue > 31: endValue="+endValue+" < "+precision+" bits="+bits+" g_BITS_PER_CHAR="+g_BITS_PER_CHAR);
//            return [base+g_BASE32[startValue], base+"~"];
        }
        else {
            return [base+g_BASE32[startValue], base+g_BASE32[endValue]];
        }
    }
    
    private func encodeGeohash(_ location: Center, _ precision: Double) -> String {
        //    validateLocation(location);
        //    if (typeof precision !== "undefined") {
        //    if (typeof precision !== "number" || isNaN(precision)) {
        //    throw new Error("precision must be a number");
        //    }
        //    else if (precision <= 0) {
        //    throw new Error("precision must be greater than 0");
        //    }
        //    else if (precision > 22) {
        //    throw new Error("precision cannot be greater than 22");
        //    }
        //    else if (Math.round(precision) !== precision) {
        //    throw new Error("precision must be an integer");
        //    }
        //    }
        
        // Use the global precision default if no precision is specified
        //    precision = precision || g_GEOHASH_PRECISION;
        
        var latitudeRange: Range = -90..<91
        
        var longitudeRange: Range = -180..<181
        
        var hash = "";
        var hashVal = 0
        var bits = 0
        var even = false
        
        while (Double(hash.count) < precision) {
            var val = even ? location.longitude : location.latitude;
            var range = even ? longitudeRange : latitudeRange;
            var mid: Double = Double((range.min()! + range.max()!) / 2);
            
            /* jshint -W016 */
            if (val > mid) {
                hashVal = (hashVal << 1) + 1;
                range = Int(mid)..<range.max()! + 1
            }
            else {
                hashVal = (hashVal << 1) + 0
                range = range.min()!..<Int(mid+1)
            }
            /* jshint +W016 */
            
            even = !even;
            if (bits < 4) {
                bits += 1
            }
            else {
                bits = 0;
                hash += g_BASE32[hashVal]
                hashVal = 0
            }
        }
        
        return hash
    }
    private func boundingBoxBits(coordinate: Center, size: Double) -> Double {
        let latDeltaDegrees = size / g_METERS_PER_DEGREE_LATITUDE;
        let latitudeNorth = min(90, coordinate.latitude + latDeltaDegrees);
        let latitudeSouth = max(-90, coordinate.latitude - latDeltaDegrees);
        let bitsLat = floor(latitudeBitsForResolution(size))*2;
        let bitsLongNorth = floor(longitudeBitsForResolution(resolution: size, latitude: latitudeNorth))*2-1;
        let bitsLongSouth = floor(longitudeBitsForResolution(resolution: size, latitude: latitudeSouth))*2-1;
        return min(bitsLat, bitsLongNorth, bitsLongSouth, g_MAXIMUM_BITS_PRECISION);
    }
    
    private func boundingBoxCoordinates(_ center: Center, _ radius: Double) -> [[Double]] {
        let latDegrees = radius / g_METERS_PER_DEGREE_LATITUDE;
        let latitudeNorth = min(90, center.latitude + latDegrees);
        let latitudeSouth = max(-90, center.latitude - latDegrees);
        let longDegsNorth = metersToLongitudeDegrees(distance: radius, latitude: latitudeNorth);
        let longDegsSouth = metersToLongitudeDegrees(distance: radius, latitude: latitudeSouth);
        let longDegs = max(longDegsNorth, longDegsSouth);
        return [
            [center.latitude, center.longitude],
            [center.latitude, wrapLongitude(longitude: center.longitude - longDegs)],
            [center.latitude, wrapLongitude(longitude: center.longitude + longDegs)],
            [latitudeNorth, center.longitude],
            [latitudeNorth, wrapLongitude(longitude: center.longitude - longDegs)],
            [latitudeNorth, wrapLongitude(longitude: center.longitude + longDegs)],
            [latitudeSouth, center.longitude],
            [latitudeSouth, wrapLongitude(longitude: center.longitude - longDegs)],
            [latitudeSouth, wrapLongitude(longitude: center.longitude + longDegs)]
        ]
    }
    
    private func wrapLongitude(longitude: Double) -> Double {
        if (longitude <= 180 && longitude >= -180) {
            return longitude
        }
        let adjusted = longitude + 180;
        if (adjusted > 0) {
            return Double(adjusted.truncatingRemainder(dividingBy: 360)) - 180;
        }
        else {
            return 180.0 - (-adjusted.truncatingRemainder(dividingBy: 360))
        }
    }
    
    private func latitudeBitsForResolution(_ resolution: Double) -> Double {
        return min(logTwo(x: Double(g_EARTH_MERI_CIRCUMFERENCE / 2) / resolution), g_MAXIMUM_BITS_PRECISION);
        
    }
    
    private func longitudeBitsForResolution(resolution: Double, latitude: Double) -> Double {
        let degs = metersToLongitudeDegrees(distance: resolution, latitude: latitude);
        return (abs(degs) > 0.000001) ? max(1, logTwo(x: 360/degs)) : 1
    }
    
    private func metersToLongitudeDegrees(distance: Double, latitude: Double) -> Double {
        let radians = degreesToRadians(degrees: latitude);
        let num = cos(radians) * g_EARTH_EQ_RADIUS * .pi/180;
        let denom = 1 / sqrt(1 - g_E2 * sin(radians) * sin(radians))
        let deltaDeg = num*denom;
        if (deltaDeg  < g_EPSILON) {
            return distance > 0 ? 360 : 0;
        }
        else {
            return min(360, distance/deltaDeg);
        }
        
    }
    
    private func degreesToRadians(degrees: Double) -> Double {
        
        
        return (degrees * .pi / 180);
    }
    // Default geohash length
    private var g_GEOHASH_PRECISION: Double = 10;
    
    // Characters used in location geohashes
    private var g_BASE32 = ["0","1","2","3","4","5","6","7","8","9","b","c","d","e","f","g","h","j","k","m","n","p","q","r","s","t","u","v","w","x","y","z"];
    
    // The meridional circumference of the earth in meters
    private var g_EARTH_MERI_CIRCUMFERENCE: Double = 40007860;
    
    // Length of a degree latitude at the equator
    private var g_METERS_PER_DEGREE_LATITUDE: Double = 110574;
    
    // Number of bits per geohash character
    private var g_BITS_PER_CHAR: Double = 5;
    
    // Maximum length of a geohash in bits
    private lazy var g_MAXIMUM_BITS_PRECISION: Double = 22 * g_BITS_PER_CHAR;
    
    // Equatorial radius of the earth in meters
    private var g_EARTH_EQ_RADIUS: Double = 6378137.0;
    
    // The following value assumes a polar radius of
    // var g_EARTH_POL_RADIUS = 6356752.3;
    // The formulate to calculate g_E2 is
    // g_E2 == (g_EARTH_EQ_RADIUS^2-g_EARTH_POL_RADIUS^2)/(g_EARTH_EQ_RADIUS^2)
    // The exact value is used here to avoid rounding errors
    private var g_E2: Double = 0.00669447819799;
    
    // Cutoff for rounding errors on double calculations
    private var g_EPSILON: Double = 1e-12;
    
    private func logTwo(x: Double) -> Double {
        return log(x) / log(2);
    }
}


extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}
