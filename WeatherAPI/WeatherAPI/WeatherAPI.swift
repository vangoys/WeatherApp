//
//  WeatherAPI.swift
//  WeatherApp
//
//  Created by ivan piskun on 7/13/19.
//  Copyright © 2019 ivan piskun. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation

/// Manages the API for weather.
public class WeatherAPI {
    private enum Constants {
        static let baseUrl = "https://api.openweathermap.org/data/2.5/weather?"
        static let apiKey = "41028b6cde254cb205c4176062518ef8"
    }
    
    private enum PlaceMarkResult {
        case success(LocatioinString)
        case failure(Swift.Error)
    }
    
    public enum WeatherError: Swift.Error, CustomStringConvertible {
        case placemarkNotFound
        case invalidJsonReceived
        case serverError(String)
        
        public var description: String {
            switch self {
            case .invalidJsonReceived:
                return "Invalid json received from server."
            case .placemarkNotFound:
                return "Place not found."
            case .serverError(let message):
                return message
            }
        }
        
        public var localizedDescription: String {
            return description
        }
    }
    
    public enum WeatherResult {
        case success(LocationWeatherInfo)
        case failure(Error)
    }
    
    public typealias GetWeatherInfoCompletionBlock = (WeatherResult) -> Void
    private typealias GetAreaNameFromLocationCompletionBlock = (PlaceMarkResult) -> Void
    private typealias LocatioinString = String
    
    public var requestInProgress = false
    public var searchByAreaName = true
    
    //MARK: - Public methods
    
    public init() { }
    
    public func getWeather(location: CLLocation, completion: @escaping GetWeatherInfoCompletionBlock) {
        requestInProgress = true
        
        if searchByAreaName {
            getAreaNameFrom(location: location) { (result) in
                var url = Constants.baseUrl
                
                switch result {
                case .success(let locationString):
                    url = url.appending("q=\(locationString)")
                case .failure(_):
                    url = url.appending("lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)")
                }
                url = url.appending("&appid=\(Constants.apiKey)")
                
                self.actuallyFetchWeatherInformation(url: url, completion: completion)
            }
        } else {
            let url = "\(Constants.baseUrl)lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)"
            self.actuallyFetchWeatherInformation(url: url, completion: completion)
        }
    }
    
    //MARK: - Private methods
    
    private func actuallyFetchWeatherInformation(url: String, completion: @escaping GetWeatherInfoCompletionBlock) {
        Alamofire.request(url).responseJSON(completionHandler: { (response) in
            switch response.result {
            case .success(let json):
                if let json = json as? [String: Any] {
                    if let message = json["message"] as? String {
                        completion(.failure(WeatherError.serverError(message)))
                        return
                    }
                    let locationInfo = LocationWeatherInfo(json: json)
                    completion(.success(locationInfo))
                    self.requestInProgress = false
                } else {
                    completion(.failure(WeatherError.invalidJsonReceived))
                    self.requestInProgress = false
                }
            case .failure(let error):
                completion(.failure(error))
                self.requestInProgress = false
            }
        })
    }
    
    private func getAreaNameFrom(location: CLLocation, completion: @escaping GetAreaNameFromLocationCompletionBlock) {
        CLGeocoder().reverseGeocodeLocation(location, preferredLocale: nil) { (placemarks, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let placemark = placemarks?.first {
                var query = [String]()
                if let city = placemark.locality {
                    query.append(city)
                }
                if let country = placemark.country {
                    query.append(country)
                }
                
                if query.count > 0, let string = query.joined(separator: ",").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    completion(.success(string))
                } else {
                    completion(.failure(WeatherError.placemarkNotFound))
                }
            } else {
                completion(.failure(WeatherError.placemarkNotFound))
            }
        }
    }
}
