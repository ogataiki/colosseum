import SpriteKit

class CharBtlAction {
    
    // ---
    // 行動のメインタイプ 攻撃を受ける側としての種別を示す
    enum ActType: Int {
        case non = 0
        case atk = 1
        case def = 2
        case jam = 3
        case enh = 4
    }
    var type = ActType.non;
    static func getActTypeName(type: ActType) -> String {
        switch type {
        case .atk:
            return "攻撃";
        case .def:
            return "防御";
        case .jam:
            return "妨害";
        case .enh:
            return "強化";
        default: break;
        }
        return "";
    }
    static func judgeAdvantage(type: ActType, comp: ActType) -> (Bool, Bool) {
        switch type {
        case .atk:
            if comp == ActType.enh {
                return (true, false);
            }
            else if comp == ActType.def {
                return (false, true);
            }
        case .def:
            if comp == ActType.atk {
                return (true, false);
            }
            else if comp == ActType.jam {
                return (false, true);
            }
        case .jam:
            if comp == ActType.def {
                return (true, false);
            }
            else if comp == ActType.enh {
                return (false, true);
            }
        case .enh:
            if comp == ActType.jam {
                return (true, false);
            }
            else if comp == ActType.atk {
                return (false, true);
            }
        default: break;
        }
        return (false, false);
    }
    
    // ---
    // 攻撃のタイプと内容
    // 複数のタイプを同時にセットすることが可能な構造だが設定してはダメ
    // 複数のタイプはスキルのみ設定可能
    
    // atk
    struct Atk {
        var atkPower: CGFloat = 1.0;
    }
    var atk: [Atk] = [];
    var atkCost: Int = 2;
    
    // def
    struct Def {
        
        var seedType = SeedType.atkNow;

        var defPower: CGFloat = 50.0;           // 0.0 ~ 100.0 100.0 = Avoided
        var defCount: Int = 1;                  // this turn enable count
        var defCounterAttack: CGFloat = 0.0;    // 0.0 ~
    }
    // 基本1個しか設定できない
    // 複数いれた場合はカウンターの値が先頭しか有効にならない
    var def: [Def] = [];
    var defCost: Int = 2;
    
    // jam
    enum JamType: Int {
        case enhAtk = 1
        case enhDef = 2
        case enhHit = 3
        case enhAvoid = 4
        case enhAtkCnt = 5
        case weakenAtk = 6
        case weakenDef = 7
        case weakenHit = 8
        case weakenAvoid = 9
        case weakenAtkCnt = 10
        case poison = 11
        case paralysis = 12
    }
    struct Jam {
        
        var type = JamType.weakenAtk;
        
        var seedType = SeedType.atkNow;
        
        var power: CGFloat = 100.0;         // Ratio % for seedtype
        var addDamage: CGFloat = 10.0;      // Ratio % for HP_base
        var turn: Int = 1;                  // Continue turn;
        var execTiming = ExecTiming.jastNow;
    }
    var jam: [Jam] = [];
    var jamCost: Int = 3;
    
    // enh
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
    
    struct Skl {
        var type = ActType.non;
        var atk: [Atk] = [];
        var def: [Def] = [];
        var jam: [Jam] = [];
        var enh: [Enh] = [];
    }
    var skl: [Skl] = [];
    var sklCost: Int = 5;
    

    enum SeedType: Int {
        case constant = 0
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
