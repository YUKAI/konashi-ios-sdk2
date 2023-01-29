//
//  SendMessage.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/08.
//

import Foundation
import nRFMeshProvision

// MARK: - PrirmaryModelDelegate

final class PrirmaryModelDelegate: ModelDelegate {
    // MARK: Lifecycle

    init() {
        let types: [SensorMessage.Type] = [
            SensorDescriptorStatus.self,
            SensorCadenceStatus.self,
            SensorSettingsStatus.self,
            SensorSettingStatus.self,
            SensorStatus.self,
            SensorColumnStatus.self,
            SensorSeriesStatus.self
        ]
        messageTypes = types.toMap()
    }

    // MARK: Internal

    let messageTypes: [UInt32: MeshMessage.Type]
    let isSubscriptionSupported: Bool = true

    // TODO: Implement Sensor Client publications.
    let publicationMessageComposer: MessageComposer? = nil

    func model(
        _ model: Model,
        didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
        from source: Address,
        sentTo destination: MeshAddress
    ) throws -> MeshMessage {
        switch request {
        // No acknowledged message supported by this Model.
        default:
            fatalError("Message not supported: \(request)")
        }
    }

    func model(
        _ model: Model,
        didReceiveUnacknowledgedMessage message: MeshMessage,
        from source: Address,
        sentTo destination: MeshAddress
    ) {
        handle(message, sentFrom: source)
    }

    func model(
        _ model: Model,
        didReceiveResponse response: MeshMessage,
        toAcknowledgedMessage request: AcknowledgedMeshMessage,
        from source: Address
    ) {
        handle(response, sentFrom: source)
    }
}

private extension PrirmaryModelDelegate {
    func handle(_ message: MeshMessage, sentFrom source: Address) {
        // Ignore.
    }
}
