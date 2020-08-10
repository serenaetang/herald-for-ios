//
//  DetectionLog.swift
//  
//
//  Created  on 04/08/2020.
//  Copyright © 2020 . All rights reserved.
//

import Foundation
import UIKit

/// CSV contact log for post event analysis and visualisation
class DetectionLog: NSObject, SensorDelegate {
    private let logger = ConcreteSensorLogger(subsystem: "Sensor", category: "Data.DetectionLog")
    private let textFile: TextFile
    private let payloadData: PayloadData
    private let deviceName = UIDevice.current.name
    private let deviceOS = UIDevice.current.systemVersion
    private var payloads: Set<String> = []
    private let queue = DispatchQueue(label: "Sensor.Data.DetectionLog.Queue")
    
    init(filename: String, payloadData: PayloadData) {
        textFile = TextFile(filename: filename)
        self.payloadData = payloadData
    }
    
    private func csv(_ value: String) -> String {
        guard value.contains(",") else {
            return value
        }
        return "\"" + value + "\""
    }

    private func write() {
        let device = "\(deviceName) (iOS \(deviceOS))"
        var payloadList: [String] = []
        payloads.forEach() { payload in
            payloadList.append(payload)
        }
        payloadList.sort()
        var content = csv(device) + ",id=" + payloadData.shortName
        payloadList.forEach() { payload in
            content.append("," + payload)
        }
        content.append("\n")
        textFile.overwrite(content)
        logger.debug("write (content=\(content))")
    }
    
    // MARK:- SensorDelegate
    
    func sensor(_ sensor: SensorType, didDetect: TargetIdentifier) {
    }
    
    func sensor(_ sensor: SensorType, didRead: PayloadData, fromTarget: TargetIdentifier) {
        queue.async {
            if self.payloads.insert(didRead.shortName).inserted {
                self.logger.debug("didRead (payload=\(didRead.shortName))")
                self.write()
            }
        }
    }
    
    func sensor(_ sensor: SensorType, didMeasure: Proximity, fromTarget: TargetIdentifier) {
    }
    
    func sensor(_ sensor: SensorType, didShare: [PayloadData], fromTarget: TargetIdentifier) {
        didShare.forEach() { payloadData in
            queue.async {
                if self.payloads.insert(payloadData.shortName).inserted {
                    self.logger.debug("didShare (payload=\(payloadData.shortName))")
                    self.write()
                }
            }
        }
    }
    
    func sensor(_ sensor: SensorType, didVisit: Location) {
    }
    

}
