/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SpriteKit

// The category on SpriteKit is just a single 32-bit integer, acting as a bitmask. This is a fancy way of saying each of the 32-bits in the integer represents a single category (and hence you can have 32 categories max). Here you're setting the first bit to indicate a monster, the next bit over to represent a projectile, and so on.
struct PhysicsCategory {
  static let none      : UInt32 = 0
  static let all       : UInt32 = UInt32.max
  static let monster   : UInt32 = 0b1       // 1
  static let projectile: UInt32 = 0b10      // 2
}

func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
  return CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
  
  func normalized() -> CGPoint {
    return self / length()
  }
}

class GameScene: SKScene {
  // Here you declare a private constant for the player (i.e. the ninja), which is an example of a sprite. As you can see, creating a sprite is easy — simply pass in the name of the image to use.
  let player = SKSpriteNode(imageNamed: "player")
  
  var monstersDestroyed = 0
  
  override func didMove(to view: SKView) {
    // Setting the background color of a scene in SpriteKit is as simple as setting the backgroundColor property. Here you set it to white.
    backgroundColor = SKColor.white
    // You position the sprite to be 10% across horizontally, and centered vertically.
    player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
    // This sets up the physics world to have no gravity, and sets the scene as the delegate to be notified when two physics bodies collide.
    physicsWorld.gravity = .zero
    physicsWorld.contactDelegate = self
    // To make the sprite appear on the scene, you must add it as a child of the scene.
    addChild(player)
    
    // Start background music
    let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
    backgroundMusic.autoplayLooped = true
    addChild(backgroundMusic)
    
    // Start spawning monsters every 1 second
    run(SKAction.repeatForever(
      SKAction.sequence([
        SKAction.run(addMonster),
        SKAction.wait(forDuration: 2.0)
        ])
    ))
  }
  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }
  
  func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
  }
  
  func addMonster() {
    
    // Create sprite
    let monster = SKSpriteNode(imageNamed: "monster")
    
    // Physics settings for monster
    // Create a physics body for the sprite. In this case, the body is defined as a rectangle of the same size as the sprite, since that's a decent approximation for the monster.
    monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size) // 1
    // Set the sprite to be dynamic. This means that the physics engine will not control the movement of the monster. You will through the code you've already written, using move actions. Dynamic = kinematic in Unity
    monster.physicsBody?.isDynamic = true // 2
    // Set the category bit mask to be the monsterCategory you defined earlier.
    monster.physicsBody?.categoryBitMask = PhysicsCategory.monster // 3
    // contactTestBitMask indicates what categories of objects this object should notify the contact listener when they intersect. You choose projectiles here.
    monster.physicsBody?.contactTestBitMask = PhysicsCategory.projectile // 4
    // collisionBitMask indicates what categories of objects this object that the physics engine handle contact responses to (i.e. bounce off of). You don't want the monster and projectile to bounce off each other — it's OK for them to go right through each other in this game — so you set this to .none.
    monster.physicsBody?.collisionBitMask = PhysicsCategory.none // 5
    
    // Determine where to spawn the monster along the Y axis
    let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
    
    // Position the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
    
    // Add the monster to the scene
    addChild(monster)
    
    // Determine speed of the monster
    let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
    
    // Create the actions
    let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY),
                                   duration: TimeInterval(actualDuration))
    let actionMoveDone = SKAction.removeFromParent()
    // Commenting this out so that player loses instead
    //monster.run(SKAction.sequence([actionMove, actionMoveDone]))
    // This instead of above so that player loses
    let loseAction = SKAction.run() { [weak self] in
      guard let `self` = self else { return }
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: false)
      self.view?.presentScene(gameOverScene, transition: reveal)
    }
    monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
  }
  
  // Tells the responder when one or more fingers are raised from a view or window.
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    // 1 - Choose one of the touches to work with
    // One of the cool things about SpriteKit is that it includes a category on UITouch with location(in:) and previousLocation(in:) methods. These let you find the coordinate of a touch within an SKNode's coordinate system. In this case, you use it to find out where the touch is within the scene's coordinate system.
    guard let touch = touches.first else {
      return
    }
    run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
    let touchLocation = touch.location(in: self)
    
    // 2 - Set up initial location of projectile
    // You then create a projectile and place it where the player is to start. Note you don't add it to the scene yet, because you have to do some sanity checking first - this game does not allow the ninja to shoot backwards.
    let projectile = SKSpriteNode(imageNamed: "projectile")
    projectile.position = player.position
    
    // You're using a circle shaped body instead of a rectangle body. Since the projectile is a nice circle, this makes for a better match.
    projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
    // Projectiles are kinematic
    projectile.physicsBody?.isDynamic = true
    projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
    projectile.physicsBody?.contactTestBitMask = PhysicsCategory.monster
    projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
    // You also set usesPreciseCollisionDetection to true. This is important to set for fast moving bodies like projectiles, because otherwise there is a chance that two fast moving bodies can pass through each other without a collision being detected.
    projectile.physicsBody?.usesPreciseCollisionDetection = true
    
    // 3 - Determine offset of location to projectile
    // You then subtract the projectile's current position from the touch location to get a vector from the current position to the touch location.
    let offset = touchLocation - projectile.position
    
    // 4 - Bail out if you are shooting down or backwards
    // If the X value is less than 0, this means the player is trying to shoot backwards. This is not allowed in this game (real ninjas don't look back!), so just return.
    if offset.x < 0 { return }
    
    // 5 - OK to add now - you've double checked position
    // Otherwise, it's OK to add the projectile to the scene.
    addChild(projectile)
    
    // 6 - Get the direction of where to shoot
    // Convert the offset into a unit vector (of length 1) by calling normalized(). This will make it easy to make a vector with a fixed length in the same direction, because 1 * length = length.
    let direction = offset.normalized()
    
    // 7 - Make it shoot far enough to be guaranteed off screen
    // Multiply the unit vector in the direction you want to shoot in by 1000. Why 1000? It will definitely be long enough to go past the edge of the screen. :]
    let shootAmount = direction * 1000
    
    // 8 - Add the shoot amount to the current position
    // Add the shoot amount to the current position to get where it should end up on the screen.
    let realDest = shootAmount + projectile.position
    
    // 9 - Create the actions
    // Finally, create move(to:,duration:) and removeFromParent() actions like you did earlier for the monster.
    let actionMove = SKAction.move(to: realDest, duration: 2.0)
    let actionMoveDone = SKAction.removeFromParent()
    projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
  }
  
  // A method that will be called when the projectile collides with the monster before the closing curly brace of GameScene.
  func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
    print("Hit")
    projectile.removeFromParent()
    monster.removeFromParent()
    
    // Increment monstersDestroyed
    monstersDestroyed += 1
    if monstersDestroyed > 30 {
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: true)
      view?.presentScene(gameOverScene, transition: reveal)
    }
    
  }
}

extension GameScene: SKPhysicsContactDelegate {
  
  // Since you set the scene as the physics world's contactDelegate earlier, this method will be called whenever two physics bodies collide and their contactTestBitMasks are set appropriately.
  // Called when two bodies first contact each other.
  func didBegin(_ contact: SKPhysicsContact) {
    // This method passes you the two bodies that collide, but does not guarantee that they are passed in any particular order. So this bit of code just arranges them so they are sorted by their category bit masks so you can make some assumptions later.
    var firstBody: SKPhysicsBody
    var secondBody: SKPhysicsBody
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
      firstBody = contact.bodyA
      secondBody = contact.bodyB
    } else {
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }
    
    // Here is the check to see if the two bodies that collided are the projectile and monster, and if so, the method you wrote earlier is called.
    if ((firstBody.categoryBitMask & PhysicsCategory.monster != 0) &&
      (secondBody.categoryBitMask & PhysicsCategory.projectile != 0)) {
      if let monster = firstBody.node as? SKSpriteNode,
        let projectile = secondBody.node as? SKSpriteNode {
        projectileDidCollideWithMonster(projectile: projectile, monster: monster)
      }
    }
  }
  
}
