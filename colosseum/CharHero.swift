import SpriteKit

class CharHero
{
    var data: CharBase;
    
    static func getName() -> String {
        return CharManager.CharNames.hero.rawValue;
    }
    static func getImageName() -> String {
        return "TestChar1";
    }
    static func getDisplayName() -> String {
        return "主人公";
    }

    init() {
        
        data = CharBase(imageNamed: CharHero.getImageName());
        data.displayName = CharHero.getDisplayName();
        data.name = CharHero.getName();
        data.gaugeInit(CGSizeMake(data.size.width, 5), direction: Gauge.Direction.horizontal, zPos: 0);
        
        // バランス型
        // 全キャラクターの基準となる性能
        
        // ステータス設定
        data.statusInit(hp: 3000, atk: 200, def: 100, hit: 100, avd: 20, add_atk: 0);
        
        // ゲージ設定
        data.gaugeLangeth = 300.0;
        data.gaugeAcceleration = 30.0;

        // 行動設定
        
        // 行動0 : 行動なし(固定)
        let non = CharBase.Action();
        non.action.type = CharBtlAction.ActType.non;
        data.actions.append(non);
        
        
        // 行動1
        // 現在攻撃力の1倍で1回攻撃
        // コスト2
        var atk_1 = CharBtlAction.Atk();
        atk_1.atkPower = 100.0;
        var act_1 = CharBase.Action();
        act_1.action.type = CharBtlAction.ActType.atk;
        act_1.action.atk.append(atk_1);
        act_1.name = "攻撃";
        act_1.cost = act_1.action.atkCost;
        data.actions.append(act_1);
        
        
        // 行動2
        // 基本防御力の2倍で1回防御
        // 2倍でカウンター
        // コスト2
        var def_1 = CharBtlAction.Def();
        def_1.seedType = CharBtlAction.SeedType.defBase;
        def_1.defPower = 200.0;
        def_1.defCount = 1;
        def_1.defCounterAttack = 200.0;
        var act_2 = CharBase.Action();
        act_2.action.type = CharBtlAction.ActType.def;
        act_2.action.def.append(def_1);
        act_2.name = "防御";
        act_2.cost = act_2.action.defCost;
        data.actions.append(act_2);
        
        
        // 行動3
        // 5%相手命中を減少
        // 3ターン
        var jam_1 = CharBtlAction.Jam();
        jam_1.type = CharBtlAction.JamType.weakenHit;
        jam_1.seedType = CharBtlAction.SeedType.constant;
        jam_1.power = 5.0;
        jam_1.turn = 3;
        jam_1.addDamage = 10.0;
        var act_3 = CharBase.Action();
        act_3.action.type = CharBtlAction.ActType.jam;
        act_3.action.jam.append(jam_1);
        act_3.name = "妨害";
        act_3.cost = act_3.action.jamCost;
        data.actions.append(act_3);
        
        
        // 行動4
        // 現在攻撃力の1.0倍で攻撃力と防御力を強化
        // 2ターン
        var enh_1 = CharBtlAction.Enh();
        enh_1.type = CharBtlAction.EnhType.atk;
        enh_1.seedType = CharBtlAction.SeedType.atkNow;
        enh_1.power = 100.0;
        enh_1.turn = 2;
        var enh_2 = CharBtlAction.Enh();
        enh_2.type = CharBtlAction.EnhType.def;
        enh_2.seedType = CharBtlAction.SeedType.atkNow;
        enh_2.power = 100.0;
        enh_2.turn = 2;
        var act_4 = CharBase.Action();
        act_4.action.type = CharBtlAction.ActType.enh;
        act_4.action.enh.append(enh_1);
        act_4.action.enh.append(enh_2);
        act_4.name = "強化";
        act_4.cost = act_4.action.enhCost;
        data.actions.append(act_4);
        
        
        // 特技
        // 基本攻撃力の2.0倍で攻撃力を強化
        // 3ターン
        var enh_3 = CharBtlAction.Enh();
        enh_3.type = CharBtlAction.EnhType.atk;
        enh_3.seedType = CharBtlAction.SeedType.atkBase;
        enh_3.power = 200.0;
        enh_3.turn = 3;
        var skl_1 = CharBtlAction.Skl();
        skl_1.type = CharBtlAction.ActType.enh;
        skl_1.enh.append(enh_3);
        // 現在攻撃力の0.5倍で4回攻撃
        var atk_2 = CharBtlAction.Atk();
        atk_2.atkPower = 50.0;
        var skl_2 = CharBtlAction.Skl();
        skl_2.type = CharBtlAction.ActType.atk;
        skl_2.atk.append(atk_2);
        skl_2.atk.append(atk_2);
        skl_2.atk.append(atk_2);
        skl_2.atk.append(atk_2);
        
        var act_5 = CharBase.Action();
        act_5.type = CharBase.ActionType.skl;
        act_5.action.type = CharBtlAction.ActType.enh;
        act_5.action.skl.append(skl_1);
        act_5.action.skl.append(skl_2);
        act_5.name = "強化&ラッシュ";
        act_5.cost = act_5.action.sklCost;
        data.actions.append(act_5);
        
        
        data.speech_battlePre = [];
        
        data.speech_battleStart = [];
        
        data.speech_battleEnd_win = [];

        data.speech_battleEnd_lose = [];

    }
}
