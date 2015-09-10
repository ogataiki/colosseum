import SpriteKit

class CharacterHardbodyFemale
{
    var data: Character;
    
    init() {
        
        data = Character(imageNamed: "TestChar2");
        data.name = "HardbodyFemale";
        data.gaugeInit(CGSizeMake(data.size.width, 5), direction: Gauge.Direction.horizontal, zPos: 0);
        
        // 攻撃特化型
        
        // ステータス設定
        data.statusInit(hp: 3000, atk: 300, def: 50, hit: 90, avd: 20, add_atk: 0);
        
        // 行動設定
        
        // 行動0 : 行動なし(固定)
        var non = Character.Action();
        non.action.type = CharBtlAction.ActType.non;
        data.actions.append(non);
        
        
        // 行動1
        // 現在攻撃力の1.0倍と0.5倍で2回攻撃
        // コスト2
        var atk_1 = CharBtlAction.Atk();
        atk_1.atkPower = 100.0;
        var atk_2 = CharBtlAction.Atk();
        atk_2.atkPower = 50.0;
        var act_1 = Character.Action();
        act_1.action.type = CharBtlAction.ActType.atk;
        act_1.action.atkEnable = true;
        act_1.action.atk.append(atk_1);
        act_1.action.atk.append(atk_2);
        act_1.cost = act_1.action.atkCost;
        act_1.name = "強連撃";
        data.actions.append(act_1);
        
        
        // 行動2
        // 現在攻撃力の0.2倍で1回防御
        // 3倍でカウンター
        // コスト2
        var def_1 = CharBtlAction.Def();
        def_1.seedType = CharBtlAction.SeedType.atkNow;
        def_1.defPower = 0.3;
        def_1.defCount = 1;
        def_1.defCounterAttack = 300.0;
        var act_2 = Character.Action();
        act_2.action.type = CharBtlAction.ActType.def;
        act_2.action.defEnable = true;
        act_2.action.def = def_1;
        act_2.cost = act_2.action.defCost;
        act_2.name = "反撃の構え";
        data.actions.append(act_2);
        
        
        // 行動3
        // 基本攻撃力の0.5倍で相手攻撃力を減少
        // 2ターン
        var jam_1 = CharBtlAction.Jam();
        jam_1.type = CharBtlAction.JamType.weakenAtk;
        jam_1.seedType = CharBtlAction.SeedType.atkBase;
        jam_1.power = 50.0;
        jam_1.turn = 3;
        jam_1.addDamage = 5.0;
        var act_3 = Character.Action();
        act_3.action.type = CharBtlAction.ActType.jam;
        act_3.action.jamEnable = true;
        act_3.action.jam.append(jam_1);
        act_3.cost = act_3.action.jamCost;
        act_3.name = "武器破壊";
        data.actions.append(act_3);
        
        
        // 行動4
        // 攻撃回数1増加
        // 2ターン
        var enh_1 = CharBtlAction.Enh();
        enh_1.type = CharBtlAction.EnhType.atkcnt;
        enh_1.power = 1.0;
        enh_1.turn = 2;
        var act_4 = Character.Action();
        act_4.action.type = CharBtlAction.ActType.enh;
        act_4.action.enhEnable = true;
        act_4.action.enh.append(enh_1);
        act_4.cost = act_4.action.enhCost;
        act_4.name = "加速";
        data.actions.append(act_4);
        
        
        // 特技
        // 現在攻撃力の5.0倍で1回攻撃
        var atk_3 = CharBtlAction.Atk();
        atk_3.atkPower = 500.0;
        
        var act_5 = Character.Action();
        act_5.name = "全力強撃";
        act_5.action.type = CharBtlAction.ActType.atk;
        act_5.action.atkEnable = true;
        act_5.action.atk.append(atk_3);
        act_5.cost = 4;
        data.actions.append(act_5);
    }
}
