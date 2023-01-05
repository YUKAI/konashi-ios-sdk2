//
//  KonashiPeripheral+AnalogPublisher.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/18.
//

import Combine
import Foundation

public extension KonashiPeripheral {
    private func makeAnalogInputSubject(pin: Analog.Pin) -> PassthroughSubject<Analog.InputValue, Never> {
        guard let subject = objc_getAssociatedObject(
            self,
            pin.rawValue.description
        ) as? PassthroughSubject<Analog.InputValue, Never> else {
            let subject = PassthroughSubject<Analog.InputValue, Never>()
            objc_setAssociatedObject(
                self,
                pin.rawValue.description,
                subject,
                .OBJC_ASSOCIATION_RETAIN
            )
            controlService.analogInput.value.map {
                return $0.values[Int(pin.rawValue)]
            }.sink { [weak self] value in
                guard let self else {
                    return
                }
                self.makeAnalogInputSubject(pin: pin).send(value)
            }.store(in: &subjectCancellable)
            return subject
        }
        return subject
    }

    /// A subject that sends value of AIO0.
    var analog0: PassthroughSubject<Analog.InputValue, Never> {
        return makeAnalogInputSubject(pin: .pin0)
    }

    /// A subject that sends value of AIO1.
    var analog1: PassthroughSubject<Analog.InputValue, Never> {
        return makeAnalogInputSubject(pin: .pin1)
    }

    /// A subject that sends value of AIO2.
    var analog2: PassthroughSubject<Analog.InputValue, Never> {
        return makeAnalogInputSubject(pin: .pin2)
    }
}
