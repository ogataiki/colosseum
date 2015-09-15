import SpriteKit

class PrologueScene: SKScene {
    
    enum SceneStatus: Int {
        case pretreat = -1
        case idle = 0
        case runText
    }
    var scene_status = SceneStatus.pretreat;
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        // これしないと孫要素の表示順がおかしくなる
        view.ignoresSiblingOrder = false;
        
        let back = SKSpriteNode(imageNamed: "ColosseumExterior");
        back.position = CGPointMake(self.size.width*0.5, self.size.height*0.5);
        back.size = CGSizeMake(back.size.width * (self.size.height / back.size.height), self.size.height);
        self.addChild(back);
        
        runPrologue();
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch in (touches as! Set<UITouch>) {
            let location = touch.locationInNode(self)
            
            switch scene_status {
            case .runText:
                if let t = prologueNarration {
                    prologueNarration.skip();
                }
                scene_status = .idle;
            
            case .idle:
                if let p = prologueNarration {
                    prologueNarration.remove({ () -> Void in
                        SceneManager.changeScene(SceneManager.Scenes.home);
                    })
                }
                else {
                    SceneManager.changeScene(SceneManager.Scenes.home);
                }
            
            default:
                break;
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
    }

    var prologueNarration: NarrationBase!;
    func runPrologue() {
        
        scene_status = .runText;
        
        let prologue = "   〜　コロシアム　〜\n\n\nそれは国民の娯楽。\n\n\nあるいは、\n\n\n食うに困った者たちが行き着く\n最後の働き口。\n\n\nそして、\n\n\n一獲千金を目指す者たちの\n夢の舞台。";
        
        let back = SKSpriteNode(color: UIColor.blackColor(), size: self.size);
        back.alpha = 0.4;

        prologueNarration = NarrationBase(scene: self
            , text: prologue
            , size: self.size
            , position: CGPointMake(self.size.width*0.5, self.size.height*0.5)
            , z: 0
            , background: back
            , callback: { () -> Void in
                self.scene_status = .idle;
        });
        prologueNarration.delayTime = 0.15;
        prologueNarration.run();
    }
}