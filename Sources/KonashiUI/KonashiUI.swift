//
//  KonashiUI.swift
//  konashi-ios-ui
//
//  Created by Akira Matsuda on 2021/08/10.
//

import Combine
import JGProgressHUD
import Konashi
import UIKit

// MARK: - KonashiUI

public final class KonashiUI {
    // MARK: Lifecycle

    init() {
        CentralManager.shared.didDiscoverPublisher.sink { [weak self] peripheral in
            guard let weakSelf = self, let peripheral = peripheral as? KonashiPeripheral else {
                return
            }
            if weakSelf.rssiThreshold.decimalValue <= peripheral.currentRSSI.decimalValue {
                weakSelf.discoveredPeripherals.insert(peripheral)
            }
        }.store(in: &cancellable)
        CentralManager.shared.$isScanning
            .receive(on: DispatchQueue.main)
            .sink { scanning in
                guard let window = UIApplication.shared.windows.first else {
                    return
                }
                if scanning {
                    let hud = JGProgressHUD()
                    hud.textLabel.text = "Scanning"
                    hud.show(in: window)
                }
                else {
                    JGProgressHUD.allProgressHUDs(in: window).forEach { hud in
                        hud.dismiss()
                    }
                }
            }.store(in: &cancellable)
        CentralManager.shared.$isConnecting
            .receive(on: DispatchQueue.main)
            .sink { connecting in
                guard let window = UIApplication.shared.windows.first else {
                    return
                }
                if connecting {
                    let hud = JGProgressHUD()
                    hud.textLabel.text = "Connecting"
                    hud.show(in: window)
                }
                else {
                    JGProgressHUD.allProgressHUDs(in: window).forEach { hud in
                        hud.dismiss()
                    }
                }
            }.store(in: &cancellable)
        CentralManager.shared.didDisconnectPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                discoveredPeripherals.removeAll()
                hudCancellable.removeAll()
                guard let window = UIApplication.shared.windows.first else {
                    return
                }
                JGProgressHUD.allProgressHUDs(in: window).forEach { hud in
                    hud.dismiss()
                }
            }.store(in: &cancellable)
    }

    // MARK: Public

    public enum ScanError: LocalizedError {
        case peripheralNotFound

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case .peripheralNotFound:
                return "Could not find peripherals."
            }
        }
    }

    public enum OperationError: LocalizedError {
        case cancelled

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case .cancelled:
                return "Operation cancelled."
            }
        }
    }

    public static let shared = KonashiUI()
    public static let defaultRSSIThreshold: NSNumber = -80

    // MARK: Internal

    var rssiThreshold: NSNumber = defaultRSSIThreshold

    // MARK: Fileprivate

    fileprivate var hudCancellable = Set<AnyCancellable>()
    fileprivate var discoveredPeripherals = Set<KonashiPeripheral>()

    // MARK: Private

    private var cancellable = Set<AnyCancellable>()
}

// MARK: - UIViewController + AlertPresentable

extension UIViewController: AlertPresentable {
    var presentingViewController: UIViewController {
        return self
    }

    public func presentCandidatePeripheral(name: String, timeoutInterval: TimeInterval = 3, rssiThreshold: NSNumber = KonashiUI.defaultRSSIThreshold) {
        KonashiUI.shared.rssiThreshold = rssiThreshold
        Task {
            var peripheral: (any Peripheral)?
            do {
                peripheral = try await CentralManager.shared.find(name: name, timeoutInterval: timeoutInterval)
            }
            catch {
                CentralManager.shared.stopScan()
            }
            guard let peripheral else {
                let alertController = UIAlertController(
                    title: NSLocalizedString("次の名前のKonashiが見つかりませんでした", comment: ""),
                    message: name,
                    preferredStyle: .alert
                )
                alertController.addAction(
                    UIAlertAction(
                        title: NSLocalizedString("OK", comment: ""),
                        style: .cancel,
                        handler: nil
                    )
                )
                present(alertController, animated: true, completion: nil)
                return
            }
            var name: String {
                guard let name = peripheral.name else {
                    return ""
                }
                return name
            }
            let alertController = UIAlertController(
                title: NSLocalizedString("このKonashiと接続しますか？", comment: ""),
                message: name,
                preferredStyle: .alert
            )
            alertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("接続", comment: ""),
                    style: .default,
                    handler: { _ in
                        Task {
                            do {
                                try await peripheral.connect(timeoutInterval: 15)
                                self.presentConnectedAlertController(name: peripheral.name)
                            }
                            catch {
                                self.presentAlertViewController(
                                    AlertContext(
                                        title: NSLocalizedString("接続できませんでした", comment: ""),
                                        detail: error.localizedDescription
                                    )
                                )
                            }
                        }
                    }
                )
            )
            alertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("キャンセル", comment: ""),
                    style: .cancel,
                    handler: nil
                )
            )
            present(alertController, animated: true, completion: nil)
        }
    }

    public func presentKonashiListViewController(
        scanDuration: TimeInterval = 3,
        rssiThreshold: NSNumber = KonashiUI.defaultRSSIThreshold
    ) async throws -> any Peripheral {
        KonashiUI.shared.rssiThreshold = rssiThreshold
        try await CentralManager.shared.scan(timeoutInterval: scanDuration)
        CentralManager.shared.stopScan()

        if KonashiUI.shared.discoveredPeripherals.isEmpty {
            let alertController = UIAlertController(
                title: nil,
                message: NSLocalizedString("接続可能なKonashiを発見できませんでした", comment: ""),
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
            throw KonashiUI.ScanError.peripheralNotFound
        }
        return try await withCheckedThrowingContinuation { continuation in
            let alertController = UIAlertController(
                title: NSLocalizedString("接続するKonashiを選択してください", comment: ""),
                message: nil,
                preferredStyle: .actionSheet
            )
            for peripheral in KonashiUI.shared.discoveredPeripherals {
                alertController.addAction(
                    UIAlertAction(
                        title: peripheral.name,
                        style: .default,
                        handler: { _ in
                            Task {
                                KonashiUI.shared.hudCancellable.removeAll()
                                peripheral.isReady
                                    .receive(on: DispatchQueue.main)
                                    .sink { ready in
                                        guard let window = UIApplication.shared.windows.first else {
                                            return
                                        }
                                        if ready == false {
                                            let hud = JGProgressHUD()
                                            hud.textLabel.text = "Preparing..."
                                            hud.show(in: window)
                                        }
                                        else {
                                            JGProgressHUD.allProgressHUDs(in: window).forEach { hud in
                                                hud.dismiss()
                                            }
                                        }
                                    }.store(in: &KonashiUI.shared.hudCancellable)
                                do {
                                    try await peripheral.connect()
                                    continuation.resume(returning: peripheral)
                                    self.presentConnectedAlertController(name: peripheral.name)
                                }
                                catch {
                                    continuation.resume(throwing: error)
                                    self.presentAlertViewController(
                                        AlertContext(
                                            title: NSLocalizedString("接続できませんでした", comment: ""),
                                            detail: error.localizedDescription
                                        )
                                    )
                                }
                            }
                        }
                    )
                )
            }
            alertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("キャンセル", comment: ""),
                    style: .cancel,
                    handler: { _ in
                        continuation.resume(throwing: KonashiUI.OperationError.cancelled)
                    }
                )
            )
            present(alertController, animated: true, completion: nil)
        }
    }

    private func presentConnectedAlertController(name: String?) {
        let alertController = UIAlertController(
            title: NSLocalizedString("次のKonashiに接続しました", comment: ""),
            message: name,
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(
                title: NSLocalizedString("OK", comment: ""),
                style: .cancel,
                handler: nil
            )
        )
        present(alertController, animated: true, completion: nil)
    }
}