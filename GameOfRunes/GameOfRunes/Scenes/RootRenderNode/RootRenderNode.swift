//
//  RootRenderNode.swift
//  GameOfRunes
//
//  Created by Brian Yen on 10/4/20.
//  Copyright © 2020 TeamHoWan. All rights reserved.
//

import SpriteKit

/**
 `SKNode` that acts as the root node for all the UI elements
 required for a game. This class establishes the UI for the game (in Single
 Player Mode). It comes packaged together with a GameEngine so that
 an entire game unit can be added to a `GameScene` just by initialising
 an instance of this class.
 */
class RootRenderNode: SKNode, RenderNodeFacade {
    var gameEngine: GameEngineFacade!
    private(set) var size: CGSize
    var center: CGPoint {
        .init(x: size.width / 2, y: size.height / 2)
    }

    // layers
    private(set) var backgroundLayer: SKNode!
    private(set) var powerUpAnimationLayer: SKNode!
    private(set) var unitLayer: SKNode!
    private(set) var removalAnimationLayer: SKNode!
    private(set) var gestureLayer: SKNode!
    private(set) var playerAreaLayer: SKNode!
    private(set) var manaDropLayer: SKNode!
    private(set) var highestPriorityLayer: SKNode!

    private var playerAreaNode: PlayerAreaNode!
    var playerEndPoint: SKSpriteNode!
    private var gestureAreaNode: GestureAreaNode!
    private var bgmNode: SKAudioNode!

    init(stage: Stage,
         avatar: Avatar,
         zPosition: CGFloat,
         position: CGPoint,
         size: CGSize) {

        self.size = size
        super.init()
        self.position = position
        self.gameEngine = GameEngine(stage: stage, avatar: avatar, renderNode: self)
        
        // Allows RootRenderNode to add Entities during set-up
        self.zPosition = zPosition
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
        setUpBackgroundMusic()
    }

    /**
     Minimal initialiser that only populates required instance parameters.
     No setting up of UI elements is performed.
     Called by Subclass `RemoteRootRenderNode`.
     */
    init(size: CGSize) {
        self.size = size
        super.init()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func buildLayers() {
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

    func setUpBackground() {
        let backgroundNode = SKSpriteNode(
            texture: gameEngine.metadata.stage.arena.texture,
            color: .clear,
            size: size
        )
        backgroundNode.position = center
        backgroundLayer.addChild(backgroundNode)
    }

    func setUpPlayerArea() {
        let playerAreaWidth = size.width
        let playerAreaHeight = size.height * GameConfig.GamePlayScene.playerAreaHeightRatio
        playerAreaNode = .init(
            size: .init(width: playerAreaWidth, height: playerAreaHeight),
            position: .init(x: playerAreaWidth / 2, y: playerAreaHeight / 2)
        )

        playerAreaNode.powerUpContainerNode.powerUpTypes = gameEngine.metadata.availablePowerUps
        playerAreaLayer.addChild(playerAreaNode)
    }

    func setUpGestureArea() {
        gestureAreaNode = .init(
            size: size.applying(.init(scaleX: 1.0, y: GameConfig.GamePlayScene.gestureAreaHeightRatio)),
            gameEngine: gameEngine
        )
        gestureAreaNode.position = center +
            .init(dx: 0.0, dy: playerAreaNode.size.height / 2)
        gestureLayer.addChild(gestureAreaNode)
    }

    func setUpPauseButton() {
        // Re-position and resize
        let buttonMargin = GameConfig.GamePlayScene.buttonMargin
        let buttonSize = CGSize(
            width: size.width * GameConfig.GamePlayScene.buttonWidthRatio,
            height: size.width * GameConfig.GamePlayScene.buttonHeightRatio
        )
        let pauseButton = ButtonNode(
            size: buttonSize,
            texture: .init(imageNamed: "pause-button"),
            buttonType: .pauseButton,
            position: .init(x: 0, y: size.height)
                + .init(dx: buttonSize.width / 2, dy: -buttonSize.height / 2)
                + .init(dx: buttonMargin, dy: -buttonMargin)
        )

        // relative to the layer
        pauseButton.zPosition = 1

        highestPriorityLayer.addChild(pauseButton)
    }

    func setUpEndPoint() {
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
        gameEngine.addEndPointEntity(node: endPointNode, team: .player)

        // check if need to add enemy end point for elite knight
        guard gameEngine.metadata.avatar == .holyKnight else {
            return
        }

        let enemyEndPointNode = SKSpriteNode(color: .clear, size: newEndPointSize)
        let yPosition = (1 - GameConfig.GamePlayScene.verticalOffSetRatio) * size.height
        enemyEndPointNode.position = .init(x: center.x, y: yPosition)
        gameEngine.addEndPointEntity(node: enemyEndPointNode, team: .enemy)
    }

    func setUpPlayer() {
        let healthNode = setUpPlayerHealth()
        let manaNode = setUpPlayerMana()
        let scoreNode = playerAreaNode.scoreNode
        gameEngine.addPlayerEntity(healthNode: healthNode,
                                   manaNode: manaNode,
                                   scoreNode: scoreNode)
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

    func setUpTimer(isCountdown: Bool, initialTimerValue: TimeInterval = 0) {
        let timerNode = SKLabelNode(fontNamed: "DragonFire")

        timerNode.fontSize = 50
        timerNode.fontColor = SKColor.white
        timerNode.position = CGPoint(x: size.width / 2, y: 50)
        timerNode.zPosition = 75
        timerNode.horizontalAlignmentMode = .center
        timerNode.verticalAlignmentMode = .center
        timerNode.text = "\(Int(initialTimerValue))"

        gameEngine.addTimerEntity(timerNode: timerNode, initialTimerValue: initialTimerValue)
    }

    func setUpBackgroundMusic() {
        bgmNode = .init(fileNamed: "Disturbance in Agustria")
        addChild(bgmNode)
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
 Extension to deal with button-related logic (when calls are
 propagated from `GameScene`
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
 Extension to propagate Scene-related logic to `GameScene`
 */
extension RootRenderNode {
    /**
     Propagates the call upwards to GameScene.
     - Note: GameScene is responsible for State and Scene-related
     transitions (it has a reference to `GameStateMachine` for this purpose.
     */
    func gameDidEnd(didWin: Bool, finalScore: Int) {
        (scene as? GameScene)?.gameDidEnd(didWin: didWin, finalScore: finalScore)
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

        gameEngine.activatePowerUp(at: touch.location(in: self), with: nil)
    }

    func deselectPowerUp() {
        guard playerAreaNode != nil else {
            return
        }
        
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
