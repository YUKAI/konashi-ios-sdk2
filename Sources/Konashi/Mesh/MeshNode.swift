//
//  MeshNode.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2022/12/26.
//

import Combine
import Foundation
import nRFMeshProvision

public class MeshNode: NodeCompatible {
    public enum Element: Int, NodeElement {
        public var index: Int {
            return rawValue
        }

        case configuration // Element 1
        case control0 // Element 2
        case control1 // Element 3
        case control2 // Element 4
        case control3 // Element 5
        case control4 // Element 6
        case control5 // Element 7
        case control6 // Element 8
        case control7 // Element 9
        case control8 // Element 10
        case control9 // Element 11
        case control10 // Element 12
        case sensor // Element 13
        case ledHue // Element 14
        case ledSaturation // Element 15

        public enum Model: NodeModel {
            // Element 1
            case configurationServer
            case healthServer

            // Element 2
            case gpio0OutputServer
            case gpio0InputClient
            case hardwarePWM0Server

            // Element 3
            case gpio1OutputServer
            case gpio1InputClient
            case hardwarePWM1Server

            // Element 4
            case gpio2OutputServer
            case gpio2InputClient
            case hardwarePWM2Server

            // Element 5
            case gpio3OutputServer
            case gpio3InputClient
            case hardwarePWM3Server

            // Element 6
            case gpio4OutputServer
            case gpio4InputClient
            case softwarePWM0Server

            // Element 7
            case gpio5OutputServer
            case gpio5InputClient
            case softwarePWM1Server

            // Element 8
            case gpio6OutputServer
            case gpio6InputClient
            case softwarePWM2Server

            // Element 9
            case gpio7OutputServer
            case gpio7InputClient
            case softwarePWM3Server

            // Element 10
            case analog0OutputServer
            case analog0InputClient

            // Element 11
            case analog1OutputServer
            case analog1InputClient

            // Element 12
            case analog2OutputServer
            case analog2InputClient

            // Element 13
            case sensorServer
            // TODO: TBA

            // Element 14
            // TODO: TBA

            // Element 15
            // TODO: TBA

            public var identifier: UInt32 {
                switch self {
                case .configurationServer:
                    return 0x0000
                case .healthServer:
                    return 0x0002
                case .gpio0OutputServer,
                     .gpio1OutputServer,
                     .gpio2OutputServer,
                     .gpio3OutputServer,
                     .gpio4OutputServer,
                     .gpio5OutputServer,
                     .gpio6OutputServer,
                     .gpio7OutputServer:
                    return 0x1000
                case .gpio0InputClient,
                     .gpio1InputClient,
                     .gpio2InputClient,
                     .gpio3InputClient,
                     .gpio4InputClient,
                     .gpio5InputClient,
                     .gpio6InputClient,
                     .gpio7InputClient:
                    return 0x1001
                case .hardwarePWM0Server,
                     .hardwarePWM1Server,
                     .hardwarePWM2Server,
                     .hardwarePWM3Server,
                     .softwarePWM0Server,
                     .softwarePWM1Server,
                     .softwarePWM2Server,
                     .softwarePWM3Server,
                     .analog0OutputServer,
                     .analog1OutputServer,
                     .analog2OutputServer:
                    return 0x1002
                case .analog0InputClient,
                     .analog1InputClient,
                     .analog2InputClient:
                    return 0x1003
                case .sensorServer:
                    return 0x1100
                }
            }

            public var element: NodeElement {
                switch self {
                case .configurationServer, .healthServer:
                    return Element.configuration
                case .gpio0InputClient, .gpio0OutputServer, .hardwarePWM0Server:
                    return Element.control0
                case .gpio1InputClient, .gpio1OutputServer, .hardwarePWM1Server:
                    return Element.control1
                case .gpio2InputClient, .gpio2OutputServer, .hardwarePWM2Server:
                    return Element.control2
                case .gpio3InputClient, .gpio3OutputServer, .hardwarePWM3Server:
                    return Element.control3
                case .gpio4InputClient, .gpio4OutputServer, .softwarePWM0Server:
                    return Element.control4
                case .gpio5InputClient, .gpio5OutputServer, .softwarePWM1Server:
                    return Element.control5
                case .gpio6InputClient, .gpio6OutputServer, .softwarePWM2Server:
                    return Element.control6
                case .gpio7InputClient, .gpio7OutputServer, .softwarePWM3Server:
                    return Element.control7
                case .analog0InputClient, .analog0OutputServer:
                    return Element.control8
                case .analog1InputClient, .analog1OutputServer:
                    return Element.control9
                case .analog2InputClient, .analog2OutputServer:
                    return Element.control10
                case .sensorServer:
                    return Element.sensor
                }
            }
        }
    }

    public var unicastAddress: Address? {
        return node.unicastAddress
    }

    public var deviceKey: Data? {
        return node.deviceKey
    }

    public var name: String? {
        return node.name
    }

    public var uuid: UUID? {
        return node.uuid
    }

    public var isProvisioner: Bool {
        return node.isProvisioner
    }

    public var elements: [nRFMeshProvision.Element] {
        return node.elements
    }

    public var receivedMessageSubject = PassthroughSubject<ReceivedMessage, Never>()

    private var cancellable = Set<AnyCancellable>()
    public private(set) var node: Node
    private(set) var manager: MeshManager

    public init?(manager: MeshManager, uuid: UUID) {
        guard let node = manager.node(for: uuid) else {
            return nil
        }
        self.manager = manager
        self.node = node
        self.manager.didReceiveMessageSubject
            .filter(for: self)
            .sink { [weak self] message in
                guard let self else {
                    return
                }
                self.receivedMessageSubject.send(message)
            }.store(in: &cancellable)
    }

    public func updateName(_ name: String?) throws {
        let oldName = node.name
        do {
            node.name = name
            try manager.save()
        }
        catch {
            node.name = oldName
            throw error
        }
    }

    public func element(with address: nRFMeshProvision.Address) -> nRFMeshProvision.Element? {
        return node.element(withAddress: address)
    }

    public func element(for element: NodeElement) -> nRFMeshProvision.Element? {
        return node.elements[safe: element.index]
    }

    public func model(for model: NodeModel) -> nRFMeshProvision.Model? {
        return node.elements[safe: model.element.index]?.model(withModelId: model.identifier)
    }

    public func removeFromNetwork() throws {
        guard let network = manager.networkManager.meshNetwork else {
            throw MeshManager.NetworkError.invalidMeshNetwork
        }
        network.remove(node: node)
    }

    @discardableResult
    public func send(message: nRFMeshProvision.MeshMessage, to model: nRFMeshProvision.Model) async throws -> NodeCompatible {
        try await checkOperationAvailability()
        if node.isCompositionDataReceived == false {
            throw NodeOperationError.noCompositionData
        }
        try manager.networkManager.send(message, to: model)
        return self
    }

    @discardableResult
    public func send(config: nRFMeshProvision.ConfigMessage) async throws -> NodeCompatible {
        try await checkOperationAvailability()
        try manager.networkManager.send(config, to: node)
        return self
    }

    @discardableResult
    public func waitForSendMessage() async throws -> SendMessage {
        try await checkOperationAvailability()
        return try await manager.didSendMessageSubject.eraseToAnyPublisher().async()
    }

    @discardableResult
    public func waitForResponse<T>(for messageType: T) async throws -> ReceivedMessage {
        try await checkOperationAvailability()
        return try await manager.didReceiveMessageSubject
            .filter { type(of: $0.body) is T }
            .eraseToAnyPublisher()
            .async()
    }

    @discardableResult
    public func setGattProxyEnabled(_ enabled: Bool) async throws -> NodeCompatible {
        try await send(config: ConfigGATTProxySet(enable: enabled))
        return self
    }

    @discardableResult
    public func addApplicationKey(_ applicationKey: ApplicationKey) async throws -> NodeCompatible {
        try await send(config: ConfigAppKeyAdd(applicationKey: applicationKey))
        return self
    }

    @discardableResult
    public func bindApplicationKey(_ applicationKey: ApplicationKey, to model: NodeModel) async throws -> NodeCompatible {
        let meshModel = try node.findElement(of: model.element).findModel(of: model)
        guard let message = ConfigModelAppBind(applicationKey: applicationKey, to: meshModel) else {
            throw NodeOperationError.invalidParentElement(modelIdentifier: meshModel.modelIdentifier)
        }
        try await send(config: message)
        return self
    }

    private func checkOperationAvailability() async throws {
        try await manager.waitUntilConnectionOpen()
    }
}

extension nRFMeshProvision.Node {
    func findElement(of element: MeshNode.Element) throws -> nRFMeshProvision.Element {
        return try findElement(of: element as NodeElement)
    }
}

extension nRFMeshProvision.Element {
    func findModel(of model: MeshNode.Element.Model) throws -> nRFMeshProvision.Model {
        return try findModel(of: model as NodeModel)
    }
}
