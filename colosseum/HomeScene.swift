import SpriteKit

class HomeScene: SKScene {
    
    enum SceneStatus: Int {
        case pretreat = -1
        case idle = 0
        case runTutorialSpeech
        case waitTapTutorialSpeech
    }
    var scene_status = SceneStatus.pretreat;

    
    
    //---------------
    // ナビキャラ
    
    var naviChar: SKSpriteNode!;
    func naviStart() {
        naviChar = SKSpriteNode(imageNamed: "NaviChar");
        naviChar.position = CGPointMake(self.size.width*0.85+self.size.width, self.size.height*0.4);
        self.addChild(naviChar);
        
        let move1 = SKAction.moveToX(self.size.width*0.88, duration: 0.2);
        let move2 = SKAction.moveToX(self.size.width*0.83, duration: 0.1);
        let move3 = SKAction.moveToX(self.size.width*0.85, duration: 0.05);
        let moveend = SKAction.runBlock { () -> Void in
            
            // TODO:チュートリアルの各段階とチュートリアル終了後のランダム台詞を用意
            self.tutorialSpeechInit();
            self.tutorialSpeechStart(
                point: CGPointMake(self.size.width*0.5, self.naviChar.position.y + self.naviChar.size.height*0.6)
                , index: 0
            );
        }
        let moveseq = SKAction.sequence([move1, move2, move3, moveend]);
        naviChar.runAction(moveseq);
    }

    
    
    //---------------
    // チュートリアル用
    
    var tutorialSpeech: [SpeechBase] = [];
    var tutorialSpeechIndex: Int = 0;
    func tutorialSpeechInit() {
        let speechs: [String] = [
            "案内するぞい。",
            "それがワシの仕事じゃ。",
            "（面倒じゃ・・・）",
            "とりあえず、",
            "戦うといい。",
            "それしかやることはない。"
        ];
        for var i = speechs.count-1; i >= 0; --i {
            let speech = SpeechBase(scene: self
                , speaker: naviChar
                , text: speechs[i]
                , index: i
                , size: CGSizeMake(self.size.width*0.8, 40)
                , position: CGPointZero
                , z: 0
                , callback: tutorialSpeechCallback);
            tutorialSpeech.insert(speech, atIndex: 0);
        }
    }
    func tutorialSpeechStart(#point: CGPoint, index: Int) {
        
        if index >= tutorialSpeech.count {
            tutorialSpeechEnd();
            return;
        }
        
        tutorialSpeechIndex = index;
        tutorialSpeech[index].setPosition(point);
        tutorialSpeech[index].run();
        
        scene_status = .runTutorialSpeech;
    }
    func tutorialSpeechCallback(index: Int) {
        
        scene_status = .waitTapTutorialSpeech;
    }
    func tutorialSpeechEnd() {
        // TODO:ここでストーリーモード選択ボタンカットイン
        
        scene_status = .idle;
    }

    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        // これしないと孫要素の表示順がおかしくなる
        view.ignoresSiblingOrder = false;
        
        naviStart();
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch in (touches as! Set<UITouch>) {
            let location = touch.locationInNode(self)
            
            switch scene_status {
            case .idle:
                SceneManager.changeScene(SceneManager.Scenes.mock);
                
            case .runTutorialSpeech:
                tutorialSpeech[tutorialSpeechIndex].skip();
                scene_status = .waitTapTutorialSpeech;
                
            case .waitTapTutorialSpeech:
                let index = tutorialSpeechIndex;
                
                tutorialSpeech[index].remove({ () -> Void in
                    self.tutorialSpeechStart(point: self.tutorialSpeech[index].center, index: index+1);
                })
                
            default:
                break;
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
    }

}