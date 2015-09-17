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
    
    var HP_base: Int = 3000;
    var ATK_base: Int = 100;
    var DEF_base: Int = 50;
    var HIT_base: Int = 100;
    var AVD_base: Int = 20;
    
    var HP: Int = 3000;
    var ATK: Int = 100;
    var DEF: Int = 50;
    var HIT: Int = 100;
    var AVD: Int = 20;
    var ADD_ATK: Int = 0;
    
    func statusInit(
        #hp: Int,
        atk: Int,
        def: Int,
        hit: Int,
        avd: Int,
        add_atk: Int)
    {
        HP_base = hp;
        ATK_base = atk;
        DEF_base = def;
        HIT_base = hit;
        AVD_base = avd;
        
        HP = hp;
        ATK = atk;
        DEF = def;
        HIT = hit;
        AVD = avd;
        ADD_ATK = add_atk;
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
    func refleshStatus() {
        if let gauge = gaugeHP {
            gaugeHP.updateProgress(CGFloat(HP) / CGFloat(HP_base) * 100);
        }
        if let label = labelHP {
            labelHP.text = "HP:\(HP)";
            if HP < HP_base / 5 {
                labelHP.fontColor = UIColor.redColor();
            }
            else if HP < HP_base / 2 {
                labelHP.fontColor = UIColor.yellowColor();
            }
            else if HP < HP_base {
                labelHP.fontColor = UIColor.blueColor();
            }
            else {
                labelHP.fontColor = UIColor.whiteColor();
            }
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
        if let label = labelADDATK {
            labelADDATK.text = "ADDATK:\(ADD_ATK)";
            if ADD_ATK > 0 {
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
    }
    
    func procAction_atk(atk: [CharBtlAction.Atk], target: CharBase
        , counter: Bool = false, counter_content: CharBtlAction.Def = CharBtlAction.Def()) -> [Attacked]
    {
        var result: [Attacked] = [];
        for i in 0 ..< atk.count {
            var data = Attacked();
            data.content = atk[i];
            data.consumeDefenced = (target.defenceds.count > 0) ? true : false;
            data.counter = counter;
            if counter {
                // カウンターはミスなし
                data.damage = (calcATK() * Int(counter_content.defCounterAttack) / 100) - target.calcDEF(consumeDefenceds: true);
                if data.damage <= 0 {
                    data.damage = 1;
                }
            }
            else {
                data.damage = (calcATK() * Int(atk[i].atkPower) / 100) - target.calcDEF(consumeDefenceds: true);
                if data.damage <= 0 {
                    data.damage = 1;
                }
                
                // 命中計算
                var hit = HIT - target.AVD;
                hit = min(100, hit);
                hit = max(1, hit);
                let random = 1 + (arc4random() % 100);
                if random > UInt32(hit) {
                    // ミス
                    data.damage = 0;
                }
            }
            result.append(data);
        }
        // 加算攻撃回数
        for i in 0 ..< ADD_ATK {
            var data = Attacked();
            data.content = CharBtlAction.Atk();
            data.content.atkPower = 100.0;
            data.consumeDefenced = (target.defenceds.count > 0) ? true : false;
            data.counter = counter;
            data.damage = calcATK() - target.calcDEF(consumeDefenceds: true);
            if data.damage <= 0 {
                data.damage = 1;
            }
            
            // 命中計算
            var hit = HIT - target.AVD;
            hit = min(100, hit);
            hit = max(1, hit);
            let random = 1 + (arc4random() % 100);
            if random > UInt32(hit) {
                // ミス
                data.damage = 0;
            }
            result.append(data);
        }
        
        return result;
    }
    func addDamage(atk: [Attacked]) {
        for data in atk {
            HP = HP - data.damage;
            if HP < 0 {
                HP = 0;
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
    }
    var defenceds: [Defenced] = [];
    
    func procAction_def(def: [CharBtlAction.Def]) -> [Defenced] {
        var result: [Defenced] = [];
        for i in 0 ..< def.count {
            var data = Defenced();
            data.content = def[i];
            data.lastCount = def[i].defCount
            
            // 強さ取得
            let (power_TypeRatio: Int, power_TypeConst: Int) = calcPower(Int(def[i].defPower), seedType: def[i].seedType, char: self);
            data.addDef = power_TypeRatio;
            
            result.append(data);
        }
        return result;
    }
    func addDefenced(def: [Defenced]) {
        for data in def {
            defenceds.append(data);
        }
        
        // 以降、相手の攻撃を受けるタイミングで消費
        // ターンで消費しない
    }
    func allCancelDefenced() {
        defenceds = [];
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
    }
    var jammings: [Jamming] = [];
    
    func procAction_jam(jam: [CharBtlAction.Jam], target: CharBase) -> [Jamming] {
        var result: [Jamming] = [];
        for i in 0 ..< jam.count {
            var data = Jamming();
            // HPベース比率からの割合　防御力無視ダメージ
            data.damage = (target.HP_base * Int(jam[i].addDamage) / 100);
            if data.damage <= 0 {
                data.damage = 1;
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
            result.append(data);
        }
        return result;
    }
    func addJamming(jam: [Jamming]) {
        for data in jam {
            jammings.append(data);

            // ステータスに反映
            if data.content.execTiming == CharBtlAction.ExecTiming.jastNow {
                HP += data.addHP;
                ATK += data.addATK;
                DEF += data.addDEF;
                HIT += data.addHIT;
                AVD += data.addAVD;
                ADD_ATK += data.addATKCNT;
                
                HP = HP - data.damage;
                if HP < 0 {
                    HP = 0;
                }
            }
        }
    }
    func allCancelJammings() {
        for jam in jammings {
            
            // ステータスに反映
            HP -= jam.addHP;
            ATK -= jam.addATK;
            DEF -= jam.addDEF;
            HIT -= jam.addHIT;
            AVD -= jam.addAVD;
            ADD_ATK -= jam.addATKCNT;
        }
        jammings = [];
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
    
    func procAction_enh(enh: [CharBtlAction.Enh]) -> [Enhanced] {
        var result: [Enhanced] = [];
        for i in 0 ..< enh.count {
            var data = Enhanced();
            data.content = enh[i];
            data.lastTrun = enh[i].turn;
            
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
            result.append(data);
        }
        return result;
    }
    func addEnhanced(enh: [Enhanced]) {
        for data in enh {
            enhances.append(data);
            
            // ステータスに反映
            if data.content.execTiming == CharBtlAction.ExecTiming.jastNow {
                HP += data.addHP;
                ATK += data.addATK;
                DEF += data.addDEF;
                HIT += data.addHIT;
                AVD += data.addAVD;
                ADD_ATK += data.addATKCNT;
            }
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
            ADD_ATK -= enh.addATKCNT;
        }
        enhances = [];
    }
    
    struct Skilled {
        var type = CharBtlAction.ActType.non;
        var atk: [Attacked] = [];
        var def: [Defenced] = [];
        var jam: [Jamming] = [];
        var enh: [Enhanced] = [];
    }
    var skilleds: [Skilled] = [];
    
    func procAction_skl(skl: [CharBtlAction.Skl], target: CharBase)
        -> [Skilled]
    {
        var result: [Skilled] = [];
        for i in 0 ..< skl.count {
            var data = Skilled();
            data.type = skl[i].type;
            switch skl[i].type {
            case .atk:
                data.atk = procAction_atk(skl[i].atk, target: target);
            case .def:
                data.def = procAction_def(skl[i].def);
            case .jam:
                data.jam = procAction_jam(skl[i].jam, target: target);
            case .enh:
                data.enh = procAction_enh(skl[i].enh);
            default:
                break;
            }
            result.append(data);
        }
        return result;
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
            power_TypeRatio = (char.ATK * Int(power) / 100);
        case .atkBase:
            power_TypeRatio = (char.ATK_base * Int(power) / 100);
        case .defNow:
            power_TypeRatio = (char.DEF * Int(power) / 100);
        case .defBase:
            power_TypeRatio = (char.DEF_base * Int(power) / 100);
        case .lasthp:
            power_TypeRatio = (char.HP * Int(power) / 100);
        case .maxhp:
            power_TypeRatio = (char.HP_base * Int(power) / 100);
        case .subhp:
            power_TypeRatio = ((char.HP_base - char.HP) * Int(power) / 100);
        }
        return (power_TypeRatio, power_TypeConst);
    }
    
    func turnEnd() -> Bool {
        
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
                ADD_ATK -= jamming.addATKCNT;

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
                HP -= enhance.addHP;
                ATK -= enhance.addATK;
                DEF -= enhance.addDEF;
                HIT -= enhance.addHIT;
                AVD -= enhance.addAVD;
                ADD_ATK -= enhance.addATKCNT;
                
                enhances.removeAtIndex(i);
            }
        }
        
        return (HP <= 0) ? true : false;
    }
    
    func calcATK() -> Int {
        // エンハンス時にステータスの値変更したのでそのまま使う
        return ATK;
    }
    
    func calcDEF(consumeDefenceds: Bool = true) -> Int {
        // エンハンス時にステータスの値変更したのでそのまま使う
        var def = DEF;
        if consumeDefenceds {
            if defenceds.count > 0 {
                var defence = defenceds[defenceds.count-1];
                def += defence.addDef;
            }
        }
        return def;
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
}
