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
    private(set) var backgroundLayer: SKNode!
    private(set) var enemyLayer: SKNode!
    private(set) var powerUpAnimationLayer: SKNode!
    private(set) var gestureLayer: SKNode!
    private(set) var playerAreaLayer: SKNode!
    private(set) var manaDropLayer: SKNode!
    private(set) var highestPriorityLayer: SKNode!
    private(set) var playerAreaNode: PlayerAreaNode!
    private(set) var gestureAreaNode: GestureAreaNode!
    var bgmNode: SKAudioNode!
    
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
        let dispatchGroup = DispatchGroup()
        // marks the start of possible async block
        dispatchGroup.enter()
        
        // must use other thread queues (not .main) to avoid deadlocks
        DispatchQueue.global(qos: .default).async {
            // set up animation textures
            TextureContainer.loadTextures()
            PowerUpType.loadPowerUpCastsTextures()
            // indicates that the execution is done
            dispatchGroup.leave()
        }
        
        // continue setting up other stuff in .main thread
        gameEngine = GameEngine(gameScene: self, gameStateMachine: gameStateMachine)
        
        // UI
        buildLayers()
        setUpBackground()
        setUpPlayerArea()
        setUpGestureArea()
        setUpPauseButton()
        
        // Entities
        setUpEndPoint()
        setUpPlayerHealth()
        setUpPlayerMana()
        
        // set up bgm
        bgmNode = .init(fileNamed: "Lion King Eldigan")
        
        // ensures textures have been loaded
        dispatchGroup.wait()
    }
    
    override func didMove(to view: SKView) {
        addChild(bgmNode)
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        
        bgmNode.removeFromParent()
    }
    
    private func buildLayers() {
        backgroundLayer = .init()
        backgroundLayer.zPosition = GameConfig.GamePlayScene.backgroundLayerZPosition
        addChild(backgroundLayer)
        
        enemyLayer = .init()
        enemyLayer.zPosition = GameConfig.GamePlayScene.enemyLayerZPosition
        addChild(enemyLayer)
        
        powerUpAnimationLayer = .init()
        powerUpAnimationLayer.zPosition = GameConfig.GamePlayScene.powerUpAnimationLayerZPosition
        addChild(powerUpAnimationLayer)
        
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
        playerAreaNode.powerUpContainerNode.gameScene = self
        playerAreaLayer.addChild(playerAreaNode)
    }
    
    private func setUpGestureArea() {
        gestureAreaNode = .init(
            size: size.applying(.init(scaleX: 1.0, y: GameConfig.GamePlayScene.gestureAreaHeightRatio)),
            gameEngine: gameEngine
        )
        gestureAreaNode.position = .init(x: frame.midX, y: frame.midY) + .init(dx: 0.0, dy: playerAreaNode.size.height / 2)
        gestureLayer.addChild(gestureAreaNode)
    }
    
    private func setUpPauseButton() {
        // re-position and resize
        let buttonMargin = GameConfig.GamePlayScene.buttonMargin
        let buttonSize = CGSize(
            width: size.width * GameConfig.GamePlayScene.buttonWidthRatio,
            height: size.width * GameConfig.GamePlayScene.buttonHeightRatio
        )
        let pauseButton = ButtonNode(
            size: buttonSize,
            position: .init(x: frame.maxX, y: frame.maxY)
                + .init(dx: -buttonSize.width / 2, dy: -buttonSize.height / 2)
                + .init(dx: -buttonMargin, dy: -buttonMargin),
            texture: .init(imageNamed: ButtonType.pauseButton.rawValue),
            name: ButtonType.pauseButton.rawValue
        )
        
        highestPriorityLayer.addChild(pauseButton)
    }
    
    private func setUpEndPoint() {
        let endPointNode = SKSpriteNode(imageNamed: "finish-line")
        // re-position and resize
        let newEndPointWidth = size.width
        let newEndPointHeight = size.height * GameConfig.GamePlayScene.endPointHeightRatio
        endPointNode.size = .init(width: newEndPointWidth, height: newEndPointHeight)
        endPointNode.position = playerAreaNode.position
            + .init(dx: 0.0, dy: (playerAreaNode.size.height + newEndPointHeight) / 2)
        // TODO: after a layer parameter have been added to sprite component
        endPointNode.zPosition = 299
        
        let endPointEntity = EndPointEntity(node: endPointNode)
        gameEngine.add(endPointEntity)
    }
    
    private func setUpPlayerHealth() {
        let healthBarNode = playerAreaNode.healthBarNode
        // arbitrary num, can be replaced with meta-data
        healthBarNode.totalLives = 5
        let playerHealthEntity = PlayerHealthEntity(healthPoints: healthBarNode.totalLives, healthBarNode: healthBarNode)
        gameEngine.add(playerHealthEntity)
    }
    
    private func setUpPlayerMana() {
        let manaBarNode = playerAreaNode.manaBarNode
        // arbitrary num, can be replaced with meta-data
        manaBarNode.numManaUnits = 8
        manaBarNode.manaPointsPerUnit = 10
        let playerManaEntity = PlayerManaEntity(manaPoints: 0, manaBarNode: manaBarNode)
        gameEngine.add(playerManaEntity)
    }
    
    override func update(_ currentTime: TimeInterval) {
        var deltaTime = currentTime - lastUpdateTime
        deltaTime = deltaTime > maximumUpdateDeltaTime ? maximumUpdateDeltaTime : deltaTime
        lastUpdateTime = currentTime

        gameEngine.update(with: deltaTime)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
            let selectedPowerUp = playerAreaNode.powerUpContainerNode.selectedPowerUp else {
            return
        }
        selectedPowerUp.runAnimation(
            at: touch.location(in: powerUpAnimationLayer),
            with: .init(width: size.width / 3, height: size.width / 3),
            on: powerUpAnimationLayer
        )
        playerAreaNode.powerUpContainerNode.selectedPowerUp = nil
    }
}

/**
 Extension to deal with button-related logic (i.e. the Pause Button)
 */
extension GameScene: TapResponder {
    func onTapped(tappedNode: SKSpriteNode) {
        switch tappedNode.name {
        case ButtonType.pauseButton.rawValue:
            gameStateMachine?.enter(GamePauseState.self)
        case ButtonType.summonButton.rawValue:
            gameEngine.spawnEnemy()
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
