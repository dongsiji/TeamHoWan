//
//  TimerSystem.swift
//  GameOfRunes
//
//  Created by Dong SiJi on 16/3/20.
//  Copyright © 2020 TeamHoWan. All rights reserved.
//

import GameplayKit

class TimerSystem: GKComponentSystem<TimerComponent>, System {
    private weak var gameEngine: GameEngine?
    
    init(gameEngine: GameEngine) {
        self.gameEngine = gameEngine
        super.init(componentClass: TimerComponent.self)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        for component in components {
            updateComponent(component)
        }
    }
    
    private func updateComponent(_ component: TimerComponent) {
        guard CACurrentMediaTime() - component.lastUpdatedTime >= 1.0 else {
            return
        }
        
        component.lastUpdatedTime = CACurrentMediaTime()
        
        if component.isCountdown {
            component.currentTime = max(0, component.currentTime - 1)
            // TODO: Check if is 0, then propagate call to game state machine for lose state.
        } else {
            component.currentTime += 1
//            gameEngine?.spawnEnemy()
        }
    }
    
    func removeComponent(_ component: Component) {
        guard let component = component as? TimerComponent else {
            return
        }
        
        super.removeComponent(component)
    }
}