import SpriteKit

class SpeechBase {
    enum Status: Int {
        case idle = 0
        case runText
    }
    var status = Status.idle;
    
    var targetScene: SKScene;
    
    var speechChar: SKSpriteNode;
    
    var speech: String;
    var speechIndex: Int = 0;
    var speechBalloon: SKSpriteNode!;
    var width: CGFloat;
    var height: CGFloat;
    var center: CGPoint;
    
    var zPosition: CGFloat = 0.0;

    var callback_finish: (index: Int) -> Void;
    
    var fontSize: CGFloat = 14;
    var fontColor: UIColor = UIColor.blackColor();
    var delayTime: CGFloat = 0.1;
    
    init (scene: SKScene
        , speaker: SKSpriteNode
        , balloon: SKSpriteNode? = nil
        , text: String
        , index: Int = 0
        , size: CGSize, position: CGPoint
        , z: CGFloat = 0.0
        , callback: (index: Int) -> Void)
    {
        targetScene = scene;
        speechChar = speaker;
        speech = text;
        speechIndex = index;
        width = size.width;
        height = size.height;
        center = position;
        zPosition = z;
        if let b = balloon {
            speechBalloon = b;
            speechBalloon.size = size;
            speechBalloon.position = position;
            speechBalloon.zPosition = z;
            speechBalloon.yScale = 0.0;
            targetScene.addChild(speechBalloon);
        }
        
        callback_finish = callback;
    }
    
    deinit {
        removeProc();
    }
    
    var text: SKSendText!;
    
    func run() {
        
        status = .runText;
        
        if let b = speechBalloon {
            speechBalloon.runAction(SKAction.sequence([
                SKAction.scaleYTo(1.0, duration: 0.1)
                , SKAction.runBlock({ () -> Void in
                })
            ]));
        }
        
        runProc();
    }
    func runProc() {

        let color: UIColor;
        if let b = speechBalloon {
            color = UIColor.clearColor();
        }
        else {
            color = UIColor.whiteColor();
        }
        text = SKSendText(color: color, size: CGSizeMake(width, height));
        text.setting(""
            , fontSize: fontSize
            , fontColor: fontColor
            , posX: 0, posY: 0
            , addView: targetScene);
        text.position = center;
        text.zPosition = zPosition;
        text.yScale = 0.0;
        targetScene.addChild(text);
        
        text.parseText(speech);
        text.m_delayTime = self.delayTime;
        
        text.runAction(SKAction.sequence([
            SKAction.scaleYTo(1.0, duration: 0.1)
            , SKAction.runBlock({ () -> Void in
                self.text.drawText { () -> Void in
                    self.status = .idle;
                    self.callback_finish(index: self.speechIndex);
                }
            })
        ]));
    }
    
    func skip() {
        if status == .runText {
            if let t = text {
                text.changeState( .skip );
                status = .idle;
            }
        }
    }
    
    func remove(callback: () -> Void) {
        if let b = speechBalloon {
            speechBalloon.runAction(SKAction.sequence([
                SKAction.scaleYTo(0.0, duration: 0.1)
                , SKAction.runBlock({ () -> Void in
                    self.speechBalloon.removeFromParent();
                })
            ]));
        }
        if let t = text {
            text.runAction(SKAction.sequence([
                SKAction.scaleYTo(0.0, duration: 0.1)
                , SKAction.runBlock({ () -> Void in
                    self.text.removeFromParent();
                    callback();
                })
            ]));
        }
        else {
            removeProc();
            callback();
        }
    }
    func removeProc() {
        if let b = speechBalloon {
            speechBalloon.removeFromParent();
        }
        if let t = text {
            text.removeFromParent();
        }
    }
    
    func setPosition(position: CGPoint) {
        center = position;
        if let b = speechBalloon {
            speechBalloon.position = position;
        }
    }
}