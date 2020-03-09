//
//  GameScene.swift
//  GameOfRunes
//
//  Created by Jermy on 8/3/20.
//  Copyright © 2020 TeamHoWan. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    private var entityManager: EntityManager!
    private var lastUpdateTime: TimeInterval = 0.0
    let manaLabel = SKLabelNode(fontNamed: "DragonFire")
    
    override func sceneDidLoad() {
        entityManager = .init(scene: self)
        
        setUpArenaLayout()
        setUpEndPoint()
        setUpMana()
    }
    
    private func setUpArenaLayout() {
        let backgroundEntity = BackgroundEntity(arenaType: .arena2)
        let playerAreaEntity = PlayerAreaEntity()
        
        if let spriteComponent = backgroundEntity.component(ofType: SpriteComponent.self) {
            spriteComponent.node.position = .init(
                x: size.width / 2,
                y: size.height / 2
            )
            spriteComponent.node.size = size
            spriteComponent.node.zPosition = -1
            spriteComponent.node.name = "background"
        }
        
        if let spriteComponent = playerAreaEntity.component(ofType: SpriteComponent.self) {
            let newSpriteWidth = size.width
            let newSpriteHeight = size.height / 6
            spriteComponent.node.size = .init(width: newSpriteWidth, height: newSpriteHeight)
            spriteComponent.node.position = .init(
                x: newSpriteWidth / 2,
                y: newSpriteHeight / 2
            )
            spriteComponent.node.zPosition = 1
            spriteComponent.node.name = "player area"
        }
        
        entityManager.add(backgroundEntity)
        entityManager.add(playerAreaEntity)
    }
    
    private func setUpEndPoint() {
        let endPointEntity = EndPointEntity(entityManger: entityManager)
        
        if let spriteComponent = endPointEntity.component(ofType: SpriteComponent.self),
            let playerAreaNode = scene?.childNode(withName: "player area") {
            let newSpriteWidth = size.width
            let newSpriteHeight = size.height / 40
            spriteComponent.node.size = .init(width: newSpriteWidth, height: newSpriteHeight)
            spriteComponent.node.position = .init(
                x: size.width / 2,
                y: playerAreaNode.frame.size.height + newSpriteHeight / 2
            )
            spriteComponent.node.zPosition = 1
        }
        
        entityManager.add(endPointEntity)
    }
    
    private func setUpMana() {
        entityManager.add(PlayerManaEntity())
        
        manaLabel.fontSize = 50
        manaLabel.fontColor = SKColor.white
        manaLabel.position = CGPoint(x: size.width / 2, y: 100)
        manaLabel.zPosition = 2
        manaLabel.horizontalAlignmentMode = .center
        manaLabel.verticalAlignmentMode = .center
        manaLabel.text = "0"
        addChild(manaLabel)
    }
    
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        entityManager.update(with: deltaTime)
        
        if let manaEntity = entityManager
            .entities
            .compactMap({ $0.component(ofType: ManaComponent.self) })
            .first {
            manaLabel.text = "\(manaEntity.manaPoints)"
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        entityManager.spawnEnemy()
    }
}