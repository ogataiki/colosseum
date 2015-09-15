import SpriteKit

protocol StoryProtocol {
    var storyProgress: Int { get set };
    var storys: [StoryBase] { get set };
    var isStoryTapWait: Bool { get set };
    
    func runStory();
    func updateStory();
    func finishStory();
}

class StoryBase {
    
    enum StoryType: Int {
        case wait = 0
        case narration
        case speech
        case select
        case wait_tap
        case wait_select
    }
    var type = StoryType.wait;
    
    var textSkip: Bool = true;
    
    //-----------
    // ナレーション
    
    struct NarrationData {
        var text = "";
        var textObj: SKSendText!;
    }
    var narration = NarrationData();
    func runNarration() {
        
    }

    //-----------
    // 会話

    struct SpeechData {
        var text = "";
        var textObj: SKSendText!;
        var speaker: CharBase!;
    }
    var speech = SpeechData();
    
    
    //-----------
    // 選択肢
    
    struct SelectData {
        var button: UIButton!;               // 選択肢文言
    }
    var select: [SelectData] = [];
    
    
    //-----------
    // 待機
    
    struct WaitData {
        var wait: NSTimeInterval = 2.0;
        var callback: () -> Void = {};
    }
    var wait = WaitData();
    
    var callback_waitTap: () -> Void = {};
}