import SpriteKit
import CoreEngine

/// SpriteKit-based renderer for grid and tile games.
/// Implements the RenderPipeline protocol using SKScene.
public final class SpriteKitContext: SKScene, @unchecked Sendable {
    private var pendingCommands: [RenderCommand] = []

    /// Queue render commands from the game logic.
    public func submitCommands(_ commands: [RenderCommand]) {
        pendingCommands = commands
    }

    override public func update(_ currentTime: TimeInterval) {
        removeAllChildren()
        for command in pendingCommands {
            processCommand(command)
        }
        pendingCommands.removeAll()
    }

    private func processCommand(_ command: RenderCommand) {
        switch command {
        case .clear(let r, let g, let b, _):
            backgroundColor = SKColor(red: CGFloat(r), green: CGFloat(g),
                                      blue: CGFloat(b), alpha: 1.0)
        case .fillRect(let x, let y, let w, let h, let r, let g, let b, let a):
            let node = SKSpriteNode(color: SKColor(red: CGFloat(r), green: CGFloat(g),
                                                   blue: CGFloat(b), alpha: CGFloat(a)),
                                    size: CGSize(width: CGFloat(w), height: CGFloat(h)))
            node.position = CGPoint(x: CGFloat(x), y: CGFloat(y))
            node.anchorPoint = .zero
            addChild(node)
        case .fillCircle(let cx, let cy, let radius, let r, let g, let b, let a):
            let diameter = CGFloat(radius) * 2
            let node = SKShapeNode(circleOfRadius: CGFloat(radius))
            node.fillColor = SKColor(red: CGFloat(r), green: CGFloat(g),
                                     blue: CGFloat(b), alpha: CGFloat(a))
            node.strokeColor = .clear
            node.position = CGPoint(x: CGFloat(cx), y: CGFloat(cy))
            addChild(node)
            _ = diameter
        case .drawLine(let x1, let y1, let x2, let y2,
                       let r, let g, let b, let a, let lineWidth):
            let path = CGMutablePath()
            path.move(to: CGPoint(x: CGFloat(x1), y: CGFloat(y1)))
            path.addLine(to: CGPoint(x: CGFloat(x2), y: CGFloat(y2)))
            let node = SKShapeNode(path: path)
            node.strokeColor = SKColor(red: CGFloat(r), green: CGFloat(g),
                                       blue: CGFloat(b), alpha: CGFloat(a))
            node.lineWidth = CGFloat(lineWidth)
            addChild(node)
        case .drawSprite(let name, let x, let y, let w, let h):
            let node = SKSpriteNode(imageNamed: name)
            node.position = CGPoint(x: CGFloat(x), y: CGFloat(y))
            node.size = CGSize(width: CGFloat(w), height: CGFloat(h))
            addChild(node)
        case .drawText(let text, let x, let y, let size,
                       let r, let g, let b, let a):
            let node = SKLabelNode(text: text)
            node.fontSize = CGFloat(size)
            node.fontColor = SKColor(red: CGFloat(r), green: CGFloat(g),
                                     blue: CGFloat(b), alpha: CGFloat(a))
            node.position = CGPoint(x: CGFloat(x), y: CGFloat(y))
            addChild(node)
        }
    }
}
