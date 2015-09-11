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
class SKSendText : SKNode {
    // メンバ変数
    // テキストを文字送りするのに必要そうな変数
    var m_text: String?                 // 表示する文字列
    var m_count: Int = 0                // テキストの文字数取得
    var m_strcount: CGFloat = 0.0       // 現在何文字目表示したか
    var m_delayTime: CGFloat = 0.1      // 一文字毎に描画するのを遅らせる秒数
    var m_nextLineKey: Character = "\n" // 改行キー
    var m_parentScene: SKScene?         // とりつけるシーン
    var m_fontSize: CGFloat = 12.0      // フォントサイズ
    
    var m_labelArray: Array<SKLabelNode> = []   // 表示しているラベル達
    
    // 文字の位置決定用変数(後で変換するのが面倒なのでCGCloatで作成)
    var x: UInt = 0              // 横に何文字目か
    var y: UInt = 0              // 何行目か
    var maxWidth: UInt = 15         // 横に最大何文字表示するか
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
                self.skipDraw(m_text)
            case .remove:
                self.remove()
            }
            
        }
    }
    
    
    
    // (文字送りで表示するテキスト、フォントサイズ、初期位置X、初期位置Y、ラベルを取り付けるシーン)
    convenience init(text: String!, fontsize: CGFloat!, posX: CGFloat!, posY: CGFloat!, addView: SKScene!){
        self.init(text: text, fontsize: fontsize, posX: posX, posY: posY,addView: addView,nextLineKey: nil, maxWidth: nil, delayTime: nil, mode: nil, color: nil)
    }
    
    // (文字送りで表示するテキスト、フォントサイズ、初期位置X、初期位置Y、ラベルを取り付けるシーン、文字色)
    convenience init(text: String!, fontsize: CGFloat!, posX: CGFloat!, posY: CGFloat!, addView: SKScene!, color: UIColor!){
        self.init(text: text, fontsize: fontsize, posX: posX, posY: posY,addView: addView,nextLineKey: nil, maxWidth: nil, delayTime: nil, mode: nil, color: color)
    }
    // (文字送りで表示するテキスト、フォントサイズ、初期位置X、初期位置Y、ラベルを取り付けるシーン、横に書ける最大文字数)
    convenience init(text: String!, fontsize: CGFloat!, posX: CGFloat!, posY: CGFloat!, addView: SKScene!, maxWidth: UInt!){
        self.init(text: text, fontsize: fontsize, posX: posX, posY: posY,addView: addView,nextLineKey: nil, maxWidth: maxWidth, delayTime: nil, mode: nil, color: nil)
    }
    // (文字送りで表示するテキスト、フォントサイズ、初期位置X、初期位置Y、ラベルを取り付けるシーン、モード)
    convenience init(text: String!, fontsize: CGFloat!, posX: CGFloat!, posY: CGFloat!, addView: SKScene!, mode: eTextState){
        self.init(text: text, fontsize: fontsize, posX: posX, posY: posY,addView: addView,nextLineKey: nil, maxWidth: nil, delayTime: nil, mode: mode, color: nil)
    }
    // (文字送りで表示するテキスト、フォントサイズ、初期位置X、初期位置Y、ラベルを取り付けるシーン、文字表示の遅さ)
    convenience init(text: String!, fontsize: CGFloat!, posX: CGFloat!, posY: CGFloat!, addView: SKScene!, delayTime: CGFloat!){
        self.init(text: text, fontsize: fontsize, posX: posX, posY: posY,addView: addView,nextLineKey: nil, maxWidth: nil, delayTime: delayTime, mode: nil, color: nil)
    }
    
    init(text: String!
        , fontsize: CGFloat!
        , posX: CGFloat!, posY: CGFloat!
        , addView: SKScene!
        ,nextLineKey: Character!
        , maxWidth: UInt!
        , delayTime: CGFloat!
        , mode: eTextState!
        , color: UIColor!)
    {
        super.init();
            
        if (nextLineKey != nil) { m_nextLineKey = nextLineKey }
        if (maxWidth != nil)    { self.maxWidth = maxWidth }
        if (delayTime != nil)   { self.m_delayTime = delayTime }
        if (mode != nil)        { self.m_state = mode }
        if (fontsize != nil)    { self.m_fontSize = fontsize }
        if (color != nil)       { self.m_color = color }
        
        
        self.m_posX = posX
        self.m_posY = posY
        self.m_parentScene = addView
    }
    
    required init?(coder aDecoder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /// テキストの描画
    func drawText(text: String!){
        // テキストの保管と文字数の取得
        var text: String = text
        m_text = text
        m_count = count(text)
        if m_count == 0 { return }  // 空なら描画せず終了
        
        for n in 1 ... m_count {
            if m_state == .remove { return }    // 表示途中で文字を消して、といった処理が来た時用のフラグと処理
            
            let chara:Character = text.removeAtIndex(text.startIndex)         // 一文字目をテキストから削除
            
            if chara == m_nextLineKey {     // 嬲 は改行用のキー文時
                y++                     // 行目をプラス
                x = 0                   // 行が変わるので、横ずらしを初期化
            } else if x > maxWidth {    // 改行用の処理
                y++                     // 行目をプラス
                x = 0                   // 同上
            } else if m_posX! + (m_fontSize * CGFloat(x)) + m_fontSize/2.0 > m_parentScene?.frame.width {   // 画面外にいかないように
                y++                     // 行目をプラス
                x = 0                   // 同上
            }
            x++
            
            // ラベルノードの生成
            var label: SKLabelNode = SKLabelNode(text: "\(chara)")
            label.fontSize = m_fontSize // フォントサイズ指定
            label.position = CGPoint(x: m_posX! + (CGFloat(x-1) * m_fontSize), y: m_posY! - (CGFloat(y) * m_fontSize))   // 文字の位置設定
            label.alpha = 0.0           // 透明度の設定(初期は透明なので0.0)
            label.fontColor = m_color   // 文字色指定
            
            // ラベルの取り付け
            self.addChild(label)
            // ラベルの配列に登録
            m_labelArray.append(label)
            
            // 表示する時間をずらすためのアクションの設定
            let delay = SKAction.waitForDuration(NSTimeInterval(m_delayTime * m_strcount))  // 基本の送らせる時間に文字数を掛けることでずれを大きくする
            let fadein = SKAction.fadeAlphaBy(1.0, duration: 0.5)   // 不透明にするアクションの生成
            let seq = SKAction.sequence([delay, fadein])            // 上記2つのアクションを連結
            label.runAction(seq)                                    // 実行
            
            
            m_strcount += 1.0             // 現在の文字数をプラス
        }
        y = 0
        x = 0
        m_strcount = 0.0
    }
    
    /// スキップモードの文字の描画
    func skipDraw(text: String!){
        if m_drawEndFlag { return }
        
        self.remove()
        
        // テキストの保管と文字数の取得
        var text: String = text
        
        m_count = count(text)
        if m_count == 0 { return }  // 空なら描画せず終了
        
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
            
            // ラベルノードの生成
            var label: SKLabelNode = SKLabelNode(text: "\(chara)")  // "\(chara)"とすることでStringに変換
            // フォントサイズ指定
            label.fontSize = m_fontSize
            // 文字の位置設定
            label.position = CGPoint(x: m_posX! + (CGFloat(x-1) * m_fontSize), y: m_posY! - (CGFloat(y) * m_fontSize))
            // 透明度の設定(スキップの場合、最初から不透明)
            label.fontColor = m_color
            
            // ラベルの取り付け
            self.addChild(label)
            
            m_labelArray.append(label)
            
            m_strcount += 1.0
        }
        y = 0               // 縦ずらし初期化
        x = 0               // 横ずらし初期化
        m_strcount = 0.0    // 描画した文字数の初期化
    }
    
    
    /// 文字が全て表示されたかの確認
    func checkDrawEnd() -> Bool {
        if m_labelArray.count >= m_count && m_labelArray.last!.alpha >= 1.0 {
            m_drawEndFlag = true
        }
        return m_drawEndFlag;
    }
    
    /// 描画モードの切り替え
    func changeState( mode: eTextState ){
        self.m_state = mode
    }
    
    /// 描画の基本設定はそのままに、違う文へ切り替え
    func changeText(text: String!){
        if m_drawEndFlag {
            self.remove()
            self.changeState( .send )
            drawText(text)
        } else {
            self.changeState( .skip )
        }
    }
    
    /// ラベルの取り外し
    func remove(){
        while m_labelArray.count > 0  {
            m_labelArray.last?.removeFromParent()
            m_labelArray.removeLast()
            m_drawEndFlag = false
        }
    }
}