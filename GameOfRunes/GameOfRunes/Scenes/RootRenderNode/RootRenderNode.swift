//
//  RootRenderNode.swift
//  GameOfRunes
//
//  Created by Brian Yen on 10/4/20.
//  Copyright © 2020 TeamHoWan. All rights reserved.
//

import SpriteKit

class RootRenderNode: SKNode {
    private(set) var gameEngine: GameEngine
    private(set) var size: CGSize
    private(set) var center: CGPoint

    // layers
    private var backgroundLayer: SKNode!
    private var powerUpAnimationLayer: SKNode!
    private var unitLayer: SKNode!
    private var removalAnimationLayer: SKNode!
    private var gestureLayer: SKNode!
    private var playerAreaLayer: SKNode!
    private var manaDropLayer: SKNode!
    private var highestPriorityLayer: SKNode!
    private(set) var playerAreaNode: PlayerAreaNode! //Must these be private(set)?
    private(set) var playerEndPoint: SKSpriteNode!
    private(set) var gestureAreaNode: GestureAreaNode!
    private var bgmNode: SKAudioNode!

    // TODO: Remove center and put as computed property once done debugging
    init(gameEngine: GameEngine, zPosition: CGFloat, size: CGSize, center: CGPoint) {
        self.center = center
        self.gameEngine = gameEngine
        self.size = size
        super.init()

        // Note: the following is necessary in order to allow RootRenderNode
        // to add Entities during set-up
        // TODO: can this be fixed? (This can be fixed by ensuring that all
        // classes that require rootRenderNode are passed in rootRenderNode
        // instead of accessing through gameEngine
        self.gameEngine.rootRenderNode = self
        self.zPosition = zPosition
        // TODO: Note: This is necessary for DarkVortex to work (because after
        // disabling user interaction for the gesture node, you need to let
        // RootRenderNode detect the gestures instead (used to be GameScene)
        self.isUserInteractionEnabled = true

        // UI
        buildLayers()
        setUpBackground()
        setUpPlayerArea()
        setUpGestureArea()
        setUpPauseButton()

        // Entities
        setUpEndPoint()
        setUpPlayer()
        setUpTimer(isCountdown: false)

        // Set Up Background Music
        bgmNode = .init(fileNamed: "Disturbance in Agustria")
        addChild(bgmNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildLayers() {
        backgroundLayer = .init()
        backgroundLayer.zPosition = GameConfig.GamePlayScene.backgroundLayerZPosition
        addChild(backgroundLayer)

        powerUpAnimationLayer = .init()
        powerUpAnimationLayer.zPosition = GameConfig.GamePlayScene.powerUpAnimationLayerZPosition
        addChild(powerUpAnimationLayer)

        unitLayer = .init()
        unitLayer.zPosition = GameConfig.GamePlayScene.unitLayerZPosition
        addChild(unitLayer)

        removalAnimationLayer = .init()
        removalAnimationLayer.zPosition = GameConfig.GamePlayScene.removalAnimationLayerZPosition
        addChild(removalAnimationLayer)

        gestureLayer = .init()
        gestureLayer.zPosition = GameConfig.GamePlayScene.gestureLayerZPosition
        addChild(gestureLayer)

        playerAreaLayer = .init()
        playerAreaLayer.zPosition = GameConfig.GamePlayScene.playerAreaLayerZPosition
        addChild(playerAreaLayer)

        manaDropLayer = .init()
        manaDropLayer.zPosition = GameConfig.GamePlayScene.manaDropLayerZPosition
        addChild(manaDropLayer)

        highestPriorityLayer = .init()
        highestPriorityLayer.zPosition = GameConfig.GamePlayScene.highestPriorityLayerZPosition
        addChild(highestPriorityLayer)
    }

    private func setUpBackground() {
        let backgroundNode = SKSpriteNode(
            texture: gameEngine.metadata.stage.arena.texture,
            color: .clear,
            size: size
        )
        backgroundNode.aspectFillToSize(fillSize: size)
        backgroundNode.position = center
        backgroundLayer.addChild(backgroundNode)
    }

    private func setUpPlayerArea() {
        let playerAreaWidth = size.width
        let playerAreaHeight = size.height * GameConfig.GamePlayScene.playerAreaHeightRatio
        playerAreaNode = .init(
            size: .init(width: playerAreaWidth, height: playerAreaHeight),
            position: .init(x: playerAreaWidth / 2, y: playerAreaHeight / 2)
        )

        playerAreaNode.powerUpContainerNode.powerUpTypes = gameEngine.metadata.availablePowerUps
        playerAreaLayer.addChild(playerAreaNode)
    }

    private func setUpGestureArea() {
        gestureAreaNode = .init(
            size: size.applying(.init(scaleX: 1.0, y: GameConfig.GamePlayScene.gestureAreaHeightRatio)),
            gameEngine: gameEngine
        )
        gestureAreaNode.position = center +
            .init(dx: 0.0, dy: playerAreaNode.size.height / 2)
        gestureLayer.addChild(gestureAreaNode)
    }

    private func setUpPauseButton() {
        // Re-position and resize
        let buttonMargin = GameConfig.GamePlayScene.buttonMargin
        let buttonSize = CGSize(
            width: size.width * GameConfig.GamePlayScene.buttonWidthRatio,
            height: size.width * GameConfig.GamePlayScene.buttonHeightRatio
        )
        let pauseButton = ButtonNode(
            size: buttonSize,
            texture: .init(imageNamed: "\(ButtonType.pauseButton)"),
            buttonType: .pauseButton,
            position: .init(x: size.width, y: size.height)
                + .init(dx: -buttonSize.width / 2, dy: -buttonSize.height / 2)
                + .init(dx: -buttonMargin, dy: -buttonMargin)
        )

        // relative to the layer
        pauseButton.zPosition = 1

        highestPriorityLayer.addChild(pauseButton)
    }

    private func setUpEndPoint() {
        guard GameConfig.GamePlayScene.numEndPoints > 0 else {
            fatalError("There must be more than 1 lane")
        }

        // set up visual end point line
        let endPointNode = SKSpriteNode(imageNamed: "finish-line")

        // re-position and resize
        let newEndPointWidth = size.width
        let newEndPointHeight = size.height * GameConfig.GamePlayScene.endPointHeightRatio
        let newEndPointSize = CGSize(width: newEndPointWidth, height: newEndPointHeight)
        endPointNode.size = newEndPointSize
        endPointNode.position = playerAreaNode.position
            + .init(dx: 0.0, dy: (playerAreaNode.size.height + newEndPointHeight) / 2)

        // relative to the player area layer
        endPointNode.zPosition = -1
        endPointNode.addGlow()

        playerEndPoint = endPointNode
        let endPointEntity = EndPointEntity(node: endPointNode, team: .player)
        gameEngine.add(endPointEntity)

        // check if need to add enemy end point for elite knight
        guard gameEngine.metadata.avatar == .holyKnight else {
            return
        }

        let enemyEndPointNode = SKSpriteNode(color: .clear, size: newEndPointSize)
        enemyEndPointNode.position = .init(x: size.width, y: size.height - GameConfig.GamePlayScene.verticalOffSet)
        let enemyEndPointEntity = EndPointEntity(node: enemyEndPointNode, team: .enemy)
        gameEngine.add(enemyEndPointEntity)
    }

    private func setUpPlayer() {
        let healthNode = setUpPlayerHealth()
        let manaNode = setUpPlayerMana()
        let scoreNode = playerAreaNode.scoreNode
        let playerEntity = PlayerEntity(
            gameEngine: gameEngine,
            healthNode: healthNode,
            manaNode: manaNode,
            scoreNode: scoreNode
        )
        gameEngine.add(playerEntity)
    }

    private func setUpPlayerHealth() -> HealthBarNode {
        let healthBarNode = playerAreaNode.healthBarNode
        healthBarNode.totalLives = gameEngine.metadata.maxPlayerHealth
        return healthBarNode
    }

    private func setUpPlayerMana() -> ManaBarNode {
        let manaBarNode = playerAreaNode.manaBarNode
        manaBarNode.numManaUnits = gameEngine.metadata.numManaUnits
        manaBarNode.manaPointsPerUnit = gameEngine.metadata.manaPointsPerManaUnit
        return manaBarNode
    }

    private func setUpTimer(isCountdown: Bool, initialTimerValue: TimeInterval = 0) {
        let timerNode = SKLabelNode(fontNamed: "DragonFire")

        timerNode.fontSize = 50
        timerNode.fontColor = SKColor.white
        timerNode.position = CGPoint(x: size.width / 2, y: 50)
        timerNode.zPosition = 75
        timerNode.horizontalAlignmentMode = .center
        timerNode.verticalAlignmentMode = .center
        timerNode.text = "\(Int(initialTimerValue))"

        gameEngine.add(TimerEntity(gameEngine: gameEngine, timerNode: timerNode, initialTimerValue: initialTimerValue))
    }

    func addNodeToLayer(layer: SpriteLayerType, node: SKNode) {
        switch layer {
        case .backgroundLayer:
            backgroundLayer.addChild(node)
        case .powerUpAnimationLayer:
            powerUpAnimationLayer.addChild(node)
        case .unitLayer:
            unitLayer.addChild(node)
        case .removalAnimationLayer:
            removalAnimationLayer.addChild(node)
        case .gestureLayer:
            gestureLayer.addChild(node)
        case .playerAreaLayer:
            playerAreaLayer.addChild(node)
        case .manaDropLayer:
            manaDropLayer.addChild(node)
        case .highestPriorityLayer:
            highestPriorityLayer.addChild(node)
        }
    }

    func update(with deltaTime: TimeInterval) {
        gameEngine.update(with: deltaTime)
    }
}

/**
 Extension to deal with button-related logic
 */
extension RootRenderNode {
    func summonButtonTapped() {
        gameEngine.startNextSpawnWave()
    }

    func powerUpButtonTapped() {
        gameEngine.updateSelectedPowerUp(powerUpType: selectedPowerUp)
    }
}

/**
 Extension to propagate Scene-related logic to GameScene
 */
extension RootRenderNode {
    // TODO: Should this be re-factored
    /** Propagates the call upwards to GameScene */
    func gameDidEnd(didWin: Bool, finalScore: Int) {
        guard let gameScene = scene as? GameScene else {
            print("Scene is not of type GameScene")
            return
        }

        gameScene.gameDidEnd(didWin: didWin, finalScore: finalScore)
    }
}


/**
 Extension to deal with power-up related logic
 */
extension RootRenderNode {
    /** Detects the activation of Power Ups */
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        gameEngine.activatePowerUp(at: touch.location(in: self))
    }

    func deselectPowerUp() {
        selectedPowerUp = nil
        gameEngine.updateSelectedPowerUp(powerUpType: selectedPowerUp)
    }

    var selectedPowerUp: PowerUpType? {
        get {
            playerAreaNode.powerUpContainerNode.selectedPowerUp
        }
        set {
            playerAreaNode.powerUpContainerNode.selectedPowerUp = newValue
        }
    }

    func deactivateGestureDetection() {
        gestureAreaNode.isUserInteractionEnabled = false
    }

    func activateGestureDetection() {
        gestureAreaNode.isUserInteractionEnabled = true
    }

    func showInsufficientMana(at location: CGPoint) {
        let insufficientManaLabel = SKLabelNode(fontNamed: GameConfig.fontName)
        insufficientManaLabel.position = location
        insufficientManaLabel.text = "Insufficient Mana"
        insufficientManaLabel.fontSize = size.width / 25
        insufficientManaLabel.fontColor = .green
        let animationAction = SKAction.sequence([
            .move(by: .init(dx: 0.0, dy: size.width / 100), duration: 1.5),
            .fadeOut(withDuration: 0.25),
            .removeFromParent()
        ])

        insufficientManaLabel.run(animationAction)
        highestPriorityLayer.addChild(insufficientManaLabel)
    }

    func showPowerUpDisabled(at location: CGPoint) {
        let powerUpDisabledLabel = SKLabelNode(fontNamed: GameConfig.fontName)
        powerUpDisabledLabel.position = location
        powerUpDisabledLabel.text = "PowerUp Disabled"
        powerUpDisabledLabel.fontSize = size.width / 25
        powerUpDisabledLabel.fontColor = .red
        let animationAction = SKAction.sequence([
            .move(by: .init(dx: 0.0, dy: size.width / 100), duration: 1.5),
            .fadeOut(withDuration: 0.25),
            .removeFromParent()
        ])

        powerUpDisabledLabel.run(animationAction)
        highestPriorityLayer.addChild(powerUpDisabledLabel)
    }
}