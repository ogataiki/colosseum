import SpriteKit

class BattleScene: SKScene, SpeechDelegate {
    
    var gameManager = GameManager.instance;
    
    enum SceneStatus: Int {
        case pretreat = 0
        case speech_start
        case speech_tactical
        case speech_end
        case stock
        case tactical
        case melee
        case finish
        case end
        
        case animation_wait
        case debug = -1
    }
    var scene_status = SceneStatus.pretreat;
    func changeStatus(status: SceneStatus) {
        if scene_status == SceneStatus.debug {
            debug_status = status;
        }
        else {
            scene_status = status;
        }
    }
    
    var turn: Int = 0;
    
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
        var player_action = CharBase.ActionType.non;
        var enemy_action = CharBase.ActionType.non;
    }
    struct MeleeSpec {
        var spec = CharBase.Spec();
        var defs: [CharBase.Defenced] = [];
    }
    struct MeleeResult {
        var non_action: Bool = false;
        var cancel_action: Bool = false;
        var attack: [CharBase.Attacked] = [];
        var defence: [CharBase.Defenced] = [];
        var jamming: [CharBase.Jamming] = [];
        var enhance: [CharBase.Enhanced] = [];
        var skill: [CharBase.Skilled] = [];
        var specAfter_executer = MeleeSpec();
        var specAfter_target = MeleeSpec();
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
    
    var player_spec = CharBase.Spec();
    var enemy_spec = CharBase.Spec();
    
    //------
    // UI系
    var ui_playerLastStock: SKLabelNode!;
    var ui_tacticalCommandLbl: SKLabelNode!;
    var ui_tacticalAtk: UIButton!;
    var ui_tacticalDef: UIButton!;
    var ui_tacticalJam: UIButton!;
    var ui_tacticalEnh: UIButton!;
    var ui_tacticalSkl: UIButton!;
    var ui_tacticalCompatibleArrow_atk_enh: SKSpriteNode!;
    var ui_tacticalCompatibleArrow_def_atk: SKSpriteNode!;
    var ui_tacticalCompatibleArrow_jam_def: SKSpriteNode!;
    var ui_tacticalCompatibleArrow_enh_jam: SKSpriteNode!;
    var ui_tacticalEnter: UIButton!;
    var ui_tacticalReset: UIButton!;
    var tc_lastStock: Int = 0;
    var tc_list: [CharBase.ActionType] = [];
    
    var log_list: [String] = [];
    var log_label_list: [SKLabelNode] = [];
    var log_back: SKSpriteNode!;
    
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
        
        turn = 1;
        
        speech_battleStart();
    }
    
    func gaugeInit() {
        gauge = Gauge(color: UIColor.grayColor(), size: CGSizeMake(30, player_char.gaugeLangeth));
        gauge.initGauge(color: UIColor.greenColor(), direction: Gauge.Direction.vertical, zPos:ZCtrl.gauge.rawValue);
        gauge.initGauge_lo(color: UIColor.redColor(), zPos:ZCtrl.gauge_lo.rawValue);
        gauge.resetProgress(0.0);
        gauge.changeAnchorPoint(CGPointMake(0.5, 0.5));
        gauge.changePosition(CGPointMake(self.size.width*0.25, self.size.height*0.5));
        gauge.alpha = 0.0;
        self.addChild(gauge);
        
        rise_bar = SKSpriteNode(color: UIColor.blackColor(), size: CGSizeMake(36, 5));
        rise_bar.position = CGPointMake(gauge.position.x, gauge.position.y - gauge.size.height*0.5);
        rise_bar.zPosition = ZCtrl.gauge_rise_bar.rawValue;
        rise_bar.alpha = 0.0;
        self.addChild(rise_bar);
        
        attack_count_lbl = SKLabelNode(text: "0");
        attack_count_lbl.position = CGPointMake(gauge.position.x, gauge.position.y - gauge.size.height*0.65);
        attack_count_lbl.alpha = 0.0;
        self.addChild(attack_count_lbl);
        
        reach_frame = reach_base;
        rise_speed = rise_speed_base;
        gauge.updateProgress(100);
    }
    func gaugeCutinAnimation(callback: () -> Void) {
        gaugeInit();
        let move = SKAction.moveToX(gauge.position.x - self.size.width, duration: 0.0);
        let fade = SKAction.fadeAlphaTo(1.0, duration: 0.0);
        let move2 = SKAction.moveToX(gauge.position.x, duration: 0.3);
        let endf = SKAction.runBlock { () -> Void in
            self.rise_bar.alpha = 0.5;
            self.attack_count_lbl.alpha = 1.0;
            callback();
        }
        gauge.runAction(SKAction.sequence([move, fade, move2, endf]));
    }
    func gaugeCutoutAnimation(callback: () -> Void) {
        self.rise_bar.alpha = 0.0;
        self.attack_count_lbl.alpha = 0.0;
        let move = SKAction.moveToX(gauge.position.x - self.size.width, duration: 0.3);
        let endf = SKAction.runBlock { () -> Void in
            self.gaugeRemove();
            callback();
        }
        gauge.runAction(SKAction.sequence([move, endf]));
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
        
        let ui_positions: [CGPoint] = [
            CGPointMake(self.size.width*0.3, self.size.height*0.5),
            CGPointMake(self.size.width*0.7, self.size.height*0.5),
            CGPointMake(self.size.width*0.7, self.size.height*0.65),
            CGPointMake(self.size.width*0.3, self.size.height*0.65),
            CGPointMake(self.size.width*0.5, self.size.height*0.775),
            CGPointMake(self.size.width*0.25, self.size.height*0.9),
            CGPointMake(self.size.width*0.75, self.size.height*0.9)
        ];
        
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
        ui_tacticalAtk.layer.position = ui_positions[0];
        ui_tacticalAtk.backgroundColor = UIColor.brownColor();
        ui_tacticalAtk.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping;
        let actionAtk = player_char.actions[CharBase.ActionType.atk.rawValue];
        let titleAtk = "\(actionAtk.name) \ncost:\(actionAtk.cost)"
        ui_tacticalAtk.setTitle(titleAtk, forState: UIControlState.Normal)
        ui_tacticalAtk.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        ui_tacticalAtk.setTitle(titleAtk, forState: UIControlState.Highlighted)
        ui_tacticalAtk.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        ui_tacticalAtk.addTarget(self, action: "tacticalAtk", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(ui_tacticalAtk);
        
        ui_tacticalDef = UIButton(frame: CGRectMake(0,0, ui_tacticalAtk.frame.size.width, ui_tacticalAtk.frame.size.height));
        ui_tacticalDef.layer.position = ui_positions[1];
        ui_tacticalDef.backgroundColor = UIColor.brownColor();
        ui_tacticalDef.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping;
        let actionDef = player_char.actions[CharBase.ActionType.def.rawValue];
        let titleDef = "\(actionDef.name) \ncost:\(actionDef.cost)"
        ui_tacticalDef.setTitle(titleDef, forState: UIControlState.Normal)
        ui_tacticalDef.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        ui_tacticalDef.setTitle(titleDef, forState: UIControlState.Highlighted)
        ui_tacticalDef.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        ui_tacticalDef.addTarget(self, action: "tacticalDef", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(ui_tacticalDef);
        
        ui_tacticalJam = UIButton(frame: CGRectMake(0,0, ui_tacticalAtk.frame.size.width, ui_tacticalAtk.frame.size.height));
        ui_tacticalJam.layer.position = ui_positions[2];
        ui_tacticalJam.backgroundColor = UIColor.brownColor();
        ui_tacticalJam.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping;
        let actionJam = player_char.actions[CharBase.ActionType.jam.rawValue];
        let titleJam = "\(actionJam.name) \ncost:\(actionJam.cost)"
        ui_tacticalJam.setTitle(titleJam, forState: UIControlState.Normal)
        ui_tacticalJam.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        ui_tacticalJam.setTitle(titleJam, forState: UIControlState.Highlighted)
        ui_tacticalJam.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        ui_tacticalJam.addTarget(self, action: "tacticalJam", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(ui_tacticalJam);
        
        ui_tacticalEnh = UIButton(frame: CGRectMake(0,0, ui_tacticalAtk.frame.size.width, ui_tacticalAtk.frame.size.height));
        ui_tacticalEnh.layer.position = ui_positions[3];
        ui_tacticalEnh.backgroundColor = UIColor.brownColor();
        ui_tacticalEnh.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping;
        let actionEnh = player_char.actions[CharBase.ActionType.enh.rawValue];
        let titleEnh = "\(actionEnh.name) \ncost:\(actionEnh.cost)"
        ui_tacticalEnh.setTitle(titleEnh, forState: UIControlState.Normal)
        ui_tacticalEnh.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        ui_tacticalEnh.setTitle(titleEnh, forState: UIControlState.Highlighted)
        ui_tacticalEnh.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        ui_tacticalEnh.addTarget(self, action: "tacticalEnh", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(ui_tacticalEnh);
        
        ui_tacticalSkl = UIButton(frame: CGRectMake(0,0, self.size.width*0.6, ui_tacticalAtk.frame.size.height*0.8));
        ui_tacticalSkl.layer.position = ui_positions[4];
        ui_tacticalSkl.backgroundColor = UIColor.brownColor();
        ui_tacticalSkl.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping;
        let actionSkl = player_char.actions[CharBase.ActionType.skl.rawValue];
        let titleSkl = "\(actionSkl.name) \ncost:\(actionSkl.cost)"
        ui_tacticalSkl.setTitle(titleSkl, forState: UIControlState.Normal)
        ui_tacticalSkl.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        ui_tacticalSkl.setTitle(titleSkl, forState: UIControlState.Highlighted)
        ui_tacticalSkl.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        ui_tacticalSkl.addTarget(self, action: "tacticalSkl", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(ui_tacticalSkl);
        
        
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
        ui_tacticalEnter.layer.position = ui_positions[5];
        ui_tacticalEnter.backgroundColor = UIColor.greenColor();
        ui_tacticalEnter.setTitle("enter", forState: UIControlState.Normal)
        ui_tacticalEnter.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        ui_tacticalEnter.setTitle("enter", forState: UIControlState.Highlighted)
        ui_tacticalEnter.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        ui_tacticalEnter.addTarget(self, action: "tacticalEnter", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(ui_tacticalEnter);
        
        ui_tacticalReset = UIButton(frame: CGRectMake(0,0, self.view!.frame.size.width*0.4, self.view!.frame.size.height*0.1));
        ui_tacticalReset.layer.position = ui_positions[6];
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
        if let ui = ui_tacticalSkl {
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
        
        if let ui = debug_updateStopButton {
            ui.removeFromSuperview();
        }
    }
    
    func playerInit() {
        
        player_char = CharManager.getChar(gameManager.player_character.rawValue);
        player_char.posUpdate(CGPointMake(self.size.width*0.85, self.size.height*0.8));
        player_char.setPlayer(true);
        player_char.zPosUpdate(0);
        self.addChild(player_char.gaugeHP);
        self.addChild(player_char);
        char_list[player_char.name!] = player_char;
        
        
        player_char.labelHP = SKLabelNode(text: "HP:\(player_char.spec.HP)");
        player_char.labelATK = SKLabelNode(text: "ATK:\(player_char.spec.ATK)");
        player_char.labelDEF = SKLabelNode(text: "DEF:\(player_char.spec.DEF)");
        player_char.labelHIT = SKLabelNode(text: "HIT:\(player_char.spec.HIT)");
        player_char.labelAVD = SKLabelNode(text: "ADV:\(player_char.spec.AVD)");
        player_char.labelADDATK = SKLabelNode(text: "ADDATK:\(player_char.spec.ADD_ATK)");
        
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
        
        player_char.refleshStatus();
    }
    
    func enemyInit() {
        
        enemy_char = CharManager.getChar(gameManager.enemy_character.rawValue);
        enemy_char.posUpdate(CGPointMake(self.size.width*0.15, self.size.height*0.8));
        enemy_char.setPlayer(false);
        enemy_char.zPosUpdate(0);
        self.addChild(enemy_char.gaugeHP);
        self.addChild(enemy_char);
        char_list[enemy_char.name!] = enemy_char;
        
        enemy_char.labelHP = SKLabelNode(text: "HP:\(enemy_char.spec.HP)");
        enemy_char.labelATK = SKLabelNode(text: "ATK:\(enemy_char.spec.ATK)");
        enemy_char.labelDEF = SKLabelNode(text: "DEF:\(enemy_char.spec.DEF)");
        enemy_char.labelHIT = SKLabelNode(text: "HIT:\(enemy_char.spec.HIT)");
        enemy_char.labelAVD = SKLabelNode(text: "ADV:\(enemy_char.spec.AVD)");
        enemy_char.labelADDATK = SKLabelNode(text: "ADDATK:\(enemy_char.spec.ADD_ATK)");
        
        enemy_char.labelHP.fontSize = 12;
        enemy_char.labelATK.fontSize = 12;
        enemy_char.labelDEF.fontSize = 12;
        enemy_char.labelHIT.fontSize = 12;
        enemy_char.labelAVD.fontSize = 12;
        enemy_char.labelADDATK.fontSize = 12;
        
        enemy_char.labelHP.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*0.8);
        enemy_char.labelATK.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*1.0);
        enemy_char.labelDEF.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*1.2);
        enemy_char.labelHIT.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*1.4);
        enemy_char.labelAVD.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*1.6);
        enemy_char.labelADDATK.position = CGPointMake(enemy_char.position.x, enemy_char.position.y - enemy_char.size.height*1.8);
        
        self.addChild(enemy_char.labelHP);
        self.addChild(enemy_char.labelATK);
        self.addChild(enemy_char.labelDEF);
        self.addChild(enemy_char.labelHIT);
        self.addChild(enemy_char.labelAVD);
        self.addChild(enemy_char.labelADDATK);
        
        enemy_char.refleshStatus();
    }
    func enemyCutinAnimation(callback: () -> Void) {
        enemy_char.gaugeHP.alpha = 0.0;
        enemy_char.labelHP.alpha = 0.0;
        enemy_char.labelATK.alpha = 0.0;
        enemy_char.labelDEF.alpha = 0.0;
        enemy_char.labelHIT.alpha = 0.0;
        enemy_char.labelAVD.alpha = 0.0;
        enemy_char.labelADDATK.alpha = 0.0;
        let move = SKAction.moveToX(enemy_char.position_base.x - self.size.width, duration: 0.0);
        let move2 = SKAction.moveToX(enemy_char.position_base.x, duration: 0.3);
        let endf = SKAction.runBlock { () -> Void in
            self.enemy_char.gaugeHP.alpha = 1.0;
            self.enemy_char.labelHP.alpha = 1.0;
            self.enemy_char.labelATK.alpha = 1.0;
            self.enemy_char.labelDEF.alpha = 1.0;
            self.enemy_char.labelHIT.alpha = 1.0;
            self.enemy_char.labelAVD.alpha = 1.0;
            self.enemy_char.labelADDATK.alpha = 1.0;
            callback();
        }
        enemy_char.runAction(SKAction.sequence([move, move2, endf]));
    }
    func enemyCutoutAnimation(callback: () -> Void) {
        enemy_char.gaugeHP.alpha = 0.0;
        enemy_char.labelHP.alpha = 0.0;
        enemy_char.labelATK.alpha = 0.0;
        enemy_char.labelDEF.alpha = 0.0;
        enemy_char.labelHIT.alpha = 0.0;
        enemy_char.labelAVD.alpha = 0.0;
        enemy_char.labelADDATK.alpha = 0.0;
        let move = SKAction.moveToX(enemy_char.position_base.x - self.size.width, duration: 0.3);
        let endf = SKAction.runBlock { () -> Void in
            callback();
        }
        enemy_char.runAction(SKAction.sequence([move, endf]));
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        for touch in (touches ) {
            let location = touch.locationInNode(self)
            
            switch(scene_status) {
            
            case .pretreat:
                break;
                
            case .speech_start:
                fallthrough;
            case .speech_tactical:
                fallthrough;
            case .speech_end:
                speechCtrl.tap();
                break;

            case .stock:
                
                if reach_frame < rise_frame {
                    
                    // ui入れ替え
                    changeStatus(SceneStatus.animation_wait);
                    gaugeCutoutAnimation { () -> Void in
                        self.enemyCutinAnimation({ () -> Void in
                            self.tacticalStart();
                        })
                    }
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
                
            case .finish:
                break;
                
            case .end:
                SceneManager.changeScene(SceneManager.Scenes.home);
                
            case .animation_wait:
                break;
            case .debug:
                break;
            }
            
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        switch(scene_status) {
        case .pretreat:
            break;
        case .speech_start:
            break;
        case .speech_tactical:
            break;
        case .speech_end:
            break;
        case .stock:
            updateStock();
        case .tactical:
            updateTactical();
        case .melee:
            updateMelee();
        case .finish:
            break;
        case .end:
            break;
        case .animation_wait:
            break;
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
            let speed = rise_speed + (rise_frame / player_char.gaugeAcceleration);
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
        
        tacticalUIInit();

        tc_list = [];
        tc_lastStock = attack_list.count;
        ui_playerLastStock.text = "lastStock:\(self.tc_lastStock)";
        
        if speech_battleTactical(turn) == false {
            changeStatus(SceneStatus.tactical);
        }
    }
    func tacticalAtk() {
        if scene_status != SceneStatus.tactical {
            return;
        }
        let cost = player_char.actions[CharBase.ActionType.atk.rawValue].action.atkCost;
        if tc_lastStock >= cost {
            tc_list.append(CharBase.ActionType.atk);
            tc_lastStock = tc_lastStock - cost;
            ui_playerLastStock.text = "lastStock:\(tc_lastStock)";
            tacticalStockExpendEffect(cost, pos: ui_playerLastStock.position, size: ui_playerLastStock.frame.size);
            tacticalStockExpendEffect_ui(cost, frame: ui_tacticalAtk.frame);
        }
    }
    func tacticalDef() {
        if scene_status != SceneStatus.tactical {
            return;
        }
        let cost = player_char.actions[CharBase.ActionType.def.rawValue].action.defCost;
        if tc_lastStock >= cost {
            tc_list.append(CharBase.ActionType.def);
            tc_lastStock = tc_lastStock - cost;
            ui_playerLastStock.text = "lastStock:\(tc_lastStock)";
            tacticalStockExpendEffect(cost, pos: ui_playerLastStock.position, size: ui_playerLastStock.frame.size);
            tacticalStockExpendEffect_ui(cost, frame: ui_tacticalDef.frame);
        }
    }
    func tacticalJam() {
        if scene_status != SceneStatus.tactical {
            return;
        }
        let cost = player_char.actions[CharBase.ActionType.jam.rawValue].action.jamCost;
        if tc_lastStock >= cost {
            tc_list.append(CharBase.ActionType.jam);
            tc_lastStock = tc_lastStock - cost;
            ui_playerLastStock.text = "lastStock:\(tc_lastStock)";
            tacticalStockExpendEffect(cost, pos: ui_playerLastStock.position, size: ui_playerLastStock.frame.size);
            tacticalStockExpendEffect_ui(cost, frame: ui_tacticalJam.frame);
        }
    }
    func tacticalEnh() {
        if scene_status != SceneStatus.tactical {
            return;
        }
        let cost = player_char.actions[CharBase.ActionType.enh.rawValue].action.enhCost;
        if tc_lastStock >= cost {
            tc_list.append(CharBase.ActionType.enh);
            tc_lastStock = tc_lastStock - cost;
            ui_playerLastStock.text = "lastStock:\(tc_lastStock)";
            tacticalStockExpendEffect(cost, pos: ui_playerLastStock.position, size: ui_playerLastStock.frame.size);
            tacticalStockExpendEffect_ui(cost, frame: ui_tacticalEnh.frame);
        }
    }
    func tacticalSkl() {
        if scene_status != SceneStatus.tactical {
            return;
        }
        let act = player_char.actions[CharBase.ActionType.skl.rawValue];
        let cost = act.action.sklCost;
        if tc_lastStock >= cost {
            tc_list.append(CharBase.ActionType.skl);
            tc_lastStock = tc_lastStock - cost;
            ui_playerLastStock.text = "lastStock:\(tc_lastStock)";
            tacticalStockExpendEffect(cost, pos: ui_playerLastStock.position, size: ui_playerLastStock.frame.size);
            tacticalStockExpendEffect_ui(cost, frame: ui_tacticalSkl.frame);
        }
    }
    func tacticalEnter() {
        if scene_status != SceneStatus.tactical {
            return;
        }
        tacticalUIRemove();
        
        meleeStart();
    }
    func tacticalReset() {
        if scene_status != SceneStatus.tactical {
            return;
        }
        tc_lastStock = attack_list.count;
        ui_playerLastStock.text = "lastStock:\(tc_lastStock)";
        
        tc_list = [];
    }
    
    func tacticalStockExpendEffect(cost: Int, pos: CGPoint, size: CGSize) {
        let expend = SKLabelNode(text: "-\(cost)");
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
        let expend = UILabel(frame: CGRectMake(frame.origin.x + frame.size.width*0.5, frame.origin.y - frame.size.height*0.5
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
                    lbl.text! += "atk,"
                case .def:
                    lbl.text! += "def,"
                case .enh:
                    lbl.text! += "enh,"
                case .jam:
                    lbl.text! += "jam,"
                case .skl:
                    lbl.text! += "skl,"
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
        let loop = max(tc_list.count, Int(enemyActs));
        for i in 0 ..< loop {
            
            let enemy_act: CharBase.ActionType;
            if i > Int(enemyActs) {enemy_act = CharBase.ActionType.non}
            else if arc4random()%3 == 0 {enemy_act = CharBase.ActionType.def}
            else if arc4random()%3 == 0 {enemy_act = CharBase.ActionType.jam}
            else if arc4random()%3 == 0 {enemy_act = CharBase.ActionType.enh}
            else if arc4random()%3 == 0 {enemy_act = CharBase.ActionType.skl}
            else {enemy_act = CharBase.ActionType.atk}
            
            let player_act = (i < tc_list.count) ? tc_list[i] : CharBase.ActionType.non;
            
            let data: MeleeData = MeleeData(player_action: player_act, enemy_action: enemy_act);
            meleeBuffer.append(data);
        }
        
        player_spec = player_char.spec;
        enemy_spec = enemy_char.spec;
        

        meleeProgress = 0;
        meleeMain();
    }
    func meleeMain() {
        
        if player_char.isDead() || enemy_char.isDead() {
            meleeEnd();
            return;
        }

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
        
        meleeAction_Pre(pAct: CharBase.cnvActType(playerAction), eAct: CharBase.cnvActType(enemyAction)) { () -> Void in
            self.meleeNextActionExec(playerAction: playerAction, enemyAction: enemyAction);
        };
    }
    func meleeNextActionExec(playerAction playerAction: CharBase.Action, enemyAction: CharBase.Action) {
        switch CharBase.cnvActType(playerAction) {
        case .atk:
            switch CharBase.cnvActType(enemyAction) {
            case .non: melee_atk_non(pAct: playerAction);
            case .atk: melee_atk_atk(pAct: playerAction, eAct: enemyAction);
            case .def: melee_atk_def(pAct: playerAction, eAct: enemyAction);
            case .jam: melee_atk_jam(pAct: playerAction, eAct: enemyAction);
            case .enh: melee_atk_enh(pAct: playerAction, eAct: enemyAction);
            }
        case .def:
            switch CharBase.cnvActType(enemyAction) {
            case .non: melee_def_non(pAct: playerAction);
            case .atk: melee_def_atk(pAct: playerAction, eAct: enemyAction);
            case .def: melee_def_def(pAct: playerAction, eAct: enemyAction);
            case .jam: melee_def_jam(pAct: playerAction, eAct: enemyAction);
            case .enh: melee_def_enh(pAct: playerAction, eAct: enemyAction);
            }
        case .enh:
            switch CharBase.cnvActType(enemyAction) {
            case .non: melee_enh_non(pAct: playerAction);
            case .atk: melee_enh_atk(pAct: playerAction, eAct: enemyAction);
            case .def: melee_enh_def(pAct: playerAction, eAct: enemyAction);
            case .jam: melee_enh_jam(pAct: playerAction, eAct: enemyAction);
            case .enh: melee_enh_enh(pAct: playerAction, eAct: enemyAction);
            }
        case .jam:
            switch CharBase.cnvActType(enemyAction) {
            case .non: melee_jam_non(pAct: playerAction);
            case .atk: melee_jam_atk(pAct: playerAction, eAct: enemyAction);
            case .def: melee_jam_def(pAct: playerAction, eAct: enemyAction);
            case .jam: melee_jam_jam(pAct: playerAction, eAct: enemyAction);
            case .enh: melee_jam_enh(pAct: playerAction, eAct: enemyAction);
            }
        case .non:
            switch CharBase.cnvActType(enemyAction) {
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
        
        player_char.turnEnd();
        enemy_char.turnEnd();
        
        player_char.refleshStatus();
        enemy_char.refleshStatus();
        
        if player_char.isDead() || enemy_char.isDead() {
            changeStatus(SceneStatus.finish);
            battleFinish({ () -> Void in
                self.changeStatus(SceneStatus.speech_end);
                self.speech_battleEnd(self.player_char.isDead());
            });
        }
        else {
            
            // ゲージを初期化
            self.changeStatus(SceneStatus.animation_wait);
            enemyCutoutAnimation({ () -> Void in
            })
            gaugeCutinAnimation { () -> Void in
                self.attack_list = [];
                self.attack_count_lbl.text = "\(self.attack_list.count)"
                
                self.turn++;
                self.changeStatus(SceneStatus.stock);
            }
        }
    }
    
    func meleeLogUpdate() {
        for var i = log_list.count-1; i >= 0; i-- {
            if log_label_list.count <= i {
                
            }
        }
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
    
    //--------------
    // melee common
    
    // 行動終了フラグ関係
    func melee_action_finish_player() {
        self.meleeNextFlg[0] = true;
        self.meleeActionFinish();
    }
    func melee_action_finish_enemy() {
        self.meleeNextFlg[1] = true;
        self.meleeActionFinish();
    }
    func melee_action_finish_all() {
        self.meleeNextFlg[0] = true;
        self.meleeNextFlg[1] = true;
        self.meleeActionFinish();
    }
    
    // プレイヤー行動
    func melee_player(meleeResult: MeleeResult, pAct: CharBase.Action, callback: () -> Void) {
        
        // スキルならスキル実行
        if melee_skl_player(meleeResult.skill, pAct: pAct, callback: callback) == false {
            
            // スキル以外なら該当行動実行
            switch pAct.action.type {
            case .atk:
                meleeAction_Atk(attacker: player_char, target: enemy_char
                    , content: meleeResult.attack
                    , left: true
                    , callback: callback);
            case .def:
                meleeAction_Def(target: player_char
                    , content: meleeResult.defence
                    , left: true
                    , callback: callback)
            case .jam:
                meleeAction_Jam(target: enemy_char
                    , content: meleeResult.jamming
                    , callback: callback)
            case .enh:
                meleeAction_Enh(target: player_char
                    , content: meleeResult.enhance
                    , callback: callback)
            default:
                callback();
            }
        }
    }
    
    // 敵行動
    func melee_enemy(meleeResult: MeleeResult, eAct: CharBase.Action, callback: () -> Void) {
        
        // スキルならスキル実行
        if melee_skl_enemy(meleeResult.skill, eAct: eAct, callback: callback) == false {
            
            // スキル以外なら該当行動実行
            switch eAct.action.type {
            case .atk:
                meleeAction_Atk(attacker: enemy_char, target: player_char
                    , content: meleeResult.attack
                    , left: false
                    , callback: callback);
            case .def:
                meleeAction_Def(target: enemy_char
                    , content: meleeResult.defence
                    , left: false
                    , callback: callback)
            case .jam:
                meleeAction_Jam(target: player_char
                    , content: meleeResult.jamming
                    , callback: callback)
            case .enh:
                meleeAction_Enh(target: enemy_char
                    , content: meleeResult.enhance
                    , callback: callback)
            default:
                callback();
            }
        }
    }
    
    // playerスキル行動
    func melee_skl_player(meleeResult: [CharBase.Skilled], pAct: CharBase.Action, callback: () -> Void) -> Bool {
        if pAct.type == CharBase.ActionType.skl {
            meleeAction_Skl(executer: player_char, target: enemy_char
                , content: meleeResult
                , left: true
                , callback: callback);
            return true;
        }
        return false;
    }
    // enemyスキル行動
    func melee_skl_enemy(meleeResult: [CharBase.Skilled], eAct: CharBase.Action, callback: () -> Void) -> Bool {
        if eAct.type == CharBase.ActionType.skl  {
            meleeAction_Skl(executer: enemy_char, target: player_char
                , content: meleeResult
                , left: true
                , callback: callback);
            return true;
        }
        return false;
    }
    
    //------------
    // player atk
    
    func melee_atk_non(pAct pAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds));
        meleeResult.enemy_result.non_action = true;
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // playerのみ行動
        melee_player(meleeResult.player_result, pAct: pAct, callback: melee_action_finish_all);
    }
    
    func melee_atk_atk(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds));
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds));
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // 同時に行動
        melee_player(meleeResult.player_result, pAct: pAct, callback: melee_action_finish_player);
        melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: melee_action_finish_enemy);
    }
    
    func melee_atk_def(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        // player不利
        // atk < def 攻撃失敗 + 有利側カウンターアタック
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.cancel_action = true;
        
        var counter_result = enemy_char.procAction_atk(pAct.action.atk
            , _attack: enemy_char.spec.ATK, targetSpecBefor: player_char.spec, targetDefences: player_char.defenceds
            , counter: true, counter_content: eAct.action.def[0]);
        
        meleeResult.player_result.specAfter_target.spec = counter_result.specAfter;
        meleeResult.player_result.specAfter_target.defs = counter_result.defsAfter;
        
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: meleeResult.player_result.specAfter_target);
        meleeResult.enemy_result.attack = counter_result.result;
        
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // 敵カウンター行動->敵行動
        self.meleeCancelAllAction(true, enemy: false, index: self.meleeProgress);
        self.melee_action_finish_player();
        
        self.meleeAction_ActTitleDisplay(player: "", enemy: "カウンター", callback: { () -> Void in
        });
        self.meleeAction_Atk(attacker: self.enemy_char, target: self.player_char
            , content: counter_result.result
            , left: false
            , callback: { () -> Void in
                
                self.melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: self.melee_action_finish_enemy);
        })
    }
    
    func melee_atk_jam(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds));
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds));
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // player行動->enemy行動
        melee_player(meleeResult.player_result, pAct: pAct) { () -> Void in
            self.melee_action_finish_player();
            
            self.melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: self.melee_action_finish_enemy);
        }
    }
    
    func melee_atk_enh(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        // player有利
        // enh < atk 強化失敗 + 強化効果全解除
        
        var meleeResult = MeleeResultData();
        meleeResult.enemy_result.cancel_action = true;
        let eSpec = meleeCancelAllStatus(self.enemy_char, cancelType: CharBtlAction.ActType.enh, proc: true);
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: eSpec);
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // enemy行動キャンセル->player行動
        self.meleeCancelAllAction(false, enemy: true, index: self.meleeProgress);
        self.meleeCancelAllStatus(self.enemy_char, cancelType: CharBtlAction.ActType.enh);
        self.enemy_char.refleshStatus();
        self.melee_action_finish_enemy();
        
        melee_player(meleeResult.player_result, pAct: pAct, callback:melee_action_finish_player);
    }
    
    //------------
    // player def
    
    func melee_def_non(pAct pAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds));
        meleeResult.enemy_result.non_action = true;
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // playerのみ行動
        melee_player(meleeResult.player_result, pAct: pAct, callback: melee_action_finish_all);
    }
    
    func melee_def_atk(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        // player有利
        // atk < def 攻撃失敗 + 有利側カウンターアタック
        
        var meleeResult = MeleeResultData();
        meleeResult.enemy_result.cancel_action = true;
        
        var counter_result = player_char.procAction_atk(eAct.action.atk
            , _attack: player_char.spec.ATK, targetSpecBefor: enemy_char.spec, targetDefences: enemy_char.defenceds
            , counter: true, counter_content: pAct.action.def[0]);
        
        meleeResult.enemy_result.specAfter_target.spec = counter_result.specAfter;
        meleeResult.enemy_result.specAfter_target.defs = counter_result.defsAfter;

        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: meleeResult.enemy_result.specAfter_target);
        meleeResult.player_result.attack = counter_result.result;
        
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // playerカウンター行動->player行動
        self.meleeCancelAllAction(false, enemy: true, index: self.meleeProgress);
        self.enemy_char.refleshStatus();
        self.melee_action_finish_enemy();
        
        self.meleeAction_ActTitleDisplay(player: "カウンター", enemy: "", callback: { () -> Void in
        });
        self.meleeAction_Atk(attacker: self.player_char, target: self.enemy_char
            , content: counter_result.result
            , left: true
            , callback: { () -> Void in
                
                self.melee_player(meleeResult.player_result, pAct: pAct, callback: self.melee_action_finish_player);
        })
    }
    
    func melee_def_def(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds));
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds));
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // 同時に行動
        melee_player(meleeResult.player_result, pAct: pAct, callback: melee_action_finish_player);
        melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: melee_action_finish_enemy);
    }
    
    func melee_def_jam(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        // player不利
        // def < jam 防御失敗 + 防御効果全破壊
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.cancel_action = true;
        let pSpec = meleeCancelAllStatus(self.player_char, cancelType: CharBtlAction.ActType.def, proc: true);
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: pSpec);


        // TODO : ここで通信
        
        // 通信結果OK
        
        // player行動キャンセル->enemy行動
        self.meleeCancelAllAction(true, enemy: false, index: self.meleeProgress);
        self.meleeCancelAllStatus(self.player_char, cancelType: CharBtlAction.ActType.def);
        self.player_char.refleshStatus();
        self.melee_action_finish_player();
        
        melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: melee_action_finish_enemy);
    }
    
    func melee_def_enh(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds));
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds));
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // 同時に行動
        melee_player(meleeResult.player_result, pAct: pAct, callback: melee_action_finish_player);
        melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: melee_action_finish_enemy);
    }
    
    //------------
    // player jam
    
    func melee_jam_non(pAct pAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds));
        meleeResult.enemy_result.non_action = true;
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // playerのみ行動
        melee_player(meleeResult.player_result, pAct: pAct, callback: melee_action_finish_all);
    }
    
    func melee_jam_atk(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds));
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds));
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // enemy行動(攻撃)->player行動
        melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: { () -> Void in
            
            self.melee_action_finish_enemy();
            
            self.melee_player(meleeResult.player_result, pAct: pAct, callback: self.melee_action_finish_player);
        });
    }
    
    func melee_jam_def(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        // player有利
        // def < jam 防御失敗 + 防御効果全破壊
        
        var meleeResult = MeleeResultData();
        meleeResult.enemy_result.cancel_action = true;
        let eSpec = meleeCancelAllStatus(self.enemy_char, cancelType: CharBtlAction.ActType.def, proc: true);
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: eSpec);

        // TODO : ここで通信
        
        // 通信結果OK
        
        // enemy行動キャンセル->player行動
        self.meleeCancelAllAction(false, enemy: true, index: self.meleeProgress);
        self.meleeCancelAllStatus(self.enemy_char, cancelType: CharBtlAction.ActType.def);
        self.enemy_char.refleshStatus();
        self.melee_action_finish_enemy();

        melee_player(meleeResult.player_result, pAct: pAct, callback: melee_action_finish_player);
    }
    
    func melee_jam_jam(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds));
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds));
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // 同時に行動
        melee_player(meleeResult.player_result, pAct: pAct, callback: melee_action_finish_player);
        melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: melee_action_finish_enemy);
    }
    
    func melee_jam_enh(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        // player不利
        // jam < enh 妨害失敗 + 妨害追加効果全解除
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.cancel_action = true;
        let eSpec = meleeCancelAllStatus(self.enemy_char, cancelType: CharBtlAction.ActType.jam);
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: eSpec
            , specBefor_target: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds));
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // player行動キャンセル->enemy行動
        self.meleeCancelAllAction(true, enemy: false, index: self.meleeProgress);
        self.meleeCancelAllStatus(self.enemy_char, cancelType: CharBtlAction.ActType.jam);
        self.enemy_char.refleshStatus();
        self.melee_action_finish_player();
        
        melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: melee_action_finish_enemy);
    }
    
    //------------
    // player enh
    
    func melee_enh_non(pAct pAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds));
        meleeResult.enemy_result.non_action = true;
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // playerのみ行動
        melee_player(meleeResult.player_result, pAct: pAct, callback: melee_action_finish_all);
    }
    
    func melee_enh_atk(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        // player不利
        // enh < atk 強化失敗 + 強化効果全解除
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.cancel_action = true;
        let pSpec = meleeCancelAllStatus(self.player_char, cancelType: CharBtlAction.ActType.enh, proc: true);
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: pSpec);
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // player行動キャンセル->enemy行動
        self.meleeCancelAllAction(true, enemy: false, index: self.meleeProgress);
        self.meleeCancelAllStatus(self.player_char, cancelType: CharBtlAction.ActType.enh);
        self.player_char.refleshStatus();
        self.melee_action_finish_player();

        melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: melee_action_finish_enemy);
    }
    
    func melee_enh_def(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds));
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds));
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // 同時に行動
        melee_player(meleeResult.player_result, pAct: pAct, callback: melee_action_finish_player);
        melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: melee_action_finish_enemy);
    }
    
    func melee_enh_jam(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        // player有利
        // jam < enh 妨害失敗 + 妨害追加効果全解除
        
        var meleeResult = MeleeResultData();
        meleeResult.enemy_result.cancel_action = true;
        let pSpec = meleeCancelAllStatus(self.player_char, cancelType: CharBtlAction.ActType.jam, proc: true);
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: pSpec
            , specBefor_target: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds));
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // enemy行動キャンセル->player行動
        self.meleeCancelAllAction(false, enemy: true, index: self.meleeProgress);
        self.meleeCancelAllStatus(self.player_char, cancelType: CharBtlAction.ActType.jam);
        self.player_char.refleshStatus();
        self.melee_action_finish_enemy();
        
        melee_player(meleeResult.player_result, pAct: pAct, callback: melee_action_finish_player);
    }
    
    func melee_enh_enh(pAct pAct: CharBase.Action, eAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result = melee_getResult(player_char, target: enemy_char, act: pAct
            , specBefor: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds)
            , specBefor_target: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds));
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds));
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // 同時に行動
        melee_player(meleeResult.player_result, pAct: pAct, callback: melee_action_finish_player);
        melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: melee_action_finish_enemy);
    }
    
    //------------
    // player non
    
    func melee_non_atk(eAct eAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.non_action = true;
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds));
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // enemyのみ行動
        melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: melee_action_finish_all);
    }
    
    func melee_non_def(eAct eAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.non_action = true;
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds));
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // enemyのみ行動
        melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: melee_action_finish_all);
    }
    
    func melee_non_jam(eAct eAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.non_action = true;
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds));
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // enemyのみ行動
        melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: melee_action_finish_all);
    }
    
    func melee_non_enh(eAct eAct: CharBase.Action) {
        
        var meleeResult = MeleeResultData();
        meleeResult.player_result.non_action = true;
        meleeResult.enemy_result = melee_getResult(enemy_char, target: player_char, act: eAct
            , specBefor: MeleeSpec(spec: enemy_char.spec, defs: enemy_char.defenceds)
            , specBefor_target: MeleeSpec(spec: player_char.spec, defs: player_char.defenceds));
        
        // TODO : ここで通信
        
        // 通信結果OK
        
        // enemyのみ行動
        melee_enemy(meleeResult.enemy_result, eAct: eAct, callback: melee_action_finish_all);
    }
    
    func melee_non_non() {
        
        melee_action_finish_all();
    }
    
    //--------------
    // 混戦結果の計算
    func melee_getResult(c: CharBase, target: CharBase, act:CharBase.Action, specBefor: MeleeSpec, specBefor_target: MeleeSpec
        , counter: Bool = false, counter_content: CharBtlAction.Def = CharBtlAction.Def())
        -> MeleeResult
    {
        var result = MeleeResult();
        if act.type == CharBase.ActionType.skl  {
            let ret = c.procAction_skl(act.action.skl
                , specBefor_executer: specBefor.spec, specBefor_target: specBefor_target.spec, specBase_target: target.spec_base
                , targetDefences: specBefor_target.defs);
            result.skill = ret.result;
            result.specAfter_executer.spec = ret.specAfter_executer;
            result.specAfter_executer.defs = specBefor.defs;
            result.specAfter_target.spec = ret.specAfter_target;
            result.specAfter_target.defs = ret.defsAfter_target;
        }
        else {
            switch act.action.type {
            case .atk:
                let ret = c.procAction_atk(act.action.atk
                    , _attack: specBefor.spec.ATK, targetSpecBefor: specBefor_target.spec, targetDefences: specBefor_target.defs
                    , counter: counter, counter_content: counter_content);
                result.attack = ret.result;
                result.specAfter_executer = specBefor;
                result.specAfter_target.spec = ret.specAfter;
                result.specAfter_target.defs = ret.defsAfter;
            case .def:
                let ret = c.procAction_def(act.action.def, specBefor: specBefor.spec);
                result.defence = ret.result;
                result.specAfter_executer.spec = ret.specAfter;
                result.specAfter_executer.defs = specBefor.defs;
                result.specAfter_target = specBefor_target;
            case .jam:
                let ret = c.procAction_jam(act.action.jam, specBase: target.spec_base, specBefor: specBefor_target.spec);
                result.jamming = ret.result;
                result.specAfter_executer = specBefor;
                result.specAfter_target.spec = ret.specAfter;
                result.specAfter_target.defs = specBefor_target.defs;
            case .enh:
                let ret = c.procAction_enh(act.action.enh, specBefor: specBefor.spec);
                result.enhance = ret.result;
                result.specAfter_executer.spec = ret.specAfter;
                result.specAfter_executer.defs = specBefor.defs;
                result.specAfter_target = specBefor_target;
            default:
                result.non_action = true;
                result.specAfter_executer = specBefor;
                result.specAfter_target = specBefor_target;
                break;
            }
        }
        return result;
    }
    
    
    func meleeAction_Pre(pAct pAct: CharBtlAction.ActType, eAct: CharBtlAction.ActType, callback: () -> Void)
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
    func meleeAction_ActTitleDisplay(player player: String, enemy: String, callback: () -> Void) {
        
        if player != "" {
            
            if let cutin = playerCutin {
                playerCutin.removeAllChildren();
                playerCutin.removeFromParent();
            }
            
            playerCutin = SKSpriteNode(color: UIColor.greenColor(), size: CGSizeMake(self.size.width*0.3, self.size.width*0.1));
            playerCutin.anchorPoint = CGPointMake(1.0, 1.0);
            playerCutin.position = CGPointMake(self.size.width + playerCutin.size.width, self.size.height);
            self.addChild(playerCutin);
            
            let pActLbl = SKLabelNode(text: player);
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
            
            let eActLbl = SKLabelNode(text: enemy);
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
    
    func meleeAction_Break(breakAct breakAct: CharBtlAction.ActType
        , advantageChar: CharBase, breakChar: CharBase
        , callback: () -> Void)
    {
        let cutin = SKSpriteNode(color: UIColor.greenColor(), size: CGSizeMake(self.size.width, self.size.height*0.2));
        cutin.position = CGPointMake(self.size.width*0.5, self.size.height*0.3);
        self.addChild(cutin);
        
        let contentText1 = "\(advantageChar.displayName)の有利行動";
        let contentText2 = "\(breakChar.displayName)は体勢を崩した！";
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
        let contentLbl1 = SKLabelNode(text: contentText1);
        contentLbl1.position = CGPointMake(0, cutin.size.height*0.25);
        contentLbl1.fontSize = 17;
        contentLbl1.fontColor = UIColor.blackColor();
        contentLbl1.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center;
        contentLbl1.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center;
        cutin.addChild(contentLbl1);
        let contentLbl2 = SKLabelNode(text: contentText2);
        contentLbl2.position = CGPointMake(0, cutin.size.height*0.05*(-1));
        contentLbl2.fontSize = 16;
        contentLbl2.fontColor = UIColor.blackColor();
        contentLbl2.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center;
        contentLbl2.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center;
        cutin.addChild(contentLbl2);
        let contentLbl3 = SKLabelNode(text: contentText3);
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
    
    func meleeAction_Atk(attacker attacker: CharBase, target: CharBase
        , content: [CharBase.Attacked] = []
        , content_index: Int = 0
        , left: Bool = false
        , callback: () -> Void)
    {
        if content_index >= content.count {
            callback();
            return;
        }
        var actions: [SKAction] = [];
        
        let damage = content[content_index].damage;
        let first = (content_index == 0) ? true : false;
        let last = (content_index == content.count-1) ? true : false;
        let basePos = attacker.position;
        let movePos: CGPoint;
        if left {
            if target.size.width < 0.0 {
                movePos = CGPointMake(target.position.x - target.size.width*0.4, target.position.y);
            }
            else {
                movePos = CGPointMake(target.position.x + target.size.width*0.4, target.position.y);
            }
        }
        else {
            if target.size.width < 0.0 {
                movePos = CGPointMake(target.position.x + target.size.width*0.4, target.position.y);
            }
            else {
                movePos = CGPointMake(target.position.x - target.size.width*0.4, target.position.y);
            }
        }
        let move = SKAction.moveTo(movePos, duration: 0.1);
        actions.append(move);
        
        let attack_effect = SKAction.runBlock { () -> Void in
            
            for i2 in 0 ..< 2 {
                var startPos: CGPoint, endPos: CGPoint;
                if left {
                    if target.size.width < 0.0 {
                        startPos = CGPointMake(target.position.x - target.size.width*0.6, target.position.y + target.size.height*0.6);
                        endPos = CGPointMake(target.position.x + target.size.width*0.4, target.position.y - target.size.height*0.4);
                    }
                    else {
                        startPos = CGPointMake(target.position.x + target.size.width*0.6, target.position.y + target.size.height*0.6);
                        endPos = CGPointMake(target.position.x - target.size.width*0.4, target.position.y - target.size.height*0.4);
                    }
                }
                else {
                    if target.size.width < 0.0 {
                        startPos = CGPointMake(target.position.x + target.size.width*0.6, target.position.y + target.size.height*0.6);
                        endPos = CGPointMake(target.position.x - target.size.width*0.4, target.position.y - target.size.height*0.4);
                    }
                    else {
                        startPos = CGPointMake(target.position.x - target.size.width*0.6, target.position.y + target.size.height*0.6);
                        endPos = CGPointMake(target.position.x + target.size.width*0.4, target.position.y - target.size.height*0.4);
                    }
                }
                let atkEffect = SKSpriteNode(imageNamed: "Sparkline");
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
                                target.addDamage([content[content_index]]);
                                target.refleshStatus();
                            })
                        }
                    }
                    atkEffect.removeFromParent();
                })
                atkEffect.runAction(SKAction.sequence([atkScale1, atkRote, SKAction.group([atkMove, atkScaleSeq]), atkEFunc]));
            }
        }
        actions.append(attack_effect);
        
        let waitTime = (last) ? 1.2 : 0.8;
        let wait = SKAction.waitForDuration(waitTime);
        actions.append(wait);
        
        let recoil = SKActionEx.jumpTo(startPoint: movePos
            , targetPoint: basePos
            , height: attacker.size.height
            , duration: 0.5);
        actions.append(recoil);
        let attack_end = SKAction.runBlock { () -> Void in
            self.meleeAction_Atk(attacker: attacker, target: target
                , content: content, content_index: content_index+1
                , left: left
                , callback: callback);
        }
        actions.append(attack_end);
        
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
    
    func meleeAction_Def(target target: CharBase
        , content: [CharBase.Defenced]
        , left: Bool = false
        , callback: () -> Void)
    {
        for i in 0 ..< 10 {
            let delay = SKAction.waitForDuration(NSTimeInterval(createRandom(Min: 0.0, Max: 0.3)));
            print("left:\(left), target.pos:\(target.position), target.size:\(target.size)");
            let pos: CGFloat;
            if left {
                if target.size.width < 0.0 {
                    pos = target.position.x + (target.size.width*0.6);
                }
                else {
                    pos = target.position.x - (target.size.width*0.6);
                }
            }
            else {
                if target.size.width < 0.0 {
                    pos = target.position.x - (target.size.width*0.6);
                }
                else {
                    pos = target.position.x + (target.size.width*0.6);
                }
            }
            print("pos:\(pos)");
            let move = SKAction.moveToX(pos, duration: 0.5);
            let scale = SKAction.scaleYTo(0.9, duration: 0.5);
            let group = SKAction.group([move, scale]);
            for j in 0 ..< 2 {
                let line = SKSpriteNode(imageNamed: "Sparkline");
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
                
                target.addDefenced(content);
                target.refleshStatus();
                
                callback();
            })
            ]));
    }
    
    func meleeAction_Jam(target target: CharBase
        , content: [CharBase.Jamming]
        , callback: () -> Void)
    {
        for i in 0 ..< 30 {
            let line = SKSpriteNode(imageNamed: "Sparkline");
            line.blendMode = (arc4random() % 2 == 0) ? SKBlendMode.Add : SKBlendMode.Alpha;
            line.position.x = createRandom(Min: target.position.x - target.size.width*0.5, Max: target.position.x + target.size.width*0.5)
            line.position.y = target.position.y + target.size.height*0.4;
            line.xScale = 1.5;
            line.yScale = 0.0;
            line.zRotation = CGFloat(M_PI) / 1.0;
            line.color = UIColor.blueColor();
            line.colorBlendFactor = 1.0;
            self.addChild(line);
            
            let delay = SKAction.waitForDuration(NSTimeInterval(createRandom(Min: 0.0, Max: 0.3)));
            let scaleX = SKAction.scaleXTo(0.0, duration: 0.4);
            scaleX.timingMode = SKActionTimingMode.EaseInEaseOut;
            let scaleY = SKAction.scaleYTo(1.1, duration: 0.8);
            scaleY.timingMode = SKActionTimingMode.EaseOut;
            let move = SKAction.moveToY(target.position.y - target.size.height*0.3, duration: 0.4)
            let scaleGroup = SKAction.group([scaleX, scaleY, move]);
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
                
                target.addJamming(content);
                target.refleshStatus();
                
                callback();
            })
            ]));
    }
    
    func meleeAction_Enh(target target: CharBase
        , content: [CharBase.Enhanced]
        , callback: () -> Void)
    {
        for i in 0 ..< 30 {
            let line = SKSpriteNode(imageNamed: "Sparkline");
            line.blendMode = SKBlendMode.Add;
            line.position.x = createRandom(Min: target.position.x - target.size.width*0.5, Max: target.position.x + target.size.width*0.5)
            line.position.y = target.position.y - target.size.height*0.5;
            line.xScale = 1.5;
            line.yScale = 0.0;
            line.color = UIColor.orangeColor();
            line.colorBlendFactor = 1.0;
            self.addChild(line);
            
            let delay = SKAction.waitForDuration(NSTimeInterval(createRandom(Min: 0.0, Max: 0.3)));
            let scaleX = SKAction.scaleXTo(0.0, duration: 0.4);
            scaleX.timingMode = SKActionTimingMode.EaseInEaseOut;
            let scaleY = SKAction.scaleYTo(1.1, duration: 0.8);
            scaleY.timingMode = SKActionTimingMode.EaseOut;
            let move = SKAction.moveToY(target.position.y + target.size.height*0.3, duration: 0.8)
            let scaleGroup = SKAction.group([scaleX, scaleY, move]);
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
                
                target.addEnhanced(content);
                target.refleshStatus();
                
                callback();
            })
            ]));
        
    }
    
    func meleeAction_Skl(executer executer: CharBase, target: CharBase
        , content: [CharBase.Skilled]
        , index: Int = 0
        , left: Bool = false
        , callback: () -> Void)
    {
        if index >= content.count {
            callback();
            return;
        }
        let skl = content[index];
        switch skl.type {
        case .atk:
            meleeAction_Atk(attacker: executer, target: target
                , content: skl.atk
                , left: left
                , callback: { () -> Void in
                    self.meleeAction_Skl(executer: executer, target: target
                        , content: content
                        , index: index+1
                        , left: left
                        , callback: { () -> Void in
                            callback();
                    })
            })
        case .def:
            meleeAction_Def(target: executer
                , content: skl.def
                , left: left
                , callback: { () -> Void in
                    self.meleeAction_Skl(executer: executer, target: target
                        , content: content
                        , index: index+1
                        , left: left
                        , callback: { () -> Void in
                            callback();
                    })
                    
            })
        case .jam:
            meleeAction_Jam(target: target
                , content: skl.jam
                , callback: { () -> Void in
                    self.meleeAction_Skl(executer: executer, target: target
                        , content: content
                        , index: index+1
                        , left: left
                        , callback: { () -> Void in
                            callback();
                    })
                    
            })
        case .enh:
            meleeAction_Enh(target: executer
                , content: skl.enh
                , callback: { () -> Void in
                    self.meleeAction_Skl(executer: executer, target: target
                        , content: content
                        , index: index+1
                        , left: left
                        , callback: { () -> Void in
                            callback();
                    })
            })
        default:
            self.meleeAction_Skl(executer: executer, target: target
                , content: content
                , index: index+1
                , left: left
                , callback: { () -> Void in
                    callback();
            })
            break;
        }
    }
    
    func meleeCancelAllAction(player: Bool = false, enemy: Bool = false, index: Int = 0) {
        for var i = meleeProgress; i < meleeBuffer.count; ++i {
            if player {
                meleeBuffer[i].player_action = CharBase.ActionType.non;
            }
            if enemy {
                meleeBuffer[i].enemy_action = CharBase.ActionType.non;
            }
        }
    }
    func meleeCancelAllStatus(target: CharBase, cancelType: CharBtlAction.ActType, proc: Bool = false)
        -> MeleeSpec
    {
        var ret = MeleeSpec(spec: target.spec, defs: target.defenceds);
        switch cancelType {
        case .atk:
            break;
        case .def:
            if proc {
                ret.spec = target.procCancel_def();
            }
            else {
                ret.spec = target.allCancelDefenced();
            }
            ret.defs = [];
        case .jam:
            if proc {
                ret.spec = target.procCancel_jam();
            }
            else {
                ret.spec = target.allCancelJammings();
            }
        case .enh:
            if proc {
                ret.spec = target.procCancel_enh();
            }
            else {
                ret.spec = target.allCancelEnhanced();
            }
        default: break;
        }
        return ret;
    }
    
    
    
    // バトル終了   
    func battleFinish(callback: () -> Void) {
        let cutin = SKSpriteNode(color: UIColor.orangeColor(), size: CGSizeMake(self.size.width, self.size.height*0.2));
        cutin.position = CGPointMake(self.size.width*0.5, self.size.height*0.3);
        self.addChild(cutin);
        
        var contentText = "";
        if player_char.isDead() {
            contentText += "\(player_char.displayName) ";
        }
        if enemy_char.isDead() {
            contentText += "\(enemy_char.displayName) ";
        }
        contentText += "は戦闘不能";
        
        let contentLbl = SKLabelNode(text: contentText);
        contentLbl.position = CGPointMake(0, 0);
        contentLbl.fontSize = 17;
        contentLbl.fontColor = UIColor.blackColor();
        contentLbl.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center;
        contentLbl.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center;
        cutin.addChild(contentLbl);
        
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
    }
    
    // 乱数生成
    func createRandom(Min Min : CGFloat, Max : CGFloat) -> CGFloat {
        
        return ( CGFloat(arc4random_uniform(UINT32_MAX)) / CGFloat(UINT32_MAX) ) * (Max - Min) + Min;
    }
    
    
    
    
    var speechs: [String] = [];
    var speechCtrl: SpeechCtrl!;
    var speechIndex: Int = 0;
    func speech_battleStart() {
        speechIndex = 0;
        speechs = enemy_char.speech_battleStart;
        if speechs.count <= 0 {
            return;
        }
        speechCtrl = SpeechCtrl(_scene: self
            , _speaker_position: CGPointMake(self.size.width*0.5, self.size.height*0.9)
            , _zPosition: 0
            , _speechs: speechs
            , _delegate: self);
        speechCtrl.run();
        scene_status = .speech_start;
    }
    func speech_battleTactical(turn: Int) -> Bool {
        if turn >= enemy_char.speech_battleTactical.count {
            return false;
        }
        speechIndex = 0;
        speechs = enemy_char.speech_battleTactical[turn].speech;
        if speechs.count <= 0 {
            return false;
        }
        speechCtrl = SpeechCtrl(_scene: self
            , _speaker_position: CGPointMake(self.size.width*0.5, self.size.height*0.9)
            , _zPosition: 0
            , _speechs: speechs
            , _delegate: self);
        speechCtrl.run();
        scene_status = .speech_tactical;
        return true;
    }
    func speech_battleEnd(win: Bool) {
        speechIndex = 0;
        if win {
            speechs = enemy_char.speech_battleEnd_win;
        }
        else {
            speechs = enemy_char.speech_battleEnd_lose;
        }
        if speechs.count <= 0 {
            return;
        }
        speechCtrl = SpeechCtrl(_scene: self
            , _speaker_position: CGPointMake(self.size.width*0.5, self.size.height*0.9)
            , _zPosition: 0
            , _speechs: speechs
            , _delegate: self);
        speechCtrl.run();
        scene_status = .speech_end;
    }
    func callbackSpeechFinish(index: Int) {
        enemy_char.runAction(SKAction.sequence([
            SKAction.waitForDuration(1.0)
            , SKAction.runBlock({ () -> Void in
                self.speechCtrl.tap();
                self.speechNext(index);
            })
        ]));

    }
    func speechNext(index: Int) {
        if index+1 >= speechs.count {
            switch scene_status {
            case .speech_start:
                changeStatus(SceneStatus.animation_wait);
                enemyCutoutAnimation { () -> Void in
                    self.gaugeCutinAnimation { () -> Void in
                        self.changeStatus(SceneStatus.stock);
                    }
                }
                break;
            case .speech_tactical:
                changeStatus(SceneStatus.tactical);
                break;
            case .speech_end:
                changeStatus(SceneStatus.end);
                break;
            default:
                break;
            }
        }
        self.speechIndex++;
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
