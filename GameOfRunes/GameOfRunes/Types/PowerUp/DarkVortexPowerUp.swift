//
//  DarkVortexPowerUp.swift
//  GameOfRunes
//
//  Created by Andy on 10/4/20.
//  Copyright © 2020 TeamHoWan. All rights reserved.
//

import SpriteKit

enum DarkVortexPowerUp: TapActivatedPowerUp, AllAnimationPowerUp {
    static let type: PowerUpType = .darkVortex
    static let manaUnitCost: Int = 4
    static let duration: TimeInterval = 5
    static let description: String = """
        Dark Vortex
        Tap on the arena to summon a dark vortex
        that pulls nearby enemies towards it
        """
    
    static func createEntity(at position: CGPoint, with size: CGSize) -> Entity? {
        DarkVortexPowerUpEntity(at: position, with: size)
    }
    
    static func activate(at position: CGPoint, with size: CGSize?, gameEngine: GameEngine) {
        guard let renderNodeSize = gameEngine.renderNode?.size else {
            return
        }

        let radius = renderNodeSize.width / 3
        let powerUpSize: CGSize = .init(width: radius, height: radius)
        
        guard let entity = createEntity(at: position, with: powerUpSize) else {
                return
        }
        gameEngine.add(entity)
    }
}
