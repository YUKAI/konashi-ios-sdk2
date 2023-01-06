//
//  MeshProvisioner.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/06.
//

import Foundation
import nRFMeshProvision

class MeshProvisioner {
    public enum ProvisioningError: Error {
        case invalidUnicastAddress
        case unsupportedDevice
    }

    private var currentContinuation: CheckedContinuation<ProvisioningCapabilities, Error>?
    private var provisioningManager: ProvisioningManager

    @Published var state: ProvisioningState?

    init(for provisioningManager: ProvisioningManager) {
        self.provisioningManager = provisioningManager
    }

    @discardableResult
    func identify(attractFor: UInt8 = 5) async throws -> ProvisioningCapabilities {
        provisioningManager.delegate = self
        return try await withCheckedThrowingContinuation { continuation in
            self.currentContinuation = continuation
            do {
                try provisioningManager.identify(andAttractFor: attractFor)
            }
            catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

extension MeshProvisioner: ProvisioningDelegate {
    public func provisioningState(
        of unprovisionedDevice: UnprovisionedDevice,
        didChangeTo state: ProvisioningState
    ) {
        self.state = state
        switch state {
        case let .capabilitiesReceived(capabilities):
            if let currentContinuation {
                if provisioningManager.isUnicastAddressValid == false {
                    currentContinuation.resume(throwing: ProvisioningError.invalidUnicastAddress)
                    self.currentContinuation = nil
                    return
                }
                if provisioningManager.isDeviceSupported == false {
                    currentContinuation.resume(throwing: ProvisioningError.unsupportedDevice)
                    self.currentContinuation = nil
                    return
                }
                currentContinuation.resume(returning: capabilities)
                self.currentContinuation = nil
            }
        case let .fail(error):
            if let currentContinuation {
                currentContinuation.resume(throwing: error)
                self.currentContinuation = nil
            }
        default:
            break
        }
    }

    public func authenticationActionRequired(_ action: AuthAction) {
//        switch action {
//        case let .provideStaticKey(callback: callback):
//            self.dismissStatusDialog {
//                let message = "Enter 16-character hexadecimal string."
//                self.presentTextAlert(title: "Static OOB Key", message: message,
//                                      type: .keyRequired, cancelHandler: nil) { hex in
//                    callback(Data(hex: hex))
//                }
//            }
//        case let .provideNumeric(maximumNumberOfDigits: _, outputAction: action, callback: callback):
//            self.dismissStatusDialog {
//                var message: String
//                switch action {
//                case .blink:
//                    message = "Enter number of blinks."
//                case .beep:
//                    message = "Enter number of beeps."
//                case .vibrate:
//                    message = "Enter number of vibrations."
//                case .outputNumeric:
//                    message = "Enter the number displayed on the device."
//                default:
//                    message = "Action \(action) is not supported."
//                }
//                self.presentTextAlert(title: "Authentication", message: message,
//                                      type: .unsignedNumberRequired, cancelHandler: nil) { text in
//                    callback(UInt(text)!)
//                }
//            }
//        case let .provideAlphanumeric(maximumNumberOfCharacters: _, callback: callback):
//            self.dismissStatusDialog {
//                let message = "Enter the text displayed on the device."
//                self.presentTextAlert(title: "Authentication", message: message,
//                                      type: .nameRequired, cancelHandler: nil) { text in
//                    callback(text)
//                }
//            }
//        case let .displayAlphanumeric(text):
//            self.presentStatusDialog(message: "Enter the following text on your device:\n\n\(text)")
//        case let .displayNumber(value, inputAction: action):
//            self.presentStatusDialog(message: "Perform \(action) \(value) times on your device.")
//        }
    }

    public func inputComplete() {
//        self.presentStatusDialog(message: "Provisioning...")
    }
}
