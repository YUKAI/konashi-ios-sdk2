//
//  Peripheral+AnalogPublisher.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/18.
//

import Combine
import Foundation

public extension Peripheral {
    typealias AnalogPublisher = (input: AnyPublisher<Analog.InputValue, Never>, output: AnyPublisher<Analog.OutputValue, Never>)

    private func analogInputPublisher(for pin: Analog.Pin) -> AnyPublisher<Analog.InputValue, Never> {
        return controlService.analogInput.value.map {
            return $0.values[Int(pin.rawValue)]
        }.eraseToAnyPublisher()
    }

    private func analogOutputPublisher(for pin: Analog.Pin) -> AnyPublisher<Analog.OutputValue, Never> {
        return controlService.analogOutput.value.map {
            return $0.values[Int(pin.rawValue)]
        }.eraseToAnyPublisher()
    }

    private func makeAnalogPublisher(for pin: Analog.Pin) -> AnalogPublisher {
        return (
            input: analogInputPublisher(for: pin),
            output: analogOutputPublisher(for: pin)
        )
    }

    /// A subject that sends value of AIO0.
    var analog0: AnalogPublisher {
        return makeAnalogPublisher(for: .pin0)
    }

    /// A subject that sends value of AIO1.
    var analog1: AnalogPublisher {
        return makeAnalogPublisher(for: .pin1)
    }

    /// A subject that sends value of AIO2.
    var analog2: AnalogPublisher {
        return makeAnalogPublisher(for: .pin2)
    }
}
