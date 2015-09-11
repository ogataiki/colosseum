import SpriteKit

class PrologueScene: SKScene {
    
    var prologueText: SKSendText!;
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        // これしないと孫要素の表示順がおかしくなる
        view.ignoresSiblingOrder = false;
        
        let back = SKSpriteNode(imageNamed: "ColosseumExterior");
        back.position = CGPointMake(self.size.width*0.5, self.size.height*0.5);
        back.size = CGSizeMake(back.size.width * (self.size.height / back.size.height), self.size.height);
        back.color = UIColor.blackColor();
        back.colorBlendFactor = 0.4;
        self.addChild(back);
        
        let prologue = "   〜　コロシアム　〜\n\n\nそれは国民の娯楽。\n\n\nあるいは、\n\n\n食うに困った者たちが行き着く\n最後の働き口。\n\n\nそして、\n\n\n一獲千金を目指す者たちの\n夢の舞台。";
        
        prologueText = SKSendText(color: UIColor.clearColor(), size: self.size);
        prologueText.setting("", fontSize: 14, fontColor: UIColor.whiteColor(), posX: 0, posY: 0, addView: self);
        prologueText.position = CGPointMake(self.size.width*0.5, self.size.height*0.5);
        self.addChild(prologueText);
        prologueText.parseText(prologue);
        prologueText.m_delayTime = 0.15;
        prologueText.drawText { () -> Void in
        }
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch in (touches as! Set<UITouch>) {
            let location = touch.locationInNode(self)
            
            if let text = prologueText {
                if text.checkDrawEnd() == false {
                    text.changeState( .skip );
                }
                else {
                    SceneManager.changeScene(SceneManager.Scenes.home);
                }
            }
            else {
                SceneManager.changeScene(SceneManager.Scenes.home);
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
    }
    
}