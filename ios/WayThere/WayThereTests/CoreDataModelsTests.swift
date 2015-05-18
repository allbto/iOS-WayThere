//
//  MR_Tests.swift
//  WayThere
//
//  Created by Allan BARBATO on 5/17/15.
//  Copyright (c) 2015 Allan BARBATO. All rights reserved.
//

import Foundation
import XCTest
import MagicalRecord
import WayThere
import Nimble

class CoreDataModelsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()

        // Setup the default model from the current class' bundle
        MagicalRecord.setDefaultModelFromClass(CoreDataModelsTests.self)
        
        // Setup a default store
        MagicalRecord.setupCoreDataStackWithInMemoryStore()
        
        MagicalRecord.saveUsingCurrentThreadContextWithBlockAndWait { (context:NSManagedObjectContext!) -> Void in
            CD_City.MR_truncateAllInContext(context)
            CD_Wind.MR_truncateAllInContext(context)
            CD_Weather.MR_truncateAllInContext(context)
        }
    }
    
    override func tearDown() {
        MagicalRecord.cleanUp()
        
        super.tearDown()
    }
    
    func testCreateCity()
    {
        MagicalRecord.saveUsingCurrentThreadContextWithBlockAndWait { (context:NSManagedObjectContext!) -> Void in
            var city = CD_City.MR_createInContext(context) as? CD_City
            
            expect(city).toNot(beNil())
            
            city!.remoteId = "3067696"
            city!.name = "Prague"
            city!.country = "CZ"
            city!.coordinates = CD_Coordinates.MR_createInContext(context) as? CD_Coordinates
            city!.coordinates?.latitude = NSNumber(double: 50.09)
            city!.coordinates?.longitude = NSNumber(double: 14.42)

        }

        var city = CD_City.MR_findFirst() as? CD_City
        
        expect(city).toNot(beNil())
        expect(city!.remoteId).to(equal("3067696"))
        expect(city!.name).to(equal("Prague"))
        expect(city!.country).to(equal("CZ"))
        expect(city!.coordinates?.latitude?.doubleValue).to(equal(50.09))
        expect(city!.coordinates?.longitude?.doubleValue).to(equal(14.42))
        
        MagicalRecord.saveUsingCurrentThreadContextWithBlockAndWait { (context:NSManagedObjectContext!) -> Void in
            city!.MR_deleteInContext(context)
        }
        expect(CD_City.MR_findFirst()).to(beNil())
    }
    
    func testCreateWind()
    {
        MagicalRecord.saveUsingCurrentThreadContextWithBlockAndWait { (context:NSManagedObjectContext!) -> Void in
            var wind = CD_Wind.MR_createInContext(context) as? CD_Wind

            expect(wind).toNot(beNil())

            wind!.speed = 2.47
            wind!.degree = 214.501
        }
        
        var wind = CD_Wind.MR_findFirst() as? CD_Wind
        
        expect(wind).toNot(beNil())
        expect(wind!.speedMetric!.floatValue).to(equal(2.47))
        expect(wind!.speedImperial!.floatValue).to(beCloseTo(1.53, within: 0.01))
        expect(wind!.degrees!.floatValue).to(equal(214.501))
        expect(wind!.direction!).to(equal("SW"))
        
        wind!.degree = 0
        expect(wind!.direction!).to(equal("N"))

        wind!.degree = 180
        expect(wind!.direction!).to(equal("S"))

        wind!.degree = 12
        expect(wind!.direction!).to(equal("NNE"))

        MagicalRecord.saveUsingCurrentThreadContextWithBlockAndWait { (context:NSManagedObjectContext!) -> Void in
            wind!.MR_deleteInContext(context)
        }
        expect(CD_Wind.MR_findFirst()).to(beNil())
    }
    
    func testCreateWeather()
    {
        MagicalRecord.saveUsingCurrentThreadContextWithBlockAndWait { (context:NSManagedObjectContext!) -> Void in
            var weather = CD_Weather.MR_createInContext(context) as? CD_Weather
            
            expect(weather).toNot(beNil())
            
            weather!.title = "Clear"
            weather!.temp = 1
        }
        
        var weather = CD_Weather.MR_findFirst() as? CD_Weather
        
        expect(weather).toNot(beNil())
        expect(weather!.title).to(equal("Clear"))
        expect(weather!.tempCelcius!.floatValue).to(equal(1))
        expect(weather!.tempFahrenheit!.floatValue).to(equal(33.8))
        
        weather!.temp = 15
        expect(weather!.tempCelcius!.floatValue).to(equal(15))
        expect(weather!.tempFahrenheit!.floatValue).to(equal(59))

        weather!.temp = 34
        expect(weather!.tempCelcius!.floatValue).to(equal(34))
        expect(weather!.tempFahrenheit!.floatValue).to(equal(93.2))
        
        MagicalRecord.saveUsingCurrentThreadContextWithBlockAndWait { (context:NSManagedObjectContext!) -> Void in
            weather!.MR_deleteInContext(context)
        }
        expect(CD_Wind.MR_findFirst()).to(beNil())
    }
    
    func testConvertCDCityToCity()
    {
        func testCreateCity()
        {
            MagicalRecord.saveUsingCurrentThreadContextWithBlockAndWait { (context:NSManagedObjectContext!) -> Void in
                var city = CD_City.MR_createInContext(context) as? CD_City
                
                expect(city).toNot(beNil())
                
                city!.remoteId = "3067696"
                city!.name = "Prague"
                city!.country = "CZ"
                city!.coordinates = CD_Coordinates.MR_createInContext(context) as? CD_Coordinates
                city!.coordinates?.latitude = NSNumber(double: 50.09)
                city!.coordinates?.longitude = NSNumber(double: 14.42)
                
            }
            
            var cdCity = CD_City.MR_findFirst() as? CD_City
            
            expect(cdCity).toNot(beNil())
            
            var city = City(model: cdCity!)
            
            expect(city.remoteId).to(equal("3067696"))
            expect(city.name).to(equal("Prague"))
            expect(city.country).to(equal("CZ"))
            expect(city.coordinates?.latitude).to(equal(50.09))
            expect(city.coordinates?.longitude).to(equal(14.42))
            
            MagicalRecord.saveUsingCurrentThreadContextWithBlockAndWait { (context:NSManagedObjectContext!) -> Void in
                cdCity!.MR_deleteInContext(context)
            }
            expect(CD_City.MR_findFirst()).to(beNil())
        }
    }
}

