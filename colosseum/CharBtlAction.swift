import SpriteKit

class CharBtlAction {
    
    // ---
    // 行動のメインタイプ 攻撃を受ける側としての種別を示す
    enum ActType: Int {
        case non = 0
        case atk = 1
        case def = 2
        case enh = 3
        case jam = 4
    }
    var type = ActType.non;
    
    // ---
    // 攻撃のタイプと内容
    // 複数のタイプを同時にセットすることが可能
    
    // atk
    var atkEnable: Bool = false;
    struct Atk {
        var atkPower: CGFloat = 1.0;
        var atkCount: Int = 1;
    }
    var atk: [Atk] = [];
    
    // def
    var defEnable: Bool = false;
    struct Def {
        var defPower: CGFloat = 1.0;            // 0.0 ~ 100.0 100.0 = Avoided
        var defCount: Int = 1;                  // enable turn
        var defCounterAttack: CGFloat = 0.0;    // 0.0 ~
    }
    var def = Def();
    
    // enh
    var enhEnable: Bool = false;
    struct Enh {
        var enhAtkPowerAdd: CGFloat = 200.0;    // Ratio %
        var enhAtkCountAdd: Int = 0;            // count 0 ~
        var enhDefPowerAdd: CGFloat = 0.0;      // Ratio %
        var enhAvoidedAdd: CGFloat = 0.0;       // %
    }
    var enh: [Enh] = [];
    
    // jam
    var jamEnable: Bool = false;
    enum JamType: Int {
        case recover = 0
        case enhAtk = 1
        case enhDef = 2
        case enhAvoid = 3
        case weakenAtk = 4
        case weakenDef = 5
        case weakenAvoid = 6
        case poison = 7
        case paralysis = 8
    }
    struct Jam {
        
        var type = JamType.recover;
        
        enum JamSeedType: Int {
            case atkNow = 10
            case atkBase = 11
            case lasthp = 20
            case subhp = 21
            case maxhp = 22
            case defNow = 30
            case defBase = 31
        }
        var seedType = JamSeedType.atkNow;
        
        var power: CGFloat = 100.0;         // Ratio % for seedtype
        var turn: Int = 1;                  // Continue turn;
    }
    var jam: [Jam] = [];
    
}
