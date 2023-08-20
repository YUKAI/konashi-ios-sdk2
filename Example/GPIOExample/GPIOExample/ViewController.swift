//
//  ViewController.swift
//  GPIOExample
//
//  Created by Akira Matsuda on 2023/08/20.
//

import Combine
import UIKit
import Konashi
import KonashiUI

class ViewController: UIViewController {
    @IBOutlet private var connectedPeripheralLabel: UILabel!
    @IBOutlet private var connectButton: UIButton!
    @IBOutlet private var buttonStateStackView: UIStackView!
    @IBOutlet private var buttonStateLabel: UILabel!
    @IBOutlet private var toggleGPIO1Button: UIButton!
    private var cancellable: AnyCancellable?
    private var connectedPeripheral: KonashiPeripheral?

    override func viewDidLoad() {
        super.viewDidLoad()
        buttonStateStackView.isHidden = true
        connectButton.configuration?.imagePadding = 8
        toggleGPIO1Button.configuration?.imagePadding = 8
    }

    @IBAction private func didConnectButtonPress(_ sender: Any) {
        Task {
            defer {
                connectButton.isEnabled = true
                connectButton.configuration?.showsActivityIndicator = false
            }
            connectButton.isEnabled = false
            connectButton.configuration?.showsActivityIndicator = true
            do {
                if let connectedPeripheral {
                    try await connectedPeripheral.disconnect()
                }
                cancellable = nil
                guard let peripheral = try await presentKonashiListViewController() as? KonashiPeripheral else {
                    return
                }
                connectedPeripheral = peripheral
                buttonStateStackView.isHidden = false
                connectedPeripheralLabel.text = peripheral.name

                try await peripheral.pinMode(.pin0, mode: .inputPullUp)
                cancellable = peripheral.gpio0.input.sink { value in
                    self.buttonStateLabel.text = value.level == .high ? "On" : "Off"
                }
                try await peripheral.pinMode(.pin1, mode: .output)
                try await peripheral.digitalWrite(.pin1, value: .high)
            } catch {
                connectedPeripheralLabel.text = error.localizedDescription
            }
        }
    }

    @IBAction private func toggleGPIO2(_ sender: Any) {
        Task {
            defer {
                toggleGPIO1Button.isEnabled = true
                toggleGPIO1Button.configuration?.showsActivityIndicator = false
            }
            toggleGPIO1Button.isEnabled = false
            toggleGPIO1Button.configuration?.showsActivityIndicator = true
            guard let peripheral = connectedPeripheral else {
                return
            }
            try await peripheral.digitalWrite(.pin1, value: .low)
            try await Task.sleep(for: .seconds(0.5))
            try await peripheral.digitalWrite(.pin1, value: .high)
        }
    }
}
