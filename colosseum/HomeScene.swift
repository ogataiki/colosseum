import SpriteKit

class HomeScene: SKScene, SpeechDelegate {
    
    enum SceneStatus: Int {
        case pretreat = -1
        case idle = 0
        case runSpeech
        case waitTapSpeech
    }
    var scene_status = SceneStatus.pretreat;
    var next_scene = SceneManager.Scenes.char_select;

    var game_mgr = GameManager.instance;
    var story_mgr = StoryManager.instance;
    
    //---------------
    // ナビ
    var navi: SpeechCtrl!;
    var speechRunning = StoryManager.SpeechNum.non;
    var speechs: [String] = [];
    func naviStart(num: StoryManager.SpeechNum) {
        if num == StoryManager.SpeechNum.navi_home {
            speechs = [story_mgr.getSpeech_naviHome()];
        }
        else {
            speechs = story_mgr.getSpeechs(num);
        }
        if speechs.count <= 0 {
            return;
        }
        speechRunning = num;
        navi = SpeechCtrl(_scene: self
            , _speaker_image: "NaviChar"
            , _speaker_position: CGPointMake(self.size.width*0.85+self.size.width, self.size.height*0.4)
            , _zPosition: 0
            , _speechs: speechs
            , _delegate: self);
        navi.run();
        scene_status = .runSpeech;
    }
    func callbackSpeechFinish(index: Int) {
        
        if speechRunning == StoryManager.SpeechNum.navi_home {
            scene_status = .idle;
        }
        else {
            if index+1 >= speechs.count {
                story_mgr.finishSave(speechRunning.rawValue);
                scene_status = .idle;
            }
            else {
                scene_status = .waitTapSpeech;
            }
        }
    }
    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        // これしないと孫要素の表示順がおかしくなる
        view.ignoresSiblingOrder = false;
        
        if false == story_mgr.finishLoad(StoryManager.SpeechNum.tutorial_navi_home_1.rawValue) {
            next_scene = SceneManager.Scenes.battle;
            game_mgr.enemy_character = CharManager.CharNames.mob;
            naviStart(StoryManager.SpeechNum.tutorial_navi_home_1);
        }
        else if false == story_mgr.finishLoad(StoryManager.SpeechNum.tutorial_navi_home_2.rawValue) {
            naviStart(StoryManager.SpeechNum.tutorial_navi_home_2);
        }
        else {
            naviStart(StoryManager.SpeechNum.navi_home);
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        for touch in (touches ) {
            let location = touch.locationInNode(self)
            
            switch scene_status {
            case .idle:
                SceneManager.changeScene(next_scene);
                
            case .runSpeech:
                fallthrough
            case .waitTapSpeech:
                let sts = navi.tap();
                switch sts {
                case .runSpeech:
                    scene_status = .runSpeech;
                case .waitTap:
                    scene_status = .waitTapSpeech;
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