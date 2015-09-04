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
    static func getActTypeName(type: ActType) -> String {
        switch type {
        case ActType.atk:
            return "攻撃";
        case ActType.def:
            return "防御";
        case ActType.enh:
            return "強化";
        case ActType.jam:
            return "妨害";
        default: break;
        }
        return "";
    }
    
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
    var atkCost: Int = 2;
    
    // def
    var defEnable: Bool = false;
    struct Def {
        
        var seedType = SeedType.atkNow;

        var defPower: CGFloat = 50.0;           // 0.0 ~ 100.0 100.0 = Avoided
        var defCount: Int = 1;                  // this turn enable count
        var defCounterAttack: CGFloat = 0.0;    // 0.0 ~
    }
    var def = Def();
    var defCost: Int = 2;
    
    // enh
    var enhEnable: Bool = false;
    enum EnhType: Int {
        case atk = 1
        case def = 2
        case avd = 3
        case hit = 4
        case atkcnt = 5
    }
    struct Enh {
        
        var type = EnhType.atk;
        var seedType = SeedType.atkNow;

        var power: CGFloat = 100.0;
        var turn: Int = 2;                      // Continue turn;
        var execTiming = ExecTiming.jastNow;
    }
    var enh: [Enh] = [];
    var enhCost: Int = 3;
    
    // jam
    var jamEnable: Bool = false;
    enum JamType: Int {
        case recover = 0
        case enhAtk = 1
        case enhDef = 2
        case enhAvoid = 3
        case enhAtkCnt = 4
        case weakenAtk = 5
        case weakenDef = 6
        case weakenAvoid = 7
        case weakenAtkCnt = 8
        case poison = 9
        case paralysis = 10
    }
    struct Jam {
        
        var type = JamType.recover;
        
        var seedType = SeedType.atkNow;
        
        var power: CGFloat = 100.0;         // Ratio % for seedtype
        var turn: Int = 1;                  // Continue turn;
        var execTiming = ExecTiming.jastNow;
    }
    var jam: [Jam] = [];
    var jamCost: Int = 3;
    
    enum SeedType: Int {
        case atkNow = 10
        case atkBase = 11
        case lasthp = 20
        case subhp = 21
        case maxhp = 22
        case defNow = 30
        case defBase = 31
    }
    
    enum ExecTiming: Int {
        case jastNow = 0
        case turnEnd = 1
    }

}
