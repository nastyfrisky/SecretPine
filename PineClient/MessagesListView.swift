//
//  MessagesListView.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 18.11.2022.
//

import UIKit

struct MessagesListViewModel {
	let messages: [MessageViewModel]
}

protocol MessagesListViewDelegate: AnyObject {
    func didTapSend(with text: String)
    func didTapARButton()
}

final class MessagesListView: UIView {

    weak var delegate: MessagesListViewDelegate?

	private lazy var tableView: UITableView = {
		let table = UITableView(frame: .zero)
        table.separatorStyle = .none
        table.allowsSelection = false
		table.dataSource = self
		table.delegate = self
		return table
	}()
    
    private let messageInputView = MessageInputView()

	private var messages: [MessageViewModel] = []

	init() {
		super.init(frame: .zero)
        
        messageInputView.delegate = self
        
        [tableView, messageInputView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.topAnchor.constraint(equalTo: topAnchor)
        ])
        
        NSLayoutConstraint.activate([
            messageInputView.leadingAnchor.constraint(equalTo: leadingAnchor),
            messageInputView.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageInputView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 8),
            messageInputView.bottomAnchor.constraint(equalTo: bottomAnchor),
            messageInputView.topAnchor.constraint(greaterThanOrEqualTo: centerYAnchor)
        ])
	}

	required init?(coder: NSCoder) { nil }

	func configure(with model: MessagesListViewModel) {
        messages = model.messages
        tableView.reloadData()
        
        guard messages.count > 0 else { return }
        tableView.scrollToRow(at: .init(row: messages.count - 1, section: 0), at: .none, animated: false)
	}
    
    func resetInput() {
        messageInputView.resetInput()
    }
}

extension MessagesListView: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "messageCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        guard let cell = cell as? MessageViewCell else {
            let cell = MessageViewCell(style: .default, reuseIdentifier: identifier)
            configureCell(cell: cell, indexPath: indexPath)
            return cell
        }
        
        configureCell(cell: cell, indexPath: indexPath)
        return cell
	}
    
    private func configureCell(cell: MessageViewCell, indexPath: IndexPath) {
        cell.configure(with: messages[indexPath.row])
    }
}

extension MessagesListView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}

extension MessagesListView: MessageInputViewDelegate {
    func didTapSend(with text: String) {
        delegate?.didTapSend(with: text)
    }
    
    func didTapARButton() {
        delegate?.didTapARButton()
    }
}
