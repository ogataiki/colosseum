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
            labelDEF.text = "DEF:\(DEF)+\(defenceds.count)";
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
    
    struct Defenced {
        var content = CharBtlAction.Def();
        var addDef: Int = 0;
        var lastCount: Int = 0;
    }
    var defenceds: [Defenced] = [];
    func addDefenced(def: CharBtlAction.Def) {
        var defence = Defenced();
        defence.content = def;
        defence.lastCount = def.defCount
        
        // 強さ取得
        let (power_TypeRatio: Int, power_TypeConst: Int) = calcPower(Int(def.defPower), seedType: def.seedType, char: self);
        defence.addDef = power_TypeRatio;

        defenceds.append(defence);
        
        // 以降、相手の攻撃を受けるタイミングで消費
        // ターンで消費しない
    }
    func allCancelDefenced() {
        defenceds = [];
    }

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
        let (power_TypeRatio: Int, power_TypeConst: Int) = calcPower(Int(enh.power), seedType: enh.seedType, char: self);

        switch enh.type {
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
    func allCancelEnhanced() {
        for enh in enhances {
            
            // ステータスに反映
            HP -= enh.addHP;
            ATK -= enh.addATK;
            DEF -= enh.addDEF;
            HIT -= enh.addHIT;
            AVD -= enh.addAVD;
            ATK_CNT -= enh.addATKCNT;
        }
        enhances = [];
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
        let (power_TypeRatio: Int, power_TypeConst: Int) = calcPower(Int(jam.power), seedType: jam.seedType, char: executor);
        
        switch jam.type {
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
    func allCancelJammings() {
        for jam in jammings {
            
            // ステータスに反映
            HP += jam.addHP;
            ATK += jam.addATK;
            DEF += jam.addDEF;
            HIT += jam.addHIT;
            AVD += jam.addAVD;
            ATK_CNT += jam.addATKCNT;
        }
        jammings = [];
    }

    func calcPower(power: Int, seedType: CharBtlAction.SeedType, char: Character) -> (ratioValue:Int, constValue:Int) {
        let power_TypeConst = Int(power);
        let power_TypeRatio: Int;
        switch seedType {
        case CharBtlAction.SeedType.atkNow:
            power_TypeRatio = (char.ATK * Int(power) / 100);
        case CharBtlAction.SeedType.atkBase:
            power_TypeRatio = (char.ATK_base * Int(power) / 100);
        case CharBtlAction.SeedType.defNow:
            power_TypeRatio = (char.DEF * Int(power) / 100);
        case CharBtlAction.SeedType.defBase:
            power_TypeRatio = (char.DEF_base * Int(power) / 100);
        case CharBtlAction.SeedType.lasthp:
            power_TypeRatio = (char.HP * Int(power) / 100);
        case CharBtlAction.SeedType.maxhp:
            power_TypeRatio = (char.HP_base * Int(power) / 100);
        case CharBtlAction.SeedType.subhp:
            power_TypeRatio = ((char.HP_base - char.HP) * Int(power) / 100);
        }
        return (power_TypeRatio, power_TypeConst);
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
    
    func calcDEF(consumeDefenceds: Bool = false) -> Int {
        var def = DEF;
        if defenceds.count > 0 {
            var defence = defenceds[defenceds.count-1];
            def += defence.addDef;
            defence.lastCount--;
            if defence.lastCount <= 0 {
                defenceds.removeLast();
            }
        }
        return def;
    }

}
