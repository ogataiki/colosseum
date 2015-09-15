import SpriteKit

class NarrationBase {
 
    enum Status: Int {
        case idle = 0
        case runText
    }
    var status = Status.idle;

    var targetScene: SKScene;
    
    var narration: String;
    
    var back: SKSpriteNode!;
    
    var width: CGFloat;
    var height: CGFloat;
    var center: CGPoint;
    var zPosition: CGFloat = 0.0;
    
    var callback_finish: () -> Void;
    
    var fontSize: CGFloat = 14;
    var fontColor: UIColor = UIColor.whiteColor();
    var delayTime: CGFloat = 0.1;

    var backAlpha: CGFloat = 0.0;

    init (scene: SKScene
        , text: String
        , size: CGSize, position: CGPoint, z: CGFloat = 0.0
        , background: SKSpriteNode? = nil
        , callback: () -> Void)
    {
        targetScene = scene;
        narration = text;
        width = size.width;
        height = size.height;
        center = position;
        zPosition = z;
        if let b = background {
            back = b;
            backAlpha = b.alpha;
            back.size = size;
            back.position = position;
            back.zPosition = z;
            back.alpha = 0.0;
            targetScene.addChild(back);
        }
        callback_finish = callback;
    }
    
    deinit {
        removeProc();
    }
    
    var text: SKSendText!;
    
    func run() {
        
        status = .runText;
        
        if let b = back {
            back.runAction(SKAction.sequence([
                SKAction.fadeAlphaTo(backAlpha, duration: 0.25)
                , SKAction.runBlock({ () -> Void in
                    self.runProc();
                })
            ]));
        }
        else {
            runProc();
        }
    }
    func runProc() {
        text = SKSendText(color: UIColor.clearColor(), size: CGSizeMake(width, height));
        text.setting(""
            , fontSize: fontSize
            , fontColor: fontColor
            , posX: 0, posY: 0
            , addView: targetScene);
        text.position = center;
        text.zPosition = zPosition;
        targetScene.addChild(text);
        
        text.parseText(narration);
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
    
    func remove(callback: () -> Void) {
        if let b = back {
            back.runAction(SKAction.sequence([
                SKAction.fadeAlphaTo(0.0, duration: 0.15)
                , SKAction.runBlock({ () -> Void in
                    self.back.removeFromParent();
                })
            ]));
        }
        if let t = text {
            text.runAction(SKAction.sequence([
                SKAction.fadeAlphaTo(0.0, duration: 0.15)
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
        if let b = back {
            back.removeFromParent();
        }
        if let t = text {
            text.removeFromParent();
        }
    }
}