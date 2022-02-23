//
//  Peripheral+GPIOPublisher.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/18.
//

import Combine
import Foundation

extension Peripheral {
    var subjectCancellable: Set<AnyCancellable> {
        get {
            guard let cancellable = objc_getAssociatedObject(
                self,
                "subjectCancellable"
            ) as? Set<AnyCancellable> else {
                let cancellable = Set<AnyCancellable>()
                objc_setAssociatedObject(
                    self,
                    "subjectCancellable",
                    cancellable,
                    .OBJC_ASSOCIATION_RETAIN
                )
                return cancellable
            }
            return cancellable
        }
        set {
            objc_setAssociatedObject(
                self,
                "subjectCancellable",
                newValue,
                .OBJC_ASSOCIATION_RETAIN
            )
        }
    }
}

public extension Peripheral {
    private func makeGPIOSubject(pin: GPIO.Pin) -> PassthroughSubject<GPIO.Value, Never> {
        guard let subject = objc_getAssociatedObject(
            self,
            pin.rawValue.description
        ) as? PassthroughSubject<GPIO.Value, Never> else {
            let subject = PassthroughSubject<GPIO.Value, Never>()
            objc_setAssociatedObject(
                self,
                pin.rawValue.description,
                subject,
                .OBJC_ASSOCIATION_RETAIN
            )
            controlService.gpioOutput.value.map {
                return $0.values[Int(pin.rawValue)]
            }.sink { [weak self] value in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.makeGPIOSubject(pin: pin).send(value)
            }.store(in: &subjectCancellable)
            return subject
        }
        return subject
    }

    /// A subject that sends value of GPIO0.
    var gpio0: PassthroughSubject<GPIO.Value, Never> {
        return makeGPIOSubject(pin: .pin0)
    }

    /// A subject that sends value of GPIO1.
    var gpio1: PassthroughSubject<GPIO.Value, Never> {
        return makeGPIOSubject(pin: .pin1)
    }

    /// A subject that sends value of GPIO2.
    var gpio2: PassthroughSubject<GPIO.Value, Never> {
        return makeGPIOSubject(pin: .pin2)
    }

    /// A subject that sends value of GPIO3.
    var gpio3: PassthroughSubject<GPIO.Value, Never> {
        return makeGPIOSubject(pin: .pin3)
    }

    /// A subject that sends value of GPIO4.
    var gpio4: PassthroughSubject<GPIO.Value, Never> {
        return makeGPIOSubject(pin: .pin4)
    }

    /// A subject that sends value of GPIO5.
    var gpio5: PassthroughSubject<GPIO.Value, Never> {
        return makeGPIOSubject(pin: .pin5)
    }

    /// A subject that sends value of GPIO6.
    var gpio6: PassthroughSubject<GPIO.Value, Never> {
        return makeGPIOSubject(pin: .pin6)
    }

    /// A subject that sends value of GPIO7.
    var gpio7: PassthroughSubject<GPIO.Value, Never> {
        return makeGPIOSubject(pin: .pin7)
    }
}
