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
    private var cancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        buttonStateStackView.isHidden = true
        connectButton.configuration?.imagePadding = 8
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
                cancellable = nil
                guard let peripheral = try await presentKonashiListViewController() as? KonashiPeripheral else {
                    return
                }
                buttonStateStackView.isHidden = false
                connectedPeripheralLabel.text = peripheral.name
                try await peripheral.pinMode(.pin1, mode: .output)
                try await peripheral.digitalWrite(.pin1, value: .high)
                try await peripheral.pinMode(.pin0, mode: .inputPullUp)
                cancellable = peripheral.gpio0.input.sink { value in
                    self.buttonStateLabel.text = value.level == .high ? "On" : "Off"
                }
            } catch {
                connectedPeripheralLabel.text = error.localizedDescription
            }
        }
    }
}
