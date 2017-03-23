//
//  GameScene.swift
//  SpaceGame
//
//  Created by Avinash on 19/03/17.
//  Copyright © 2017 avinash. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var starfield:SKEmitterNode!
    var player:SKSpriteNode!
    
    var scoreLabel:SKLabelNode!
    //intitate score with 0 and make it a computed property with didSet
    var score:Int  = 0{
        didSet{
            scoreLabel.text = "Score: \(score)"
        }
    }
    var highScore:Int = 0
    var gameTimer:Timer!
    var possibleAliens = ["alien", "alien2", "alien3"]
    let alienCategory:UInt32 = 0x1 << 1
    let photonTorpedoCategory:UInt32 = 0x1 << 0
    
    //Motion Sensor
    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0
    
    var livesArray:[SKSpriteNode]!
    
    override func didMove(to view: SKView) {
        addLives()
        
        starfield = SKEmitterNode(fileNamed: "Starfield") //load the Starfield.sks file into our game scene
        starfield.position = CGPoint(x: 0, y: 1334)
        starfield.advanceSimulationTime(10) //this is because the starfiled after starting from top takes few secs to reach the bottom, so we advance the simulation time
        self.addChild(starfield)
        
        starfield.zPosition = -1 //this to always keep it behind everything
        
        player = SKSpriteNode(imageNamed: "shuttle")
        player.size = CGSize(width: 45, height: 44)
        player.position = CGPoint(x: self.frame.midX, y: self.frame.minY+(player.size.height/2+10)) //add the player centered to the screen and 20px from the bottom
        self.addChild(player)
        
        //disable Gravity, gravity is a CGVector
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: self.frame.minX+75, y: self.frame.maxY-50)
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = UIColor.white
        score = 0
        self.addChild(scoreLabel)
        
        var timeInterval = 0.75
        
        if UserDefaults.standard.bool(forKey: "hard"){
            timeInterval = 0.50
        }
        
        //note the selector: #selector(addAlein) below is the method addAlien we create which we pass as a selector
        gameTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
       
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: (OperationQueue.current)!) { (data:CMAccelerometerData?, error:Error?) in
            if let accelerometerData = data{
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.50 /*+ self.xAcceleration * 0.25*/
            }
        }
    }
    func addLives(){
        livesArray = [SKSpriteNode]()
        
        for live in 1 ... 3 {
            let liveNode = SKSpriteNode(imageNamed: "shuttle")
            liveNode.position = CGPoint(x: self.frame.maxX-CGFloat(4-live)*liveNode.size.width, y: self.frame.maxY-40)
            self.addChild(liveNode)
            livesArray.append(liveNode)
            
        }
    }
    func addAlien(){
        //using the sharedRandom() from GamePlayKit "GKRandomSource" we can randomize our aliens by shuffling the array as below
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        
        //we can now choose the starting image from oir possibleAliens array and assign it to alien
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        
        let randonAlienPosition = GKRandomDistribution(lowestValue: Int(self.frame.minX), highestValue: Int(self.frame.maxX))
        let position = CGFloat(randonAlienPosition.nextInt())
        
        alien.position = CGPoint(x: position, y: self.frame.maxY - alien.size.height)
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        let animationDuration:TimeInterval = 4
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: position, y:self.frame.minY + alien.size.height), duration: animationDuration))
        actionArray.append(SKAction.run {
            self.run(SKAction.playSoundFileNamed("loose.mp3", waitForCompletion: false))
            if self.livesArray.count > 0{
                let liveNode = self.livesArray.first
                liveNode!.removeFromParent()
                self.livesArray.removeFirst()
                
                if self.livesArray.count == 0 {
                    if self.score > self.highScore{
                        self.highScore = self.score
                        UserDefaults.standard.set(self.score, forKey: "highScore")
                    }
                    //Game over screen transition
                    let transition = SKTransition.fade(withDuration: 0.5)
                    let gameOver = SKScene(fileNamed: "GameOverScene") as! GameOverScene
                    gameOver.score = self.score
                    self.view?.presentScene(gameOver, transition: transition)
                }
            }
        })
        actionArray.append(SKAction.removeFromParent())
        
        alien.run(SKAction.sequence(actionArray))
        
    }
    //fire a torpedo when the user touches the screen
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireTorpedo()
    }
    func fireTorpedo(){
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.position = player.position
        torpedoNode.position.y += 5
        
        //torpedo to collide with the aliens
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.isDynamic = true
        
        torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = alienCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(torpedoNode)
        
        let animationDuration:TimeInterval = 0.4
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y:self.frame.size.height + 10), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        torpedoNode.run(SKAction.sequence(actionArray))
        
    }
    //idnetify the alien and torpedo physics bodies and then call the torpedoDidCollideWithAlien fn when they collide
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0 {
            self.torpedoDidCollideWithAlien(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
        }
    }
    
    func torpedoDidCollideWithAlien(torpedoNode:SKSpriteNode, alienNode:SKSpriteNode){
        let explosion = SKEmitterNode(fileNamed: "Explosion")
        explosion?.position = alienNode.position
        self.addChild(explosion!)
        
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        //remove both the torpedo and alien nodes on collision
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        //note the run function has a completion() handler, this is to remove the explosion mp3
        self.run(SKAction.wait(forDuration: 4)) {
            explosion?.removeFromParent()
        }
        score += 1
    }
    override func didSimulatePhysics() {
        player.position.x += xAcceleration * 50
        if player.position.x < (self.frame.minX - 20){
            player.position = CGPoint(x: self.frame.minX, y: player.position.y)
        }else if player.position.x > (self.frame.maxX + 20){
            player.position = CGPoint(x: self.frame.maxX, y: player.position.y)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
