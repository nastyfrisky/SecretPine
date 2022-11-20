//
//  ARComponentView.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 17.11.2022.
//

import SceneKit
import ARKit

protocol ARComponentViewDelegate: AnyObject {
    func saveButtonTapped()
    func addImageButtonTapped()
}

final class ARComponentView: UIView {
    weak var delegate: ARComponentViewDelegate?
    
    private let sceneView = ARSCNView()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        
        let height: CGFloat = 50
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalTo: button.heightAnchor),
            button.heightAnchor.constraint(equalToConstant: height)
        ])
        
        button.layer.cornerRadius = height / 2
        
        button.setImage(UIImage(systemName: "square.and.arrow.up")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemGreen
        
        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(saveButtonTapped)))
        
        return button
    }()
    
    private lazy var addImageButton: UIButton = {
        let button = UIButton()
        
        let height: CGFloat = 50
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalTo: button.heightAnchor),
            button.heightAnchor.constraint(equalToConstant: height)
        ])
        
        button.layer.cornerRadius = height / 2
        
        button.setImage(UIImage(systemName: "plus")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        
        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addImageButtonTapped)))
        
        return button
    }()
    
    private let hintView = HintView()
    
    var session: ARSession { sceneView.session }
    
    init() {
        super.init(frame: .zero)
        
        [sceneView, saveButton, addImageButton, hintView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: bottomAnchor),
            sceneView.leftAnchor.constraint(equalTo: leftAnchor),
            sceneView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        
        NSLayoutConstraint.activate([
            saveButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            saveButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -16)
        ])
        
        NSLayoutConstraint.activate([
            addImageButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            addImageButton.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            hintView.bottomAnchor.constraint(equalTo: addImageButton.topAnchor, constant: -8),
            hintView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hintView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
    
    required init?(coder: NSCoder) { nil }
    
    func setSceneViewDelegate(delegate: ARSCNViewDelegate) {
        sceneView.delegate = delegate
    }
    
    @objc private func saveButtonTapped() {
        delegate?.saveButtonTapped()
    }
    
    @objc private func addImageButtonTapped() {
        delegate?.addImageButtonTapped()
    }

    func showHint() { hintView.isHidden = false }
    func hideHint() { hintView.isHidden = true }
    
    func hideButtons() { setButtonsHidden(isHidden: true) }
    func showAddImageButton() { addImageButton.isHidden = false }
    func showSaveButton() { saveButton.isHidden = false }
    
    private func setButtonsHidden(isHidden: Bool) {
        [addImageButton, saveButton].forEach { $0.isHidden = isHidden }
    }
    
    func configure(with model: HintViewModel) {
        hintView.configure(with: model)
    }
}
