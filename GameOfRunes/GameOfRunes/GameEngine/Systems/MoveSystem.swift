//
//  MoveSystem.swift
//  GameOfRunes
//
//  Created by Dong SiJi on 12/3/20.
//  Copyright © 2020 TeamHoWan. All rights reserved.
//

import GameplayKit

class MoveSystem: GKComponentSystem<MoveComponent>, System {
    private unowned let gameEngine: GameEngine
    
    init(gameEngine: GameEngine) {
        self.gameEngine = gameEngine
        super.init(componentClass: MoveComponent.self)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        for component in components where !component.isRemoved {
            updateComponent(component)
            // Call to component.update to trigger observer events.
            component.update(deltaTime: seconds)
        }
        
        checkEnemyEndPointCollision()
    }
    
    // Note: end-point entity also has a move component.
    private func updateComponent(_ component: MoveComponent) {
        guard let entity = component.entity,
            let teamComponent = entity.component(ofType: TeamComponent.self),
            let enemyMoveComponent = closestMoveComponent(from: component,
                                                          for: teamComponent.team.oppositeTeam) else {
                return
        }

        let alliedMoveComponents = gameEngine.moveComponents(for: teamComponent.team)
        
        // Update Entity Movement Behaviour
        component.behavior = MoveBehavior(targetSpeed: component.maxSpeed, seek: enemyMoveComponent,
                                          avoid: alliedMoveComponents)
    }
    
    private func closestMoveComponent(from component: MoveComponent, for team: Team) -> GKAgent2D? {
        var closestMoveComponent: MoveComponent?
        var closestDistance: CGFloat = 0.0
        
        gameEngine.moveComponents(for: team).forEach {
            let distance = component.cgPosition.distance(to: $0.cgPosition)
            if closestMoveComponent == nil || distance < closestDistance {
                closestMoveComponent = $0
                closestDistance = distance
            }
        }
        
        return closestMoveComponent
    }
    
    private func checkEnemyEndPointCollision() {
        guard let endpointComponent = gameEngine.entities(for: .player).first as? EndPointEntity,
            let endpointNode = endpointComponent.component(ofType: SpriteComponent.self)?.node else {
            return
        }
        
        for enemyEntity in gameEngine.entities(for: .enemy) {
            guard let componentRemoved = enemyEntity.component(ofType: MoveComponent.self)?.isRemoved,
                !componentRemoved else {
                continue
            }

            if enemyEntity
                .component(ofType: SpriteComponent.self)?
                .node
                .calculateAccumulatedFrame()
                .intersects(endpointNode.calculateAccumulatedFrame()) ?? false {
                gameEngine.enemyReachedLine(enemyEntity)
            }
        }
    }
}
