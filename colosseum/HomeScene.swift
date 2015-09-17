import SpriteKit

class HomeScene: SKScene, SpeechDelegate {
    
    enum SceneStatus: Int {
        case pretreat = -1
        case idle = 0
        case runTutorialSpeech
        case waitTapTutorialSpeech
    }
    var scene_status = SceneStatus.pretreat;

    
    
    //---------------
    // チュートリアル用
    
    var tutorialSpeech: [String] = [
        "案内するぞい。",
        "それがワシの仕事じゃ。",
        "（面倒じゃ・・・）",
        "とりあえず、",
        "戦うといい。",
        "それしかやることはない。"
    ];
    var tutorialNavi: SpeechCtrl!;
    func tutorialNaviStart() {
        tutorialNavi = SpeechCtrl(_scene: self
            , _speaker_image: "NaviChar"
            , _speaker_position: CGPointMake(self.size.width*0.85+self.size.width, self.size.height*0.4)
            , _zPosition: 0
            , _speechs: tutorialSpeech
            , _delegate: self);
        tutorialNavi.run();
    }
    func callbackSpeechFinish(index: Int) {
        
        if index >= tutorialSpeech.count {
            scene_status = .idle;
        }
        else {
            scene_status = .waitTapTutorialSpeech;
        }
    }
    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        // これしないと孫要素の表示順がおかしくなる
        view.ignoresSiblingOrder = false;
        
        tutorialNaviStart();
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch in (touches as! Set<UITouch>) {
            let location = touch.locationInNode(self)
            
            switch scene_status {
            case .idle:
                SceneManager.changeScene(SceneManager.Scenes.battle);
                
            case .runTutorialSpeech:
                fallthrough
            case .waitTapTutorialSpeech:
                let sts = tutorialNavi.tap();
                switch sts {
                case .runSpeech:
                    scene_status = .runTutorialSpeech;
                case .waitTap:
                    scene_status = .waitTapTutorialSpeech;
                case .idle:
                    scene_status = .idle;
                default:
                    break;
                }
            
            default:
                break;
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
    }

}