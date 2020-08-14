
import SpriteKit

public class GameScene: SKScene, SKPhysicsContactDelegate {
    let numberOfPokemons = 5
    let maxPokemonSpeed: UInt32 = 80
    var DistancingLenght: CGFloat = 1.5
    
    var player: SKSpriteNode!
    var people = [SKSpriteNode]()
    var gameOver = false
    var movingPlayer = false
    var offset: CGPoint!
    
    func positionWithin(range: CGFloat, containerSize: CGFloat) -> CGFloat {
        let partA = CGFloat(arc4random_uniform(100)) / 100.0
        let partB = (containerSize * (1.0 - range) * 0.5)
        let partC = (containerSize * range + partB)
        
        return  partA * partC
    }
    
    func distanceFrom(posA: CGPoint ,posB: CGPoint) -> CGFloat {
        let aSquared = (posA.x - posB.x) * (posA.x - posB.x)
        let bSquared = (posA.y - posB.y) * (posA.y - posB.y)
        
        return sqrt(aSquared + bSquared)
    }
    
    public override func didMove(to view: SKView) {
        DistancingLenght /= 2.0 
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.0
        physicsWorld.contactDelegate = self
        
        // Background
        let bg = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "p.jpg")))
        bg.zPosition = -10
        bg.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(bg)
        
        // Player
        player = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "pikachu.png")), color: .clear, size: CGSize(width: size.width * 0.05, height: size.width * 0.05))
        player.position = CGPoint(x: frame.midX, y: frame.midY)
        player.addCircle(radius: player.size.width * (0.5 + DistancingLenght), edgeColor: .green, filled: true)
        addChild(player)
        
        // Creates the circle around the player
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width * (0.5 + DistancingLenght))
        player.physicsBody?.isDynamic = false
        player.physicsBody?.categoryBitMask = Bitmasks.player
        player.physicsBody?.contactTestBitMask = Bitmasks.rocket
        
        // Creates the Pokemons
        for _ in 1...numberOfPokemons {
            createPokemon()
        }
        
        for pokemon in people {
            pokemon.physicsBody?.applyImpulse(CGVector(dx: CGFloat(arc4random_uniform(maxPokemonSpeed)) - (CGFloat(maxPokemonSpeed) * 0.5), dy: CGFloat(arc4random_uniform(maxPokemonSpeed)) - (CGFloat(maxPokemonSpeed) * 0.5)))
        }
        
        let rocket = people[Int(arc4random_uniform(UInt32(people.count)))]
        rocket.texture = SKTexture(image: #imageLiteral(resourceName: "meowth.png"))
        rocket.physicsBody?.categoryBitMask = Bitmasks.rocket
        (rocket.children.first as? SKShapeNode)?.strokeColor = .orange
        (rocket.children.first as? SKShapeNode)?.fillColor = .init(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.6)
    }
    
    func createPokemon() {
        let pokemon = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "squirtle.png")), color: .clear, size: CGSize(width: size.width * 0.05, height: size.width * 0.05))
        
        pokemon.position = CGPoint(x: positionWithin(range: 0.8, containerSize: size.width),y: positionWithin(range: 0.8, containerSize: size.height))
        
        pokemon.addCircle(radius: pokemon.size.width * (0.5 + DistancingLenght), edgeColor: .blue, filled: true)
        
        while distanceFrom(posA: pokemon.position, posB: player.position) < pokemon.size.width * DistancingLenght * 5 {
            pokemon.position = CGPoint(x: positionWithin(range: 0.8, containerSize: size.width),y: positionWithin(range: 0.8, containerSize: size.height))
        }
        
        addChild(pokemon)
        people.append(pokemon)
        
        // Creates the circle around the pokemon
        pokemon.physicsBody = SKPhysicsBody(circleOfRadius: pokemon.size.width * (0.5 + DistancingLenght))
        pokemon.physicsBody?.affectedByGravity = false
        pokemon.physicsBody?.categoryBitMask = Bitmasks.pokemon
        pokemon.physicsBody?.contactTestBitMask = Bitmasks.rocket
        pokemon.physicsBody?.friction = 0.0
        pokemon.physicsBody?.angularDamping = 0.0
        pokemon.physicsBody?.restitution = 1.1
        pokemon.physicsBody?.allowsRotation = false
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver else { return }
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let touchedNodes = nodes(at: touchLocation)
        
        for node in touchedNodes {
            if node == player {
                movingPlayer = true
                offset = CGPoint(x: touchLocation.x - player.position.x, y: touchLocation.y - player.position.y)
            }
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver && movingPlayer else { return }
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let newPlayerPosition = CGPoint(x: touchLocation.x - offset.x, y: touchLocation.y - offset.y)
        
        player.run(SKAction.move(to: newPlayerPosition, duration: 0.01))
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        movingPlayer = false
    }
    
    public func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == Bitmasks.pokemon && contact.bodyB.categoryBitMask == Bitmasks.rocket {
            infect(pokemon: contact.bodyA.node as! SKSpriteNode)
        } else if contact.bodyB.categoryBitMask == Bitmasks.pokemon && contact.bodyA.categoryBitMask == Bitmasks.rocket {
            infect(pokemon: contact.bodyB.node as! SKSpriteNode)
        } else if contact.bodyA.categoryBitMask == Bitmasks.player || contact.bodyB.categoryBitMask == Bitmasks.player {
            triggerGameOver()
        }
    }
    
    func infect(pokemon: SKSpriteNode) {
        pokemon.texture = SKTexture(image: #imageLiteral(resourceName: "meowth.png"))
        pokemon.physicsBody?.categoryBitMask = Bitmasks.rocket
        (pokemon.children.first as? SKShapeNode)?.strokeColor = .orange
        (pokemon.children.first as? SKShapeNode)?.fillColor = .init(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.6)
    }
    
    func triggerGameOver () {
        gameOver = true
        
        player.texture = SKTexture(image: #imageLiteral(resourceName: "pokeball.png"))
        (player.children.first as? SKShapeNode)?.strokeColor = .purple
        (player.children.first as? SKShapeNode)?.fillColor = .init(red: 0.7, green: 0.3, blue: 0.7, alpha: 0.6)
        
        for pokemon in people {
            pokemon.physicsBody?.velocity = .zero
        }
        
        let gameOverLabel = SKLabelNode(text: "THEY CATCH YOU!")
        gameOverLabel.fontSize = 80.0
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOverLabel.zPosition = 3
        gameOverLabel.fontColor = .white
        addChild(gameOverLabel)
    }
}
