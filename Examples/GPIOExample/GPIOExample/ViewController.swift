//
//  ViewController.swift
//  GPIOExample
//
//  Created by Akira Matsuda on 2023/08/20.
//

import Combine
import Konashi
import KonashiUI
import UIKit

class ViewController: UIViewController {
    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        peripheralControlStackView.isHidden = true
        connectButton.configuration?.imagePadding = 8
        blinkButton.configuration?.imagePadding = 8
    }

    // MARK: Private

    @IBOutlet private var connectedPeripheralLabel: UILabel!
    @IBOutlet private var connectButton: UIButton!
    @IBOutlet private var buttonStateLabel: UILabel!
    @IBOutlet private var blinkButton: UIButton!
    private var cancellable: AnyCancellable?
    @IBOutlet private var peripheralControlStackView: UIStackView!
    private var connectedPeripheral: KonashiPeripheral? {
        didSet {
            peripheralControlStackView.isHidden = connectedPeripheral == nil
        }
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

    private func blinkGPIO1(_ peripheral: KonashiPeripheral) async throws {
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
                connectedPeripheral = nil
                cancellable = nil
                guard let peripheral = try await presentKonashiListViewController() as? KonashiPeripheral else {
                    return
                }
                connectedPeripheral = peripheral
                connectedPeripheralLabel.text = peripheral.name
                try await setupPeripheral(peripheral)
            }
            catch {
                connectedPeripheralLabel.text = error.localizedDescription
            }
        }
    }

    @IBAction private func didBlinkButtonPress(_ sender: Any) {
        Task {
            defer {
                blinkButton.isEnabled = true
                blinkButton.configuration?.showsActivityIndicator = false
            }
            blinkButton.isEnabled = false
            blinkButton.configuration?.showsActivityIndicator = true
            guard let peripheral = connectedPeripheral else {
                return
            }
            try await blinkGPIO1(peripheral)
        }
    }
}
