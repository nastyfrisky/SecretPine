//
//  TextInputView.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 20.11.2022.
//

import UIKit

final class TextInputView: UITextField {
    init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        CGRectInset(bounds, 8, 8)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        CGRectInset(bounds, 8, 8)
    }
}
