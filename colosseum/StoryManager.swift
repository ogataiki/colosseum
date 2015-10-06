import SpriteKit

final class StoryManager
{
    static let instance = StoryManager()
    
    private init() {
    }
    
    enum SpeechNum: Int {

        case non = 0
        
        case tutorial_navi_home_1 = 1
        case tutorial_navi_home_2 = 2
        
        case navi_home = 3
    
        case navi_char_select = 4
        
        case tutorial_battle_pre_Mob = 100
        case tutorial_battle_start_Mob = 101
        case tutorial_battle_end_Mob = 102

        case battle_pre = 200
        case battle_start = 201
        case battle_end = 202
    }
    
    func getSpeechs(num: SpeechNum) -> [String] {
        switch num {
        case .tutorial_navi_home_1:
            return speech_tutorialNaviHome1;
        case .tutorial_navi_home_2:
            return speech_tutorialNaviHome2;
        default:
            return [];
        }
    }
    
    let speech_tutorialNaviHome1: [String] = [
        "新人じゃな？",
        "案内するぞい。",
        "それがワシの仕事じゃ。",
        "（面倒じゃ・・・）",
        "とりあえず、",
        "戦うといい。",
        "それしかやることはない。"
    ];
    
    let speech_tutorialNaviHome2: [String] = [
        "モブは倒せたようじゃな。",
        "ワシが教えることはもう無い。",
        "（ということにしておこう）",
        "とりあえず、",
        "どんどん戦うといい。",
        "それしかやることはない。"
    ];
    
    let speech_naviHome: [String] = [
        "攻撃には防御でカウンターじゃ",
        "防御には妨害が有効じゃぞ",
        "妨害は強化で無効にできる",
        "強化は攻撃で邪魔するのじゃ"
    ];
    func getSpeech_naviHome() -> String {
        if speech_naviHome.count > 0 {
            return speech_naviHome[Int(arc4random()) % speech_naviHome.count];
        }
        return "";
    }
    
    let speech_naviCharSelect: [String] = [
        "戦う相手を選ぶのじゃ",
    ];
    func getSpeech_naviCharSelect() -> String {
        if speech_naviCharSelect.count > 0 {
            return speech_naviCharSelect[Int(arc4random()) % speech_naviCharSelect.count];
        }
        return "";
    }

    
    var SpeechKeyDic: [Int : String] = [
        SpeechNum.tutorial_navi_home_1.rawValue         : "tutorial_navi_home_1",
        SpeechNum.tutorial_navi_home_2.rawValue         : "tutorial_navi_home_2",
        
        SpeechNum.navi_home.rawValue                    : "navi_home",

        SpeechNum.navi_char_select.rawValue             : "navi_char_select",

        SpeechNum.tutorial_battle_pre_Mob.rawValue      : "tutorial_battle_pre_Mob",
        SpeechNum.tutorial_battle_start_Mob.rawValue    : "tutorial_battle_start_Mob",
        SpeechNum.tutorial_battle_end_Mob.rawValue      : "tutorial_battle_end_Mob",

        SpeechNum.battle_pre.rawValue                   : "battle_pre",
        SpeechNum.battle_start.rawValue                 : "battle_start",
        SpeechNum.battle_end.rawValue                   : "battle_end"
    ]

    func finishSave(num: Int) {
        if let key = SpeechKeyDic[num] {
            let ud = NSUserDefaults.standardUserDefaults();
            ud.setBool(true, forKey: key);
        }
    }
    func finishLoad(num: Int) -> Bool {
        if let key = SpeechKeyDic[num] {
            let ud = NSUserDefaults.standardUserDefaults();
            return ud.boolForKey(key);
        }
        return false;
    }

}
