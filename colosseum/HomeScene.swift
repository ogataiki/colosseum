import SpriteKit

class HomeScene: SKScene {
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        // これしないと孫要素の表示順がおかしくなる
        view.ignoresSiblingOrder = false;
        
        var naviChar = SKSpriteNode(imageNamed: "NaviChar");
        naviChar.position = CGPointMake(self.size.width*0.85+naviChar.size.width, self.size.height*0.4);
        self.addChild(naviChar);
        
        let move1 = SKAction.moveToX(self.size.width*0.88, duration: 0.2);
        let move2 = SKAction.moveToX(self.size.width*0.83, duration: 0.1);
        let move3 = SKAction.moveToX(self.size.width*0.85, duration: 0.05);
        let moveend = SKAction.runBlock { () -> Void in
            
            var speech = SKSendText(color: UIColor.whiteColor(), size: CGSizeMake(self.size.width*0.8, 40));
            speech.setting("", fontSize: 14, fontColor: UIColor.blackColor(), posX: 0, posY: 0, addView: self);
            speech.position = CGPointMake(self.size.width*0.5, naviChar.position.y + naviChar.size.height*0.6);
            self.addChild(speech);
            speech.parseText("案内するぞい。");
            speech.drawText { () -> Void in
            }
        }
        let moveseq = SKAction.sequence([move1, move2, move3, moveend]);
        naviChar.runAction(moveseq);
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch in (touches as! Set<UITouch>) {
            let location = touch.locationInNode(self)
            SceneManager.changeScene(SceneManager.Scenes.mock);
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
    }

}