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
            if ATK < ATK_base {
                labelATK.fontColor = UIColor.blueColor();
            }
            else if ATK > ATK_base {
                labelATK.fontColor = UIColor.orangeColor();
            }
            else {
                labelATK.fontColor = UIColor.whiteColor();
            }
        }
        if let label = labelDEF {
            labelDEF.text = "DEF:\(DEF)";
            if DEF < DEF_base {
                labelDEF.fontColor = UIColor.blueColor();
            }
            else if DEF > DEF_base {
                labelDEF.fontColor = UIColor.orangeColor();
            }
            else {
                labelDEF.fontColor = UIColor.whiteColor();
            }
        }
        if let label = labelHIT {
            labelHIT.text = "HIT:\(HIT)";
            if HIT < HIT_base {
                labelHIT.fontColor = UIColor.blueColor();
            }
            else if HIT > HIT_base {
                labelHIT.fontColor = UIColor.orangeColor();
            }
            else {
                labelHIT.fontColor = UIColor.whiteColor();
            }
        }
        if let label = labelAVD {
            labelAVD.text = "AVD:\(AVD)";
            if AVD < AVD_base {
                labelAVD.fontColor = UIColor.blueColor();
            }
            else if AVD > AVD_base {
                labelAVD.fontColor = UIColor.orangeColor();
            }
            else {
                labelAVD.fontColor = UIColor.whiteColor();
            }
        }
        if let label = labelATKCNT {
            labelATKCNT.text = "ATK:\(ATK_CNT)";
            if ATK_CNT < ATK_CNT_base {
                labelATKCNT.fontColor = UIColor.blueColor();
            }
            else if ATK_CNT > ATK_CNT_base {
                labelATKCNT.fontColor = UIColor.orangeColor();
            }
            else {
                labelATKCNT.fontColor = UIColor.whiteColor();
            }
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
        
        // 強さ取得
        let power_TypeConst = Int(enh.power);
        let power_TypeRatio: Int;
        switch enhance.content.seedType {
        case CharBtlAction.SeedType.atkNow:
            power_TypeRatio = (ATK * Int(enh.power) / 100);
        case CharBtlAction.SeedType.atkBase:
            power_TypeRatio = (ATK_base * Int(enh.power) / 100);
        case CharBtlAction.SeedType.defNow:
            power_TypeRatio = (DEF * Int(enh.power) / 100);
        case CharBtlAction.SeedType.defBase:
            power_TypeRatio = (DEF_base * Int(enh.power) / 100);
        case CharBtlAction.SeedType.lasthp:
            power_TypeRatio = (HP * Int(enh.power) / 100);
        case CharBtlAction.SeedType.maxhp:
            power_TypeRatio = (HP_base * Int(enh.power) / 100);
        case CharBtlAction.SeedType.subhp:
            power_TypeRatio = ((HP_base - HP) * Int(enh.power) / 100);
        }

        switch enhance.content.type {
        case CharBtlAction.EnhType.atk:
            enhance.addATK = power_TypeRatio;
        case CharBtlAction.EnhType.def:
            enhance.addDEF = power_TypeRatio;
        case CharBtlAction.EnhType.avd:
            enhance.addAVD = power_TypeConst;
        case CharBtlAction.EnhType.hit:
            enhance.addHIT = power_TypeConst;
        case CharBtlAction.EnhType.atkcnt:
            enhance.addATKCNT = power_TypeConst;
        }

        enhances.append(enhance);

        // ステータスに反映
        if enhance.content.execTiming == CharBtlAction.ExecTiming.jastNow {
            HP += enhance.addHP;
            ATK += enhance.addATK;
            DEF += enhance.addDEF;
            HIT += enhance.addHIT;
            AVD += enhance.addAVD;
            ATK_CNT += enhance.addATKCNT;
        }
    }
    
    struct Jamming {
        var content = CharBtlAction.Jam();
        var recover: Int = 0;
        var addHP: Int = 0;
        var addATK: Int = 0;
        var addDEF: Int = 0;
        var addHIT: Int = 0;
        var addAVD: Int = 0;
        var addATKCNT: Int = 0;
        var poisonDamage: Int = 0;
        var paralysisAVD: Int = 0;
        var lastTrun: Int = 0;
    }
    var jammings: [Jamming] = [];
    func addJamming(jam: CharBtlAction.Jam, executor: Character) {
        var jamming = Jamming();
        jamming.content = jam;
        jamming.lastTrun = jam.turn;
        
        // 強さ取得
        let power_TypeConst = Int(jam.power);
        let power_TypeRatio: Int;
        switch jamming.content.seedType {
        case CharBtlAction.SeedType.atkNow:
            power_TypeRatio = (executor.ATK * Int(jam.power) / 100);
        case CharBtlAction.SeedType.atkBase:
            power_TypeRatio = (executor.ATK_base * Int(jam.power) / 100);
        case CharBtlAction.SeedType.defNow:
            power_TypeRatio = (executor.DEF * Int(jam.power) / 100);
        case CharBtlAction.SeedType.defBase:
            power_TypeRatio = (executor.DEF_base * Int(jam.power) / 100);
        case CharBtlAction.SeedType.lasthp:
            power_TypeRatio = (executor.HP * Int(jam.power) / 100);
        case CharBtlAction.SeedType.maxhp:
            power_TypeRatio = (executor.HP_base * Int(jam.power) / 100);
        case CharBtlAction.SeedType.subhp:
            power_TypeRatio = ((executor.HP_base - executor.HP) * Int(jam.power) / 100);
        }

        switch jamming.content.type {
        case CharBtlAction.JamType.recover:
            jamming.recover = power_TypeRatio;
        case CharBtlAction.JamType.enhAtk:
            jamming.addATK = power_TypeRatio;
        case CharBtlAction.JamType.enhDef:
            jamming.addDEF = power_TypeRatio;
        case CharBtlAction.JamType.enhAvoid:
            jamming.addAVD = power_TypeRatio;
        case CharBtlAction.JamType.enhAtkCnt:
            jamming.addATKCNT = power_TypeConst;
        case CharBtlAction.JamType.weakenAtk:
            jamming.addATK = 0 - power_TypeRatio;
        case CharBtlAction.JamType.weakenDef:
            jamming.addDEF = 0 - power_TypeRatio;
        case CharBtlAction.JamType.weakenAvoid:
            jamming.addAVD = 0 - power_TypeConst;
        case CharBtlAction.JamType.weakenAtkCnt:
            jamming.addATKCNT = 0 - power_TypeConst;
        case CharBtlAction.JamType.poison:
            jamming.poisonDamage = power_TypeRatio;
        case CharBtlAction.JamType.paralysis:
            jamming.paralysisAVD = power_TypeConst;
        }
        jammings.append(jamming);
        
        // ステータスに反映
        if jamming.content.execTiming == CharBtlAction.ExecTiming.jastNow {
            if HP + jamming.recover > HP_base {
                HP = HP_base;
            }
            else {
                HP += jamming.recover;
            }
            HP += jamming.addHP;
            ATK += jamming.addATK;
            DEF += jamming.addDEF;
            HIT += jamming.addHIT;
            AVD += jamming.addAVD;
            ATK_CNT += jamming.addATKCNT;
        }
    }
    
    func turnEnd() {
        
        for var i = enhances.count-1; i >= 0; --i {
            
            // TODO:ターン終了アクションを実行
            
            enhances[i].lastTrun--;
            
            // ターン切れ強化を削除
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
        
        for var i = jammings.count-1; i >= 0; --i {

            // TODO:ターン終了アクションを実行

            jammings[i].lastTrun--;

            // ターン切れ妨害を削除
            if jammings[i].lastTrun == 0 {
                
                // ステータスに反映
                let jamming = jammings[i];
                HP -= jamming.addHP;
                ATK -= jamming.addATK;
                DEF -= jamming.addDEF;
                HIT -= jamming.addHIT;
                AVD -= jamming.addAVD;
                ATK_CNT -= jamming.addATKCNT;

                jammings.removeAtIndex(i);
            }
        }
    }
    
    func calcATK() -> Int {
        // エンハンス時にステータスの値変更したのでそのまま使う
        return ATK;
    }
    
    func calcDEF() -> Int {
        // エンハンス時にステータスの値変更したのでそのまま使う
        return DEF;
    }

}
