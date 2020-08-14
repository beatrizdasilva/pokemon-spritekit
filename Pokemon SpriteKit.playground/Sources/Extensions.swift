
import SpriteKit

extension SKNode {
    func addCircle(radius: CGFloat, edgeColor: UIColor, filled: Bool) {
        let circle = SKShapeNode(circleOfRadius: radius)
        circle.zPosition = -3
        circle.strokeColor = edgeColor
        circle.fillColor = edgeColor.withAlphaComponent(0.4)
        addChild(circle)
    }
}
