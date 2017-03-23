//
//  MenuScene.swift
//  SpaceGame
//
//  Created by Avinash on 22/03/17.
//  Copyright © 2017 avinash. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {
    var starfield:SKEmitterNode!
    
    var newGameButtonNode:SKSpriteNode!
    var difficultyButtonNode:SKSpriteNode!
    var difficultyLabelNode:SKLabelNode!
    var highScoreLabelNode:SKLabelNode!
    var highScoreValueNode:SKLabelNode!
    
    override func didMove(to view: SKView) {
        starfield = self.childNode(withName: "starfield") as! SKEmitterNode
        starfield.advanceSimulationTime(10)
        
        newGameButtonNode = self.childNode(withName: "newGameButton") as! SKSpriteNode
        
        difficultyButtonNode = self.childNode(withName: "difficultyButton") as! SKSpriteNode
        
        //newGameButtonNode.texture = SKTexture(imageNamed: "newGameButton")
        //difficultyButtonNode.texture = SKTexture(imageNamed: "difficultyButton")
        
        difficultyLabelNode = self.childNode(withName: "difficultyLabel") as! SKLabelNode
        highScoreLabelNode = self.childNode(withName: "highScoreLabel") as! SKLabelNode
        highScoreValueNode = self.childNode(withName: "highScoreValue") as! SKLabelNode
        
        let userDefaults = UserDefaults.standard
        if userDefaults.bool(forKey: "highScore"){
            highScoreValueNode.text = String(userDefaults.integer(forKey: "highScore"))
        }
        if userDefaults.bool(forKey: "hard"){
            difficultyLabelNode.text = "Hard"
        }else{
            difficultyLabelNode.text = "Easy"
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if let location = touch?.location(in: self){
            let nodesArray = self.nodes(at: location)
            
            //on click of newGameButton load the GameScene
            
            if nodesArray.first?.name == "newGameButton"{
                
                //transition to our gameScene
                
                let transition = SKTransition.fade(withDuration: 0.5)
                let gameScene = GameScene(size: self.size)
                self.view?.presentScene(gameScene, transition: transition)
                
            }else if nodesArray.first?.name == "difficultyButton"{
                changeDifficulty()
            }
        }
        
    }
    func changeDifficulty(){
        let userDefaults = UserDefaults.standard
        
        if difficultyLabelNode.text == "Easy"{
            difficultyLabelNode.text = "Hard"
            userDefaults.set(true, forKey: "hard")
        }else{
            difficultyLabelNode.text = "Easy"
            userDefaults.set(false, forKey: "hard")
        }
        //save the userDefaults
        userDefaults.synchronize()
    }
}
