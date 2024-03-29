//
//  MeshProvisioner.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/06.
//

import Combine
import Foundation
import nRFMeshProvision

// MARK: - MeshProvisioner

final class MeshProvisioner: Provisionable {
    // MARK: Lifecycle

    init(for provisioningManager: ProvisioningManager, context: Context, bearer: MeshBearer<PBGattBearer>) {
        self.provisioningManager = provisioningManager
        self.context = context
        self.bearer = bearer
        self.provisioningManager.delegate = self
    }

    // MARK: Internal

    struct Context {
        let algorithm: Algorithm
        let publicKey: PublicKey
        let authenticationMethod: AuthenticationMethod
    }

    @Published private(set) var internalState: ProvisioningState?
    let uuid = UUID()
    let context: Context

    var state: Published<nRFMeshProvision.ProvisioningState?>.Publisher {
        $internalState
    }

    var isOpen: Bool {
        return bearer.originalBearer.isOpen
    }

    static func == (lhs: MeshProvisioner, rhs: MeshProvisioner) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    func open() async throws {
        try await bearer.open()
    }

    func identify(attractFor: UInt8 = 5) async throws {
        try checkConnectivity()
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
            }.eraseToAnyPublisher().konashi_makeAsync()
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
        try checkConnectivity()
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
                }.eraseToAnyPublisher().konashi_makeAsync()
            return
        }
        catch {
            throw error
        }
    }

    // MARK: Private

    private var provisioningManager: ProvisioningManager
    private var bearer: MeshBearer<PBGattBearer>

    private func checkConnectivity() throws {
        if isOpen == false {
            throw ProvisionerError.connectionError
        }
    }
}

// MARK: ProvisioningDelegate

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
