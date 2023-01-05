//
//  KonashiPeripheral+Notification.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2022/02/23.
//

import Foundation

public extension KonashiPeripheral {
    /// A notification that posts immediately after the peripheral is initialized.
    static let readyToUse = Notification.Name("Peripheral.readyToUseNotification")
    /// A notification that posts immediately after the peripheral is connected to the device.
    static let didConnect = Notification.Name("Peripheral.didConnectNotification")
    /// A notification that posts immediately after the peripheral failed to connect to the device.
    static let didFailedToConnect = Notification.Name("Peripheral.didFailedToConnectNotification")
    /// A notification that posts immediately after the peripheral is disconnected from the device.
    static let didDisconnect = Notification.Name("Peripheral.didDisconnectNotification")
    /// A notification that posts immediately after the peripheral failed to disconnect from the device.
    static let didFailedToDisconnect = Notification.Name("Peripheral.didFailedToDisconnectNotification")
}
