//
//  ButtonNode.swift
//  GameOfRunes
//
//  Created by Brian Yen on 11/3/20.
//  Copyright © 2020 TeamHoWan. All rights reserved.
//

import SpriteKit

/**
 An `SKSpriteNode` that functions as a button.
 To be added to `SKScene` or it subclasses.
 */
class ButtonNode: SKSpriteNode {
    private static let onTappedScaleFactor: CGFloat = 0.9
    private var responder: TapResponder {
        guard let responder = scene as? TapResponder else {
            fatalError("This node can only be used within a `TapResponder` scene.")
        }
        return responder
    }
    private var identitySize: CGSize
    override var size: CGSize {
        didSet {
            guard oldValue != size else {
                return
            }
            identitySize = size
        }
    }
    let buttonType: ButtonType
    lazy var onTouchEnded = { (touches: Set<UITouch>) in
        guard let touch = touches.first,
            let parent = self.parent,
            parent.atPoint(touch.location(in: parent)) === self else {
                return
        }
        
        self.responder.onTapped(tappedNode: self)
    }

    init(size: CGSize, texture: SKTexture?, buttonType: ButtonType, position: CGPoint = .zero) {
        self.buttonType = buttonType
        identitySize = size
        super.init(texture: texture, color: .clear, size: size)
        
        self.size = size
        self.position = position
        isUserInteractionEnabled = true
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /** UIResponder touch handling. */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        run(.scale(to: Self.onTappedScaleFactor, duration: 0.05))
    }

    /** UIResponder touch handling. */
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        run(.scale(to: identitySize, duration: 0.1))
        onTouchEnded(touches)
    }

    /** UIResponder touch handling. */
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        run(.scale(to: identitySize, duration: 0.1))
    }
}
