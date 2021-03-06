//
//  GameStageSelectionState.swift
//  GameOfRunes
//
//  Created by Jermy on 28/3/20.
//  Copyright © 2020 TeamHoWan. All rights reserved.
//

import GameplayKit

/** State for `GameStateMachine` when the player is selecting the stage. */
class GameStageSelectionState: GKState {
    /** Checks for if the state to transition to is valid. */
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass is GameStartState.Type || stateClass is GameModeSelectionState.Type
    }
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        guard let gameStateMachine = stateMachine as? GameStateMachine,
            let sceneManager = gameStateMachine.sceneManager else {
                fatalError("No SceneManager associated with GameStateMachine")
        }
        
        if previousState is GameEndState || previousState is GamePauseState {
            sceneManager.transitionToScene(
                sceneIdentifier: .map,
                transition: .doorsOpenHorizontal(withDuration: GameConfig.SceneManager.sceneTransitionDuration)
            )
            return
        } else if previousState is GameModeSelectionState {
            sceneManager.loadNewMap()
        }
        
        sceneManager.transitionToScene(sceneIdentifier: .map)
    }
}
