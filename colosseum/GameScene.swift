import SpriteKit

class GameScene: SKScene {
    
    var gameManager = GameManager.instance;
    
    enum SceneStatus: Int {
        case stock = 1
        case tactical = 2
        case melee = 3
        
        case debug = -1
    }
    var scene_status = SceneStatus.stock;
    func changeStatus(status: SceneStatus) {
        if scene_status == SceneStatus.debug {
            debug_status = status;
        }
        else {
            scene_status = status;
        }
    }
    
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
    struct MeleeResult {
        var non_action: Bool = false;
        var cancel_action: Bool = false;
        var attack: [CharBase.Attacked] = [];
        var defence: [CharBase.Defenced] = [];
        var jamming: [CharBase.Jamming] = [];
        var enhance: [CharBase.Enhanced] = [];
    }
    struct MeleeResultData {
        var player_result = MeleeResult();
        var enemy_result = MeleeResult();
    }
    var meleeBuffer: [MeleeData] = [];
    var meleeResultBuffer: [MeleeResultData] = [];
    var meleeProgress: Int = 0;
    var meleeNextFlg: [Bool] = [false, false];
    var meleeActionFinishFlg: Bool = true;
    
    var player_char: CharBase!;
    var enemy_char: CharBase!;
    var char_list: [String : CharBase] = [:];
    
    //------
    // UI系
    var ui_playerLastStock: SKLabelNode!;
    var ui_tacticalCommandLbl: SKLabelNode!;
    var ui_tacticalAtk: UIButton!;
    var ui_tacticalDef: UIButton!;
    var ui_tacticalJam: UIButton!;
    var ui_tacticalEnh: UIButton!;
    var ui_tacticalCompatibleArrow_atk_enh: SKSpriteNode!;
    var ui_tacticalCompatibleArrow_def_atk: SKSpriteNode!;
    var ui_tacticalCompatibleArrow_jam_def: SKSpriteNode!;
    var ui_tacticalCompatibleArrow_enh_jam: SKSpriteNode!;
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
        
        debug_setting();
        
        // これしないと孫要素の表示順がおかしくなる
        view.ignoresSiblingOrder = false;

        playerInit();
        
        enemyInit();
                
        gaugeInit();
    }
    
    func gaugeInit() {
        gauge = Gauge(color: UIColor.grayColor(), size: CGSizeMake(30, player_char.gaugeLangeth));
        gauge.initGauge(color: UIColor.greenColor(), direction: Gauge.Direction.vertical, zPos:ZCtrl.gauge.rawValue);
        gauge.initGauge_lo(color: UIColor.redColor(), zPos:ZCtrl.gauge_lo.rawValue);
        gauge.resetProgress(0.0);
        gauge.changeAnchorPoint(CGPointMake(0.5, 0.5));
        gauge.changePosition(self.view!.center);
        self.addChild(gauge);
        
        rise_bar = SKSpriteNode(color: UIColor.blackColor(), size: CGSizeMake(36, 5));
        rise_bar.position = CGPointMake(gauge.position.x, gauge.position.y - gauge.size.height*0.5);
        rise_bar.zPosition = ZCtrl.gauge_rise_bar.rawValue;
        rise_bar.alpha = 0.5;
        self.addChild(rise_bar);
        
        attack_count_lbl = SKLabelNode(text: "0");
        attack_count_lbl.position = CGPointMake(gauge.position.x, gauge.position.y - gauge.size.height*0.65);
        self.addChild(attack_count_lbl);
        
        reach_frame = reach_base;
        rise_speed = rise_speed_base;
        gauge.updateProgress(100);
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
        
        
        ui_tacticalCompatibleArrow_def_atk = SKSpriteNode(imageNamed: "CompatibleArrow");
        ui_tacticalCompatibleArrow_def_atk.position = CGPointMake(
            ui_tacticalAtk.layer.position.x + ((ui_tacticalDef.layer.position.x - ui_tacticalAtk.layer.position.x)/2)
            , self.size.height - ui_tacticalAtk.layer.position.y);
        ui_tacticalCompatibleArrow_def_atk.xScale = -1.0;
        addChild(ui_tacticalCompatibleArrow_def_atk);

        ui_tacticalCompatibleArrow_jam_def = SKSpriteNode(imageNamed: "CompatibleArrow");
        ui_tacticalCompatibleArrow_jam_def.position = CGPointMake(
            ui_tacticalJam.layer.position.x
            , self.size.height - (ui_tacticalJam.layer.position.y - ((ui_tacticalJam.layer.position.y - ui_tacticalDef.layer.position.y)/2)));
        ui_tacticalCompatibleArrow_jam_def.zRotation = 90 / 180.0 * CGFloat(M_PI);
        addChild(ui_tacticalCompatibleArrow_jam_def);

        ui_tacticalCompatibleArrow_enh_jam = SKSpriteNode(imageNamed: "CompatibleArrow");
        ui_tacticalCompatibleArrow_enh_jam.position = CGPointMake(
            ui_tacticalEnh.layer.position.x + ((ui_tacticalJam.layer.position.x - ui_tacticalEnh.layer.position.x)/2)
            , self.size.height - ui_tacticalEnh.layer.position.y);
        addChild(ui_tacticalCompatibleArrow_enh_jam);

        ui_tacticalCompatibleArrow_atk_enh = SKSpriteNode(imageNamed: "CompatibleArrow");
        ui_tacticalCompatibleArrow_atk_enh.position = CGPointMake(
            ui_tacticalAtk.layer.position.x
            , self.size.height - (ui_tacticalEnh.layer.position.y - ((ui_tacticalEnh.layer.position.y - ui_tacticalAtk.layer.position.y)/2)));
        ui_tacticalCompatibleArrow_atk_enh.zRotation = 270 / 180.0 * CGFloat(M_PI);
        addChild(ui_tacticalCompatibleArrow_atk_enh);
        
        

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
        if let ui = ui_tacticalJam {
            ui.removeFromSuperview();
        }
        if let ui = ui_tacticalEnh {
            ui.removeFromSuperview();
        }
        if let ui = ui_tacticalCompatibleArrow_atk_enh {
            ui.removeFromParent();
        }
        if let ui = ui_tacticalCompatibleArrow_def_atk {
            ui.removeFromParent();
        }
        if let ui = ui_tacticalCompatibleArrow_jam_def {
            ui.removeFromParent();
        }
        if let ui = ui_tacticalCompatibleArrow_enh_jam {
            ui.removeFromParent();
        }
        if let ui = ui_tacticalEnter {
            ui.removeFromSuperview();
        }
        if let ui = ui_tacticalReset {
            ui.removeFromSuperview();
        }
    }
    
    func playerInit() {
        
        player_char = CharManager.getChar("Hero");
        player_char.posUpdate(CGPointMake(self.size.width*0.85, self.size.height*0.9));
        player_char.setPlayer(v: true);
        player_char.zPosUpdate(0);
        self.addChild(player_char.gaugeHP);
        self.addChild(player_char);
        char_list[player_char.name!] = player_char;

        
        player_char.labelHP = SKLabelNode(text: "HP:\(player_char.HP)");
        player_char.labelATK = SKLabelNode(text: "ATK:\(player_char.ATK)");
        player_char.labelDEF = SKLabelNode(text: "DEF:\(player_char.DEF)");
        player_char.labelHIT = SKLabelNode(text: "HIT:\(player_char.HIT)");
        player_char.labelAVD = SKLabelNode(text: "ADV:\(player_char.AVD)");
        player_char.labelADDATK = SKLabelNode(text: "ADDATK:\(player_char.ADD_ATK)");
        
        player_char.labelHP.fontSize = 12;
        player_char.labelATK.fontSize = 12;
        player_char.labelDEF.fontSize = 12;
        player_char.labelHIT.fontSize = 12;
        player_char.labelAVD.fontSize = 12;
        player_char.labelADDATK.fontSize = 12;

        player_char.labelHP.position = CGPointMake(player_char.position.x, player_char.position.y - player_char.size.height*0.8);
        player_char.labelATK.position = CGPointMake(player_char.position.x, player_char.position.y - player_char.size.height*1.0);
        player_char.labelDEF.position = CGPointMake(player_char.position.x, player_char.position.y - player_char.size.height*1.2);
        player_char.labelHIT.position = CGPointMake(player_char.position.x, player_char.position.y - player_char.size.height*1.4);
        player_char.labelAVD.position = CGPointMake(player_char.position.x, player_char.position.y - player_char.size.height*1.6);
        player_char.labelADDATK.position = CGPointMake(player_char.position.x, player_char.position.y - player_char.size.height*1.8);
        
        self.addChild(player_char.labelHP);
        self.addChild(player_char.labelATK);
        self.addChild(player_char.labelDEF);
        self.addChild(player_char.labelHIT);
        self.addChild(player_char.labelAVD);
        self.addChild(player_char.labelADDATK);
        
        // ゲージの長さをプレイヤーキャラ依存に
        reach_base = player_char.gaugeLangeth;
    }
    
    func enemyInit() {
        
        enemy_char = CharManager.getChar("HardbodyFemale");
        enemy_char.posUpdate(CGPointMake(self.size.width*0.15, self.size.height*0.9));
        enemy_char.setPlayer(v: false);
        enemy_char.zPosUpdate(0);
        self.addChild(enemy_char.gaugeHP);
        self.addChild(enemy_char);
        char_list[enemy_char.name!] = enemy_char;
        
        enemy_char.labelHP = SKLabelNode(text: "HP:\(enemy_char.HP)");
        enemy_char.labelATK = SKLabelNode(text: "ATK:\(enemy_char.ATK)");
        enemy_char.labelDEF = SKLabelNode(text: "DEF:\(enemy_char.DEF)");
        enemy_char.labelHIT = SKLabelNode(text: "HIT:\(enemy_char.HIT)");
        enemy_char.labelAVD = SKLabelNode(text: "ADV:\(enemy_char.AVD)");
        enemy_char.labelADDATK = SKLabelNode(text: "ADDATK:\(enemy_char.ADD_ATK)");
        
        enemy_char.labelHP.fontSize = 12;
        enemy_char.labelATK.fontSize = 12;
        enemy_char.labelDEF.fontSize = 12;
        enemy_char.labelHIT.fontSize = 12;
        enemy_char.labelAVD.fontSize = 12;
        enemy_char.labelADDATK.fontSize = 12;

        enemy_char.labelHP.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*1.0);
        enemy_char.labelATK.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*1.3);
        enemy_char.labelDEF.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*1.6);
        enemy_char.labelHIT.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*1.9);
        enemy_char.labelAVD.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*2.2);
        enemy_char.labelADDATK.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*2.5);
        
        self.addChild(enemy_char.labelHP);
        self.addChild(enemy_char.labelATK);
        self.addChild(enemy_char.labelDEF);
        self.addChild(enemy_char.labelHIT);
        self.addChild(enemy_char.labelAVD);
        self.addChild(enemy_char.labelADDATK);
     }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch in (touches as! Set<UITouch>) {
            let location = touch.locationInNode(self)

            switch(scene_status) {
                
            case .stock:
                
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
                
            case .tactical:
                // 各UIのハンドラに任せる
                break;
                
            case .melee:
                
                //meleeEnd();
                break;
            case .debug:
                break;
            }

        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        switch(scene_status) {
        case .stock:
            updateStock();
        case .tactical:
            updateTactical();
        case .melee:
            updateMelee();
        case .debug:
            break;
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
        
        if meleeActionFinishFlg {
            
            meleeProgress++;
            meleeMain();
        }
    }
    
    func tacticalStart() {
        
        changeStatus(SceneStatus.tactical);

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
                case .atk:
                    lbl.text += "atk,"
                case .def:
                    lbl.text += "def,"
                case .enh:
                    lbl.text += "enh,"
                case .jam:
                    lbl.text += "jam,"
                default:
                    break;
                }
            }
        }
    }

    
    func meleeStart() {
        
        changeStatus(SceneStatus.melee);

        meleeBuffer = [];
        let enemyActs = arc4random() % 6;
        let roop = max(tc_list.count, Int(enemyActs));
        for i in 0 ..< roop {
            
            let enemy_act: CharBtlAction.ActType;
            if i > Int(enemyActs) {enemy_act = CharBtlAction.ActType.non}
            else if arc4random()%3 == 0 {enemy_act = CharBtlAction.ActType.def}
            else if arc4random()%3 == 0 {enemy_act = CharBtlAction.ActType.jam}
            else if arc4random()%3 == 0 {enemy_act = CharBtlAction.ActType.enh}
            else {enemy_act = CharBtlAction.ActType.atk}
            
            let player_act = (i < tc_list.count) ? tc_list[i] : CharBtlAction.ActType.non;
    
            var data: MeleeData = MeleeData(player_action: player_act, enemy_action: enemy_act);
            meleeBuffer.append(data);
        }
        
        meleeProgress = 0;
        meleeMain();
    }
    func meleeMain() {
        
        meleeNextFlg[0] = false;
        meleeNextFlg[1] = false;
        
        if self.meleeProgress >= self.meleeBuffer.count {
            self.meleeEnd();
        }
        else {
            self.meleeNextAction();
        }
    }
    func meleeNextAction() {
        
        meleeActionFinishFlg = false;
        
        let meleeData = meleeBuffer[meleeProgress];
        let playerAction = player_char.actions[meleeData.player_action.rawValue];
        let enemyAction = enemy_char.actions[meleeData.enemy_action.rawValue];
        
        meleeAction_Pre(pAct: meleeData.player_action, eAct: meleeData.enemy_action) { () -> Void in
            self.meleeNextActionExec(meleeData, playerAction: playerAction, enemyAction: enemyAction);
        };
    }
    func meleeNextActionExec(meleeData: MeleeData, playerAction: CharBase.Action, enemyAction: CharBase.Action) {
        switch meleeData.player_action {
        case .atk:
            switch meleeData.enemy_action {
            case .non: melee_atk_non(pAct: playerAction);
            case .atk: melee_atk_atk(pAct: playerAction, eAct: enemyAction);
            case .def: melee_atk_def(pAct: playerAction, eAct: enemyAction);
            case .jam: melee_atk_jam(pAct: playerAction, eAct: enemyAction);
            case .enh: melee_atk_enh(pAct: playerAction, eAct: enemyAction);
            }
        case .def:
            switch meleeData.enemy_action {
            case .non: melee_def_non(pAct: playerAction);
            case .atk: melee_def_atk(pAct: playerAction, eAct: enemyAction);
            case .def: melee_def_def(pAct: playerAction, eAct: enemyAction);
            case .jam: melee_def_jam(pAct: playerAction, eAct: enemyAction);
            case .enh: melee_def_enh(pAct: playerAction, eAct: enemyAction);
            }
        case .enh:
            switch meleeData.enemy_action {
            case .non: melee_enh_non(pAct: playerAction);
            case .atk: melee_enh_atk(pAct: playerAction, eAct: enemyAction);
            case .def: melee_enh_def(pAct: playerAction, eAct: enemyAction);
            case .jam: melee_enh_jam(pAct: playerAction, eAct: enemyAction);
            case .enh: melee_enh_enh(pAct: playerAction, eAct: enemyAction);
            }
        case .jam:
            switch meleeData.enemy_action {
            case .non: melee_jam_non(pAct: playerAction);
            case .atk: melee_jam_atk(pAct: playerAction, eAct: enemyAction);
            case .def: melee_jam_def(pAct: playerAction, eAct: enemyAction);
            case .jam: melee_jam_jam(pAct: playerAction, eAct: enemyAction);
            case .enh: melee_jam_enh(pAct: playerAction, eAct: enemyAction);
            }
        case .non:
            switch meleeData.enemy_action {
            case .non: melee_non_non();
            case .atk: melee_non_atk(eAct: enemyAction);
            case .def: melee_non_def(eAct: enemyAction);
            case .jam: melee_non_jam(eAct: enemyAction);
            case .enh: melee_non_enh(eAct: enemyAction);
            }
        }
    }
    func meleeActionFinish() {
        
        //混戦中の1アクションが終わったら処理する
        if meleeNextFlg[0] && meleeNextFlg[1] {

            meleeAction_ActTitleRemove { () -> Void in
            }
            
            self.meleeActionFinishFlg = true;
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
        
        attack_list = [];
        attack_count_lbl.text = "\(attack_list.count)"
        
        player_char.turnEnd();
        enemy_char.turnEnd();
        
        player_char.refleshStatus();
        enemy_char.refleshStatus();
        
        changeStatus(SceneStatus.stock);
    }
    
    //------------
    // 行動
    // atk : 通常攻撃ダメージ
    // def : 防御効果付与
    // jam : 防御無視ダメージ + 追加効果
    // enh : 強化効果付与
    //------------
    // 行動優先順
    // 有利不利がある場合 : 有利 > 不利
    // 有利不利がない場合 : atk > その他
    //------------
    // 有利不利
    // atk < def 攻撃失敗 + 有利側カウンターアタック
    // def < jam 防御失敗 + 防御効果全破壊        
    // jam < enh 妨害失敗 + 妨害追加効果全解除
    // enh < atk 強化失敗 + 強化効果全解除
    // さらに不利行動をとったキャラはそのターンの行動キャンセル
    //------------
    
    //------------
    // player atk
    
    func melee_atk_non(#pAct: CharBase.Action) {
        
        let atk_result = player_char.procAction_atk(pAct.action.atk, target: enemy_char);

        var meleeResult = MeleeResultData();
        meleeResult.player_result.attack = atk_result;
        meleeResult.enemy_result.non_action = true;

        // TODO : ここで通信
        
        // 通信結果OK
        meleeAction_Atk(attacker: player_char, target: enemy_char
            , content: atk_result
            , left: true
            , callback: { () -> Void in
                
                self.enemy_char.addDamage(atk_result);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        });
    }

    func melee_atk_atk(#pAct: CharBase.Action, eAct: CharBase.Action) {

        let player_atk_result = player_char.procAction_atk(pAct.action.atk, target: enemy_char);
        let enemy_atk_result = enemy_char.procAction_atk(eAct.action.atk, target: player_char);

        var meleeResult = MeleeResultData();
        meleeResult.player_result.attack = player_atk_result;
        meleeResult.enemy_result.attack = enemy_atk_result;

        // TODO : ここで通信
        
        // 通信結果OK

        var unilaterally: ([Bool], [Bool]) = ([], []);
        let count = max(player_atk_result.count, enemy_atk_result.count);
        for i in 0 ..< count {
            if i < player_atk_result.count && i < enemy_atk_result.count {
                unilaterally.0.append(false);
                unilaterally.1.append(false);
            }
            else {
                unilaterally.0.append(true);
                unilaterally.1.append(true);
            }
        }
        
        meleeAction_Atk(attacker: player_char, target: enemy_char
            , content: player_atk_result
            , unilaterally: unilaterally.0
            , left: true
            , callback: { () -> Void in
                
                self.enemy_char.addDamage(player_atk_result);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeActionFinish();
        });
        
        meleeAction_Atk(attacker: enemy_char, target: player_char
            , content: enemy_atk_result
            , unilaterally: unilaterally.1
            , left: false
            , callback: { () -> Void in
                
                self.player_char.addDamage(enemy_atk_result);
                self.player_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        });
    }

    func melee_atk_def(#pAct: CharBase.Action, eAct: CharBase.Action) {
        // player不利
        // atk < def 攻撃失敗 + 有利側カウンターアタック

        let counter_result = enemy_char.procAction_atk(pAct.action.atk, target: player_char, counter: true, counter_content: eAct.action.def);
        let def_result = enemy_char.procAction_def([eAct.action.def]);

        var meleeResult = MeleeResultData();
        meleeResult.player_result.cancel_action = true;
        meleeResult.enemy_result.attack = counter_result;
        meleeResult.enemy_result.defence = def_result;

        // TODO : ここで通信
        
        // 通信結果OK
        

        self.meleeCancelAllAction(player: true, enemy: false, index: self.meleeProgress);
        self.meleeAction_ActTitleDisplay(player: "", enemy: "カウンター", callback: { () -> Void in
        });
        self.meleeAction_Atk(attacker: self.enemy_char, target: self.player_char
            , content: counter_result
            , left: false
            , callback: { () -> Void in
                
                self.player_char.addDamage(counter_result);
                self.meleeCancelAllAction(player: true, enemy: false, index: self.meleeProgress);
                self.player_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeAction_Def(target: self.enemy_char
                    , content: def_result
                    , left: false
                    , callback: { () -> Void in
                        
                        self.enemy_char.addDefenced(def_result);
                        self.enemy_char.refleshStatus();
                        self.meleeNextFlg[1] = true;
                        
                        self.meleeActionFinish();
                })
        })
    }

    func melee_atk_jam(#pAct: CharBase.Action, eAct: CharBase.Action) {
        
        let atk_result = player_char.procAction_atk(pAct.action.atk, target: enemy_char);
        let jam_result = enemy_char.procAction_jam(eAct.action.jam, target: player_char);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.attack = atk_result;
        meleeResult.enemy_result.jamming = jam_result;
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        meleeAction_Atk(attacker: player_char, target: enemy_char
            , content: atk_result
            , left: true
            , callback: { () -> Void in
                
                self.enemy_char.addDamage(atk_result);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeAction_Jam(target: self.player_char
                    , content: jam_result
                    , callback: { () -> Void in
                        
                        self.player_char.addJamming(jam_result);
                        self.player_char.refleshStatus();
                        self.meleeNextFlg[1] = true;
                        
                        self.meleeActionFinish();
                })
        });        
    }

    func melee_atk_enh(#pAct: CharBase.Action, eAct: CharBase.Action) {
        // player有利
        // enh < atk 強化失敗 + 強化効果全解除
        
        let atk_result = player_char.procAction_atk(pAct.action.atk, target: enemy_char);

        var meleeResult = MeleeResultData();
        meleeResult.player_result.attack = atk_result;
        meleeResult.enemy_result.cancel_action = true;

        // TODO : ここで通信
        
        // 通信結果OK


        meleeAction_Atk(attacker: player_char, target: enemy_char
            , content: atk_result
            , left: true
            , callback: { () -> Void in
                
                self.enemy_char.addDamage(atk_result);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeCancelAllAction(player: false, enemy: true, index: self.meleeProgress);
                self.meleeCancelAllStatus(self.enemy_char, cancelType: CharBtlAction.ActType.enh);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        });
        
    }

    //------------
    // player def

    func melee_def_non(#pAct: CharBase.Action) {
        
        let def_result = player_char.procAction_def([pAct.action.def]);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.defence = def_result;
        meleeResult.enemy_result.non_action = true;

        // TODO : ここで通信
        
        // 通信結果OK

        meleeAction_Def(target: player_char
            , content: def_result
            , left: true
            , callback: { () -> Void in
                
                self.player_char.addDefenced(def_result);
                self.player_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        })
    }

    func melee_def_atk(#pAct: CharBase.Action, eAct: CharBase.Action) {
        // player有利
        // atk < def 攻撃失敗 + 有利側カウンターアタック

        let def_result = player_char.procAction_def([pAct.action.def]);
        let counter_result = player_char.procAction_atk(eAct.action.atk, target: enemy_char, counter: true, counter_content: pAct.action.def);

        var meleeResult = MeleeResultData();
        meleeResult.player_result.attack = counter_result;
        meleeResult.player_result.defence = def_result;
        meleeResult.enemy_result.cancel_action = true;

        // TODO : ここで通信
        
        // 通信結果OK

        self.meleeCancelAllAction(player: false, enemy: true, index: self.meleeProgress);
        self.meleeAction_ActTitleDisplay(player: "カウンター", enemy: "", callback: { () -> Void in
        });
        self.meleeAction_Atk(attacker: self.player_char, target: self.enemy_char
            , content: counter_result
            , left: true
            , callback: { () -> Void in
                
                self.enemy_char.addDamage(counter_result);
                self.meleeCancelAllAction(player: false, enemy: true, index: self.meleeProgress);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeAction_Def(target: self.player_char
                    , content: def_result
                    , left: true
                    , callback: { () -> Void in
                        
                        self.player_char.addDefenced(def_result);
                        self.player_char.refleshStatus();
                        self.meleeNextFlg[0] = true;
                        
                        self.meleeActionFinish();
                })
        })
    }

    func melee_def_def(#pAct: CharBase.Action, eAct: CharBase.Action) {
        
        let player_def_result = player_char.procAction_def([pAct.action.def]);
        let enemy_def_result = enemy_char.procAction_def([eAct.action.def]);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.defence = player_def_result;
        meleeResult.enemy_result.defence = enemy_def_result;

        // TODO : ここで通信
        
        // 通信結果OK

        meleeAction_Def(target: player_char
            , content: player_def_result
            , left: true
            , callback: { () -> Void in
                
                self.player_char.addDefenced(player_def_result);
                self.player_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeActionFinish();
        })

        meleeAction_Def(target: enemy_char
            , content: enemy_def_result
            , left: false
            , callback: { () -> Void in
                
                self.enemy_char.addDefenced(enemy_def_result);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        })
    }

    func melee_def_jam(#pAct: CharBase.Action, eAct: CharBase.Action) {
        // player不利
        // def < jam 防御失敗 + 防御効果全破壊
        
        let jam_result = enemy_char.procAction_jam(eAct.action.jam, target:player_char);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.cancel_action = true;
        meleeResult.enemy_result.jamming = jam_result;
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        meleeAction_Jam(target: player_char
            , content: jam_result
            , callback: { () -> Void in
                
                self.player_char.addJamming(jam_result);
                self.player_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeCancelAllAction(player: true, enemy: false, index: self.meleeProgress);
                self.meleeCancelAllStatus(self.player_char, cancelType: CharBtlAction.ActType.def);
                self.player_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeActionFinish();
        })
        
    }

    func melee_def_enh(#pAct: CharBase.Action, eAct: CharBase.Action) {
        
        let def_result = player_char.procAction_def([pAct.action.def]);
        let enh_result = enemy_char.procAction_enh(eAct.action.enh);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.defence = def_result;
        meleeResult.enemy_result.enhance = enh_result;
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        meleeAction_Def(target: player_char
            , content: def_result
            , left: true
            ) { () -> Void in
                
                self.player_char.addDefenced(def_result);
                self.player_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeActionFinish();
        }

        meleeAction_Enh(target: enemy_char
            , content: enh_result
            , callback: { () -> Void in
                
                self.enemy_char.addEnhanced(enh_result);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        })
    }

    //------------
    // player jam
    
    func melee_jam_non(#pAct: CharBase.Action) {
        
        let jam_result = player_char.procAction_jam(pAct.action.jam, target:enemy_char);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.jamming = jam_result;
        meleeResult.enemy_result.non_action = true;
        
        // TODO : ここで通信
        
        // 通信結果OK

        
        meleeAction_Jam(target: enemy_char
            , content: jam_result
            , callback: { () -> Void in
                
                self.enemy_char.addJamming(jam_result);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeActionFinish();
        })
        
        self.meleeNextFlg[1] = true;
    }
    
    func melee_jam_atk(#pAct: CharBase.Action, eAct: CharBase.Action) {

        let jam_result = player_char.procAction_jam(pAct.action.jam, target:enemy_char);
        let atk_result = enemy_char.procAction_atk(eAct.action.atk, target: player_char);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.jamming = jam_result;
        meleeResult.enemy_result.attack = atk_result;
        
        // TODO : ここで通信
        
        // 通信結果OK

        meleeAction_Atk(attacker: enemy_char, target: player_char
            , content: atk_result
            , left: false
            , callback: { () -> Void in
                
                self.player_char.addDamage(atk_result);
                self.player_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeAction_Jam(target: self.enemy_char
                    , content: jam_result
                    , callback: { () -> Void in
                        
                        self.enemy_char.addJamming(jam_result);
                        self.enemy_char.refleshStatus();
                        self.meleeNextFlg[0] = true;
                        
                        self.meleeActionFinish();
                })
        });
    }
    
    func melee_jam_def(#pAct: CharBase.Action, eAct: CharBase.Action) {
        // player有利
        // def < jam 防御失敗 + 防御効果全破壊
        
        let jam_result = player_char.procAction_jam(pAct.action.jam, target:enemy_char);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.jamming = jam_result;
        meleeResult.enemy_result.cancel_action = true;
        
        // TODO : ここで通信
        
        // 通信結果OK

        meleeAction_Jam(target: enemy_char
            , content: jam_result
            , callback: { () -> Void in
                
                self.enemy_char.addJamming(jam_result);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeCancelAllAction(player: false, enemy: true, index: self.meleeProgress);
                self.meleeCancelAllStatus(self.enemy_char, cancelType: CharBtlAction.ActType.def);
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        })
    }
    
    func melee_jam_jam(#pAct: CharBase.Action, eAct: CharBase.Action) {
        
        let player_jam_result = player_char.procAction_jam(pAct.action.jam, target:enemy_char);
        let enemy_jam_result = enemy_char.procAction_jam(pAct.action.jam, target:player_char);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.jamming = player_jam_result;
        meleeResult.enemy_result.jamming = enemy_jam_result;
        
        // TODO : ここで通信
        
        // 通信結果OK
        

        self.meleeAction_Jam(target: self.enemy_char
            , content: player_jam_result
            , callback: { () -> Void in
                
                self.enemy_char.addJamming(player_jam_result);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeActionFinish();
        })
        
        self.meleeAction_Jam(target: self.player_char
            , content: enemy_jam_result
            , callback: { () -> Void in
                
                self.player_char.addJamming(enemy_jam_result);
                self.player_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        })
    }

    func melee_jam_enh(#pAct: CharBase.Action, eAct: CharBase.Action) {
        // player不利
        // jam < enh 妨害失敗 + 妨害追加効果全解除
        
        let enh_result = enemy_char.procAction_enh(eAct.action.enh);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.cancel_action = true;
        meleeResult.enemy_result.enhance = enh_result;
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        
        meleeAction_Enh(target: enemy_char
            , content: enh_result
            ) { () -> Void in
                
                self.enemy_char.addEnhanced(enh_result);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeCancelAllAction(player: true, enemy: false, index: self.meleeProgress);
                self.meleeCancelAllStatus(self.enemy_char, cancelType: CharBtlAction.ActType.jam);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeActionFinish();
        }
    }
    
    //------------
    // player enh

    func melee_enh_non(#pAct: CharBase.Action) {
        
        let enh_result = player_char.procAction_enh(pAct.action.enh);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.enhance = enh_result;
        meleeResult.enemy_result.non_action = true;
        
        // TODO : ここで通信
        
        // 通信結果OK

        meleeAction_Enh(target: player_char
            , content: enh_result
            , callback: { () -> Void in
            
                self.player_char.addEnhanced(enh_result);
                self.player_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeActionFinish();
        })
        
        self.meleeNextFlg[1] = true;
    }

    func melee_enh_atk(#pAct: CharBase.Action, eAct: CharBase.Action) {
        // player不利
        // enh < atk 強化失敗 + 強化効果全解除
        
        let atk_result = enemy_char.procAction_atk(eAct.action.atk, target: player_char);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.cancel_action = true;
        meleeResult.enemy_result.attack = atk_result;
        
        // TODO : ここで通信
        
        // 通信結果OK
        

        meleeAction_Atk(attacker: enemy_char, target: player_char
            , content: atk_result
            , left: false
            , callback: { () -> Void in
                
                self.player_char.addDamage(atk_result);
                self.player_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeCancelAllAction(player: true, enemy: false, index: self.meleeProgress);
                self.meleeCancelAllStatus(self.player_char, cancelType: CharBtlAction.ActType.enh);
                self.player_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeActionFinish();
        });
    }
    
    func melee_enh_def(#pAct: CharBase.Action, eAct: CharBase.Action) {

        let enh_result = player_char.procAction_enh(pAct.action.enh);
        let def_result = enemy_char.procAction_def([eAct.action.def]);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.enhance = enh_result;
        meleeResult.enemy_result.defence = def_result;
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        
        meleeAction_Enh(target: player_char
            , content: enh_result
            , callback: { () -> Void in
            
                self.player_char.addEnhanced(enh_result);
                self.player_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeActionFinish();
        })
        
        meleeAction_Def(target: enemy_char
            , content: def_result
            , left: false
            ) { () -> Void in

                self.enemy_char.addDefenced(def_result);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        }
    }

    func melee_enh_jam(#pAct: CharBase.Action, eAct: CharBase.Action) {
        // player有利
        // jam < enh 妨害失敗 + 妨害追加効果全解除
        
        let enh_result = player_char.procAction_enh(pAct.action.enh);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.enhance = enh_result;
        meleeResult.enemy_result.cancel_action = true;
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        
        meleeAction_Enh(target: player_char
            , content: enh_result
            ) { () -> Void in
                
                self.player_char.addEnhanced(enh_result);
                self.player_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeCancelAllAction(player: false, enemy: true, index: self.meleeProgress);
                self.meleeCancelAllStatus(self.player_char, cancelType: CharBtlAction.ActType.jam);
                self.player_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        }
    }

    func melee_enh_enh(#pAct: CharBase.Action, eAct: CharBase.Action) {
        
        let player_enh_result = player_char.procAction_enh(pAct.action.enh);
        let enemy_enh_result = enemy_char.procAction_enh(eAct.action.enh);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.enhance = player_enh_result;
        meleeResult.enemy_result.enhance = enemy_enh_result;
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        
        meleeAction_Enh(target: player_char
            , content: player_enh_result
            , callback: { () -> Void in
                
                self.player_char.addEnhanced(player_enh_result);
                self.player_char.refleshStatus();
                self.meleeNextFlg[0] = true;
                
                self.meleeActionFinish();
        })
        
        meleeAction_Enh(target: enemy_char
            , content: player_enh_result
            , callback: { () -> Void in
                
                self.enemy_char.addEnhanced(enemy_enh_result);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        })
    }

    //------------
    // player non

    func melee_non_atk(#eAct: CharBase.Action) {
        
        let atk_result = enemy_char.procAction_atk(eAct.action.atk, target: player_char);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.non_action = true;
        meleeResult.enemy_result.attack = atk_result;
        
        // TODO : ここで通信
        
        // 通信結果OK
        

        self.meleeNextFlg[0] = true;
        
        meleeAction_Atk(attacker: enemy_char, target: player_char
            , content: atk_result
            , left: false
            , callback: { () -> Void in
                
                self.player_char.addDamage(atk_result);
                self.player_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        });
    }
    
    func melee_non_def(#eAct: CharBase.Action) {
        
        let def_result = enemy_char.procAction_def([eAct.action.def]);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.non_action = true;
        meleeResult.enemy_result.defence = def_result;
        
        // TODO : ここで通信
        
        // 通信結果OK
        

        self.meleeNextFlg[0] = true;
        
        meleeAction_Def(target: enemy_char
            , content: def_result
            , left: false
            , callback: { () -> Void in
                
                self.enemy_char.addDefenced(def_result);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        })
    }
    
    func melee_non_jam(#eAct: CharBase.Action) {
        
        let jam_result = enemy_char.procAction_jam(eAct.action.jam, target: player_char);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.non_action = true;
        meleeResult.enemy_result.jamming = jam_result;
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        

        self.meleeNextFlg[0] = true;
        
        self.meleeAction_Jam(target: self.player_char
            , content: jam_result
            , callback: { () -> Void in
                
                self.player_char.addJamming(jam_result);
                self.player_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        })
    }

    func melee_non_enh(#eAct: CharBase.Action) {
        
        let enh_result = enemy_char.procAction_enh(eAct.action.enh);
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.non_action = true;
        meleeResult.enemy_result.enhance = enh_result;
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        
        self.meleeNextFlg[0] = true;
        
        self.meleeAction_Enh(target: self.enemy_char
            , content: enh_result
            , callback: { () -> Void in
                
                self.enemy_char.addEnhanced(enh_result);
                self.enemy_char.refleshStatus();
                self.meleeNextFlg[1] = true;
                
                self.meleeActionFinish();
        })
    }
    
    func melee_non_non() {
        
        self.meleeNextFlg[0] = true;
        self.meleeNextFlg[1] = true;
        self.meleeActionFinish();
    }

    func meleeAction_Pre(#pAct: CharBtlAction.ActType, eAct: CharBtlAction.ActType, callback: () -> Void)
    {
        if pAct != CharBtlAction.ActType.non {
            meleeAction_ActTitleDisplay(player: CharBtlAction.getActTypeName(pAct), enemy: "", callback: { () -> Void in
            });
        }

        if eAct != CharBtlAction.ActType.non {
            meleeAction_ActTitleDisplay(player: "", enemy: CharBtlAction.getActTypeName(eAct), callback: { () -> Void in
            });
        }
        
        let advantage: (p:Bool, e:Bool) = CharBtlAction.judgeAdvantage(pAct, comp: eAct);
        if advantage.p {
            // enemyが不利のためブレイク
            meleeAction_Break(breakAct: pAct, advantageChar: player_char, breakChar: enemy_char, callback: { () -> Void in
                callback();
            })
        }
        else if advantage.e {
            // playerが不利のためブレイク
            meleeAction_Break(breakAct: eAct, advantageChar: enemy_char, breakChar: player_char, callback: { () -> Void in
                callback();
            })
        }
        else {
            callback();
        }
    }
    
    var playerCutin: SKSpriteNode!;
    var enemyCutin: SKSpriteNode!;
    func meleeAction_ActTitleDisplay(#player: String, enemy: String, callback: () -> Void) {
        
        if player != "" {
            
            if let cutin = playerCutin {
                playerCutin.removeAllChildren();
                playerCutin.removeFromParent();
            }
            
            playerCutin = SKSpriteNode(color: UIColor.greenColor(), size: CGSizeMake(self.size.width*0.3, self.size.width*0.1));
            playerCutin.anchorPoint = CGPointMake(1.0, 1.0);
            playerCutin.position = CGPointMake(self.size.width + playerCutin.size.width, self.size.height);
            self.addChild(playerCutin);
            
            var pActLbl = SKLabelNode(text: player);
            pActLbl.position = CGPointMake(playerCutin.size.width*0.5*(-1), playerCutin.size.height*0.5*(-1));
            pActLbl.fontSize = 18;
            pActLbl.fontColor = UIColor.blackColor();
            pActLbl.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center;
            pActLbl.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center;
            playerCutin.addChild(pActLbl);
            
            playerCutin.runAction(SKAction.moveToX(self.size.width, duration: 0.2));
        }
        
        if enemy != "" {
            
            if let cutin = enemyCutin {
                enemyCutin.removeAllChildren();
                enemyCutin.removeFromParent();
            }

            enemyCutin = SKSpriteNode(color: UIColor.orangeColor(), size: CGSizeMake(self.size.width*0.3, self.size.width*0.1));
            enemyCutin.anchorPoint = CGPointMake(0.0, 1.0);
            enemyCutin.position = CGPointMake(0 - enemyCutin.size.width, self.size.height);
            self.addChild(enemyCutin);
            
            var eActLbl = SKLabelNode(text: enemy);
            eActLbl.position = CGPointMake(enemyCutin.size.width*0.5, enemyCutin.size.height*0.5*(-1));
            eActLbl.fontSize = 18;
            eActLbl.fontColor = UIColor.blackColor();
            eActLbl.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center;
            eActLbl.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center;
            enemyCutin.addChild(eActLbl);
            
            enemyCutin.runAction(SKAction.moveToX(0, duration: 0.2));
        }
    }
    func meleeAction_ActTitleRemove(callback: () -> Void) {
    
        if let cutin = playerCutin {
            let move = SKAction.moveToX(self.size.width + cutin.size.width, duration: 0.2);
            let endfunc = SKAction.runBlock({ () -> Void in
                cutin.removeAllChildren();
                cutin.removeFromParent();
            });
            cutin.runAction(SKAction.sequence([move, endfunc]));
        }
        if let cutin = enemyCutin {
            let move = SKAction.moveToX(0 - cutin.size.width, duration: 0.2);
            let endfunc = SKAction.runBlock({ () -> Void in
                cutin.removeAllChildren();
                cutin.removeFromParent();
            });
            cutin.runAction(SKAction.sequence([move, endfunc]));
        }
        callback();
    }

    func meleeAction_Break(#breakAct: CharBtlAction.ActType
        , advantageChar: CharBase, breakChar: CharBase
        , callback: () -> Void)
    {
        var cutin = SKSpriteNode(color: UIColor.greenColor(), size: CGSizeMake(self.size.width, self.size.height*0.2));
        cutin.position = CGPointMake(self.size.width*0.5, self.size.height*0.5);
        self.addChild(cutin);
        
        var contentText1 = "\(advantageChar.displayName)の有利行動";
        var contentText2 = "\(breakChar.displayName)は体勢を崩した！";
        let contentText3: String;
        switch breakAct {
        case .atk:
            contentText3 = "さらに\(breakChar.displayName)の強化効果がすべて解除！";
        case .def:
            contentText3 = "さらに\(breakChar.displayName)へカウンター！";
        case .jam:
            contentText3 = "さらに\(breakChar.displayName)の防御効果がすべて解除！";
        case .enh:
            contentText3 = "さらに\(advantageChar.displayName)への妨害効果がすべて解除！";
        default:
            contentText3 = "";
        }
        var contentLbl1 = SKLabelNode(text: contentText1);
        contentLbl1.position = CGPointMake(0, cutin.size.height*0.25);
        contentLbl1.fontSize = 17;
        contentLbl1.fontColor = UIColor.blackColor();
        contentLbl1.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center;
        contentLbl1.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center;
        cutin.addChild(contentLbl1);
        var contentLbl2 = SKLabelNode(text: contentText2);
        contentLbl2.position = CGPointMake(0, cutin.size.height*0.05*(-1));
        contentLbl2.fontSize = 16;
        contentLbl2.fontColor = UIColor.blackColor();
        contentLbl2.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center;
        contentLbl2.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center;
        cutin.addChild(contentLbl2);
        var contentLbl3 = SKLabelNode(text: contentText3);
        contentLbl3.position = CGPointMake(0, cutin.size.height*0.2*(-1));
        contentLbl3.fontSize = 16;
        contentLbl3.fontColor = UIColor.blackColor();
        contentLbl3.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center;
        contentLbl3.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center;
        cutin.addChild(contentLbl3);
        
        let scale1 = SKAction.scaleYTo(0.0, duration: 0.0);
        let scale2 = SKAction.scaleYTo(1.0, duration: 0.2);
        let wait = SKAction.waitForDuration(2.5);
        let scale3 = SKAction.scaleYTo(0.0, duration: 0.2);
        
        let endfunc = SKAction.runBlock({ () -> Void in
            cutin.removeAllChildren();
            cutin.removeFromParent();
            callback();
        });
        cutin.runAction(SKAction.sequence([scale1, scale2, wait, scale3, endfunc]));
        
        let jump = SKActionEx.jumpTo(startPoint: advantageChar.position, targetPoint: advantageChar.position, height: advantageChar.size.height*0.2, duration: 0.2);
        advantageChar.runAction(SKAction.sequence([jump, jump]));
    }

    func meleeAction_Atk(#attacker: CharBase, target: CharBase
        , content: [CharBase.Attacked] = []
        , unilaterally: [Bool] = []
        , left: Bool = false
        , callback: () -> Void)
    {
        if content.count == 0 {
            callback();
            return;
        }
        var actions: [SKAction] = [];

        for i in 0 ..< content.count {
            let damage = content[i].damage;
            let first = (i == 0) ? true : false;
            let last = (i == content.count-1) ? true : false;
            let basePos = attacker.position;
            let movePos: CGPoint;
            if i >= unilaterally.count || unilaterally[i] {
                if left {
                    movePos = CGPointMake(target.position.x + target.size.width*0.4, target.position.y);
                }
                else {
                    movePos = CGPointMake(target.position.x - target.size.width*0.4, target.position.y);
                }
            }
            else {
                movePos = CGPointMake(self.size.width*0.5 - ((self.size.width*0.5 - attacker.position.x) * 0.05), attacker.position.y);
            }
            let move = SKAction.moveTo(movePos, duration: 0.1);
            actions.append(move);
            
            let attack_effect = SKAction.runBlock { () -> Void in
                
                for i2 in 0 ..< 2 {
                    var startPos: CGPoint, endPos: CGPoint;
                    if left {
                        startPos = CGPointMake(target.position.x + target.size.width*0.6, target.position.y + target.size.height*0.6);
                        endPos = CGPointMake(target.position.x - target.size.width*0.4, target.position.y - target.size.height*0.4);
                    }
                    else {
                        startPos = CGPointMake(target.position.x - target.size.width*0.6, target.position.y + target.size.height*0.6);
                        endPos = CGPointMake(target.position.x + target.size.width*0.4, target.position.y - target.size.height*0.4);
                    }
                    var atkEffect = SKSpriteNode(imageNamed: "Sparkline");
                    atkEffect.blendMode = (i2 % 2 == 0) ? SKBlendMode.Add : SKBlendMode.Alpha;
                    atkEffect.alpha = 0.6;
                    atkEffect.position = startPos;
                    atkEffect.zPosition = target.zPosition;
                    atkEffect.setScale(0.0);
                    self.addChild(atkEffect);
                    
                    let atkScale1 = SKAction.scaleTo(0.0, duration: 0.0);
                    let radian = atan2(endPos.x - startPos.x, endPos.y - startPos.y);
                    let atkRote = SKAction.rotateToAngle(radian*(-1), duration: 0.0);
                    let atkMove = SKAction.moveTo(endPos, duration: 0.1);
                    let atkScale2 = SKAction.group([SKAction.scaleXTo(0.7, duration: 0.05), SKAction.scaleYTo(1.0, duration: 0.1)]);
                    let atkScale3 = SKAction.scaleXTo(0.0, duration: 0.05);
                    let atkScaleSeq = SKAction.sequence([atkScale2, atkScale3]);
                    let atkEFunc = SKAction.runBlock({ () -> Void in
                        if i2 == 0 {
                            if damage == 0 {
                                self.meleeAction_Miss(target.name!, callback: { () -> Void in
                                })
                            }
                            else {
                                self.meleeAction_Damage(target.name!, damage: damage, callback: { () -> Void in
                                })
                            }
                        }
                        atkEffect.removeFromParent();
                    })
                    atkEffect.runAction(SKAction.sequence([atkScale1, atkRote, SKAction.group([atkMove, atkScaleSeq]), atkEFunc]));
                }
            }
            actions.append(attack_effect);
            
            var waitTime = (last) ? 1.0 : 0.3;
            let wait = SKAction.waitForDuration(waitTime);
            actions.append(wait);
            
            let recoil = SKActionEx.jumpTo(startPoint: movePos
                , targetPoint: basePos
                , height: attacker.size.height
                , duration: 0.5);
            actions.append(recoil);
            let attack_end = SKAction.runBlock { () -> Void in
                if last {
                    callback();
                }
            }
            actions.append(attack_end);
        }
        
        attacker.runAction(SKAction.sequence(actions));
    }
    
    func meleeAction_Damage(target_name: String, damage: Int, callback: () -> Void) {
        let target = char_list[target_name];
        if target != nil {
            
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

    func meleeAction_Miss(target_name: String, callback: () -> Void) {
        let target = char_list[target_name];
        if target != nil {
            
            let basePos = target!.position;
            
            let miss_lbl = SKLabelNode(text: "MISS");
            miss_lbl.fontColor = UIColor.whiteColor();
            miss_lbl.fontSize = 14;
            miss_lbl.position = CGPointMake(target!.position.x, target!.position.y + target!.size.height*0.4);
            miss_lbl.zPosition = ZCtrl.damage_label.rawValue;
            self.addChild(miss_lbl);
            
            let m1 = SKAction.moveTo(CGPointMake(target!.position.x, target!.position.y + target!.size.height*0.5), duration: 0.3);
            let f1 = SKAction.fadeAlphaTo(0.0, duration: 0.1);
            let dend = SKAction.runBlock({ () -> Void in
                miss_lbl.removeFromParent();
                
                callback();
            })
            miss_lbl.runAction(SKAction.sequence([m1, f1, dend]));
        }
    }

    func meleeAction_Def(#target: CharBase
        , content: [CharBase.Defenced]
        , left: Bool = false
        , callback: () -> Void)
    {
        for i in 0 ..< 10 {
            let delay = SKAction.waitForDuration(NSTimeInterval(createRandom(Min: 0.0, Max: 0.3)));
            let move = SKAction.moveToX(target.position.x + ((left) ? target.size.width*0.6*(-1) : target.size.width*0.6), duration: 0.5);
            let scale = SKAction.scaleYTo(0.9, duration: 0.5);
            let group = SKAction.group([move, scale]);
            for j in 0 ..< 2 {
                var line = SKSpriteNode(imageNamed: "Sparkline");
                line.blendMode = (j % 2 == 0) ? SKBlendMode.Add : SKBlendMode.Alpha;
                line.position.x = target.position.x;
                line.position.y = target.position.y;
                line.xScale = 0.15;
                line.yScale = 0.6;
                line.color = UIColor.yellowColor();
                line.colorBlendFactor = 0.5;
                self.addChild(line);
                
                let endfunc = SKAction.runBlock { () -> Void in
                    line.removeFromParent();
                }
                line.runAction(SKAction.sequence([delay, group, endfunc]));
            }
        }
        
        target.color = UIColor.yellowColor();
        target.colorBlendFactor = 0.3;
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

    func meleeAction_Enh(#target: CharBase
        , content: [CharBase.Enhanced]
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
    
    func meleeAction_Jam(#target: CharBase
        , content: [CharBase.Jamming]
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

    func meleeCancelAllAction(player: Bool = false, enemy: Bool = false, index: Int = 0) {
        for var i = meleeProgress; i < meleeBuffer.count; ++i {
            if player {
                meleeBuffer[i].player_action = CharBtlAction.ActType.non;
            }
            if enemy {
                meleeBuffer[i].enemy_action = CharBtlAction.ActType.non;
            }
        }
    }
    func meleeCancelAllStatus(target: CharBase, cancelType: CharBtlAction.ActType) {
        switch cancelType {
        case .atk:
            break;
        case .def:
            target.allCancelDefenced();
        case .enh:
            target.allCancelEnhanced();
        case .jam:
            target.allCancelJammings();
        default: break;
        }
    }
    
    // 乱数生成
    func createRandom(#Min : CGFloat, Max : CGFloat) -> CGFloat {
        
        return ( CGFloat(arc4random_uniform(UINT32_MAX)) / CGFloat(UINT32_MAX) ) * (Max - Min) + Min
    }
    
    
    
    //------
    // debug
    var debug_status = SceneStatus.debug;
    var debug_speed: CGFloat = 0.0;
    var debug_updateStopButton: UIButton!;
    func debug_setting() {
        debug_updateStopButton = UIButton(frame: CGRectMake(self.frame.size.width-30, self.frame.size.height-30, 30, 30));
        debug_updateStopButton.backgroundColor = UIColor.whiteColor();
        debug_updateStopButton.addTarget(self, action: "debug_updateStop", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(debug_updateStopButton);
    }
    func debug_updateStop() {
        if scene_status == SceneStatus.debug {
            self.speed = debug_speed;
            debug_speed = 0;
            scene_status = debug_status;
            debug_status = SceneStatus.debug
        }
        else {
            debug_speed = self.speed;
            self.speed = 0;
            debug_status = scene_status;
            scene_status = SceneStatus.debug;
        }
    }
}
