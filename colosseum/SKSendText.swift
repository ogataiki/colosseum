import SpriteKit

enum eTextState: Int {
    case send = 0       // 通常文字送り
    case skip           // 文字送りスキップ
    case remove         // 貼付けた文字の取り外し
}


/**
 *  文字送り用クラス
 *  現在は横文字表示しか対応していません。
 */
class SKSendText : SKSpriteNode {
    // メンバ変数
    // テキストを文字送りするのに必要そうな変数
    var m_text: String?                 // 表示する文字列
    var m_count: Int = 0                // テキストの文字数取得
    var m_strcount: Int = 0             // 現在何文字目表示したか
    var m_delayTime: CGFloat = 0.1      // 一文字毎に描画するのを遅らせる秒数
    var m_nextLineKey: Character = "\n" // 改行キー
    var m_parentScene: SKScene?         // とりつけるシーン
    var m_fontSize: CGFloat = 12.0      // フォントサイズ
    
    struct Content {
        var x: UInt = 0
        var y: UInt = 0
        var label: SKLabelNode!;
    }
    var m_labelArray: Array<Content> = []   // 表示しているラベル達
    
    // 文字の位置決定用変数(後で変換するのが面倒なのでCGCloatで作成)
    var maxWidth: UInt = 15         // 横に最大何文字表示するか
    var m_totalHeight: UInt = 0
    var m_posX: CGFloat?
    var m_posY: CGFloat?
    var m_color: UIColor = UIColor.blackColor()
    var m_drawEndFlag: Bool = false
    
    var m_state: eTextState = .send {
        willSet{}
        didSet{
            switch m_state {
            case .send:
                self.m_delayTime = 0.1
            case .skip:
                self.skipDraw(m_text, callback: {() -> Void in
                })
            case .remove:
                self.remove()
            }
            
        }
    }
    
    
    
     func setting(text: String!
        , fontSize: CGFloat!
        , fontColor: UIColor!
        , posX: CGFloat!, posY: CGFloat!
        , addView: SKScene!)
    {
        setting(text
            , fontSize: fontSize
            , fontColor: fontColor
            , posX: posX
            , posY: posY
            , addView: addView
            , nextLineKey: nil
            , maxWidth: nil
            , delayTime: nil
            , mode: nil);
    }
    
    func setting(text: String!
        , fontSize: CGFloat!
        , fontColor: UIColor!
        , posX: CGFloat!, posY: CGFloat!
        , addView: SKScene!
        , nextLineKey: Character!
        , maxWidth: UInt!
        , delayTime: CGFloat!
        , mode: eTextState!)
    {
        if (fontSize != nil)    { self.m_fontSize = fontSize }
        if (fontColor != nil)   { self.m_color = fontColor }
        self.m_posX = posX
        self.m_posY = posY
        self.m_parentScene = addView
        if (nextLineKey != nil) { m_nextLineKey = nextLineKey }
        if (maxWidth != nil)    { self.maxWidth = maxWidth }
        if (delayTime != nil)   { self.m_delayTime = delayTime }
        if (mode != nil)        { self.m_state = mode }
        
        parseText(text);
    }
    
    func parseText(text: String!) {
        
        self.remove()
        
        // テキストの保管と文字数の取得
        var text: String = text
        m_text = text
        m_count = text.characters.count
        if m_count == 0 { return };
        var strcount: CGFloat = 0.0
        var x: UInt = 0              // 横に何文字目か
        var y: UInt = 0              // 何行目か
        for n in 1 ... m_count {
            
            let chara:Character = text.removeAtIndex(text.startIndex)
            
            if chara == m_nextLineKey {
                y++
                x = 0
            } else if x > maxWidth {
                // 改行用の処理
                y++
                x = 0
            } else if m_posX! + (m_fontSize * CGFloat(x)) + m_fontSize/2.0 > m_parentScene?.frame.width {
                // 画面外にいかないように
                y++                     // 行目をプラス
                x = 0                   // 同上
            }
            x++
            
            // ラベルノードの生成
            let content = Content(x: x, y: y, label: SKLabelNode(text: "\(chara)"));
            content.label.fontSize = m_fontSize;
            content.label.alpha = 0.0;
            content.label.fontColor = m_color;
            m_labelArray.append(content);
            
            strcount += 1.0
        }
        m_totalHeight = y;
        
        // 開始点を調整
        m_posX = 0 - (CGFloat(maxWidth/2) * m_fontSize);
        if maxWidth % 2 == 1 {
            m_posX! -= (m_fontSize*0.5);
        }
        m_posY = (CGFloat(m_totalHeight/2) * m_fontSize);
        if m_totalHeight % 2 == 1 {
            m_posY! += (m_fontSize*0.5);
        }
    }
    
    /// テキストの描画
    func drawText(callback: () -> Void) {
        
        if m_count == 0 { return }  // 空なら描画せず終了
        var strcount: CGFloat = 0.0
        var x: UInt = 0              // 横に何文字目か
        var y: UInt = 0              // 何行目か
        for content in m_labelArray {
            if m_state != .send { return }    // 表示途中で文字を消して、といった処理が来た時用のフラグと処理

            // 描画開始
            let xPos = m_posX! + (CGFloat(content.x-1) * m_fontSize);
            let yPos = m_posY! - (CGFloat(content.y) * m_fontSize);
            content.label.position = CGPoint(x: xPos, y: yPos);
            self.addChild(content.label)
            
            let delay = SKAction.waitForDuration(NSTimeInterval(m_delayTime * strcount))
            let fadein = SKAction.fadeAlphaBy(1.0, duration: 0.5)
            let end = SKAction.runBlock({ () -> Void in
                self.m_strcount++;
                if self.m_strcount >= self.m_labelArray.count-1 {
                    callback();
                    self.m_strcount = 0;
                }
            });
            let seq = SKAction.sequence([delay, fadein, end])
            content.label.runAction(seq)
            
            strcount += 1.0
        }
    }
    
    /// スキップモードの文字の描画
    func skipDraw(text: String!, callback: () -> Void){
        if m_drawEndFlag { return }
        
        self.remove()
        
        // テキストの保管と文字数の取得
        var text: String = text
        
        m_count = text.characters.count
        if m_count == 0 { return }  // 空なら描画せず終了
        
        var x: UInt = 0              // 横に何文字目か
        var y: UInt = 0              // 何行目か
        for n in 1 ... m_count {
            if m_state == .remove { return }    // 表示途中で文字を消して、といった処理が来た時用のフラグと処理
            
            let chara:Character = text.removeAtIndex(text.startIndex)         // 一文字目をテキストから削除
            
            if chara == m_nextLineKey {     // \n は改行用のキー文時
                y++                     // 行目をプラス
                x = 0
            } else if x > maxWidth {    // 改行用の処理
                y++                     // 行目をプラス
                x = 0                   // 行が変わるので、横にずらす距離を初期化
            } else if m_posX! + (m_fontSize * CGFloat(x)) + m_fontSize/2.0 > m_parentScene?.frame.width {
                y++                     // 行目をプラス
                x = 0
            }
            x++
            
            let label: SKLabelNode = SKLabelNode(text: "\(chara)")
            label.fontSize = m_fontSize
            let xPos = m_posX! + (CGFloat(x-1) * m_fontSize);
            let yPos = m_posY! - (CGFloat(y) * m_fontSize);
            label.position = CGPoint(x: xPos, y: yPos);
            label.fontColor = m_color
            
            self.addChild(label)
            
            let content = Content(x: x, y: y, label: label);
            m_labelArray.append(content)
        }
        m_totalHeight = y;
        
        callback();
    }
    
    
    /// 文字が全て表示されたかの確認
    func checkDrawEnd() -> Bool {
        if m_labelArray.count >= m_count && m_labelArray.last!.label.alpha >= 1.0 {
            m_drawEndFlag = true
        }
        return m_drawEndFlag;
    }
    
    /// 描画モードの切り替え
    func changeState( mode: eTextState ){
        self.m_state = mode
    }
    
    /// 描画の基本設定はそのままに、違う文へ切り替え
    func changeText(text: String!, callback: () -> Void){
        if m_drawEndFlag {
            self.changeState( .send )
            parseText(text);
            drawText({ () -> Void in
                callback();
            })
        } else {
            self.changeState( .skip )
        }
    }
    
    /// ラベルの取り外し
    func remove(){
        self.removeAllChildren();
        m_labelArray = [];
        m_drawEndFlag = false
    }
}