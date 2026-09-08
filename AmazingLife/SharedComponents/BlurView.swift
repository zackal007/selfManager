//
//  BlurView.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import SwiftUI
import UIKit

// BlurView组件，用于创建毛玻璃背景效果
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}