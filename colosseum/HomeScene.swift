import SpriteKit

class HomeScene: SKScene {
    
    //---------------
    // ナビキャラ
    
    var naviChar: SKSpriteNode!;
    func naviStart(callback: () -> Void) {
        naviChar = SKSpriteNode(imageNamed: "NaviChar");
        naviChar.position = CGPointMake(self.size.width*0.85+self.size.width, self.size.height*0.4);
        self.addChild(naviChar);
        
        let move1 = SKAction.moveToX(self.size.width*0.88, duration: 0.2);
        let move2 = SKAction.moveToX(self.size.width*0.83, duration: 0.1);
        let move3 = SKAction.moveToX(self.size.width*0.85, duration: 0.05);
        let moveend = SKAction.runBlock { () -> Void in
            
            self.tutorialSpeechInit();
            self.tutorialSpeechStart(point: CGPointMake(self.size.width*0.5, self.naviChar.position.y + self.naviChar.size.height*0.6)
                , index: 0
                , callback: { () -> Void in
                    
                    // TODO:ここでストーリーモード選択ボタンカットイン
                    callback();
            })
        }
        let moveseq = SKAction.sequence([move1, move2, move3, moveend]);
        naviChar.runAction(moveseq);
    }

    
    
    //---------------
    // ナビキャラの台詞

    struct SpeechData {
        var speech = "";
        var wait: NSTimeInterval = 2.0;
    }
    func speechStart(speechList: [SpeechData], point: CGPoint, index: Int, callback: () -> Void) {
        
        if index >= speechList.count {
            callback();
            return;
        }
        
        var speech = SKSendText(color: UIColor.whiteColor(), size: CGSizeMake(self.size.width*0.8, 40));
        speech.setting("", fontSize: 14, fontColor: UIColor.blackColor(), posX: 0, posY: 0, addView: self);
        speech.position = point;
        self.addChild(speech);
        speech.parseText(speechList[index].speech);
        speech.drawText { () -> Void in
            
            let wait = SKAction.waitForDuration(speechList[index].wait);
            let next = SKAction.runBlock({ () -> Void in
                speech.remove();
                speech.removeFromParent();
                self.speechStart(speechList, point: point, index: index+1, callback: { () -> Void in
                    callback();
                })
            })
            speech.runAction(SKAction.sequence([wait, next]));
        }
    }

    
    //---------------
    // チュートリアル用
    
    var tutorialSpeech: [SpeechData] = [];
    func tutorialSpeechInit() {
        tutorialSpeech.append(SpeechData(speech: "案内するぞい。", wait: 2.0));
        tutorialSpeech.append(SpeechData(speech: "それがワシの仕事じゃ。", wait: 2.0));
        tutorialSpeech.append(SpeechData(speech: "（面倒じゃ・・・）", wait: 1.0));
        tutorialSpeech.append(SpeechData(speech: "とりあえず、", wait: 1.6));
        tutorialSpeech.append(SpeechData(speech: "戦うといい。", wait: 1.8));
        tutorialSpeech.append(SpeechData(speech: "それしかやることはない。", wait: 2.5));
    }
    func tutorialSpeechStart(#point: CGPoint, index: Int, callback: () -> Void) {
        
        speechStart(tutorialSpeech, point: point, index: index) { () -> Void in
            callback();
        }
    }

    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        // これしないと孫要素の表示順がおかしくなる
        view.ignoresSiblingOrder = false;
        
        naviStart { () -> Void in
        }
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