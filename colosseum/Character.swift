import SpriteKit

class Character : SKSpriteNode {

    var HP_base: Int = 3000;
    var ATK_base: Int = 100;
    var DEF_base: Int = 50;
    var HIT_base: Int = 100;
    var AVD_base: Int = 20;
    var ATK_CNT_base: Int = 1;
    
    var HP: Int = 3000;
    var ATK: Int = 100;
    var DEF: Int = 50;
    var HIT: Int = 100;
    var AVD: Int = 20;
    var ATK_CNT: Int = 1;
    
    var gaugeLangeth: CGFloat = 200.0;
    var gaugeAcceleration: CGFloat = 20.0;
    
    var gaugeHP: Gauge!;
    var labelHP: SKLabelNode!;
    var labelATK: SKLabelNode!;
    var labelDEF: SKLabelNode!;
    var labelHIT: SKLabelNode!;
    var labelAVD: SKLabelNode!;
    var labelATKCNT: SKLabelNode!;
    func refleshStatus() {
        if let gauge = gaugeHP {
            gaugeHP.updateProgress(CGFloat(HP) / CGFloat(HP_base) * 100);
        }
        if let label = labelHP {
            labelHP.text = "HP:\(HP)";
        }
        if let label = labelATK {
            labelATK.text = "ATK:\(ATK)";
        }
        if let label = labelDEF {
            labelDEF.text = "DEF:\(DEF)";
        }
        if let label = labelHIT {
            labelHIT.text = "HIT:\(HIT)";
        }
        if let label = labelAVD {
            labelAVD.text = "AVD:\(AVD)";
        }
        if let label = labelATKCNT {
            labelATKCNT.text = "ATK:\(ATK_CNT)";
        }
    }
    
    var position_base: CGPoint = CGPointZero;
    
    struct Action {
        var name: String = "";
        var cost: Int = 2;
        var action = CharBtlAction();
    }
    var actions: [Action] = [];
    
    struct Enhanced {
        var content = CharBtlAction.Enh();
        var addHP: Int = 0;
        var addATK: Int = 0;
        var addDEF: Int = 0;
        var addHIT: Int = 0;
        var addAVD: Int = 0;
        var addATKCNT: Int = 0;
        var lastTrun: Int = 0;
    }
    var enhances: [Enhanced] = [];
    func addEnhanced(enh: CharBtlAction.Enh) {
        var enhance = Enhanced();
        enhance.content = enh;
        enhance.lastTrun = enh.turn;
        
        switch enhance.content.seedType {
        case CharBtlAction.SeedType.atkNow:
            enhance.addATK = (ATK * Int(enhance.content.enhAtkPowerAdd) / 100);
            enhance.addDEF = (ATK * Int(enhance.content.enhDefPowerAdd) / 100);
        case CharBtlAction.SeedType.atkBase:
            enhance.addATK = (ATK_base * Int(enhance.content.enhAtkPowerAdd) / 100);
            enhance.addDEF = (ATK_base * Int(enhance.content.enhDefPowerAdd) / 100);
        case CharBtlAction.SeedType.defNow:
            enhance.addATK = (DEF * Int(enhance.content.enhAtkPowerAdd) / 100);
            enhance.addDEF = (DEF * Int(enhance.content.enhDefPowerAdd) / 100);
        case CharBtlAction.SeedType.defBase:
            enhance.addATK = (DEF_base * Int(enhance.content.enhAtkPowerAdd) / 100);
            enhance.addDEF = (DEF_base * Int(enhance.content.enhDefPowerAdd) / 100);
        case CharBtlAction.SeedType.lasthp:
            enhance.addATK = (HP * Int(enhance.content.enhAtkPowerAdd) / 100);
            enhance.addDEF = (HP * Int(enhance.content.enhDefPowerAdd) / 100);
        case CharBtlAction.SeedType.maxhp:
            enhance.addATK = (HP_base * Int(enhance.content.enhAtkPowerAdd) / 100);
            enhance.addDEF = (HP_base * Int(enhance.content.enhDefPowerAdd) / 100);
        case CharBtlAction.SeedType.subhp:
            enhance.addATK = ((HP_base - HP) * Int(enhance.content.enhAtkPowerAdd) / 100);
            enhance.addDEF = ((HP_base - HP) * Int(enhance.content.enhDefPowerAdd) / 100);
        }
        enhance.addAVD = Int(enhance.content.enhAvoidedAdd);
        enhance.addATKCNT = enhance.content.enhAtkCountAdd;
        
        enhances.append(enhance);

        // ステータスに反映
        HP += enhance.addHP;
        ATK += enhance.addATK;
        DEF += enhance.addDEF;
        HIT += enhance.addHIT;
        AVD += enhance.addAVD;
        ATK_CNT += enhance.addATKCNT;
    }
    
    struct Jamming {
        var content = CharBtlAction.Jam();
        var lastTrun: Int = 0;
    }
    var jammings: [Jamming] = [];
    func addJamming(jam: CharBtlAction.Jam) {
        var jamming = Jamming(content: jam, lastTrun: jam.turn);
        jammings.append(jamming);
    }
    
    func turnEnd() {
        
        // ターン切れ強化を削除
        for var i = enhances.count-1; i >= 0; --i {
            enhances[i].lastTrun--;
            if enhances[i].lastTrun == 0 {
                
                // ステータスに反映
                let enhance = enhances[i];
                HP -= enhance.addHP;
                ATK -= enhance.addATK;
                DEF -= enhance.addDEF;
                HIT -= enhance.addHIT;
                AVD -= enhance.addAVD;
                ATK_CNT -= enhance.addATKCNT;
                
                enhances.removeAtIndex(i);
            }
        }
        
        // ターン切れ妨害を削除
        for var i = jammings.count-1; i >= 0; --i {
            jammings[i].lastTrun--;
            if jammings[i].lastTrun == 0 {
                jammings.removeAtIndex(i);
            }
        }
    }
    
    func calcATK() -> Int {
        var atk = ATK;
        // エンハンス時にステータスの値変更したのでそのまま使う
        /*
        for enh in enhances {
            switch enh.content.seedType {
            case CharBtlAction.SeedType.atkNow:
                atk += (ATK * Int(enh.content.enhAtkPowerAdd) / 100);
            case CharBtlAction.SeedType.atkBase:
                atk += (ATK_base * Int(enh.content.enhAtkPowerAdd) / 100);
            case CharBtlAction.SeedType.defNow:
                atk += (DEF * Int(enh.content.enhAtkPowerAdd) / 100);
            case CharBtlAction.SeedType.defBase:
                atk += (DEF_base * Int(enh.content.enhAtkPowerAdd) / 100);
            case CharBtlAction.SeedType.lasthp:
                atk += (HP * Int(enh.content.enhAtkPowerAdd) / 100);
            case CharBtlAction.SeedType.maxhp:
                atk += (HP_base * Int(enh.content.enhAtkPowerAdd) / 100);
            case CharBtlAction.SeedType.subhp:
                atk += ((HP_base - HP) * Int(enh.content.enhAtkPowerAdd) / 100);
            }
        }
        */
        for jam in jammings {
            if jam.content.type == CharBtlAction.JamType.weakenAtk {
                switch jam.content.seedType {
                case CharBtlAction.SeedType.atkNow:
                    atk -= (ATK * Int(jam.content.power) / 100);
                case CharBtlAction.SeedType.atkBase:
                    atk -= (ATK_base * Int(jam.content.power) / 100);
                case CharBtlAction.SeedType.defNow:
                    atk -= (DEF * Int(jam.content.power) / 100);
                case CharBtlAction.SeedType.defBase:
                    atk -= (DEF_base * Int(jam.content.power) / 100);
                case CharBtlAction.SeedType.lasthp:
                    atk -= (HP * Int(jam.content.power) / 100);
                case CharBtlAction.SeedType.maxhp:
                    atk -= (HP_base * Int(jam.content.power) / 100);
                case CharBtlAction.SeedType.subhp:
                    atk -= ((HP_base - HP) * Int(jam.content.power) / 100);
                }
            }
        }
        return atk;
    }
    
    func calcDEF() -> Int {
        var def = DEF;
        for enh in enhances {
            switch enh.content.seedType {
            case CharBtlAction.SeedType.atkNow:
                def += (ATK * Int(enh.content.enhDefPowerAdd) / 100);
            case CharBtlAction.SeedType.atkBase:
                def += (ATK_base * Int(enh.content.enhDefPowerAdd) / 100);
            case CharBtlAction.SeedType.defNow:
                def += (DEF * Int(enh.content.enhDefPowerAdd) / 100);
            case CharBtlAction.SeedType.defBase:
                def += (DEF_base * Int(enh.content.enhDefPowerAdd) / 100);
            case CharBtlAction.SeedType.lasthp:
                def += (HP * Int(enh.content.enhDefPowerAdd) / 100);
            case CharBtlAction.SeedType.maxhp:
                def += (HP_base * Int(enh.content.enhDefPowerAdd) / 100);
            case CharBtlAction.SeedType.subhp:
                def += ((HP_base - HP) * Int(enh.content.enhDefPowerAdd) / 100);
            }
        }
        for jam in jammings {
            if jam.content.type == CharBtlAction.JamType.weakenDef {
                switch jam.content.seedType {
                case CharBtlAction.SeedType.atkNow:
                    def -= (ATK * Int(jam.content.power) / 100);
                case CharBtlAction.SeedType.atkBase:
                    def -= (ATK_base * Int(jam.content.power) / 100);
                case CharBtlAction.SeedType.defNow:
                    def -= (DEF * Int(jam.content.power) / 100);
                case CharBtlAction.SeedType.defBase:
                    def -= (DEF_base * Int(jam.content.power) / 100);
                case CharBtlAction.SeedType.lasthp:
                    def -= (HP * Int(jam.content.power) / 100);
                case CharBtlAction.SeedType.maxhp:
                    def -= (HP_base * Int(jam.content.power) / 100);
                case CharBtlAction.SeedType.subhp:
                    def -= ((HP_base - HP) * Int(jam.content.power) / 100);
                }
            }
        }
        return def;
    }

}
