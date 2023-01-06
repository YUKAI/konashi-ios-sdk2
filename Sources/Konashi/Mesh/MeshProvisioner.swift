//
//  MeshProvisioner.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/06.
//

import Foundation
import nRFMeshProvision

class MeshProvisioner {
    public enum ProvisioningError: Error, LocalizedError {
        case unknown
        case invalidUnicastAddress(UnprovisionedDevice)
        case invalidCapability
        case unsupportedDevice(UnprovisionedDevice)

        public var errorDescription: String? {
            switch self {
            case .unknown:
                return "Unknown error."
            case let .invalidUnicastAddress(device):
                return "The device \(device.uuid) has invalid unicast address."
            case .invalidCapability:
                return "Provisioning capability should not be nil."
            case let .unsupportedDevice(device):
                return "The device \(device.uuid) is not able to provision."
            }
        }
    }

    private enum Invocation {
        case provision(CheckedContinuation<Void, Error>)
        case identify(CheckedContinuation<ProvisioningCapabilities, Error>)
    }

    private var invocation: Invocation?
    private var provisioningManager: ProvisioningManager

    @Published var state: ProvisioningState?

    init(for provisioningManager: ProvisioningManager) {
        self.provisioningManager = provisioningManager
    }

    @discardableResult
    func identify(attractFor: UInt8 = 5) async throws -> ProvisioningCapabilities {
        provisioningManager.delegate = self
        return try await withCheckedThrowingContinuation { continuation in
            self.invocation = .identify(continuation)
            do {
                try provisioningManager.identify(andAttractFor: attractFor)
            }
            catch {
                continuation.resume(throwing: error)
                self.invocation = nil
            }
        }
    }

    func provision(
        usingAlgorithm algorithm: Algorithm,
        publicKey: PublicKey,
        authenticationMethod: AuthenticationMethod
    ) async throws {
        provisioningManager.delegate = self
        return try await withCheckedThrowingContinuation { continuation in
            self.invocation = .provision(continuation)
            do {
                try provisioningManager.provision(
                    usingAlgorithm: algorithm,
                    publicKey: publicKey,
                    authenticationMethod: authenticationMethod
                )
            }
            catch {
                continuation.resume(throwing: error)
                self.invocation = nil
            }
        }
    }

    func throwError(_ error: Error) {
        switch invocation {
        case let .identify(continuation):
            continuation.resume(throwing: error)
        case let .provision(continuation):
            continuation.resume(throwing: error)
        case .none:
            break
        }
        invocation = nil
    }

    func resume(_ result: ProvisioningState) {
        do {
            switch result {
            case .complete:
                try resumeProvision()
            case let .capabilitiesReceived(capabilities):
                try resumeIdentify(capabilities)
            default:
                throwError(ProvisioningError.unknown)
            }
        }
        catch {
            throwError(error)
        }
    }

    private func resumeProvision() throws {
        if case let .provision(continuation) = invocation {
            continuation.resume(returning: ())
            invocation = nil
        }
        else {
            throw ProvisioningError.unknown
        }
    }

    private func resumeIdentify(_ capabilities: ProvisioningCapabilities) throws {
        if case let .identify(continuation) = invocation {
            continuation.resume(returning: capabilities)
            invocation = nil
        }
        else {
            throw ProvisioningError.unknown
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
        case .capabilitiesReceived:
            guard let isUnicastAddressValid = provisioningManager.isUnicastAddressValid else {
                throwError(ProvisioningError.unknown)
                return
            }
            if isUnicastAddressValid == false {
                throwError(ProvisioningError.invalidUnicastAddress(unprovisionedDevice))
                return
            }
            guard let isDeviceSupported = provisioningManager.isDeviceSupported else {
                throwError(ProvisioningError.invalidCapability)
                return
            }
            if isDeviceSupported == false {
                throwError(ProvisioningError.unsupportedDevice(unprovisionedDevice))
                return
            }
            resume(state)
        case let .fail(error):
            throwError(error)
        case .complete:
            resume(state)
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
