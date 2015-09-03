import SpriteKit

class GameScene: SKScene {
    
    enum SceneStatus: Int {
        case stock = 1
        case tactical = 2
        case melee = 3
    }
    var scene_status = SceneStatus.stock;
    
    var gauge: Gauge!;
    var reach_base: CGFloat = 200;
    var reach_frame: CGFloat = 200;
    var rise_speed_base: CGFloat = 0.5;
    var rise_speed_add: CGFloat = 0.5;
    var rise_speed: CGFloat = 0.5;
    var rise_frame: CGFloat = 0;
    var rise_frame_last: CGFloat = 0;
    var rise_reset_flg: Bool = false;
    
    var rise_bar: SKSpriteNode!;
    
    var attack_list: [CGFloat] = [];
    var attack_count_lbl: SKLabelNode!;
    
    struct MeleeData {
        var player_action = CharBtlAction.ActType.non;
        var enemy_action = CharBtlAction.ActType.non;
    }
    var meleeBuffer: [MeleeData] = [];
    var meleeProgress: Int = 0;
    var meleeNextFlg: [Bool] = [false, false];
    
    var player_char: Character!;
    var enemy_char: Character!;
    var char_list: [String : Character] = [:];
    
    //------
    // UI系
    var ui_playerLastStock: SKLabelNode!;
    var ui_tacticalCommandLbl: SKLabelNode!;
    var ui_tacticalAtk: UIButton!;
    var ui_tacticalDef: UIButton!;
    var ui_tacticalEnh: UIButton!;
    var ui_tacticalJam: UIButton!;
    var ui_tacticalEnter: UIButton!;
    var ui_tacticalReset: UIButton!;
    var tc_lastStock: Int = 0;
    var tc_list: [CharBtlAction.ActType] = [];
    
    enum ZCtrl: CGFloat {
        case gauge_rise_bar = 101
        case gauge = 100
        case gauge_lo = 99
        case damage_label = 10
    }
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        // これしないと孫要素の表示順がおかしくなる
        view.ignoresSiblingOrder = false;

        playerInit();
        
        enemyInit();
        
        // debug
        player_char.gaugeLangeth = 300;
        player_char.gaugeAcceleration = 30;
        
        gaugeInit();
    }
    
    func gaugeInit() {
        gauge = Gauge(color: UIColor.grayColor(), size: CGSizeMake(30, player_char.gaugeLangeth));
        gauge.initGauge(color: UIColor.greenColor(), direction: Gauge.Direction.vertical, zPos:ZCtrl.gauge.rawValue);
        gauge.initGauge_lo(color: UIColor.redColor(), zPos:ZCtrl.gauge_lo.rawValue);
        gauge.resetProgress(0.0);
        gauge.changeAnchorPoint(CGPointMake(0.5, 0.5));
        gauge.changePosition(self.view!.center);
        gauge.updateProgress(100);
        self.addChild(gauge);
        
        rise_bar = SKSpriteNode(color: UIColor.blackColor(), size: CGSizeMake(36, 5));
        rise_bar.position = CGPointMake(gauge.position.x, gauge.position.y - gauge.size.height*0.5);
        rise_bar.zPosition = ZCtrl.gauge_rise_bar.rawValue;
        rise_bar.alpha = 0.5;
        self.addChild(rise_bar);
        
        attack_count_lbl = SKLabelNode(text: "0");
        attack_count_lbl.position = CGPointMake(gauge.position.x, gauge.position.y - gauge.size.height*0.65);
        self.addChild(attack_count_lbl);
    }
    func gaugeRemove() {
        if let ui = gauge {
            ui.removeFromParent();
        }
        if let ui = rise_bar {
            ui.removeFromParent();
        }
        if let ui = attack_count_lbl {
            ui.removeFromParent();
        }
    }
    
    func tacticalUIInit() {
        
        ui_playerLastStock = SKLabelNode(text: "lastStock:\(attack_list.count)");
        ui_playerLastStock.position = CGPointMake(self.size.width*0.5, self.size.height*0.85);
        ui_playerLastStock.fontSize = 16;
        self.addChild(ui_playerLastStock);
        
        ui_tacticalCommandLbl = SKLabelNode(text: "");
        ui_tacticalCommandLbl.position = CGPointMake(self.size.width*0.5, self.size.height*0.75);
        ui_tacticalCommandLbl.fontSize = 16;
        self.addChild(ui_tacticalCommandLbl);
        
        // UI系のy座標は上下逆
        
        ui_tacticalAtk = UIButton(frame: CGRectMake(0,0, self.view!.frame.size.width*0.3, self.view!.frame.size.height*0.1));
        ui_tacticalAtk.layer.position = CGPointMake(self.size.width*0.25, self.size.height*0.4);
        ui_tacticalAtk.backgroundColor = UIColor.brownColor();
        ui_tacticalAtk.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping;
        let actionAtk = player_char.actions[CharBtlAction.ActType.atk.rawValue];
        let titleAtk = "\(actionAtk.name) \ncost:\(actionAtk.cost)"
        ui_tacticalAtk.setTitle(titleAtk, forState: UIControlState.Normal)
        ui_tacticalAtk.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        ui_tacticalAtk.setTitle(titleAtk, forState: UIControlState.Highlighted)
        ui_tacticalAtk.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        ui_tacticalAtk.addTarget(self, action: "tacticalAtk", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(ui_tacticalAtk);
        
        ui_tacticalDef = UIButton(frame: CGRectMake(0,0, ui_tacticalAtk.frame.size.width, ui_tacticalAtk.frame.size.height));
        ui_tacticalDef.layer.position = CGPointMake(self.size.width*0.75, self.size.height*0.4);
        ui_tacticalDef.backgroundColor = UIColor.brownColor();
        ui_tacticalDef.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping;
        let actionDef = player_char.actions[CharBtlAction.ActType.def.rawValue];
        let titleDef = "\(actionDef.name) \ncost:\(actionDef.cost)"
        ui_tacticalDef.setTitle(titleDef, forState: UIControlState.Normal)
        ui_tacticalDef.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        ui_tacticalDef.setTitle(titleDef, forState: UIControlState.Highlighted)
        ui_tacticalDef.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        ui_tacticalDef.addTarget(self, action: "tacticalDef", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(ui_tacticalDef);
        
        ui_tacticalEnh = UIButton(frame: CGRectMake(0,0, ui_tacticalAtk.frame.size.width, ui_tacticalAtk.frame.size.height));
        ui_tacticalEnh.layer.position = CGPointMake(self.size.width*0.25, self.size.height*0.55);
        ui_tacticalEnh.backgroundColor = UIColor.brownColor();
        ui_tacticalEnh.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping;
        let actionEnh = player_char.actions[CharBtlAction.ActType.enh.rawValue];
        let titleEnh = "\(actionEnh.name) \ncost:\(actionEnh.cost)"
        ui_tacticalEnh.setTitle(titleEnh, forState: UIControlState.Normal)
        ui_tacticalEnh.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        ui_tacticalEnh.setTitle(titleEnh, forState: UIControlState.Highlighted)
        ui_tacticalEnh.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        ui_tacticalEnh.addTarget(self, action: "tacticalEnh", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(ui_tacticalEnh);
        
        ui_tacticalJam = UIButton(frame: CGRectMake(0,0, ui_tacticalAtk.frame.size.width, ui_tacticalAtk.frame.size.height));
        ui_tacticalJam.layer.position = CGPointMake(self.size.width*0.75, self.size.height*0.55);
        ui_tacticalJam.backgroundColor = UIColor.brownColor();
        ui_tacticalJam.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping;
        let actionJam = player_char.actions[CharBtlAction.ActType.jam.rawValue];
        let titleJam = "\(actionJam.name) \ncost:\(actionJam.cost)"
        ui_tacticalJam.setTitle(titleJam, forState: UIControlState.Normal)
        ui_tacticalJam.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        ui_tacticalJam.setTitle(titleJam, forState: UIControlState.Highlighted)
        ui_tacticalJam.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        ui_tacticalJam.addTarget(self, action: "tacticalJam", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(ui_tacticalJam);
        
        ui_tacticalEnter = UIButton(frame: CGRectMake(0,0, self.view!.frame.size.width*0.4, self.view!.frame.size.height*0.1));
        ui_tacticalEnter.layer.position = CGPointMake(self.size.width*0.25, self.size.height*0.7);
        ui_tacticalEnter.backgroundColor = UIColor.greenColor();
        ui_tacticalEnter.setTitle("enter", forState: UIControlState.Normal)
        ui_tacticalEnter.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        ui_tacticalEnter.setTitle("enter", forState: UIControlState.Highlighted)
        ui_tacticalEnter.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        ui_tacticalEnter.addTarget(self, action: "tacticalEnter", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(ui_tacticalEnter);
        
        ui_tacticalReset = UIButton(frame: CGRectMake(0,0, self.view!.frame.size.width*0.4, self.view!.frame.size.height*0.1));
        ui_tacticalReset.layer.position = CGPointMake(self.size.width*0.75, self.size.height*0.7);
        ui_tacticalReset.backgroundColor = UIColor.orangeColor();
        ui_tacticalReset.setTitle("reset", forState: UIControlState.Normal)
        ui_tacticalReset.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        ui_tacticalReset.setTitle("reset", forState: UIControlState.Highlighted)
        ui_tacticalReset.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        ui_tacticalReset.addTarget(self, action: "tacticalReset", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(ui_tacticalReset);
    }
    func tacticalUIRemove() {
        if let ui = ui_playerLastStock {
            ui.removeFromParent();
        }
        if let ui = ui_tacticalCommandLbl {
            ui.removeFromParent();
        }
        if let ui = ui_tacticalAtk {
            ui.removeFromSuperview();
        }
        if let ui = ui_tacticalDef {
            ui.removeFromSuperview();
        }
        if let ui = ui_tacticalEnh {
            ui.removeFromSuperview();
        }
        if let ui = ui_tacticalJam {
            ui.removeFromSuperview();
        }
        if let ui = ui_tacticalEnter {
            ui.removeFromSuperview();
        }
        if let ui = ui_tacticalReset {
            ui.removeFromSuperview();
        }
    }
    
    func playerInit() {
        player_char = Character(imageNamed: "TestChar1");
        player_char.position = CGPointMake(self.size.width*0.85, self.size.height*0.9);
        player_char.position_base = player_char.position;
        player_char.xScale = -1.0;
        player_char.name = "player";
        self.addChild(player_char);
        char_list[player_char.name!] = player_char;
        
        player_char.gaugeHP = Gauge(color: UIColor.grayColor(), size: CGSizeMake(player_char.size.width, 5));
        player_char.gaugeHP.initGauge(color: UIColor.greenColor(), direction: Gauge.Direction.horizontal, zPos:ZCtrl.gauge.rawValue);
        player_char.gaugeHP.initGauge_lo(color: UIColor.redColor(), zPos:ZCtrl.gauge_lo.rawValue);
        player_char.gaugeHP.resetProgress(0.0);
        player_char.gaugeHP.changeAnchorPoint(CGPointMake(0.5, 0.5));
        player_char.gaugeHP.changePosition(CGPointMake(player_char.position.x, player_char.position.y - player_char.size.height*0.6));
        player_char.gaugeHP.updateProgress(100);
        self.addChild(player_char.gaugeHP);

        
        player_char.labelHP = SKLabelNode(text: "HP:\(player_char.HP)");
        player_char.labelATK = SKLabelNode(text: "ATK:\(player_char.ATK)");
        player_char.labelDEF = SKLabelNode(text: "DEF:\(player_char.DEF)");
        player_char.labelHIT = SKLabelNode(text: "HIT:\(player_char.HIT)");
        player_char.labelAVD = SKLabelNode(text: "ADV:\(player_char.AVD)");
        
        player_char.labelHP.position = CGPointMake(player_char.position.x, player_char.position.y - player_char.size.height*0.8);
        player_char.labelATK.position = CGPointMake(player_char.position.x, player_char.position.y - player_char.size.height*1.0);
        player_char.labelDEF.position = CGPointMake(player_char.position.x, player_char.position.y - player_char.size.height*1.2);
        player_char.labelHIT.position = CGPointMake(player_char.position.x, player_char.position.y - player_char.size.height*1.4);
        player_char.labelAVD.position = CGPointMake(player_char.position.x, player_char.position.y - player_char.size.height*1.6);
        
        player_char.labelHP.fontSize = 12;
        player_char.labelATK.fontSize = 12;
        player_char.labelDEF.fontSize = 12;
        player_char.labelHIT.fontSize = 12;
        player_char.labelAVD.fontSize = 12;
        
        self.addChild(player_char.labelHP);
        self.addChild(player_char.labelATK);
        self.addChild(player_char.labelDEF);
        self.addChild(player_char.labelHIT);
        self.addChild(player_char.labelAVD);
        

        var non = Character.Action();
        non.action.type = CharBtlAction.ActType.non;
        player_char.actions.append(non);

        var act_1 = Character.Action();
        act_1.name = "攻撃";
        act_1.action.type = CharBtlAction.ActType.atk;
        act_1.action.atkEnable = true;
        var atk_1 = CharBtlAction.Atk();
        atk_1.atkPower = 2.0;
        atk_1.atkCount = 2;
        act_1.action.atk.append(atk_1);
        act_1.cost = atk_1.atkCount;
        player_char.actions.append(act_1);

        var act_2 = Character.Action();
        act_2.name = "防御";
        act_2.action.type = CharBtlAction.ActType.def;
        act_2.action.defEnable = true;
        act_2.action.def.defPower = 30.0;
        act_2.cost = act_2.action.defCost;
        player_char.actions.append(act_2);

        var act_3 = Character.Action();
        act_3.name = "強化";
        act_3.action.type = CharBtlAction.ActType.enh;
        act_3.action.enhEnable = true;
        var enh_1 = CharBtlAction.Enh();
        enh_1.type = CharBtlAction.EnhType.atk;
        enh_1.seedType = CharBtlAction.SeedType.atkNow;
        enh_1.power = 30.0;
        act_3.action.enh.append(enh_1);
        act_3.cost = act_3.action.enhCost;
        player_char.actions.append(act_3);

        var act_4 = Character.Action();
        act_4.name = "妨害";
        act_4.action.type = CharBtlAction.ActType.jam;
        act_4.action.jamEnable = true;
        var jam_1 = CharBtlAction.Jam();
        jam_1.type = CharBtlAction.JamType.weakenDef;
        jam_1.seedType = CharBtlAction.SeedType.atkNow;
        jam_1.power = 50.0;
        jam_1.turn = 3;
        act_4.action.jam.append(jam_1);
        act_4.cost = act_4.action.jamCost;
        player_char.actions.append(act_4);

        var act_5 = Character.Action();
        act_5.name = "特技";
        act_5.action.type = CharBtlAction.ActType.atk;
        act_5.action.atkEnable = true;
        var atk_5 = CharBtlAction.Atk();
        atk_5.atkPower = 50.0;
        atk_5.atkCount = 4;
        act_5.action.atk.append(atk_5);
        act_5.action.jamEnable = true;
        var jam_5 = CharBtlAction.Jam();
        jam_5.type = CharBtlAction.JamType.paralysis;
        jam_5.seedType = CharBtlAction.SeedType.atkBase;
        jam_5.power = 50.0;
        jam_5.turn = 2;
        act_5.action.jam.append(jam_5);
        act_5.cost = act_5.action.atkCost + act_5.action.jamCost - 1;
        player_char.actions.append(act_5);
        
        // ゲージの長さをプレイヤーキャラ依存に
        reach_base = player_char.gaugeLangeth;
    }
    
    func enemyInit() {
        enemy_char = Character(imageNamed: "TestChar2");
        enemy_char.position = CGPointMake(self.size.width*0.15, self.size.height*0.9);
        enemy_char.position_base = enemy_char.position;
        enemy_char.name = "enemy";
        self.addChild(enemy_char);
        char_list[enemy_char.name!] = enemy_char;
        
        enemy_char.gaugeHP = Gauge(color: UIColor.grayColor(), size: CGSizeMake(enemy_char.size.width, 5));
        enemy_char.gaugeHP.initGauge(color: UIColor.greenColor(), direction: Gauge.Direction.horizontal, zPos:ZCtrl.gauge.rawValue);
        enemy_char.gaugeHP.initGauge_lo(color: UIColor.redColor(), zPos:ZCtrl.gauge_lo.rawValue);
        enemy_char.gaugeHP.resetProgress(0.0);
        enemy_char.gaugeHP.changeAnchorPoint(CGPointMake(0.5, 0.5));
        enemy_char.gaugeHP.changePosition(CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*0.6));
        enemy_char.gaugeHP.updateProgress(100);
        self.addChild(enemy_char.gaugeHP);
        
        
        enemy_char.labelHP = SKLabelNode(text: "HP:\(enemy_char.HP)");
        enemy_char.labelATK = SKLabelNode(text: "ATK:\(enemy_char.ATK)");
        enemy_char.labelDEF = SKLabelNode(text: "DEF:\(enemy_char.DEF)");
        enemy_char.labelHIT = SKLabelNode(text: "HIT:\(enemy_char.HIT)");
        enemy_char.labelAVD = SKLabelNode(text: "ADV:\(enemy_char.AVD)");
        
        enemy_char.labelHP.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*1.0);
        enemy_char.labelATK.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*1.3);
        enemy_char.labelDEF.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*1.6);
        enemy_char.labelHIT.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*1.9);
        enemy_char.labelAVD.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*2.2);
        
        enemy_char.labelHP.fontSize = 12;
        enemy_char.labelATK.fontSize = 12;
        enemy_char.labelDEF.fontSize = 12;
        enemy_char.labelHIT.fontSize = 12;
        enemy_char.labelAVD.fontSize = 12;
        
        self.addChild(enemy_char.labelHP);
        self.addChild(enemy_char.labelATK);
        self.addChild(enemy_char.labelDEF);
        self.addChild(enemy_char.labelHIT);
        self.addChild(enemy_char.labelAVD);
        

        var non = Character.Action();
        non.action.type = CharBtlAction.ActType.non;
        enemy_char.actions.append(non);

        var act_1 = Character.Action();
        act_1.name = "攻撃";
        act_1.action.type = CharBtlAction.ActType.atk;
        act_1.action.atkEnable = true;
        var atk_1 = CharBtlAction.Atk();
        atk_1.atkPower = 2.0;
        atk_1.atkCount = 2;
        act_1.action.atk.append(atk_1);
        act_1.cost = atk_1.atkCount;
        enemy_char.actions.append(act_1);
        
        var act_2 = Character.Action();
        act_2.name = "防御";
        act_2.action.type = CharBtlAction.ActType.def;
        act_2.action.defEnable = true;
        act_2.action.def.defPower = 30.0;
        act_2.cost = act_2.action.defCost;
        enemy_char.actions.append(act_2);
        
        var act_3 = Character.Action();
        act_3.name = "強化";
        act_3.action.type = CharBtlAction.ActType.enh;
        act_3.action.enhEnable = true;
        var enh_1 = CharBtlAction.Enh();
        enh_1.type = CharBtlAction.EnhType.def;
        enh_1.seedType = CharBtlAction.SeedType.atkNow;
        enh_1.power = 100.0;
        act_3.action.enh.append(enh_1);
        act_3.cost = act_3.action.enhCost;
        enemy_char.actions.append(act_3);
        
        var act_4 = Character.Action();
        act_4.name = "妨害";
        act_4.action.type = CharBtlAction.ActType.jam;
        act_4.action.jamEnable = true;
        var jam_1 = CharBtlAction.Jam();
        jam_1.type = CharBtlAction.JamType.weakenAtk;
        jam_1.seedType = CharBtlAction.SeedType.atkNow;
        jam_1.power = 50.0;
        jam_1.turn = 3;
        act_4.action.jam.append(jam_1);
        act_4.cost = act_4.action.jamCost;
        enemy_char.actions.append(act_4);
        
        var act_5 = Character.Action();
        act_5.name = "特技";
        act_5.action.type = CharBtlAction.ActType.atk;
        act_5.action.atkEnable = true;
        var atk_5 = CharBtlAction.Atk();
        atk_5.atkPower = 50.0;
        atk_5.atkCount = 4;
        act_5.action.atk.append(atk_5);
        act_5.action.jamEnable = true;
        var jam_5 = CharBtlAction.Jam();
        jam_5.type = CharBtlAction.JamType.paralysis;
        jam_5.seedType = CharBtlAction.SeedType.atkBase;
        jam_5.power = 50.0;
        jam_5.turn = 2;
        act_5.action.jam.append(jam_5);
        act_5.cost = act_5.action.atkCost + act_5.action.jamCost - 1;
        enemy_char.actions.append(act_5);
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch in (touches as! Set<UITouch>) {
            let location = touch.locationInNode(self)

            switch(scene_status) {
                
            case SceneStatus.stock:
                
                println(rise_frame);
                
                if reach_frame < rise_frame {
                    
                    tacticalStart();
                }
                else {
                    reach_frame = rise_frame;
                    rise_speed += rise_speed_add;
                    gauge.updateProgress((rise_frame / reach_base) * 100);
                    
                    attack_list.append(rise_frame);
                }
                
                attack_count_lbl.text = "\(attack_list.count)"
                
                rise_frame = 0;
                
            case SceneStatus.tactical:
                // 各UIのハンドラに任せる
                break;
                
            case SceneStatus.melee:
                
                //meleeEnd();
                break;
            }

        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        switch(scene_status) {
        case SceneStatus.stock:
            updateStock();
        case SceneStatus.tactical:
            updateTactical();
        case SceneStatus.melee:
            updateMelee();
        }
    }
    
    func updateStock() {
        
        if rise_reset_flg {
            rise_frame = 0;
            rise_reset_flg = false;
        }
        else {
            var speed = rise_speed + (rise_frame / player_char.gaugeAcceleration);
            rise_frame += speed;
            
            if rise_frame > reach_base {
                rise_frame = reach_base;
                rise_reset_flg = true;
            }
        }
        
        var bar_pos = gauge.position.y - gauge.size.height*0.5;
        bar_pos += gauge.size.height * (rise_frame / reach_base);
        rise_bar.position = CGPointMake(gauge.position.x, bar_pos);
    }
    
    func updateTactical() {
        // 処理は各UIのハンドラに任せる
        tacticalCommandLabelUpdate();
    }
    
    func updateMelee() {
        
        if meleeNextFlg[0] && meleeNextFlg[1] {
            
            meleeProgress++;
            meleeMain();
        }
    }
    
    func tacticalStart() {
        
        scene_status = SceneStatus.tactical;

        // ui入れ替え
        gaugeRemove();
        tacticalUIInit();
        
        tc_list = [];
        tc_lastStock = attack_list.count;
        ui_playerLastStock.text = "lastStock:\(tc_lastStock)";
    }
    func tacticalAtk() {
        let cost = player_char.actions[CharBtlAction.ActType.atk.rawValue].action.atkCost;
        if tc_lastStock >= cost {
            tc_list.append(CharBtlAction.ActType.atk);
            tc_lastStock = tc_lastStock - cost;
            ui_playerLastStock.text = "lastStock:\(tc_lastStock)";
            tacticalStockExpendEffect(cost, pos: ui_playerLastStock.position, size: ui_playerLastStock.frame.size);
            tacticalStockExpendEffect_ui(cost, frame: ui_tacticalAtk.frame);
        }
    }
    func tacticalDef() {
        let cost = player_char.actions[CharBtlAction.ActType.def.rawValue].action.defCost;
        if tc_lastStock >= cost {
            tc_list.append(CharBtlAction.ActType.def);
            tc_lastStock = tc_lastStock - cost;
            ui_playerLastStock.text = "lastStock:\(tc_lastStock)";
            tacticalStockExpendEffect(cost, pos: ui_playerLastStock.position, size: ui_playerLastStock.frame.size);
            tacticalStockExpendEffect_ui(cost, frame: ui_tacticalDef.frame);
        }
    }
    func tacticalEnh() {
        let cost = player_char.actions[CharBtlAction.ActType.enh.rawValue].action.enhCost;
        if tc_lastStock >= cost {
            tc_list.append(CharBtlAction.ActType.enh);
            tc_lastStock = tc_lastStock - cost;
            ui_playerLastStock.text = "lastStock:\(tc_lastStock)";
            tacticalStockExpendEffect(cost, pos: ui_playerLastStock.position, size: ui_playerLastStock.frame.size);
            tacticalStockExpendEffect_ui(cost, frame: ui_tacticalEnh.frame);
        }
    }
    func tacticalJam() {
        let cost = player_char.actions[CharBtlAction.ActType.jam.rawValue].action.jamCost;
        if tc_lastStock >= cost {
            tc_list.append(CharBtlAction.ActType.jam);
            tc_lastStock = tc_lastStock - cost;
            ui_playerLastStock.text = "lastStock:\(tc_lastStock)";
            tacticalStockExpendEffect(cost, pos: ui_playerLastStock.position, size: ui_playerLastStock.frame.size);
            tacticalStockExpendEffect_ui(cost, frame: ui_tacticalJam.frame);
        }
    }
    func tacticalEnter() {
        tacticalUIRemove();
        
        meleeStart();
    }
    func tacticalReset() {
        tc_lastStock = attack_list.count;
        ui_playerLastStock.text = "lastStock:\(tc_lastStock)";
        
        tc_list = [];
    }
    
    func tacticalStockExpendEffect(cost: Int, pos: CGPoint, size: CGSize) {
        var expend = SKLabelNode(text: "-\(cost)");
        expend.position = pos;
        expend.fontSize = 16;
        self.addChild(expend);
        
        let move = SKAction.moveTo(CGPointMake(pos.x, pos.y + size.height*0.6), duration: 0.3);
        let fade1 = SKAction.fadeAlphaTo(0.5, duration: 0.1);
        let fade2 = SKAction.fadeAlphaTo(1.0, duration: 0.1);
        let fade3 = SKAction.fadeAlphaTo(0.0, duration: 0.1);
        let fadeseq = SKAction.sequence([fade1, fade2, fade1, fade2, fade3]);
        let group = SKAction.group([move, fadeseq]);
        let endfunc = SKAction.runBlock { () -> Void in
            expend.removeFromParent();
        }
        expend.runAction(SKAction.sequence([group, endfunc]));
    }
    func tacticalStockExpendEffect_ui(cost: Int, frame: CGRect) {
        var expend = UILabel(frame: CGRectMake(frame.origin.x + frame.size.width*0.5, frame.origin.y - frame.size.height*0.5
            , frame.size.width, frame.size.height));
        expend.text = "-\(cost)";
        expend.textAlignment = NSTextAlignment.Center;
        self.view!.addSubview(expend);
        
        UIView.animateWithDuration(0.5, // アニメーションの時間
            animations: {() -> Void  in
                expend.frame.origin.y = expend.frame.origin.y - frame.size.height*0.6;
                expend.alpha = 0.0;
            }, completion: {(Bool) -> Void in
                // アニメーション終了後の処理
                expend.removeFromSuperview();
        })
    }

    func tacticalCommandLabelUpdate() {
        if let lbl = ui_tacticalCommandLbl {
            lbl.text = "command:"
            for i in 0 ..< tc_list.count {
                switch tc_list[i] {
                case CharBtlAction.ActType.atk:
                    lbl.text += "atk,"
                case CharBtlAction.ActType.def:
                    lbl.text += "def,"
                case CharBtlAction.ActType.enh:
                    lbl.text += "enh,"
                case CharBtlAction.ActType.jam:
                    lbl.text += "jam,"
                default:
                    break;
                }
            }
        }
    }

    
    func meleeStart() {
        
        scene_status = SceneStatus.melee;

        meleeBuffer = [];
        for i in 0 ..< tc_list.count {
            let enemy_act: CharBtlAction.ActType;
            if arc4random()%3 == 0 {enemy_act = CharBtlAction.ActType.atk}
            else if arc4random()%3 == 0 {enemy_act = CharBtlAction.ActType.def}
            else if arc4random()%3 == 0 {enemy_act = CharBtlAction.ActType.enh}
            else if arc4random()%3 == 0 {enemy_act = CharBtlAction.ActType.jam}
            else {enemy_act = CharBtlAction.ActType.non}
    
            var data: MeleeData = MeleeData(player_action: tc_list[i], enemy_action: enemy_act);
            meleeBuffer.append(data);
        }
        
        meleeProgress = 0;
        meleeMain();
    }
    func meleeMain() {
        
        meleeNextFlg[0] = false;
        meleeNextFlg[1] = false;
        
        if meleeProgress >= meleeBuffer.count {
            meleeEnd();
        }
        else {
            meleeNextAction();
        }
    }
    func meleeNextAction() {
        
        let meleeData = meleeBuffer[meleeProgress];
        let playerAction = player_char.actions[meleeData.player_action.rawValue];
        let enemyAction = enemy_char.actions[meleeData.enemy_action.rawValue];
        
        switch meleeData.player_action {
        case CharBtlAction.ActType.atk:
            switch meleeData.enemy_action {
            case CharBtlAction.ActType.non: melee_atk_non(pAct: playerAction);
            case CharBtlAction.ActType.atk: melee_atk_atk(pAct: playerAction, eAct: enemyAction);
            case CharBtlAction.ActType.def: melee_atk_def(pAct: playerAction, eAct: enemyAction);
            case CharBtlAction.ActType.enh: melee_atk_enh(pAct: playerAction, eAct: enemyAction);
            case CharBtlAction.ActType.jam: melee_atk_jam(pAct: playerAction, eAct: enemyAction);
            }
        case CharBtlAction.ActType.def:
            switch meleeData.enemy_action {
            case CharBtlAction.ActType.non: melee_def_non(pAct: playerAction);
            case CharBtlAction.ActType.atk: melee_def_atk(pAct: playerAction, eAct: enemyAction);
            case CharBtlAction.ActType.def: melee_def_def(pAct: playerAction, eAct: enemyAction);
            case CharBtlAction.ActType.enh: melee_def_enh(pAct: playerAction, eAct: enemyAction);
            case CharBtlAction.ActType.jam: melee_def_jam(pAct: playerAction, eAct: enemyAction);
            }
        case CharBtlAction.ActType.enh:
            switch meleeData.enemy_action {
            case CharBtlAction.ActType.non: melee_enh_non(pAct: playerAction);
            case CharBtlAction.ActType.atk: melee_enh_atk(pAct: playerAction, eAct: enemyAction);
            case CharBtlAction.ActType.def: melee_enh_def(pAct: playerAction, eAct: enemyAction);
            case CharBtlAction.ActType.enh: melee_enh_enh(pAct: playerAction, eAct: enemyAction);
            case CharBtlAction.ActType.jam: melee_enh_jam(pAct: playerAction, eAct: enemyAction);
            }
        case CharBtlAction.ActType.jam:
            switch meleeData.enemy_action {
            case CharBtlAction.ActType.non: melee_jam_non(pAct: playerAction);
            case CharBtlAction.ActType.atk: melee_jam_atk(pAct: playerAction, eAct: enemyAction);
            case CharBtlAction.ActType.def: melee_jam_def(pAct: playerAction, eAct: enemyAction);
            case CharBtlAction.ActType.enh: melee_jam_enh(pAct: playerAction, eAct: enemyAction);
            case CharBtlAction.ActType.jam: melee_jam_jam(pAct: playerAction, eAct: enemyAction);
            }
        case CharBtlAction.ActType.non:
            switch meleeData.enemy_action {
            case CharBtlAction.ActType.non: melee_non_non();
            case CharBtlAction.ActType.atk: melee_non_atk(eAct: enemyAction);
            case CharBtlAction.ActType.def: melee_non_def(eAct: enemyAction);
            case CharBtlAction.ActType.enh: melee_non_enh(eAct: enemyAction);
            case CharBtlAction.ActType.jam: melee_non_jam(eAct: enemyAction);
            }
        }
    }
    func meleeEnd() {
        
        // 乱戦状態のデータを初期化
        let keys = Array(char_list.keys);
        for i in 0 ..< keys.count {
            let key = keys[i];
            if let c = char_list[key] {
                let move = SKAction.moveTo(c.position_base, duration: 0.2);
                c.runAction(move);
            }
        }
        meleeBuffer = [];
        meleeProgress = 0;
        meleeNextFlg[0] = true;
        meleeNextFlg[1] = true;
        
        // ゲージを初期化
        gaugeInit();
        reach_frame = reach_base;
        rise_speed = rise_speed_base;
        gauge.updateProgress(100);
        
        attack_list = [];
        attack_count_lbl.text = "\(attack_list.count)"
        
        player_char.turnEnd();
        enemy_char.turnEnd();
        
        player_char.refleshStatus();
        enemy_char.refleshStatus();
        
        scene_status = SceneStatus.stock;
    }
    
    //------------
    // 行動順優先順 def > atk > enh > jam
    //------------
    // 有利不利
    // def > atk
    // enh > def
    // jam > enh
    // atk > jam
    // 有利行動をとった場合はそのターン相手の次回以降の行動が終了する
    //------------
    
    //------------
    // player atk
    
    func melee_atk_non(#pAct: Character.Action) {
        
        meleeAction_Atk(attacker: player_char, target: enemy_char
            , unilaterally: true
            , damage: calcDamage(player_char, target: enemy_char)
            , callback: { () -> Void in
                
                self.meleeNextFlg[0] = true;
        });
        
        self.meleeNextFlg[1] = true;
    }

    func melee_atk_atk(#pAct: Character.Action, eAct: Character.Action) {
        
        meleeAction_Atk(attacker: player_char, target: enemy_char
            , unilaterally: false
            , damage: calcDamage(player_char, target: enemy_char)
            , callback: { () -> Void in
                
                self.meleeNextFlg[0] = true;
        });
        
        meleeAction_Atk(attacker: enemy_char, target: player_char
            , unilaterally: false
            , damage: calcDamage(enemy_char, target: player_char)
            , callback: { () -> Void in
                
                self.meleeNextFlg[1] = true;
        });
    }

    func melee_atk_def(#pAct: Character.Action, eAct: Character.Action) {
        
        // 不利
        meleeAction_Atk(attacker: player_char, target: enemy_char
            , unilaterally: true
            , damage: calcDamage(player_char, target: enemy_char)
            , callback: { () -> Void in
                
                self.meleeNextFlg[0] = true;
        });
        
        self.meleeNextFlg[1] = true;
    }

    func melee_atk_enh(#pAct: Character.Action, eAct: Character.Action) {
    
        meleeAction_Atk(attacker: player_char, target: enemy_char
            , unilaterally: true
            , damage: calcDamage(player_char, target: enemy_char)
            , callback: { () -> Void in
                
                self.meleeNextFlg[0] = true;
                
                self.meleeAction_Enh(target: self.enemy_char
                    , content: eAct.action.enh
                    , callback: { () -> Void in
                        
                        self.addEnh(self.enemy_char, action: eAct);
                        self.meleeNextFlg[1] = true;
                })
        });
        
    }

    func melee_atk_jam(#pAct: Character.Action, eAct: Character.Action) {
        // 有利
        
        meleeAction_Atk(attacker: player_char, target: enemy_char
            , unilaterally: true
            , damage: calcDamage(player_char, target: enemy_char)
            , callback: { () -> Void in
                
                self.meleeNextFlg[0] = true;
                
                self.meleeAction_Jam(target: self.player_char, content: eAct.action.jam, callback: { () -> Void in
                    self.addJam(self.player_char, executor: self.enemy_char, action: eAct);
                    self.meleeNextFlg[1] = true;
                })
        });
    }

    //------------
    // player def

    func melee_def_non(#pAct: Character.Action) {
        
        self.meleeNextFlg[0] = true;
        self.meleeNextFlg[1] = true;
    }

    func melee_def_atk(#pAct: Character.Action, eAct: Character.Action) {
        // 有利
        
        self.meleeNextFlg[0] = true;

        meleeAction_Atk(attacker: enemy_char, target: player_char
            , unilaterally: true
            , damage: calcDamage(enemy_char, target: player_char)
            , callback: { () -> Void in
                
                self.meleeNextFlg[1] = true;
        });
    }

    func melee_def_def(#pAct: Character.Action, eAct: Character.Action) {
        
        self.meleeNextFlg[0] = true;
        self.meleeNextFlg[1] = true;
    }

    func melee_def_enh(#pAct: Character.Action, eAct: Character.Action) {
        // 不利
        
        meleeNextFlg[0] = true;
        
        self.meleeAction_Enh(target: self.enemy_char
            , content: eAct.action.enh
            , callback: { () -> Void in
                
                self.addEnh(self.enemy_char, action: eAct);
                self.meleeNextFlg[1] = true;
        })
    }

    func melee_def_jam(#pAct: Character.Action, eAct: Character.Action) {
        
        self.meleeNextFlg[0] = true;
        
        self.meleeAction_Jam(target: self.player_char, content: eAct.action.jam, callback: { () -> Void in
            self.addJam(self.player_char, executor: self.enemy_char, action: eAct);
            self.meleeNextFlg[1] = true;
        })
    }

    //------------
    // player enh

    func melee_enh_non(#pAct: Character.Action) {
        
        self.meleeAction_Enh(target: self.player_char
            , content: pAct.action.enh
            , callback: { () -> Void in
            
            self.addEnh(self.player_char, action: pAct);
            self.meleeNextFlg[0] = true;
        })
        
        self.meleeNextFlg[1] = true;
    }

    func melee_enh_atk(#pAct: Character.Action, eAct: Character.Action) {
        
        meleeAction_Atk(attacker: enemy_char, target: player_char
            , unilaterally: true
            , damage: calcDamage(enemy_char, target: player_char)
            , callback: { () -> Void in
                
                self.meleeNextFlg[1] = true;
                
                self.meleeAction_Enh(target: self.player_char
                    , content: pAct.action.enh
                    , callback: { () -> Void in
                        
                        self.addEnh(self.player_char, action: pAct);
                        self.meleeNextFlg[0] = true;
                })                
        });
    }
    
    func melee_enh_def(#pAct: Character.Action, eAct: Character.Action) {
        // 有利
        
        self.meleeAction_Enh(target: self.player_char
            , content: pAct.action.enh
            , callback: { () -> Void in
            
            self.addEnh(self.player_char, action: pAct);
            self.meleeNextFlg[0] = true;
        })
        
        self.meleeNextFlg[1] = true;
    }

    func melee_enh_enh(#pAct: Character.Action, eAct: Character.Action) {
        
        self.meleeAction_Enh(target: self.player_char
            , content: pAct.action.enh
            , callback: { () -> Void in
                
                self.addEnh(self.player_char, action: pAct);
                self.meleeNextFlg[0] = true;
        })
        
        self.meleeAction_Enh(target: self.enemy_char
            , content: eAct.action.enh
            , callback: { () -> Void in
                
                self.addEnh(self.enemy_char, action: eAct);
                self.meleeNextFlg[1] = true;
        })
    }

    func melee_enh_jam(#pAct: Character.Action, eAct: Character.Action) {
        // 不利
        
        self.meleeAction_Enh(target: self.player_char
            , content: pAct.action.enh
            , callback: { () -> Void in
                
                self.addEnh(self.player_char, action: pAct);
                self.meleeNextFlg[0] = true;
                
                self.meleeAction_Jam(target: self.player_char, content: eAct.action.jam, callback: { () -> Void in
                    self.addJam(self.player_char, executor: self.enemy_char, action: eAct);
                    self.meleeNextFlg[1] = true;
                })
        })
    }

    //------------
    // player jam
    
    func melee_jam_non(#pAct: Character.Action) {
        
        self.meleeAction_Jam(target: self.enemy_char, content: pAct.action.jam, callback: { () -> Void in
            self.addJam(self.enemy_char, executor: self.player_char, action: pAct);
            self.meleeNextFlg[0] = true;
        })

        self.meleeNextFlg[1] = true;
    }

    func melee_jam_atk(#pAct: Character.Action, eAct: Character.Action) {
        // 不利
        
        meleeAction_Atk(attacker: enemy_char, target: player_char
            , unilaterally: true
            , damage: calcDamage(enemy_char, target: player_char)
            , callback: { () -> Void in
                
                self.meleeNextFlg[1] = true;
                
                self.meleeAction_Jam(target: self.enemy_char, content: pAct.action.jam, callback: { () -> Void in
                    self.addJam(self.enemy_char, executor: self.player_char, action: pAct);
                    self.meleeNextFlg[0] = true;
                })
        });
    }

    func melee_jam_def(#pAct: Character.Action, eAct: Character.Action) {
        
        self.meleeAction_Jam(target: self.enemy_char, content: pAct.action.jam, callback: { () -> Void in
            self.addJam(self.enemy_char, executor: self.player_char, action: pAct);
            self.meleeNextFlg[0] = true;
        })
        
        self.meleeNextFlg[1] = true;
    }

    func melee_jam_enh(#pAct: Character.Action, eAct: Character.Action) {
        // 有利
        
        self.meleeAction_Enh(target: self.enemy_char
            , content: eAct.action.enh
            , callback: { () -> Void in
                
                self.addEnh(self.enemy_char, action: eAct);
                self.meleeNextFlg[1] = true;
                
                self.meleeAction_Jam(target: self.enemy_char, content: pAct.action.jam, callback: { () -> Void in
                    self.addJam(self.enemy_char, executor: self.player_char, action: pAct);
                    self.meleeNextFlg[0] = true;
                })
        })
    }

    func melee_jam_jam(#pAct: Character.Action, eAct: Character.Action) {
        
        self.meleeAction_Jam(target: self.enemy_char, content: pAct.action.jam, callback: { () -> Void in
            self.addJam(self.enemy_char, executor: self.player_char, action: pAct);
            self.meleeNextFlg[0] = true;
        })
        
        self.meleeAction_Jam(target: self.player_char, content: eAct.action.jam, callback: { () -> Void in
            self.addJam(self.player_char, executor: self.enemy_char, action: eAct);
            self.meleeNextFlg[1] = true;
        })
    }

    //------------
    // player non

    func melee_non_atk(#eAct: Character.Action) {
        
        self.meleeNextFlg[0] = true;
        
        meleeAction_Atk(attacker: enemy_char, target: player_char
            , unilaterally: true
            , damage: calcDamage(enemy_char, target: player_char)
            , callback: { () -> Void in
                
                self.meleeNextFlg[1] = true;
        });
    }
    
    func melee_non_def(#eAct: Character.Action) {
        
        self.meleeNextFlg[0] = true;
        self.meleeNextFlg[1] = true;
    }
    
    func melee_non_enh(#eAct: Character.Action) {
        
        self.meleeNextFlg[0] = true;
        
        self.meleeAction_Enh(target: self.enemy_char
            , content: eAct.action.enh
            , callback: { () -> Void in
                
                self.addEnh(self.enemy_char, action: eAct);
                self.meleeNextFlg[1] = true;
        })
    }
    
    func melee_non_jam(#eAct: Character.Action) {
        
        self.meleeNextFlg[0] = true;
        
        self.meleeAction_Jam(target: self.player_char, content: eAct.action.jam, callback: { () -> Void in
            self.addJam(self.player_char, executor: self.enemy_char, action: eAct);
            self.meleeNextFlg[1] = true;
        })
    }

    func melee_non_non() {
        self.meleeNextFlg[0] = true;
        self.meleeNextFlg[1] = true;
    }

    func meleeAction_Atk(#attacker: Character, target: Character
        , unilaterally: Bool = true
        , damage: Int
        , callback: () -> Void)
    {
        
        let basePos = attacker.position;
        let movePos: CGPoint;
        if unilaterally {
            movePos = CGPointMake(target.position.x, target.position.y);
        }
        else {
            movePos = CGPointMake(self.size.width*0.5 - ((self.size.width*0.5 - attacker.position.x) * 0.05), attacker.position.y);
        }
        let move = SKAction.moveTo(movePos, duration: 0.1);
        let attack_effect = SKAction.runBlock { () -> Void in

            // TODO:攻撃エフェクトにパターン欲しい
            
            self.meleeAction_Damage(target.name!, damage: damage, callback: { () -> Void in
            })
        }
        let recoil = SKActionEx.jumpTo(startPoint: movePos
            , targetPoint: basePos
            , height: attacker.size.height
            , duration: 0.5);
        let attack_end = SKAction.runBlock { () -> Void in
            callback();
        }
        attacker.runAction(SKAction.sequence([move, attack_effect, recoil, attack_end]));
    }
    
    func meleeAction_Damage(target_name: String, damage: Int, callback: () -> Void) {
        let target = char_list[target_name];
        if target != nil {
            
            target!.HP = target!.HP - damage;
            
            target!.color = UIColor.redColor();
            target!.colorBlendFactor = 0.8;
            
            let a1 = SKAction.fadeAlphaTo(0.5, duration: 0.1);
            let a2 = SKAction.fadeAlphaTo(1.0, duration: 0.1);
            let aseq = SKAction.sequence([a1, a2, a1, a2]);
            let end = SKAction.runBlock({ () -> Void in
                target!.color = UIColor.clearColor();
                target!.colorBlendFactor = 0.0;
            })
            target!.runAction(SKAction.sequence([aseq, end]));
            
            let damage_lbl = SKLabelNode(text: "\(damage)");
            damage_lbl.fontColor = UIColor.whiteColor();
            damage_lbl.fontSize = 14;
            damage_lbl.position = CGPointMake(target!.position.x, target!.position.y + target!.size.height*0.4);
            damage_lbl.zPosition = ZCtrl.damage_label.rawValue;
            self.addChild(damage_lbl);
            
            let m1 = SKAction.moveTo(CGPointMake(target!.position.x, target!.position.y + target!.size.height*0.5), duration: 0.3);
            let f1 = SKAction.fadeAlphaTo(0.0, duration: 0.1);
            let dend = SKAction.runBlock({ () -> Void in
                damage_lbl.removeFromParent();
                
                target!.refleshStatus();

                callback();
            })
            damage_lbl.runAction(SKAction.sequence([m1, f1, dend]));
        }
    }
    
    func meleeAction_Enh(#target: Character
        , content: [CharBtlAction.Enh]
        , callback: () -> Void)
    {
        for i in 0 ..< 30 {
            var line = SKSpriteNode(imageNamed: "Sparkline");
            line.blendMode = SKBlendMode.Add;
            line.position.x = createRandom(Min: target.position.x - target.size.width*0.5, Max: target.position.x + target.size.width*0.5)
            line.position.y = target.position.y - target.size.height*0.5;
            line.xScale = 1.5;
            line.yScale = 0.0;
            line.color = UIColor.orangeColor();
            line.colorBlendFactor = 1.0;
            self.addChild(line);
            
            var delay = SKAction.waitForDuration(NSTimeInterval(createRandom(Min: 0.0, Max: 0.3)));
            var scaleX = SKAction.scaleXTo(0.0, duration: 0.4);
            scaleX.timingMode = SKActionTimingMode.EaseInEaseOut;
            var scaleY = SKAction.scaleYTo(1.1, duration: 0.8);
            scaleY.timingMode = SKActionTimingMode.EaseOut;
            var move = SKAction.moveToY(target.position.y + target.size.height*0.3, duration: 0.8)
            var scaleGroup = SKAction.group([scaleX, scaleY, move]);
            let endfunc = SKAction.runBlock { () -> Void in
                line.removeFromParent();
            }
            line.runAction(SKAction.sequence([delay, scaleGroup, endfunc]));
        }
        
        target.color = UIColor.orangeColor();
        target.colorBlendFactor = 0.5;
        target.runAction(SKAction.sequence([
            SKActionEx.jumpTo(startPoint: target.position, targetPoint: target.position, height: target.size.height*0.2, duration: 0.2)
            , SKActionEx.jumpTo(startPoint: target.position, targetPoint: target.position, height: target.size.height*0.2, duration: 0.2)
            , SKAction.waitForDuration(0.6)
            , SKAction.runBlock({ () -> Void in
                target.color = UIColor.clearColor();
                target.colorBlendFactor = 0.0;
                callback();
            })
        ]));
        
        /*
        var flour = SKEmitterNode(fileNamed: "Enhanced");
        flour.position = target.position;
        
        flour.particleTexture = SKTexture(imageNamed: "sparkline.png");
        flour.particleBlendMode = SKBlendMode.Add;
        flour.numParticlesToEmit = 100;
        flour.emissionAngle = 90;
        flour.emissionAngleRange = 20;
        flour.particleScale = 1.0;
        flour.particleScaleRange = 0;
        flour.particleScaleSpeed = 0;
        flour.particleScaleSequence = SKKeyframeSequence(keyframeValues: [0.1, 0.3, 1.0], times: [0.4, 0.3, 0.3]);
        flour.particleAlpha = 1.0;
        flour.particleAlphaRange = 0;
        flour.particleAlphaSpeed = 0;
        flour.particleAlphaSequence = SKKeyframeSequence(keyframeValues: [0.5, 0.3, 0.2], times: [0.6, 0.2, 0.2]);
        flour.particleColor = UIColor.orangeColor();
        flour.particleColorBlendFactor = 1.0;
        flour.particleLifetime = 0.8;
        flour.particleLifetimeRange = 0.3;
        flour.particlePosition = CGPointMake(0, 0 - target.size.height*0.5);
        flour.particlePositionRange = CGVector(dx: target.size.width*1.05, dy: target.size.height*0.05);
        flour.particleZPosition = target.zPosition;
        flour.particleSpeed = 30;
        flour.particleSpeedRange = 5;
        //flour.particleSize = CGSizeMake(target.size.width*0.3, target.size.height*0.6);
        flour.xAcceleration = 0;
        flour.yAcceleration = 100;
        self.addChild(flour);
        
        let endfunc = SKAction.runBlock { () -> Void in
            flour.removeFromParent();
            
            callback();
        }
        flour.runAction(SKAction.sequence([SKAction.waitForDuration(1.0), endfunc]));
        */
    }
    
    func meleeAction_Jam(#target: Character
        , content: [CharBtlAction.Jam]
        , callback: () -> Void)
    {
        for i in 0 ..< 30 {
            var line = SKSpriteNode(imageNamed: "Sparkline");
            line.blendMode = (arc4random() % 2 == 0) ? SKBlendMode.Add : SKBlendMode.Alpha;
            line.position.x = createRandom(Min: target.position.x - target.size.width*0.5, Max: target.position.x + target.size.width*0.5)
            line.position.y = target.position.y + target.size.height*0.4;
            line.xScale = 1.5;
            line.yScale = 0.0;
            line.zRotation = CGFloat(M_PI) / 1.0;
            line.color = UIColor.blueColor();
            line.colorBlendFactor = 1.0;
            self.addChild(line);
            
            var delay = SKAction.waitForDuration(NSTimeInterval(createRandom(Min: 0.0, Max: 0.3)));
            var scaleX = SKAction.scaleXTo(0.0, duration: 0.4);
            scaleX.timingMode = SKActionTimingMode.EaseInEaseOut;
            var scaleY = SKAction.scaleYTo(1.1, duration: 0.8);
            scaleY.timingMode = SKActionTimingMode.EaseOut;
            var move = SKAction.moveToY(target.position.y - target.size.height*0.3, duration: 0.4)
            var scaleGroup = SKAction.group([scaleX, scaleY, move]);
            let endfunc = SKAction.runBlock { () -> Void in
                line.removeFromParent();
            }
            line.runAction(SKAction.sequence([delay, scaleGroup, endfunc]));
        }
        
        target.color = UIColor.blueColor();
        target.colorBlendFactor = 0.5;
        target.runAction(SKAction.sequence([
            SKActionEx.jumpTo(startPoint: target.position, targetPoint: target.position, height: target.size.height*0.2, duration: 0.2)
            , SKActionEx.jumpTo(startPoint: target.position, targetPoint: target.position, height: target.size.height*0.2, duration: 0.2)
            , SKAction.waitForDuration(0.6)
            , SKAction.runBlock({ () -> Void in
                target.color = UIColor.clearColor();
                target.colorBlendFactor = 0.0;
                callback();
            })
        ]));
    }

    func calcDamage(attacker: Character, target: Character) -> Int {
        var damage = attacker.calcATK() - target.calcDEF();
        damage = (damage < 0) ? 1 : damage;
        return damage
    }
    
    func addEnh(target: Character, action: Character.Action) {
        if action.action.type == CharBtlAction.ActType.enh {
            if action.action.enhEnable {
                for enh in action.action.enh {
                    target.addEnhanced(enh);
                }
                target.refleshStatus();
            }
        }
    }
    func addJam(target: Character, executor: Character, action: Character.Action) {
        if action.action.type == CharBtlAction.ActType.jam {
            if action.action.jamEnable {
                for jam in action.action.jam {
                    target.addJamming(jam, executor: executor);
                }
                target.refleshStatus();
            }
        }
    }
    
    // 乱数生成
    func createRandom(#Min : CGFloat, Max : CGFloat) -> CGFloat {
        
        return ( CGFloat(arc4random_uniform(UINT32_MAX)) / CGFloat(UINT32_MAX) ) * (Max - Min) + Min
    }
}
