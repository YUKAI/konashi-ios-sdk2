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

    private func setupPeripheral(_ peripheral: KonashiPeripheral) async throws {
        // Configure GPIO0 as input.
        try await peripheral.pinMode(.pin0, mode: .inputPullUp)
        // Receive button input(GPIO0).
        cancellable = peripheral.gpio0.input
            .receive(on: DispatchQueue.main)
            .sink { value in
                self.buttonStateLabel.text = value.level == .high ? "On" : "Off"
            }

        // Configure GPIO1 as output.
        try await peripheral.pinMode(.pin1, mode: .output)
        // Turn LED on.
        try await peripheral.digitalWrite(.pin1, value: .high)
    }
    
    private func toggleGPIO1(_ peripheral: KonashiPeripheral) async throws {
        // Blink LED
        try await peripheral.digitalWrite(.pin1, value: .low)
        try await Task.sleep(for: .seconds(0.5))
        try await peripheral.digitalWrite(.pin1, value: .high)
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
                try await setupPeripheral(peripheral)
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
            try await toggleGPIO1(peripheral)
        }
    }
}
