import SpriteKit

// チュートリアルなどで使う雑魚キャラクター
class CharMob
{
    var data: CharBase;
    static func getName() -> String {
        return CharManager.CharNames.mob.rawValue;
    }
    static func getImageName() -> String {
        return "MobChar";
    }
    static func getDisplayName() -> String {
        return "チンピラ";
    }
    init() {
        
        data = CharBase(imageNamed: CharMob.getImageName());
        data.displayName = CharMob.getDisplayName();
        data.name = CharMob.getName();
        data.gaugeInit(CGSizeMake(data.size.width, 5), direction: Gauge.Direction.horizontal, zPos: 0);
        
        // どうしようもない雑魚
        
        // ステータス設定
        data.statusInit(hp: 1000, atk: 100, def: 50, hit: 100, avd: 0, add_atk: 0);
        
        // ゲージ設定
        data.gaugeLangeth = 100.0;
        data.gaugeAcceleration = 50.0;
        
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
        act_1.name = "カラむ";
        act_1.cost = act_1.action.atkCost;
        data.actions.append(act_1);
        
        
        // 行動2
        // 基本防御力の1倍で1回防御
        // 0.5倍でカウンター
        // コスト2
        var def_1 = CharBtlAction.Def();
        def_1.seedType = CharBtlAction.SeedType.defBase;
        def_1.defPower = 100.0;
        def_1.defCount = 1;
        def_1.defCounterAttack = 50.0;
        var act_2 = CharBase.Action();
        act_2.action.type = CharBtlAction.ActType.def;
        act_2.action.def.append(def_1);
        act_2.name = "ビビる";
        act_2.cost = act_2.action.defCost;
        data.actions.append(act_2);
        
        
        // 行動3
        // 1%相手命中を減少
        // 3ターン
        var jam_1 = CharBtlAction.Jam();
        jam_1.type = CharBtlAction.JamType.weakenHit;
        jam_1.seedType = CharBtlAction.SeedType.constant;
        jam_1.power = 1.0;
        jam_1.turn = 2;
        jam_1.addDamage = 15.0;
        var act_3 = CharBase.Action();
        act_3.action.type = CharBtlAction.ActType.jam;
        act_3.action.jam.append(jam_1);
        act_3.name = "ガンたれ";
        act_3.cost = act_3.action.jamCost;
        data.actions.append(act_3);
        
        
        // 行動4
        // 現在攻撃力の1.0倍で攻撃力を強化
        // 2ターン
        var enh_1 = CharBtlAction.Enh();
        enh_1.type = CharBtlAction.EnhType.atk;
        enh_1.seedType = CharBtlAction.SeedType.atkNow;
        enh_1.power = 100.0;
        enh_1.turn = 2;
        var act_4 = CharBase.Action();
        act_4.action.type = CharBtlAction.ActType.enh;
        act_4.action.enh.append(enh_1);
        act_4.name = "筋トレ";
        act_4.cost = act_4.action.enhCost;
        data.actions.append(act_4);
        
        
        // 特技
        // 基本攻撃力の0.1倍で4回攻撃ダウン
        var jam_2 = CharBtlAction.Jam();
        jam_2.type = CharBtlAction.JamType.weakenDef;
        jam_2.seedType = CharBtlAction.SeedType.atkBase;
        jam_2.power = 0.1;
        jam_2.addDamage = 0.1;
        var skl_1 = CharBtlAction.Skl();
        skl_1.type = CharBtlAction.ActType.atk;
        skl_1.jam.append(jam_2);
        skl_1.jam.append(jam_2);
        skl_1.jam.append(jam_2);
        skl_1.jam.append(jam_2);
        
        var act_5 = CharBase.Action();
        act_5.type = CharBase.ActionType.skl;
        act_5.action.type = CharBtlAction.ActType.jam;
        act_5.action.skl.append(skl_1);
        act_5.name = "ツルむ＆ディスる";
        act_5.cost = act_5.action.sklCost;
        data.actions.append(act_5);
        
        
        data.speech_battlePre = [];
        
        data.speech_battleStart = [
            "新人？ウヒョー！カモだぜ！",
            "集中フェーズでは",
            "集中してゲージのてっぺんで止める！",
            "そんなことも知らねぇんだろwww",
            "いただきまーす！www"
        ];
        
        data.speech_battleTactical = [
            CharBase.BattleSpeech_tactical(speech: []),
            CharBase.BattleSpeech_tactical(speech: [
                "戦略フェーズでは",
                "集中フェーズで貯めた集中力を使って",
                "行動を選択する！",
                "そんなことも知らねぇんだろwww",
                "マジお前かわいそうウケるwww"
                ]),
            CharBase.BattleSpeech_tactical(speech: [
                "相手より有利な行動なら",
                "相手の行動はキャンセルされる！",
                "そんなことも知らねぇんだろwww",
                "マジ、サンドバック乙www"
                ])
        ];
                
        data.speech_battleEnd_win = [
            "ザッコwwwマジwww"
        ];

        data.speech_battleEnd_lose = [
            "オメー覚えとけよ"
        ];

    }
}
