//
//  SensorValue+Mock.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/04.
//

import Foundation
import nRFMeshProvision

// swiftlint:disable number_separator
enum MockValue {
    static func sensorValues() -> [SensorValue] {
        return [
            (
                property: .presenceDetected,
                value: .bool(Bool.random())
            ), // presence
            (
                property: .precisePresentAmbientTemperature,
                value: .temperature(Decimal(Double.random(in: 20 ... 30)))
            ), // temperature
            (
                property: .presentAmbientRelativeHumidity,
                value: .percentage8(Decimal(Double.random(in: 30 ... 40)))
            ), // humidity
            (
                property: .airPressure,
                value: .pressure(Decimal(Double.random(in: 102000 ... 108000)))
            ) // air pressure
        ]
    }
}

// swiftlint:enable number_separator
