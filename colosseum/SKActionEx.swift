import SpriteKit

//SKアクションの拡張クラス群

class SKActionEx {
    
    static func jumpTo(#sprite: SKSpriteNode, targetPoint: CGPoint, height: CGFloat, duration: NSTimeInterval) -> SKAction {
        
        return jumpTo(startPoint: sprite.position, targetPoint: targetPoint, height: height, duration: duration);
    }
    static func jumpTo(#startPoint: CGPoint, targetPoint: CGPoint, height: CGFloat, duration: NSTimeInterval) -> SKAction {
        
        var bezierPath: UIBezierPath = UIBezierPath()
        bezierPath.moveToPoint(startPoint)
        var controlPoint: CGPoint = CGPoint()
        controlPoint.x = startPoint.x + (targetPoint.x - startPoint.x)/2
        controlPoint.y = startPoint.y + height
        bezierPath.addQuadCurveToPoint(targetPoint, controlPoint: controlPoint)
        
        let jumpAction = SKAction.followPath(bezierPath.CGPath, asOffset:false, orientToPath:false, duration: 0.2)
        jumpAction.timingMode = .EaseIn
        return jumpAction;
        /*
        let scaleA = SKAction.scaleTo(1.2, duration: 0.1)
        let scaleB = SKAction.scaleTo(1.0, duration: 0.1)
        let scaleSequence = SKAction.sequence([scaleA,scaleB])
        return SKAction.group([jumpAction, scaleSequence])
        */
    }
}