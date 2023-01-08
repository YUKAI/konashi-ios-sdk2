//
//  SendMessage.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/08.
//

import Foundation
import nRFMeshProvision

class PrirmaryModelDelegate: ModelDelegate {
    let messageTypes: [UInt32: MeshMessage.Type]
    let isSubscriptionSupported: Bool = true

    // TODO: Implement Sensor Client publications.
    let publicationMessageComposer: MessageComposer? = nil

    init() {
        let types: [StaticVendorMessage.Type] = [
            PrirmaryStatus.self
        ]
        messageTypes = types.toMap()
    }

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

struct PrirmaryStatus: StaticVendorMessage {
    // The Op Code consists of:
    // 0xC0-0000 - Vendor Op Code bitmask
    // 0x04-0000 - The Op Code defined by...
    // 0x00-0925 - Yukai Engineering Inc. company ID (in Little Endian) as defined here:
    //             https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
    static let opCode: UInt32 = 0xC40925

    var parameters: Data? {
        return nil
    }

    init() {}

    init?(parameters: Data) {}
}
