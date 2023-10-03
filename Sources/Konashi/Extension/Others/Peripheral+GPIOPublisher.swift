//
//  Peripheral+GPIOPublisher.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/18.
//

import Combine
import Foundation

public extension Peripheral {
    typealias GPIOPublisher = (input: AnyPublisher<GPIO.Value, Never>, output: AnyPublisher<GPIO.Value, Never>)

    private func gpioInputPublisher(for pin: GPIO.Pin) -> AnyPublisher<GPIO.Value, Never> {
        return controlService.gpioInput.value.map {
            return $0.values[Int(pin.rawValue)]
        }.eraseToAnyPublisher()
    }

    private func gpioOutputPublisher(for pin: GPIO.Pin) -> AnyPublisher<GPIO.Value, Never> {
        return controlService.gpioOutput.value.map {
            return $0.values[Int(pin.rawValue)]
        }.eraseToAnyPublisher()
    }

    private func makeGPIOPublisher(for pin: GPIO.Pin) -> GPIOPublisher {
        return (
            input: gpioInputPublisher(for: pin),
            output: gpioOutputPublisher(for: pin)
        )
    }

    /// A subject that sends value of GPIO0.
    var gpio0: GPIOPublisher {
        return makeGPIOPublisher(for: .pin0)
    }

    /// A subject that sends value of GPIO1.
    var gpio1: GPIOPublisher {
        return makeGPIOPublisher(for: .pin1)
    }

    /// A subject that sends value of GPIO2.
    var gpio2: GPIOPublisher {
        return makeGPIOPublisher(for: .pin2)
    }

    /// A subject that sends value of GPIO3.
    var gpio3: GPIOPublisher {
        return makeGPIOPublisher(for: .pin3)
    }

    /// A subject that sends value of GPIO4.
    var gpio4: GPIOPublisher {
        return makeGPIOPublisher(for: .pin4)
    }

    /// A subject that sends value of GPIO5.
    var gpio5: GPIOPublisher {
        return makeGPIOPublisher(for: .pin5)
    }

    /// A subject that sends value of GPIO6.
    var gpio6: GPIOPublisher {
        return makeGPIOPublisher(for: .pin6)
    }

    /// A subject that sends value of GPIO7.
    var gpio7: GPIOPublisher {
        return makeGPIOPublisher(for: .pin7)
    }
}
