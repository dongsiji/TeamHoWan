//
//  HeroicCallPowerUp.swift
//  GameOfRunes
//
//  Created by Andy on 10/4/20.
//  Copyright © 2020 TeamHoWan. All rights reserved.
//

import SpriteKit

class HeroicCallPowerUp: ImmediatelyActivatedPowerUp {
    static let shared = HeroicCallPowerUp()
    let description: String = """
            Heroic Call
            Tap to to call upon a wave of elite knights
            to fight against incoming enemies
            """
    let manaUnitCost: Int = 0
    let duration: TimeInterval = Double(Int.max)
    
    private init() { }
    
    func createEntity(at position: CGPoint, with size: CGSize) -> Entity? {
        nil
    }
    
    func activate(at position: CGPoint, with size: CGSize?, gameEngine: GameEngine) {
        gameEngine.spawnPlayerUnitWave()
    }
}