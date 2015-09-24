import SpriteKit

class CharBase : SKSpriteNode {
    
    var isPlayer: Bool = false;
    func setPlayer(v: Bool = true) {
        isPlayer = v;
        if isPlayer {
            self.xScale = -1.0;
        }
        else {
            self.xScale = 1.0;
        }
    }
    
    var displayName: String = "";
    
    struct Spec {
        var HP: Int = 3000;
        var ATK: Int = 100;
        var DEF: Int = 50;
        var HIT: Int = 100;
        var AVD: Int = 20;
        var ADD_ATK: Int = 0;
    }
    var spec_base = Spec();
    var spec = Spec();

    func statusInit(
        #hp: Int,
        atk: Int,
        def: Int,
        hit: Int,
        avd: Int,
        add_atk: Int)
    {
        spec_base.HP = hp;
        spec_base.ATK = atk;
        spec_base.DEF = def;
        spec_base.HIT = hit;
        spec_base.AVD = avd;
        spec_base.ADD_ATK = add_atk;
        
        spec.HP = hp;
        spec.ATK = atk;
        spec.DEF = def;
        spec.HIT = hit;
        spec.AVD = avd;
        spec.ADD_ATK = add_atk;
    }
    
    var gaugeLangeth: CGFloat = 200.0;
    var gaugeAcceleration: CGFloat = 20.0;
    
    var gaugeHP: Gauge!;
    func gaugeInit(size: CGSize, direction: Gauge.Direction, zPos: CGFloat) {
        gaugeHP = Gauge(color: UIColor.grayColor(), size: size);
        gaugeHP.initGauge(color: UIColor.greenColor(), direction: direction, zPos:zPos);
        gaugeHP.initGauge_lo(color: UIColor.redColor(), zPos:zPos);
        gaugeHP.changeAnchorPoint(CGPointMake(0.5, 0.5));
        gaugeHP.changePosition(CGPointMake(self.position.x, self.position.y - size.height*0.6));
        gaugeHP.resetProgress(0.0);
        gaugeHP.updateProgress(100);
    }
    
    var labelHP: SKLabelNode!;
    var labelATK: SKLabelNode!;
    var labelDEF: SKLabelNode!;
    var labelHIT: SKLabelNode!;
    var labelAVD: SKLabelNode!;
    var labelADDATK: SKLabelNode!;
    func refleshStatus(_spec: Spec? = nil) {
        let s: Spec;
        if _spec == nil {
            s = spec;
        }
        else {
            s = _spec!;
        }
        if let gauge = gaugeHP {
            gaugeHP.updateProgress(CGFloat(s.HP) / CGFloat(spec_base.HP) * 100);
        }
        if let label = labelHP {
            labelHP.text = "HP:\(s.HP)";
            if s.HP < spec_base.HP / 5 {
                labelHP.fontColor = UIColor.redColor();
            }
            else if s.HP < spec_base.HP / 2 {
                labelHP.fontColor = UIColor.yellowColor();
            }
            else if s.HP < spec_base.HP {
                labelHP.fontColor = UIColor.blueColor();
            }
            else {
                labelHP.fontColor = UIColor.whiteColor();
            }
        }
        if let label = labelATK {
            labelATK.text = "ATK:\(s.ATK)";
            if s.ATK < spec_base.ATK {
                labelATK.fontColor = UIColor.blueColor();
            }
            else if s.ATK > spec_base.ATK {
                labelATK.fontColor = UIColor.orangeColor();
            }
            else {
                labelATK.fontColor = UIColor.whiteColor();
            }
        }
        if let label = labelDEF {
            labelDEF.text = "DEF:\(s.DEF)+\(calcDefences(defenceds))";
            if s.DEF < spec_base.DEF {
                labelDEF.fontColor = UIColor.blueColor();
            }
            else if s.DEF > spec_base.DEF {
                labelDEF.fontColor = UIColor.orangeColor();
            }
            else {
                labelDEF.fontColor = UIColor.whiteColor();
            }
        }
        if let label = labelHIT {
            labelHIT.text = "HIT:\(s.HIT)";
            if s.HIT < spec_base.HIT {
                labelHIT.fontColor = UIColor.blueColor();
            }
            else if s.HIT > spec_base.HIT {
                labelHIT.fontColor = UIColor.orangeColor();
            }
            else {
                labelHIT.fontColor = UIColor.whiteColor();
            }
        }
        if let label = labelAVD {
            labelAVD.text = "AVD:\(s.AVD)";
            if s.AVD < spec_base.AVD {
                labelAVD.fontColor = UIColor.blueColor();
            }
            else if s.AVD > spec_base.AVD {
                labelAVD.fontColor = UIColor.orangeColor();
            }
            else {
                labelAVD.fontColor = UIColor.whiteColor();
            }
        }
        if let label = labelADDATK {
            labelADDATK.text = "ADDATK:\(s.ADD_ATK)";
            if s.ADD_ATK > 0 {
                labelADDATK.fontColor = UIColor.orangeColor();
            }
            else {
                labelADDATK.fontColor = UIColor.whiteColor();
            }
        }
    }
    
    var position_base: CGPoint = CGPointZero;
    
    struct Action {
        var type = ActionType.non;
        var name: String = "";
        var cost: Int = 2;
        var action = CharBtlAction();
    }
    var actions: [Action] = [];
    
    enum ActionType: Int {
        case non = 0;
        case atk
        case def
        case jam
        case enh
        case skl
    }
    static func cnvActType(action: Action) -> CharBtlAction.ActType {
        if action.type == ActionType.skl {
            switch action.action.type {
            case .non:
                return CharBtlAction.ActType.non;
            case .atk:
                return CharBtlAction.ActType.atk;
            case .def:
                return CharBtlAction.ActType.def;
            case .jam:
                return CharBtlAction.ActType.jam;
            case .enh:
                return CharBtlAction.ActType.enh;
            }
        }
        else {
            return action.action.type;
        }
    }
    
    struct Attacked {
        var content = CharBtlAction.Atk();
        var damage: Int = 0;
        var consumeDefenced: Bool = false;
        var counter: Bool = false;
        var specBefor = Spec();
        var specAfter = Spec();
    }
    
    func procAction_atk(atk: [CharBtlAction.Atk], _attack: Int? = nil, targetSpecBefor: Spec, targetDefences: [Defenced]
        , counter: Bool = false, counter_content: CharBtlAction.Def = CharBtlAction.Def())
        -> (result: [Attacked], specAfter: Spec, defsAfter: [Defenced])
    {
        var result: [Attacked] = [];
        var specWork = targetSpecBefor;
        var defsWork = targetDefences;
        let attack: Int;
        if _attack == nil {
            attack = spec.ATK;
        }
        else {
            attack = _attack!;
        }
        var totalAtkCount: Int = 0;
        for i in 0 ..< atk.count {
            var data = Attacked();
            data.content = atk[i];
            data.consumeDefenced = (defsWork.count > 0) ? true : false;
            data.counter = counter;
            if counter {
                // カウンターはミスなし
                data.damage = (attack * Int(counter_content.defCounterAttack) / 100) - (specWork.DEF + calcDefences(defsWork));
                if data.damage <= 0 {
                    data.damage = 1;
                }
                if defsWork.count > 0 {
                    defsWork.removeLast();
                }
            }
            else {
                data.damage = (attack * Int(atk[i].atkPower) / 100) - (specWork.DEF + calcDefences(defsWork));
                if data.damage <= 0 {
                    data.damage = 1;
                }
                
                // 命中計算
                var hit = spec.HIT - specWork.AVD;
                hit = min(100, hit);
                hit = max(1, hit);
                let random = 1 + (arc4random() % 100);
                if random > UInt32(hit) {
                    // ミス
                    data.damage = 0;
                }
                else {
                    if defsWork.count > 0 {
                        defsWork.removeLast();
                    }
                }
            }
            
            data.specBefor = specWork;
            data.specAfter = specWork;
            data.specAfter.HP = data.specAfter.HP - data.damage;
            if data.specAfter.HP < 0 {
                data.specAfter.HP = 0;
            }
            specWork = data.specAfter;
            
            totalAtkCount++;
            
            result.append(data);
            
            
            // 加算攻撃回数分を追加
            
            if counter {
                // カウンターの場合はなし
                continue;
            }
            
            for i in 0 ..< spec.ADD_ATK {
                var dataAdd = Attacked();
                dataAdd.content = atk[i];
                dataAdd.damage = data.damage;
                dataAdd.specBefor = specWork;
                dataAdd.specAfter = specWork;
                dataAdd.consumeDefenced = (defsWork.count > 0) ? true : false;
                dataAdd.counter = false;
                
                // 命中計算
                var hit = spec.HIT - specWork.AVD;
                hit = min(100, hit);
                hit = max(1, hit);
                let random = 1 + (arc4random() % 100);
                if random > UInt32(hit) {
                    // ミス
                    dataAdd.damage = 0;
                }
                else {
                    if defsWork.count > 0 {
                        defsWork.removeLast();
                    }
                }
                
                dataAdd.specBefor = specWork;
                specWork.HP = specWork.HP - dataAdd.damage;
                if specWork.HP < 0 {
                    specWork.HP = 0;
                }
                dataAdd.specAfter = specWork;
                
                totalAtkCount++;

                result.append(data);
            }
        }
        
        return (result, specWork, defsWork);
    }
    func addDamage(atk: [Attacked]) {
        for data in atk {
            spec.HP = spec.HP - data.damage;
            if spec.HP < 0 {
                spec.HP = 0;
            }
            
            if data.consumeDefenced {
                if defenceds.count > 0 {
                    var defence = defenceds[defenceds.count-1];
                    defence.lastCount--;
                    if defence.lastCount <= 0 {
                        defenceds.removeLast();
                    }
                }
            }
        }
    }
    
    struct Defenced {
        var content = CharBtlAction.Def();
        var addDef: Int = 0;
        var lastCount: Int = 0;
        var specBefor = Spec();
        var specAfter = Spec();
    }
    var defenceds: [Defenced] = [];
    
    func procAction_def(def: [CharBtlAction.Def], specBefor: Spec)
        -> (result: [Defenced], specAfter: Spec)
    {
        var result: [Defenced] = [];
        var specWork = specBefor;
        for i in 0 ..< def.count {
            var data = Defenced();
            data.content = def[i];
            data.specBefor = specBefor;
            data.specAfter = specBefor;
            data.lastCount = def[i].defCount
            
            // 強さ取得
            let (power_TypeRatio: Int, power_TypeConst: Int) = calcPower(Int(def[i].defPower), seedType: def[i].seedType, char: self);
            data.addDef = power_TypeRatio;
            
            result.append(data);
        }
        return (result, specWork);
    }
    func addDefenced(def: [Defenced]) {
        for data in def {
            defenceds.append(data);
        }
        
        // 以降、相手の攻撃を受けるタイミングで消費
        // ターンで消費しない
    }
    func procCancel_def() -> Spec {
        return spec;
    }
    func allCancelDefenced() -> Spec {
        defenceds = [];
        return spec;
    }
    func calcDefences(defs: [Defenced]) -> Int {
        var addDef: Int = 0;
        // TODO:ここちょっと変えるかも
        // 積み上がった防御すべてが有効になるように調整するかも
        for d in defs {
            addDef += d.addDef;
        }
        /*
        if defs.count > 0 {
            var defence = defs[defs.count-1];
            addDef += defence.addDef;
        }
        */
        return addDef;
    }

    struct Jamming {
        var content = CharBtlAction.Jam();
        var damage: Int = 0;
        var addHP: Int = 0;
        var addATK: Int = 0;
        var addDEF: Int = 0;
        var addHIT: Int = 0;
        var addAVD: Int = 0;
        var addATKCNT: Int = 0;
        var poisonDamage: Int = 0;
        var paralysisAVD: Int = 0;
        var lastTrun: Int = 0;
        var specBefor = Spec();
        var specAfter = Spec();
    }
    var jammings: [Jamming] = [];
    
    func procAction_jam(jam: [CharBtlAction.Jam], specBase: Spec, specBefor: Spec)
        -> (result: [Jamming], specAfter: Spec)
    {
        var result: [Jamming] = [];
        var specWork = specBefor;
        for i in 0 ..< jam.count {
            var data = Jamming();
            data.specBefor = specBefor;
            
            // HPベース比率からの割合　防御力無視ダメージ
            data.damage = (specBase.HP * Int(jam[i].addDamage) / 100);
            if data.damage <= 0 {
                data.damage = 1;
            }

            specWork.HP = specWork.HP - data.damage;
            if specWork.HP < 0 {
                specWork.HP = 0;
            }

            data.content = jam[i];
            data.lastTrun = jam[i].turn;
            
            // 強さ取得
            let (power_TypeRatio: Int, power_TypeConst: Int) = calcPower(Int(jam[i].power), seedType: jam[i].seedType, char: self);
            
            switch jam[i].type {
            case .enhAtk:
                data.addATK = power_TypeRatio;
            case .enhDef:
                data.addDEF = power_TypeRatio;
            case .enhHit:
                data.addHIT = power_TypeConst;
            case .enhAvoid:
                data.addAVD = power_TypeConst;
            case .enhAtkCnt:
                data.addATKCNT = power_TypeConst;
            case .weakenAtk:
                data.addATK = 0 - power_TypeRatio;
            case .weakenDef:
                data.addDEF = 0 - power_TypeRatio;
            case .weakenHit:
                data.addHIT = 0 - power_TypeConst;
            case .weakenAvoid:
                data.addAVD = 0 - power_TypeConst;
            case .weakenAtkCnt:
                data.addATKCNT = 0 - power_TypeConst;
            case .poison:
                data.poisonDamage = power_TypeRatio;
            case .paralysis:
                data.paralysisAVD = power_TypeConst;
            }
            specWork.ATK += data.addATK;
            specWork.DEF += data.addDEF;
            specWork.HIT += data.addHIT;
            specWork.AVD += data.addAVD;
            specWork.ADD_ATK += data.addATKCNT;

            data.specAfter = specWork;

            result.append(data);
        }
        return (result, specWork);
    }
    func addJamming(jam: [Jamming]) {
        for data in jam {
            jammings.append(data);

            // ステータスに反映
            if data.content.execTiming == CharBtlAction.ExecTiming.jastNow {
                spec.HP += data.addHP;
                spec.ATK += data.addATK;
                spec.DEF += data.addDEF;
                spec.HIT += data.addHIT;
                spec.AVD += data.addAVD;
                spec.ADD_ATK += data.addATKCNT;
                
                spec.HP = spec.HP - data.damage;
                if spec.HP < 0 {
                    spec.HP = 0;
                }
            }
        }
    }
    func procCancel_jam() -> Spec {
        var s = spec;
        for jam in jammings {
            
            // ステータスに反映
            s.HP -= jam.addHP;
            s.ATK -= jam.addATK;
            s.DEF -= jam.addDEF;
            s.HIT -= jam.addHIT;
            s.AVD -= jam.addAVD;
            s.ADD_ATK -= jam.addATKCNT;
        }
        return s;
    }
    func allCancelJammings() -> Spec {
        for jam in jammings {
            
            // ステータスに反映
            spec.HP -= jam.addHP;
            spec.ATK -= jam.addATK;
            spec.DEF -= jam.addDEF;
            spec.HIT -= jam.addHIT;
            spec.AVD -= jam.addAVD;
            spec.ADD_ATK -= jam.addATKCNT;
        }
        jammings = [];
        return spec;
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
        var specBefor = Spec();
        var specAfter = Spec();
    }
    var enhances: [Enhanced] = [];
    
    func procAction_enh(enh: [CharBtlAction.Enh], specBefor: Spec)
        -> (result: [Enhanced], specAfter: Spec)
    {
        var result: [Enhanced] = [];
        var specWork = specBefor;
        for i in 0 ..< enh.count {
            var data = Enhanced();
            data.content = enh[i];
            data.lastTrun = enh[i].turn;
            data.specBefor = specWork;
            
            // 強さ取得
            let (power_TypeRatio: Int, power_TypeConst: Int) = calcPower(Int(enh[i].power), seedType: enh[i].seedType, char: self);
            
            switch enh[i].type {
            case .atk:
                data.addATK = power_TypeRatio;
            case .def:
                data.addDEF = power_TypeRatio;
            case .avd:
                data.addAVD = power_TypeConst;
            case .hit:
                data.addHIT = power_TypeConst;
            case .atkcnt:
                data.addATKCNT = power_TypeConst;
            }
            specWork.ATK += data.addATK;
            specWork.DEF += data.addDEF;
            specWork.HIT += data.addHIT;
            specWork.AVD += data.addAVD;
            specWork.ADD_ATK += data.addATKCNT;
            
            data.specAfter = specWork;

            result.append(data);
        }
        return (result, specWork);
    }
    func addEnhanced(enh: [Enhanced]) {
        for data in enh {
            enhances.append(data);
            
            // ステータスに反映
            if data.content.execTiming == CharBtlAction.ExecTiming.jastNow {
                spec.HP += data.addHP;
                spec.ATK += data.addATK;
                spec.DEF += data.addDEF;
                spec.HIT += data.addHIT;
                spec.AVD += data.addAVD;
                spec.ADD_ATK += data.addATKCNT;
            }
        }
    }
    func procCancel_enh() -> Spec {
        var s = spec;
        for enh in enhances {
            
            // ステータスに反映
            s.HP -= enh.addHP;
            s.ATK -= enh.addATK;
            s.DEF -= enh.addDEF;
            s.HIT -= enh.addHIT;
            s.AVD -= enh.addAVD;
            s.ADD_ATK -= enh.addATKCNT;
        }
        return s;
    }
    func allCancelEnhanced() -> Spec {
        for enh in enhances {
            
            // ステータスに反映
            spec.HP -= enh.addHP;
            spec.ATK -= enh.addATK;
            spec.DEF -= enh.addDEF;
            spec.HIT -= enh.addHIT;
            spec.AVD -= enh.addAVD;
            spec.ADD_ATK -= enh.addATKCNT;
        }
        enhances = [];
        return spec;
    }
    
    struct Skilled {
        var type = CharBtlAction.ActType.non;
        var atk: [Attacked] = [];
        var def: [Defenced] = [];
        var jam: [Jamming] = [];
        var enh: [Enhanced] = [];
        var specBefor_executer = Spec();
        var specAfter_executer = Spec();
        var specBefor_target = Spec();
        var specAfter_target = Spec();
    }
    var skilleds: [Skilled] = [];
    
    func procAction_skl(skl: [CharBtlAction.Skl], specBefor_executer: Spec, specBefor_target: Spec, specBase_target: Spec, targetDefences: [Defenced])
        -> (result: [Skilled], specAfter_executer: Spec, specAfter_target: Spec, defsAfter_target: [Defenced])
    {
        var result: [Skilled] = [];
        var specWork_executer = specBefor_executer;
        var specWork_target = specBefor_target;
        var defsWork_target = targetDefences;
        for i in 0 ..< skl.count {
            var data = Skilled();
            data.type = skl[i].type;
            data.specBefor_executer = specWork_executer;
            data.specBefor_target = specWork_target;
            
            switch skl[i].type {
            case .atk:
                var ret = procAction_atk(skl[i].atk, _attack: specWork_executer.ATK, targetSpecBefor: specWork_target, targetDefences: defsWork_target);
                data.atk = ret.result;
                specWork_target = ret.specAfter;
                defsWork_target = ret.defsAfter;
            case .def:
                var ret = procAction_def(skl[i].def, specBefor: specWork_executer);
                data.def = ret.result;
                specWork_executer = ret.specAfter;
            case .jam:
                var ret = procAction_jam(skl[i].jam, specBase: specBase_target, specBefor: specWork_target);
                data.jam = ret.result;
                specWork_target = ret.specAfter;
            case .enh:
                var ret = procAction_enh(skl[i].enh, specBefor: specWork_executer);
                data.enh = ret.result;
                specWork_executer = ret.specAfter;
            default:
                break;
            }
            data.specAfter_executer = specWork_executer;
            data.specAfter_target = specWork_target;
            
            result.append(data);
        }
        return (result, specWork_executer, specWork_target, defsWork_target);
    }
    func addSkilled(skl: [Skilled]) {
        for data in skl {
            skilleds.append(data);
            
            // ステータスに反映
            switch data.type {
            case .atk:
                addDamage(data.atk);
            case .def:
                addDefenced(data.def);
            case .jam:
                addJamming(data.jam);
            case .enh:
                addEnhanced(data.enh);
            default:
                break;
            }
        }
    }
    func allCancelSkilled() {
        // ステータスへの反映は各々のキャンセルメソッドで処理すること
        // 特技で与えたものだけを選択してクリアはしない(複雑すぎて意味不明になる)
        skilleds = [];
    }

    func calcPower(power: Int, seedType: CharBtlAction.SeedType, char: CharBase) -> (ratioValue:Int, constValue:Int) {
        let power_TypeConst = Int(power);
        let power_TypeRatio: Int;
        switch seedType {
        case .constant:
            power_TypeRatio = power_TypeConst;
        case .atkNow:
            power_TypeRatio = (char.spec.ATK * Int(power) / 100);
        case .atkBase:
            power_TypeRatio = (char.spec_base.ATK * Int(power) / 100);
        case .defNow:
            power_TypeRatio = (char.spec.DEF * Int(power) / 100);
        case .defBase:
            power_TypeRatio = (char.spec_base.DEF * Int(power) / 100);
        case .lasthp:
            power_TypeRatio = (char.spec.HP * Int(power) / 100);
        case .maxhp:
            power_TypeRatio = (char.spec_base.HP * Int(power) / 100);
        case .subhp:
            power_TypeRatio = ((char.spec_base.HP - char.spec.HP) * Int(power) / 100);
        }
        return (power_TypeRatio, power_TypeConst);
    }
    
    func turnEnd() {
        
        for var i = jammings.count-1; i >= 0; --i {

            // TODO:ターン終了アクションを実行

            jammings[i].lastTrun--;

            // ターン切れ妨害を削除
            if jammings[i].lastTrun == 0 {
                
                // ステータスに反映
                let jamming = jammings[i];
                spec.HP -= jamming.addHP;
                spec.ATK -= jamming.addATK;
                spec.DEF -= jamming.addDEF;
                spec.HIT -= jamming.addHIT;
                spec.AVD -= jamming.addAVD;
                spec.ADD_ATK -= jamming.addATKCNT;

                jammings.removeAtIndex(i);
            }
        }
        
        for var i = enhances.count-1; i >= 0; --i {
            
            // TODO:ターン終了アクションを実行
            
            enhances[i].lastTrun--;
            
            // ターン切れ強化を削除
            if enhances[i].lastTrun == 0 {
                
                // ステータスに反映
                let enhance = enhances[i];
                spec.HP -= enhance.addHP;
                spec.ATK -= enhance.addATK;
                spec.DEF -= enhance.addDEF;
                spec.HIT -= enhance.addHIT;
                spec.AVD -= enhance.addAVD;
                spec.ADD_ATK -= enhance.addATKCNT;
                
                enhances.removeAtIndex(i);
            }
        }
    }
    
    func posUpdate(pos: CGPoint) {
        self.position = pos;
        self.position_base = pos;
        if let gauge = gaugeHP {
            gaugeHP.changePosition(CGPointMake(pos.x, pos.y - self.size.height*0.6));
        }
    }
    
    func zPosUpdate(z: CGFloat) {
        if let gauge = gaugeHP {
            gaugeHP.gauge.zPosition = z+2;
            gaugeHP.gauge_lo.zPosition = z+1;
        }
        self.zPosition = z;
    }
    
    func isDead() -> Bool {
        return (spec.HP <= 0) ? true : false;
    }
}
