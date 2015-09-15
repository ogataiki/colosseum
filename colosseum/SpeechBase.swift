import SpriteKit

class SpeechBase {
/*
    enum Status: Int {
        case idle = 0
        case runText
    }
    var status = Status.idle;
    
    var targetScene: SKScene;
    
    var speech: String;
    var charactor: SKSpriteNode;
    var charAction: SKAction;
    var speechBack: SKSpriteNode;
    var speechAction: SKAction;
    var width: CGFloat;
    var height: CGFloat;
    var center: CGPoint;
    var zPosition: CGFloat = 0.0;
    
    var callback_finish: () -> Void;
    
    var fontSize: CGFloat = 14;
    var fontColor: UIColor = UIColor.blackColor();
    var delayTime: CGFloat = 0.1;
    
    init (scene: SKScene
        , text: String
        , size: CGSize, position: CGPoint, z: CGFloat = 0.0
        , background: SKSpriteNode? = nil
        , callback: () -> Void)
    {
        targetScene = scene;
        speech = text;
        width = size.width;
        height = size.height;
        center = position;
        zPosition = z;
        if let b = background {
            back = b;
        }
        else {
            back = SKSpriteNode(color: UIColor.clearColor(), size: size);
            back.position = CGPointMake(targetScene.size.width*0.5, targetScene.size.height*0.5);
            back.size = CGSizeMake(back.size.width * (targetScene.size.height / back.size.height), targetScene.size.height);
            back.color = UIColor.blackColor();
            back.colorBlendFactor = 0.4;
        }
        back.size = size;
        back.position = position;
        back.zPosition = z;
        back.alpha = 0.0;
        targetScene.addChild(back);
        callback_finish = callback;
    }
    
    deinit {
        remove();
    }
    
    var text: SKSendText!;
    
    func run() {
        
        status = .runText;
        
        text = SKSendText(color: UIColor.clearColor(), size: CGSizeMake(width, height));
        text.setting("", fontSize: fontSize, fontColor: fontColor, posX: 0, posY: 0, addView: targetScene);
        text.position = center;
        text.zPosition = zPosition;
        targetScene.addChild(text);
        
        text.parseText(speech);
        text.m_delayTime = delayTime;
        text.drawText { () -> Void in
            self.status = .idle;
            self.callback_finish();
        }
    }
    
    func skip() {
        if status == .runText {
            if let t = text {
                text.changeState( .skip );
                status = .idle;
            }
        }
    }
    
    func remove() {
        back.removeFromParent();
        if let t = text {
            text.removeFromParent();
        }
    }
*/
}