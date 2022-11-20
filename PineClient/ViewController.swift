//
//  ViewController.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 17.11.2022.
//

import UIKit

final class ViewController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        
        let viewController = ModeSelectionViewController()
        viewController.delegate = self
        pushViewController(viewController, animated: false)
    }
}

extension ViewController: ModeSelectionViewControllerDelegate {
    func didSelectedMode(mode: AppMode) {
        switch mode {
        case .client:
            let viewController = ChatViewController()
            viewControllers = []
            pushViewController(viewController, animated: true)
        case .server:
            let viewController = ServerModeViewController()
            viewControllers = []
            pushViewController(viewController, animated: true)
        }
    }
}
