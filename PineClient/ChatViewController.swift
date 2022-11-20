//
//  ChatViewController.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 19.11.2022.
//

import UIKit

final class ChatViewController: UIViewController {
    
    private var chatPresenter = ChatPresenter()
    
    private lazy var messagesListView: MessagesListView = {
        let view = MessagesListView()
        view.delegate = self
        return view
    }()
    
    private let popoverView = PopoverView()
    
    private var bottomConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        title = "Сообщения"
        
        [messagesListView, popoverView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        let bottomConstraint = messagesListView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        self.bottomConstraint = bottomConstraint
        
        NSLayoutConstraint.activate([
            messagesListView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messagesListView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messagesListView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bottomConstraint
        ])
        
        NSLayoutConstraint.activate([
            popoverView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            popoverView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            popoverView.topAnchor.constraint(equalTo: view.topAnchor),
            popoverView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hideKeyboardWhenTappedAround()
        enableKeyboardNotifications()
        
        chatPresenter.view = self
        chatPresenter.viewLoaded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        chatPresenter.viewWillAppear()
    }
    
    func showPopover(with model: PopoverViewModel) {
        view.bringSubviewToFront(popoverView)
        popoverView.configure(with: model)
        popoverView.isHidden = false
    }
    
    func hidePopover() {
        popoverView.isHidden = true
    }
    
    func updateMessages(messages: [MessageViewModel]) {
        messagesListView.configure(with: .init(messages: messages))
    }
    
    func resetInput() {
        messagesListView.resetInput()
    }
}

extension ChatViewController: MessagesListViewDelegate {
    func didTapSend(with text: String) {
        chatPresenter.didTapSend(with: text)
        dismissKeyboard()
    }
    
    func didTapARButton() {
        chatPresenter.didTapARButton()
    }
}

private extension ChatViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func enableKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc func keyboardWillShow(sender: NSNotification) {
        guard
            let userInfo = sender.userInfo,
            let timeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
        else { return }
        
        bottomConstraint?.constant = -keyboardHeight
        UIView.animate(withDuration: timeInterval) { self.view.layoutIfNeeded() }
    }
    
    @objc func keyboardWillHide(sender: NSNotification) {
        guard
            let userInfo = sender.userInfo,
            let timeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        else { return }
        
        bottomConstraint?.constant = 0
        UIView.animate(withDuration: timeInterval) { self.view.layoutIfNeeded() }
    }
}
