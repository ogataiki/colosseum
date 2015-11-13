import SpriteKit

class CharFat
{
    var data: CharBase;
    
    static func getName() -> String {
        return CharManager.CharNames.fat.rawValue;
    }
    static func getImageName() -> String {
        return "TestChar2";
    }
    static func getDisplayName() -> String {
        return "ファド";
    }
    
    init() {
        
        data = CharBase(imageNamed: CharFat.getImageName());
        data.displayName = CharFat.getDisplayName();
        data.name = CharFat.getName();
        data.gaugeInit(CGSizeMake(data.size.width, 5), direction: Gauge.Direction.horizontal, zPos: 0);
        
        // 防御特化型
        
        // ステータス設定
        data.statusInit(hp: 4000, atk: 200, def: 200, hit: 90, avd: 20, add_atk: 0);
        
        // ゲージ設定
        data.gaugeLangeth = 200.0;
        data.gaugeAcceleration = 30.0;
        
        // 行動設定
        
        // 行動0 : 行動なし(固定)
        let non = CharBase.Action();
        non.action.type = CharBtlAction.ActType.non;
        data.actions.append(non);
        
        
        // 行動1
        // 現在攻撃力の1.00倍の攻撃
        // コスト2
        var atk_1 = CharBtlAction.Atk();
        atk_1.atkPower = 100.0;
        var act_1 = CharBase.Action();
        act_1.action.type = CharBtlAction.ActType.atk;
        act_1.action.atk.append(atk_1);
        act_1.cost = act_1.action.atkCost;
        act_1.name = "攻撃";
        data.actions.append(act_1);
        
        
        // 行動2
        // 現在攻撃力の2倍で2回防御
        // 3倍でカウンター
        // コスト2
        var def_1 = CharBtlAction.Def();
        def_1.seedType = CharBtlAction.SeedType.atkNow;
        def_1.defPower = 3.0;
        def_1.defCount = 2;
        def_1.defCounterAttack = 300.0;
        var act_2 = CharBase.Action();
        act_2.action.type = CharBtlAction.ActType.def;
        act_2.action.def.append(def_1);
        act_2.cost = act_2.action.defCost;
        act_2.name = "プレッシャー";
        data.actions.append(act_2);
        
        
        // 行動3
        // 相手命中を10減少
        // 2ターン
        var jam_1 = CharBtlAction.Jam();
        jam_1.type = CharBtlAction.JamType.weakenHit;
        jam_1.seedType = CharBtlAction.SeedType.atkBase;
        jam_1.power = 10.0;
        jam_1.turn = 2;
        jam_1.addDamage = 6.0;
        var act_3 = CharBase.Action();
        act_3.action.type = CharBtlAction.ActType.jam;
        act_3.action.jam.append(jam_1);
        act_3.cost = act_3.action.jamCost;
        act_3.name = "油飛ばし";
        data.actions.append(act_3);
        
        
        // 行動4
        // 基本攻撃分の0.75倍の防御力が上がる
        // 2ターン
        var enh_1 = CharBtlAction.Enh();
        enh_1.type = CharBtlAction.EnhType.def;
        enh_1.seedType = CharBtlAction.SeedType.atkBase;
        enh_1.power = 75.0;
        enh_1.turn = 2;
        var act_4 = CharBase.Action();
        act_4.action.type = CharBtlAction.ActType.enh;
        act_4.action.enh.append(enh_1);
        act_4.cost = act_4.action.enhCost;
        act_4.name = "膨らむ";
        data.actions.append(act_4);
        
        
        // 特技
        // 防御種別で攻撃力2.0倍で1回攻撃
        var atk_3 = CharBtlAction.Atk();
        atk_3.atkPower = 200.0;
        var skl_1 = CharBtlAction.Skl();
        skl_1.type = CharBtlAction.ActType.atk;
        skl_1.atk.append(atk_3);
        
        var act_5 = CharBase.Action();
        act_5.type = CharBase.ActionType.skl;
        act_5.name = "押しつぶす";
        act_5.action.type = CharBtlAction.ActType.def;
        act_5.action.skl.append(skl_1);
        act_5.cost = act_5.action.sklCost;
        data.actions.append(act_5);
        
        
        
        data.speech_battlePre = [
            "どうせ俺はデブだよ！",
            "だから彼女もできない！"
        ];
        
        data.speech_battleStart = [
            "俺なんてどうせダメ",
            "だってデブだもん"
        ];
        
        data.speech_battleEnd_win = [
            "オレなんかに負けるとかwww",
            "カワイソウwwwフヒwww"
        ];
        
        data.speech_battleEnd_lose = [
            "当然だよね"
        ];
    }
}
