//
//  MeshProvisioner.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/06.
//

import Combine
import Foundation
import nRFMeshProvision

class MeshProvisioner: Provisionable {
    @Published private(set) var internalState: ProvisioningState?
    var state: Published<nRFMeshProvision.ProvisioningState?>.Publisher {
        $internalState
    }

    struct Context {
        let algorithm: Algorithm
        let publicKey: PublicKey
        let authenticationMethod: AuthenticationMethod
    }

    static func == (lhs: MeshProvisioner, rhs: MeshProvisioner) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    private var provisioningManager: ProvisioningManager

    let uuid = UUID()
    let context: Context

    init(for provisioningManager: ProvisioningManager, context: Context) {
        self.provisioningManager = provisioningManager
        self.context = context
    }

    func identify(attractFor: UInt8 = 5) async throws {
        provisioningManager.delegate = self
        do {
            try provisioningManager.identify(andAttractFor: attractFor)
            _ = try await state.filter { state in
                if case .capabilitiesReceived = state {
                    return true
                }
                return false
            }.compactMap { state in
                if case let .capabilitiesReceived(capabilities) = state {
                    return capabilities
                }
                return nil
            }.eraseToAnyPublisher().async()
            guard let isUnicastAddressValid = provisioningManager.isUnicastAddressValid else {
                throw ProvisioningError.unknown
            }
            if isUnicastAddressValid == false {
                throw ProvisioningError.invalidUnicastAddress
            }
            guard let isDeviceSupported = provisioningManager.isDeviceSupported else {
                throw ProvisioningError.invalidCapability
            }
            if isDeviceSupported == false {
                throw ProvisioningError.invalidUnicastAddress
            }
        }
        catch {
            throw error
        }
    }

    func provision() async throws {
        provisioningManager.delegate = self
        do {
            try provisioningManager.provision(
                usingAlgorithm: context.algorithm,
                publicKey: context.publicKey,
                authenticationMethod: context.authenticationMethod
            )
            _ = try await state
                .filter { state in
                    if case .complete = state {
                        return true
                    }
                    return false
                }.eraseToAnyPublisher().async()
            return
        }
        catch {
            throw error
        }
    }
}

extension MeshProvisioner: ProvisioningDelegate {
    public func provisioningState(
        of unprovisionedDevice: UnprovisionedDevice,
        didChangeTo state: ProvisioningState
    ) {
        internalState = state
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
