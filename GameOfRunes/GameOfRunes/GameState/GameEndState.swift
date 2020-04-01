//
//  GameEndState.swift
//  GameOfRunes
//
//  Created by Brian Yen on 11/3/20.
//  Copyright © 2020 TeamHoWan. All rights reserved.
//

import GameplayKit

/** State for `GameStateMachine` when the Game has ended (either
 win or lose state has been reached) */
class GameEndState: GKState {
    // initialise with placeholder value
    var didWin = true
    var finalScore = 0
    
    /** Checks for if the state to transition to is valid. */
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is GameStartState.Type, is GameSelectionState.Type:
            return true
        default:
            return false
        }
    }
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        guard let gameStateMachine = stateMachine as? GameStateMachine,
            let sceneManager = gameStateMachine.sceneManager else {
                fatalError("No SceneManager associated with GameStateMachine")
        }

        updateStageData()
        sceneManager.transitionToScene(sceneIdentifier: .end(win: didWin))
    }

    func updateStageData() {
        guard let gameStateMachine = stateMachine as? GameStateMachine,
            var stage = gameStateMachine.stage else {
                return
        }

        if finalScore > stage.highScore {
            stage.highScore = finalScore
        }

        HomeViewController.storage.save(stages: stage)
    }
}
