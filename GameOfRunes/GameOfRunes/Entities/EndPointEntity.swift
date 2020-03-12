//
//  EndPointEntity.swift
//  GameOfRunes
//
//  Created by Jermy on 9/3/20.
//  Copyright © 2020 TeamHoWan. All rights reserved.
//

import SpriteKit
import GameplayKit

class EndPointEntity: GKEntity {
    init(entityManger: EntityManager) {
        super.init()
        
        let spriteComponent = SpriteComponent(texture: .init(imageNamed: "finish-line4"))
        spriteComponent.node.addGlow()
        let teamComponent = TeamComponent(team: .player)
        let moveComponent = MoveComponent(
            maxSpeed: 0.0,
            maxAcceleration: 0.0,
            radius: .init(spriteComponent.node.size.height),
            entityManager: entityManger
        )
        
        addComponent(spriteComponent)
        addComponent(teamComponent)
        addComponent(moveComponent)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
