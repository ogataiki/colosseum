import SpriteKit

protocol SpeechDelegate {
    func callbackSpeechFinish(index: Int);
}

class SpeechCtrl {
    
    enum Status: Int {
        case pretreat = -1
        case idle = 0
        case runSpeech
        case waitTap
    }
    var status = Status.pretreat;
    
    var targetScene: SKScene;
    
    var speaker: SKSpriteNode!;
    var speaker_image: String!;
    var speaker_position: CGPoint;
    
    var zPosition: CGFloat = 0.0;
    
    var speaker_inAction: SKAction!;
    var speaker_outAction: SKAction!;

    var speechs: [String] = [];
    var speechList: [SpeechBase] = [];
    var speechIndex: Int = 0;
    
    var executed: Bool = false;

    var delegate: SpeechDelegate;

    init (_scene: SKScene
        , _speaker_image: String? = nil
        , _speaker_position: CGPoint? = nil
        , _zPosition: CGFloat = 0.0
        , _speechs: [String] = []
        , _delegate: SpeechDelegate)
    {
        targetScene = _scene;
        
        speaker_image = _speaker_image;
        if _speaker_position != nil {
            speaker_position = _speaker_position!;
        }
        else {
            speaker_position = CGPointMake(_scene.size.width*0.85+_scene.size.width, _scene.size.height*0.4);
        }
        zPosition = _zPosition;
        speechs = _speechs;
        delegate = _delegate;
    }
        
    func run(existingSpeaker: Bool = false) {
        speechIndex = 0;
        
        if let speaker_name = speaker_image {
            if existingSpeaker {}
            else {
                speaker = SKSpriteNode(imageNamed: speaker_image);
                speaker.position = speaker_position;
                speaker.zPosition = zPosition;
                targetScene.addChild(speaker);
            }            
        }
        else {
            speaker = nil;
        }

        for var i = speechs.count-1; i >= 0; --i {
            let speech = SpeechBase(scene: targetScene
                , speaker: speaker
                , text: speechs[i]
                , index: i
                , size: CGSizeMake(targetScene.size.width*0.8, 40)
                , position: CGPointZero
                , z: 0
                , callback: speechCallback);
            speechList.insert(speech, atIndex: 0);
        }
        
        if existingSpeaker {
            self.speechStart(0);
        }
        else if let s = speaker {
            var action: SKAction;
            if let a = speaker_inAction {
                action = SKAction.sequence([a
                    , SKAction.runBlock { () -> Void in
                        self.speechStart(0);
                    }]);
            }
            else {
                action = SKAction.sequence([
                    SKAction.moveToX(targetScene.size.width*0.88, duration: 0.2)
                    , SKAction.moveToX(targetScene.size.width*0.83, duration: 0.1)
                    , SKAction.moveToX(targetScene.size.width*0.85, duration: 0.05)
                    , SKAction.runBlock { () -> Void in
                        self.speechStart(0);
                    }]);
            }
            speaker.runAction(action);
        }
        else {
            self.speechStart(0);
        }
    }
    
    
    
    func speechStart(index: Int) {
        
        if index >= speechList.count {
            speechEnd();
            return;
        }
        
        executed = true;
        
        speechIndex = index;
        if let s = speaker {
            speechList[index].setPosition(CGPointMake(targetScene.size.width*0.5, speaker.position.y + speaker.size.height*0.6));
        }
        else {
            speechList[index].setPosition(speaker_position);
        }
        speechList[index].run();
        
        status = .runSpeech;
    }
    func speechCallback(index: Int) {
        
        status = .waitTap;
        delegate.callbackSpeechFinish(index);
    }
    func speechEnd() {
        
        status = .idle;
    }
    
    
    func tap() -> Status {
        switch status {
        case .runSpeech:
            speechList[speechIndex].skip();
            status = .waitTap;
            delegate.callbackSpeechFinish(speechIndex);
            
        case .waitTap:
            let index = speechIndex;
            speechList[index].remove({ () -> Void in
                self.speechStart(index+1);
            })
    
        default:
            break;
        }
        
        return status;
    }
    
    func reset(callback: () -> Void) {
        if status == .runSpeech {
            speechList[speechIndex].skip();
        }
        if executed {
            speechList[speechIndex].remove({ () -> Void in
                self.status = .idle;
                self.speechIndex = 0;
                self.executed = false;
                callback();
            })
        }
        else {
            status = .idle;
            speechIndex = 0;
            self.executed = false;
            callback();
        }
    }
    
}