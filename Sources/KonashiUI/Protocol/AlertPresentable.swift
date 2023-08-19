//
//  AlertPresentable.swift
//  konashi-ios-ui
//
//  Created by Akira Matsuda on 2021/08/14.
//

import UIKit

// MARK: - AlertContext

struct AlertContext {
    let title: String?
    let detail: String?
}

// MARK: - AlertPresentable

protocol AlertPresentable {
    var presentingViewController: UIViewController { get }

    func presentAlertViewController(_ context: AlertContext)
}

extension AlertPresentable {
    func presentAlertViewController(_ context: AlertContext) {
        let alert = UIAlertController(
            title: context.title,
            message: context.detail,
            preferredStyle: .alert
        )
        alert.addAction(.init(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: nil))
        presentingViewController.present(alert, animated: true, completion: nil)
    }
}
