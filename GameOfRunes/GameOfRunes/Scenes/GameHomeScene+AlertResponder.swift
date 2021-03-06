//
//  GameHomeScene+AlertResponder.swift
//  GameOfRunes
//
//  Created by Jermy on 17/4/20.
//  Copyright © 2020 TeamHoWan. All rights reserved.
//

extension GameHomeScene: AlertResponder {
    func crossOnTapped(sender: AlertNode) {
        sender.hideAlert()
    }
    
    func tickOnTapped(sender: AlertNode) {
        if sender.identifier == "reset" {
            sender.showLoader = true
            GameViewController.storage.reset()
            GameViewController.initStagesInDatabase()
            sender.presentAlert(
                alertDescription: "Game data has been successfully reset",
                showTick: true,
                showCross: false,
                showLoader: false,
                status: .success
            )
            return
        }
        
        sender.hideAlert()
    }
}
