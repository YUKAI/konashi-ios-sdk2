//
//  MeshManager.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2022/12/26.
//

import Combine
import Foundation
import nRFMeshProvision

public class MeshManager {
    public enum ConfigurationError: Error, LocalizedError {
        case invalidUnprovisionedDevice
        case invalidNetworkKey
        case invalidApplicationKey

        public var errorDescription: String? {
            switch self {
            case .invalidUnprovisionedDevice:
                return "Failed to convert advertisement data."
            case .invalidNetworkKey:
                return "Network key shoud not be nil."
            case .invalidApplicationKey:
                return "Application key shoud not be nil."
            }
        }
    }

    public enum NetworkError: Error, LocalizedError {
        case invalidMeshNetwork
        case noNetworkConnection
        case bearerIsClosed
        case timeout

        public var errorDescription: String? {
            switch self {
            case .invalidMeshNetwork:
                return "Mesh network should not be nil."
            case .noNetworkConnection:
                return "No network connection."
            case .bearerIsClosed:
                return "Network connection is closed."
            case .timeout:
                return "Operation timeout."
            }
        }
    }

    public enum StorageError: Error, LocalizedError {
        case failedToSave
        case failedToCreateMeshNetwork

        public var errorDescription: String? {
            switch self {
            case .failedToSave:
                return "Failed to save keys to local storage."
            case .failedToCreateMeshNetwork:
                return "Failed to save mesh network settings to local storage."
            }
        }
    }

    public static let shared = MeshManager()

    public let didSendMessageSubject = PassthroughSubject<SendMessage, MessageTransmissionError>()
    public let didReceiveMessageSubject = PassthroughSubject<ReceivedMessage, Never>()
    public private(set) var networkKey: NetworkKey?
    public private(set) var applicationKey: ApplicationKey?
    public var numberOfNodes: Int {
        return networkManager.meshNetwork?.nodes.count ?? 0
    }

    public var allNodes: [Node] {
        // TODO: MeshNodeに変更する
        return networkManager.meshNetwork?.nodes ?? []
    }

    internal let networkManager: MeshNetworkManager
    private(set) var connection: MeshNetworkConnection?

    public init() {
        networkManager = MeshNetworkManager()
        networkManager.acknowledgmentTimerInterval = 0.150
        networkManager.transmissionTimerInterval = 0.600
        networkManager.incompleteMessageTimeout = 10.0
        networkManager.retransmissionLimit = 2
        networkManager.acknowledgmentMessageInterval = 4.2
        // As the interval has been increased, the timeout can be adjusted.
        // The acknowledged message will be repeated after 4.2 seconds,
        // 12.6 seconds (4.2 + 4.2 * 2), and 29.4 seconds (4.2 + 4.2 * 2 + 4.2 * 4).
        // Then, leave 10 seconds for until the incomplete message times out.
        networkManager.acknowledgmentMessageTimeout = 40.0
        networkManager.delegate = self

        // If load failed, create a new MeshNetwork.
        if let loaded = try? networkManager.load(), loaded == true {
            meshNetworkDidChange()
        }
        else {
            try? createNewMeshNetwork()
        }
    }

    public func provision(unprovisionedDevice: UnprovisionedDevice, over bearer: ProvisioningBearer) throws -> ProvisioningManager {
        return try networkManager.provision(unprovisionedDevice: unprovisionedDevice, over: bearer)
    }

    internal func node(for uuid: UUID) -> Node? {
        return networkManager.meshNetwork?.node(withUuid: uuid)
    }

    private(set) var logger: LoggerDelegate?
    public func setLogger(_ logger: LoggerDelegate) {
        self.logger = logger
        networkManager.logger = logger
        connection?.logger = logger
    }

    public func save() throws {
        if networkManager.save() == false {
            throw StorageError.failedToSave
        }
    }

    public func addNetworkKey(_ newKeyData: Data) throws {
        guard let network = networkManager.meshNetwork else {
            throw NetworkError.invalidMeshNetwork
        }
        let oldKey = networkKey
        if let oldKey {
            if oldKey.key != newKeyData {
                try network.remove(networkKey: oldKey, force: true)
            }
        }
        let newNetworkKey = try network.add(
            networkKey: newKeyData,
            withIndex: oldKey?.index,
            name: "Konashi Mesh Network Key"
        )
        networkKey = newNetworkKey
        try save()
    }

    public func addApplicationKey(_ newKeyData: Data) throws {
        guard let network = networkManager.meshNetwork else {
            throw NetworkError.invalidMeshNetwork
        }
        let oldKey = applicationKey
        if let oldKey {
            if oldKey.key != newKeyData {
                try network.remove(applicationKey: oldKey, force: true)
            }
        }
        let newApplicationKey = try network.add(
            applicationKey: newKeyData,
            withIndex: oldKey?.index,
            name: "Konashi Mesh Application Key"
        )
        applicationKey = newApplicationKey
        if let index = oldKey?.index,
           let networkKey = network.networkKeys[index] {
            try newApplicationKey.bind(to: networkKey)
        }
        try save()
    }

    private func createNewMeshNetwork() throws {
        let provisioner = Provisioner(
            name: "Konashi Mesh Manager",
            allocatedUnicastRange: [AddressRange(0x0001...0x199A)],
            allocatedGroupRange:   [AddressRange(0xC000...0xCC9A)],
            allocatedSceneRange:   [SceneRange(0x0001...0x3333)]
        )
        _ = networkManager.createNewMeshNetwork(withName: "Konashi Mesh Network", by: provisioner)
        if networkManager.save() == false {
            throw StorageError.failedToCreateMeshNetwork
        }
        meshNetworkDidChange()
    }

    /// Sets up the local Elements and reinitializes the `NetworkConnection`
    /// so that it starts scanning for devices advertising the new Network ID.
    private func meshNetworkDidChange() {
        guard let network = networkManager.meshNetwork else {
            return
        }
        networkKey = network.networkKeys.first
        applicationKey = network.applicationKeys.first
        connection?.close()
        networkManager.localElements = [
            Element(name: "Primary Element", location: .first, models: [
                Model(vendorModelId: .primaryModelId, companyId: .yukaiCompanyId, delegate: PrirmaryModelDelegate())
            ])
        ]
        connection = MeshNetworkConnection(to: network)
        connection?.dataDelegate = networkManager
        connection?.logger = logger
        networkManager.transmitter = connection
        connection?.open()
    }

    func waitUntilConnectionOpen(timeoutInterval: TimeInterval = 10) async throws {
        guard let connection else {
            throw MeshManager.NetworkError.noNetworkConnection
        }
        if connection.isOpen == false {
            let result = try await connection.$isOpen
                .removeDuplicates()
                .timeout(.seconds(timeoutInterval), scheduler: DispatchQueue.global())
                .filter { $0 }
                .eraseToAnyPublisher()
                .async()
            if result == false {
                throw MeshManager.NetworkError.bearerIsClosed
            }
        }
    }
}

extension MeshManager: MeshNetworkDelegate {
    public func meshNetworkManager(
        _ manager: MeshNetworkManager,
        didReceiveMessage message: MeshMessage,
        sentFrom source: Address,
        to destination: Address
    ) {
        didReceiveMessageSubject.send(ReceivedMessage(body: message, source: source, destination: destination))
    }

    public func meshNetworkManager(
        _ manager: MeshNetworkManager,
        didSendMessage message: MeshMessage,
        from localElement: Element,
        to destination: Address
    ) {
        didSendMessageSubject.send(SendMessage(body: message, from: localElement, destination: destination))
    }

    public func meshNetworkManager(
        _ manager: MeshNetworkManager,
        failedToSendMessage message: MeshMessage,
        from localElement: Element,
        to destination: Address,
        error: Error
    ) {
        didSendMessageSubject.send(
            completion: .failure(
                MessageTransmissionError(
                    error: error,
                    message: SendMessage(body: message, from: localElement, destination: destination)
                )
            )
        )
    }
}
