//
//  MessageInputView.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 18.11.2022.
//

import UIKit

protocol MessageInputViewDelegate: AnyObject {
    func didTapSend(with text: String)
    func didTapARButton()
}

final class MessageInputView: UIView {
    
    weak var delegate: MessageInputViewDelegate?
    
    private let textView: TextInputView = {
        let view = TextInputView()
        
        view.backgroundColor = .init(white: 0.9, alpha: 1.0)
        view.layer.cornerRadius = 25
        
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        return view
    }()
    
    private lazy var sendButton: UIButton = {
        let button = UIButton()
        
        let height: CGFloat = 50
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalTo: button.heightAnchor),
            button.heightAnchor.constraint(equalToConstant: height)
        ])
        
        button.layer.cornerRadius = height / 2
        
        button.setImage(UIImage(systemName: "paperplane")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        
        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sendButtonTapped)))
        
        return button
    }()
    
    private lazy var arButton: UIButton = {
        let button = UIButton()
        
        let height: CGFloat = 50
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalTo: button.heightAnchor),
            button.heightAnchor.constraint(equalToConstant: height)
        ])
        
        button.layer.cornerRadius = height / 2
        
        button.setImage(UIImage(systemName: "photo.artframe")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemGreen
        
        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(arButtonTapped)))
        
        return button
    }()
    
    init() {
        super.init(frame: .zero)
        
        [textView, sendButton, arButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            arButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            arButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: arButton.trailingAnchor, constant: 8),
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            sendButton.leadingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            sendButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) { nil }
    
    @objc private func sendButtonTapped() {
        delegate?.didTapSend(with: textView.text ?? "")
    }
    
    @objc private func arButtonTapped() {
        delegate?.didTapARButton()
    }
    
    func resetInput() {
        textView.text = ""
    }
}
