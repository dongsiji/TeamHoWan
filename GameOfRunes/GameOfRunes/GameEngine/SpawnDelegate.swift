//
//  SpawnSystem.swift
//  GameOfRunes
//
//  Created by Brian Yen on 28/3/20.
//  Copyright © 2020 TeamHoWan. All rights reserved.
//

import GameplayKit

/**
 This class deals with the spawning of units. Level data is accessed via
 `GameMetaData` and is updated at periodic time intervals.
 */
class SpawnDelegate {
    private weak var gameEngine: GameEngine?
    // TODO: When timer is up, should retrieve this information from GameMetaData
    private var timeTillNextSpawn: TimeInterval
    private let endlessModeSpawnHandler: EndlessModeSpawnHandler

    init(gameEngine: GameEngine) {
        self.gameEngine = gameEngine
        self.timeTillNextSpawn = 0
        self.endlessModeSpawnHandler = EndlessModeSpawnHandler(gameMetaData: gameEngine.metadata)
    }

    func update(with deltaTime: TimeInterval) {
        // Send next spawn wave when timer is up
        if self.timeTillNextSpawn <= 0 {
            startNextSpawnWave()

            // Add More Waves for Endless Mode
            if checkEndlessModeNeedWaveAddition() {
                self.endlessModeSpawnHandler.addMoreWaves()
            }
        } else {
            self.timeTillNextSpawn -= deltaTime
        }
    }

    /**
     Checks if the game is in Endless Mode and if it is, whether the enemy waves need
     replenishment.
     */
    private func checkEndlessModeNeedWaveAddition() -> Bool {
        guard let gameMetaData = gameEngine?.metadata else {
            return false
        }

        let isEndless = gameMetaData.isEndless
        let hasInsufficientEnemyWaves = gameMetaData.stageWaves.count < GameConfig.GamePlayScene.numEnemyWavesThreshold

        print("Count: \(gameMetaData.stageWaves.count)") // TODO: DEBUG
        return isEndless && hasInsufficientEnemyWaves
    }

    func startNextSpawnWave() {
        // Check that there are still waves left
        guard let gameMetaData = gameEngine?.metadata,
            !gameMetaData.stageWaves.isEmpty else {
            return
        }

        let enemySpawnWave = gameMetaData.stageWaves.removeFirstSpawnWave()
        spawnEnemyWave(enemySpawnWave)
        self.timeTillNextSpawn = gameMetaData.levelSpawnInterval
    }
    
    func spawnPlayerUnitWave() {
        (0..<GameConfig.GamePlayScene.numLanes).forEach { laneIndex in
            spawnPlayerUnit(at: laneIndex)
        }
    }
    
    private func spawnPlayerUnit(at laneIndex: Int) {
        let playerUnitEntity = PlayerUnitEntity(gameEngine: gameEngine)
        
        guard let spriteComponent = playerUnitEntity.component(ofType: SpriteComponent.self),
            let playerEndPoint = gameEngine?.rootRenderNode?.playerEndPoint else {
                return
        }
        
        spriteComponent.node.position = GameConfig.GamePlayScene.calculateHorizontallyDistributedPoints(
            width: playerEndPoint.size.width,
            laneIndex: laneIndex,
            totalPoints: GameConfig.GamePlayScene.numLanes,
            yPosition: playerEndPoint.position.y
        )

        gameEngine?.add(playerUnitEntity)
    }

    private func spawnEnemyWave(_ enemyWave: [EnemyType?]) {
        enemyWave.enumerated().forEach { laneIndex, enemyType in
            spawnEnemy(at: laneIndex, enemyType: enemyType)
        }
    }

    /**
     Creates the `EnemyEntity` at the correct spawn location (determined by the
     `laneIndex` and adds it to `GameEngine`.
     */
    private func spawnEnemy(at laneIndex: Int, enemyType: EnemyType?) {
        // No need to spawn enemy if enemyType is nil (i.e. lane is empty)
        guard let enemyType = enemyType, let gameEngine = gameEngine else {
            return
        }

        let enemyEntity = EnemyEntity(enemyType: enemyType, gameEngine: gameEngine)
        guard let spriteComponent = enemyEntity.component(ofType: SpriteComponent.self),
            let renderNodeSize = gameEngine.rootRenderNode?.size else {
                return
        }

        spriteComponent.node.position = GameConfig.GamePlayScene.calculateHorizontallyDistributedPoints(
            width: renderNodeSize.width,
            laneIndex: laneIndex,
            totalPoints: GameConfig.GamePlayScene.numLanes,
            yPosition: (1 - GameConfig.GamePlayScene.verticalOffSetRatio) * renderNodeSize.height
        )

        gameEngine.add(enemyEntity)
        gameEngine.metadata.numEnemiesOnField += 1
    }
}
