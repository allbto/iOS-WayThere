//
//  CitiesDataStore.swift
//  WayThere
//
//  Created by Allan BARBATO on 5/17/15.
//  Copyright (c) 2015 Allan BARBATO. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

protocol CitiesDataStoreDelegate
{
    func foundWeatherConfiguration(cities : [City])
    func unableToFindWeatherConfiguration(error: NSError)
    func foundCitiesForQuery(cities : [SimpleCity])
    func unableToFindCitiesForQuery(error: NSError?)
    
    func didSaveNewCity(city: City)
    func didRemoveCity(city: City)
}

class CitiesDataStore
{
    /// Vars
    
    let CountOfQueryResult = 5
    
    var delegate: CitiesDataStoreDelegate?
    var isQuerying = false
    var lastQuery : String?
    
    // Url
    
    let FindCitiesUrl = MainDataStore.BaseUrl + "/find"
    let FetchCityUrl = MainDataStore.BaseUrl + "/forecast/daily"
    
    /// Funcs
    
    func retrieveWeatherConfiguration()
    {
        delegate?.foundWeatherConfiguration(MainDataStore.retrieveCities())
    }
    
    /**
    Fetch api to find list of cities for given query string
    Has a block system allowing to delay the requests if one is already running
    For example, an user will write the name of the city, with a mistake, go back fix it then write the rest of name.
    To prevent a request to be sent everytime a letter is written, the func doesn't a request to be launched if there is already one in process
    In addition, the lastest query is saved and a request is sent when the first one is complete
    
    :param: query E.g. "Prag" if you want to look for Prague or similar (there is nothing similar to Prague ;) )
    */
    func retrieveCitiesForQuery(query : String)
    {
        if isQuerying {
            lastQuery = query
            return
        }

        isQuerying = true
        Alamofire.request(.GET, FindCitiesUrl, parameters: [
            "q" : query,
            "type" : "like",
            "sort" : "population",
            "cnt" : String(CountOfQueryResult)
            ])
            .responseJSON { [unowned self] (req, response, json, error) in
                println(req, json, error)

                // Call another query if there is a 'waiting list'
                if let query = self.lastQuery {
                    self.lastQuery = nil
                    self.isQuerying = false
                    self.retrieveCitiesForQuery(query)
                }
                else if (error == nil && json != nil) {
                    var json = JSON(json!)
                    var cities = [SimpleCity]()
                    
                    for (index, (sIndex : String, cityJSON : JSON)) in enumerate(json["list"]) {
                        if let id = cityJSON["id"].int, name = cityJSON["name"].string, country = cityJSON["sys"]["country"].string {
                            cities.append(SimpleCity(String(id), name, country))
                        }
                    }
                    self.delegate?.foundCitiesForQuery(cities)
                } else {
                    self.delegate?.unableToFindCitiesForQuery(error)
                }
                self.isQuerying = false
            }
    }
    
    /**
    Save city to CoreData
    Fetch the latest weather report for the city before saving it to CoreData
    If request fails the city is still saved, the forecast can be retrieved later on
    
    :param: city to save
    */
    func saveCity(city : SimpleCity)
    {
        Alamofire.request(.GET, MainDataStore.WeatherUrl, parameters: ["id" : city.id])
            .responseJSON { [unowned self] (req, response, json, error) in
                println(req, json, error)
                
                if let cityEntity = City.MR_createEntity() as? City {

                    cityEntity.remoteId = city.id

                    if (error == nil && json != nil) {
                        var json = JSON(json!)
                    
                        cityEntity.fromJson(json)
                    } else {
                        
                        cityEntity.name = city.name
                        cityEntity.country = city.country
                    }
                    CoreDataHelper.saveAndWait()
                    self.delegate?.didSaveNewCity(cityEntity)
                }
            }
    }

    /**
    Remove city from CoreData
    
    :param: city to remove
    */
    func removeCity(city : City)
    {
        if let cityEntity = City.MR_findFirstByAttribute("remoteId", withValue: city.remoteId) as? City {
            cityEntity.MR_deleteEntity()
            CoreDataHelper.saveAndWait()
            self.delegate?.didRemoveCity(cityEntity)
        }
    }
}

