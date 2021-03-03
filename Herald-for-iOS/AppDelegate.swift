//
//  AppDelegate.swift
//
//  Copyright 2020 VMware, Inc.
//  SPDX-License-Identifier: Apache-2.0
//

import UIKit
import os
import Herald

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SensorDelegate {
    private let logger = Log(subsystem: "Herald", category: "AppDelegate")
    var window: UIWindow?

    // Payload data supplier, sensor and contact log
    var payloadDataSupplier: PayloadDataSupplier?
    var sensor: SensorArray?
    
    var phoneMode = true

    /// Generate unique and consistent device identifier for testing detection and tracking
    private func identifier() -> Int32 {
        if UserDefaults.standard.integer(forKey: "int32identifier") == 0 {
            let randUnsigned = arc4random()
            let randSigned = Int32(bitPattern: randUnsigned)
            UserDefaults.standard.set(randSigned, forKey: "int32identifier")
        }
        return Int32(UserDefaults.standard.integer(forKey: "int32identifier"))
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        logger.debug("application:didFinishLaunchingWithOptions")
        
        return true
    }
    
    func startPhone() {
        phoneMode = true
        payloadDataSupplier = ConcreteTestPayloadDataSupplier(identifier: identifier())
        sensor = SensorArray(payloadDataSupplier!)
        sensor?.add(delegate: self)
        addEfficacyLogging()
        sensor?.start()
        
        // EXAMPLE immediate data send function (note: NOT wrapped with Herald header)
        //let targetIdentifier: TargetIdentifier? // ... set its value
        //let success: Bool = sensor!.immediateSend(data: Data(), targetIdentifier!)
        
    }
    
    func stopPhone() {
        sensor?.stop()
    }
    
    func startBeacon(_ payloadSupplier: PayloadDataSupplier) {
        phoneMode = false
        sensor = SensorArray(payloadSupplier)
        
        // Add ourselves as delegate
        sensor?.add(delegate: self)
        addEfficacyLogging()
        sensor?.start()
    }
    
    func stopBeacon() {
        sensor?.stop()
    }
    
    public func stopBluetooth() {
        if phoneMode {
            stopPhone()
        } else {
            stopBeacon()
        }
    }

    // MARK:- Efficacy Logging

    func addEfficacyLogging() {
        if let payloadData = sensor?.payloadData {
            // Loggers
            sensor?.add(delegate: ContactLog(filename: "contacts.csv"))
            sensor?.add(delegate: StatisticsLog(filename: "statistics.csv", payloadData: payloadData))
            sensor?.add(delegate: DetectionLog(filename: "detection.csv", payloadData: payloadData))
            _ = BatteryLog(filename: "battery.csv")
            if (BLESensorConfiguration.payloadDataUpdateTimeInterval != .never ||
                (BLESensorConfiguration.interopOpenTraceEnabled && BLESensorConfiguration.interopOpenTracePayloadDataUpdateTimeInterval != .never)) {
                sensor?.add(delegate: EventTimeIntervalLog(filename: "statistics_didRead.csv", payloadData: payloadData, eventType: .read))
            }
        }
    }

    // MARK:- UIApplicationDelegate
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        logger.debug("applicationDidBecomeActive")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        logger.debug("applicationWillResignActive")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        logger.debug("applicationWillEnterForeground")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        logger.debug("applicationDidEnterBackground")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        logger.debug("applicationWillTerminate")
//        stopBluetooth()
    }
    
    // MARK:- SensorDelegate
    
    func sensor(_ sensor: SensorType, didDetect: TargetIdentifier) {
        logger.info(sensor.rawValue + ",didDetect=" + didDetect.description)
    }
    
    func sensor(_ sensor: SensorType, didRead: PayloadData, fromTarget: TargetIdentifier) {
        logger.info(sensor.rawValue + ",didRead=" + didRead.shortName + ",fromTarget=" + fromTarget.description)
    }
    
    func sensor(_ sensor: SensorType, didReceive: Data, fromTarget: TargetIdentifier) {
        logger.info(sensor.rawValue + ",didReceive=" + didReceive.base64EncodedString() + ",fromTarget=" + fromTarget.description)
    }
    
    func sensor(_ sensor: SensorType, didShare: [PayloadData], fromTarget: TargetIdentifier) {
        let payloads = didShare.map { $0.shortName }
        logger.info(sensor.rawValue + ",didShare=" + payloads.description + ",fromTarget=" + fromTarget.description)
    }
    
    func sensor(_ sensor: SensorType, didMeasure: Proximity, fromTarget: TargetIdentifier) {
        logger.info(sensor.rawValue + ",didMeasure=" + didMeasure.description + ",fromTarget=" + fromTarget.description)
    }
    
    func sensor(_ sensor: SensorType, didVisit: Location?) {
        logger.info(sensor.rawValue + ",didVisit=" + String(describing: didVisit))
    }
    
    func sensor(_ sensor: SensorType, didMeasure: Proximity, fromTarget: TargetIdentifier, withPayload: PayloadData) {
        logger.info(sensor.rawValue + ",didMeasure=" + didMeasure.description + ",fromTarget=" + fromTarget.description + ",withPayload=" + withPayload.shortName)
    }
    
    func sensor(_ sensor: SensorType, didUpdateState: SensorState) {
        logger.info(sensor.rawValue + ",didUpdateState=" + didUpdateState.rawValue)
    }

}

