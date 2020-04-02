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
    private var gameEngine: GameEngine!
    private var lastUpdateTime: TimeInterval = 0.0
    private lazy var maximumUpdateDeltaTime: TimeInterval = { 1 / .init((view?.preferredFramesPerSecond ?? 60)) }()
    private weak var gameStateMachine: GameStateMachine?

    // layers
    private var backgroundLayer: SKNode!
    private var powerUpAnimationLayer: SKNode!
    private var enemyLayer: SKNode!
    private var removalAnimationLayer: SKNode!
    private var gestureLayer: SKNode!
    private var playerAreaLayer: SKNode!
    private var manaDropLayer: SKNode!
    private var highestPriorityLayer: SKNode!
    private(set) var playerAreaNode: PlayerAreaNode!
    private(set) var gestureAreaNode: GestureAreaNode!
    private var bgmNode: SKAudioNode!

    init(size: CGSize, gameStateMachine: GameStateMachine) {
        self.gameStateMachine = gameStateMachine
        super.init(size: size)
        
        registerForPauseNotifications()
    }
    
    deinit {
        unregisterNotifications()
        print("deinit game scene")
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sceneDidLoad() {
        guard let stage = gameStateMachine?.stage,
            let avatar = gameStateMachine?.avatar else {
            fatalError("Unable to load stage or/and avatar from GameStateMachine")
        }

        gameEngine = GameEngine(gameScene: self, stage: stage, avatar: avatar)
        physicsWorld.contactDelegate = gameEngine.contactDelegate

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
        
        // set up bgm
        bgmNode = .init(fileNamed: "Disturbance in Agustria")
        addChild(bgmNode)
    }
    
    private func buildLayers() {
        backgroundLayer = .init()
        backgroundLayer.zPosition = GameConfig.GamePlayScene.backgroundLayerZPosition
        addChild(backgroundLayer)
        
        powerUpAnimationLayer = .init()
        powerUpAnimationLayer.zPosition = GameConfig.GamePlayScene.powerUpAnimationLayerZPosition
        addChild(powerUpAnimationLayer)
        
        enemyLayer = .init()
        enemyLayer.zPosition = GameConfig.GamePlayScene.enemyLayerZPosition
        addChild(enemyLayer)
        
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
    
    private func setUpBackground(arenaType: ArenaType? = nil) {
        let backgroundNode = SKSpriteNode(
            texture: arenaType?.texture ?? ArenaType.allCases.randomElement()?.texture ?? .init(),
            color: .clear,
            size: size
        )
        backgroundNode.aspectFillToSize(fillSize: size)
        backgroundNode.position = .init(x: frame.midX, y: frame.midY)
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
        playerAreaNode.powerUpContainerNode.selectedPowerUpResponder = self
        playerAreaLayer.addChild(playerAreaNode)
    }
    
    private func setUpGestureArea() {
        gestureAreaNode = .init(
            size: size.applying(.init(scaleX: 1.0, y: GameConfig.GamePlayScene.gestureAreaHeightRatio)),
            gameEngine: gameEngine
        )
        gestureAreaNode.position = .init(x: frame.midX, y: frame.midY) +
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
            position: .init(x: frame.maxX, y: frame.maxY)
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
        endPointNode.size = .init(width: newEndPointWidth, height: newEndPointHeight)
        endPointNode.position = playerAreaNode.position
            + .init(dx: 0.0, dy: (playerAreaNode.size.height + newEndPointHeight) / 2)
        
        // relative to the player area layer
        endPointNode.zPosition = -1
        
        let endPointEntity = EndPointEntity(node: endPointNode)
        gameEngine.add(endPointEntity)
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
    
    override func update(_ currentTime: TimeInterval) {
        var deltaTime = currentTime - lastUpdateTime
        deltaTime = deltaTime > maximumUpdateDeltaTime ? maximumUpdateDeltaTime : deltaTime
        lastUpdateTime = currentTime
        
        gameEngine.update(with: deltaTime)
    }
    
    func addNodeToLayer(layer: SpriteLayerType, node: SKNode) {
        switch layer {
        case .backgroundLayer:
            backgroundLayer.addChild(node)
        case .powerUpAnimationLayer:
            powerUpAnimationLayer.addChild(node)
        case .enemyLayer:
            enemyLayer.addChild(node)
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
    
    func gameDidEnd(didWin: Bool, finalScore: Int) {
        gameStateMachine?.state(forClass: GameEndState.self)?.didWin = didWin
        gameStateMachine?.state(forClass: GameEndState.self)?.finalScore = finalScore
        gameStateMachine?.enter(GameEndState.self)
    }
}

/**
 Extension to deal with button-related logic (when buttons are tapped)
 */
extension GameScene: TapResponder {
    func onTapped(tappedNode: ButtonNode) {
        switch tappedNode.buttonType {
        case .pauseButton:
            gameStateMachine?.enter(GamePauseState.self)
        case .summonButton:
            gameEngine.startNextSpawnWave()
        default:
            print("Unknown node tapped")
        }
    }
}

/** Pause Game when the application becomes inactive */
extension GameScene {
    private func registerForPauseNotifications() {
        let pauseNotificationName = UIApplication.willResignActiveNotification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pauseGame),
            name: pauseNotificationName,
            object: nil
        )
    }
    
    @objc private func pauseGame() {
        gameStateMachine?.enter(GamePauseState.self)
    }
    
    private func unregisterNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}

/**
 Extension to deal with power-up related logic
 */
extension GameScene: SelectedPowerUpResponder {
    /** Detects the activation of Power Ups */
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, selectedPowerUp == .darkVortex else {
            return
        }
        
        // reasonable arbitrary value for darkVortex radius
        let radius = size.width / 3
        activatePowerUp(at: touch.location(in: self), with: .init(width: radius, height: radius))
    }
    
    func activatePowerUp(at location: CGPoint, with size: CGSize) {
        guard selectedPowerUp != nil else {
            return
        }

        gameEngine.activatePowerUp(at: location, with: size)
        deselectPowerUp()
    }
    
    func deselectPowerUp() {
        playerAreaNode.powerUpContainerNode.selectedPowerUp = nil
    }
    
    var selectedPowerUp: PowerUpType? {
        playerAreaNode.powerUpContainerNode.selectedPowerUp
    }
    
    func selectedPowerUpDidChanged(oldValue: PowerUpType?, newSelectedPowerUp: PowerUpType?) {
        // Deactivate and activate gesture detection when tap-activated power ups are selected
        gameEngine.changeSelectedPowerUp(to: newSelectedPowerUp)
        
        if let selectedPowerUp = selectedPowerUp, selectedPowerUp == .darkVortex {
            deactivateGestureDetection()
        } else if oldValue == .darkVortex {
            activateGestureDetection()
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
