//
//  WeatherDetailViewController.swift
//  WeatherApp
//
//  Created by ivan piskun on 7/13/19.
//  Copyright © 2019 ivan piskun. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
//import WeatherAPI

class WeatherDetailViewController: UIViewController {
    
    private enum Constants {
        static let cameraAltitude = CLLocationDistance(400)
        static let cameraPitch = CGFloat(0)
        static let cameraHeading = CLLocationDirection(0)
    }
    
    var location: CLLocation?
    @IBOutlet var tableView: UITableView!
    @IBOutlet var mapView: MKMapView!
    
    private let weatherApi = WeatherAPI()
    private let loader = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    private let datasource = WeatherDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loader.hidesWhenStopped = true
        let barItem = UIBarButtonItem(customView: loader)
        self.navigationItem.rightBarButtonItem = barItem
        loader.startAnimating()
        
        tableView.dataSource = datasource
        tableView.delegate = datasource
        tableView.tableFooterView = UIView()
        
        updateMap()
        fetchWeatherData()
    }
    
    private func fetchWeatherData() {
        guard let location = location else {
            return
        }
        weatherApi.getWeather(location: location) { (result) in
            switch result {
            case .success(let location):
                if let name = location.locationName {
                    self.title = name
                }
                self.datasource.locationInfo = location
                self.tableView.reloadData()
            case .failure(let err):
                var description = err.localizedDescription
                if let weatherError = err as? WeatherAPI.WeatherError {
                    description = weatherError.description
                }
                
                let alert = UIAlertController(title: "Error", message: description, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            self.loader.stopAnimating()
        }
    }
    
    private func updateMap() {
        guard let location = location else {
            return
        }
        
        let camera = MKMapCamera(lookingAtCenter: location.coordinate, fromDistance: Constants.cameraAltitude, pitch: Constants.cameraPitch,
                                 heading: Constants.cameraHeading)
        mapView.setCamera(camera, animated: false)
        
       
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        mapView.addAnnotation(annotation)
    }
}
