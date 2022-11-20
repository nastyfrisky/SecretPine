//
//  MessageViewCell.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 18.11.2022.
//

import UIKit

struct MessageViewModel {
	let text: String
}

final class MessageViewCell: UITableViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.backgroundColor = .init(white: 0.9, alpha: 1.0)
        return view
    }()
    
    private let messageLabelView: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        [containerView, messageLabelView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ])
        
        NSLayoutConstraint.activate([
            messageLabelView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            messageLabelView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            messageLabelView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            messageLabelView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
        ])
    }
    
    required init?(coder: NSCoder) { nil }
    
    func configure(with model: MessageViewModel) {
        messageLabelView.text = model.text
    }
}
