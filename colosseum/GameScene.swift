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
        var attack: CGFloat = 0;
        var attacker_name: String = "player";
        var target_name: String = "enemy";
    }
    var meleeBuffer: [MeleeData] = [];
    var meleeProgress: Int = 0;
    var meleeNextFlg: Bool = false;
    
    var player_char: Character!;
    var enemy_char: Character!;
    var char_list: [String : Character] = [:];
    
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

        gauge = Gauge(color: UIColor.grayColor(), size: CGSizeMake(30, 200));
        gauge.initGauge(color: UIColor.greenColor(), direction: Gauge.Direction.vertical, zPos:ZCtrl.gauge.rawValue);
        gauge.initGauge_lo(color: UIColor.redColor(), zPos:ZCtrl.gauge_lo.rawValue);
        gauge.resetProgress(0.0);
        gauge.changeAnchorPoint(CGPointMake(0.5, 0.5));
        gauge.changePosition(view.center);
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
        
        playerInit();
        
        enemyInit();
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

        var act_1 = Character.Action();
        act_1.name = "攻撃";
        act_1.action.type = CharBtlAction.ActType.atk;
        act_1.action.atkEnable = true;
        var atk_1 = CharBtlAction.Atk();
        atk_1.atkPower = 2.0;
        atk_1.atkCount = 2;
        act_1.action.atk.append(atk_1);
        player_char.Actions.append(act_1);

        var act_2 = Character.Action();
        act_2.name = "防御";
        act_2.action.type = CharBtlAction.ActType.def;
        act_2.action.defEnable = true;
        act_2.action.def.defPower = 30.0;
        player_char.Actions.append(act_2);

        var act_3 = Character.Action();
        act_3.name = "強化";
        act_3.action.type = CharBtlAction.ActType.enh;
        act_3.action.enhEnable = true;
        var enh_1 = CharBtlAction.Enh();
        enh_1.enhAtkPowerAdd = 100.0;
        act_3.action.enh.append(enh_1);
        player_char.Actions.append(act_3);

        var act_4 = Character.Action();
        act_4.name = "妨害";
        act_4.action.type = CharBtlAction.ActType.jam;
        act_4.action.jamEnable = true;
        var jam_1 = CharBtlAction.Jam();
        jam_1.type = CharBtlAction.JamType.poison;
        jam_1.seedType = CharBtlAction.Jam.JamSeedType.atkNow;
        jam_1.power = 0.5;
        jam_1.turn = 3;
        act_4.action.jam.append(jam_1);
        player_char.Actions.append(act_4);

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
        jam_5.seedType = CharBtlAction.Jam.JamSeedType.atkBase;
        jam_5.power = 50.0;
        jam_5.turn = 2;
        act_5.action.jam.append(jam_5);
        player_char.Actions.append(act_5);
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
        
        var act_1 = Character.Action();
        act_1.name = "攻撃";
        act_1.action.type = CharBtlAction.ActType.atk;
        act_1.action.atkEnable = true;
        var atk_1 = CharBtlAction.Atk();
        atk_1.atkPower = 2.0;
        atk_1.atkCount = 2;
        act_1.action.atk.append(atk_1);
        enemy_char.Actions.append(act_1);
        
        var act_2 = Character.Action();
        act_2.name = "防御";
        act_2.action.type = CharBtlAction.ActType.def;
        act_2.action.defEnable = true;
        act_2.action.def.defPower = 30.0;
        enemy_char.Actions.append(act_2);
        
        var act_3 = Character.Action();
        act_3.name = "強化";
        act_3.action.type = CharBtlAction.ActType.enh;
        act_3.action.enhEnable = true;
        var enh_1 = CharBtlAction.Enh();
        enh_1.enhAtkPowerAdd = 100.0;
        act_3.action.enh.append(enh_1);
        enemy_char.Actions.append(act_3);
        
        var act_4 = Character.Action();
        act_4.name = "妨害";
        act_4.action.type = CharBtlAction.ActType.jam;
        act_4.action.jamEnable = true;
        var jam_1 = CharBtlAction.Jam();
        jam_1.type = CharBtlAction.JamType.poison;
        jam_1.seedType = CharBtlAction.Jam.JamSeedType.atkNow;
        jam_1.power = 0.5;
        jam_1.turn = 3;
        act_4.action.jam.append(jam_1);
        enemy_char.Actions.append(act_4);
        
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
        jam_5.seedType = CharBtlAction.Jam.JamSeedType.atkBase;
        jam_5.power = 50.0;
        jam_5.turn = 2;
        act_5.action.jam.append(jam_5);
        enemy_char.Actions.append(act_5);
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch in (touches as! Set<UITouch>) {
            let location = touch.locationInNode(self)

            switch(scene_status) {
                
            case SceneStatus.stock:
                
                println(rise_frame);
                
                if reach_frame < rise_frame {
                    
                    meleeStart();
                    scene_status = SceneStatus.melee;
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
                break;
                
            case SceneStatus.melee:
                
                //meleeEnd();
                //scene_status = SceneStatus.stock;
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
            var speed = rise_speed + (rise_frame / 20);
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
        
    }
    
    func updateMelee() {
        
        if meleeNextFlg {
            meleeNextFlg = false;
            if meleeProgress >= meleeBuffer.count {
                meleeEnd();
                scene_status = SceneStatus.stock;
            }
            else {
                meleeAction_Attack(meleeBuffer[meleeProgress].attacker_name
                    , target_name: meleeBuffer[meleeProgress].target_name
                    , damage: Int(meleeBuffer[meleeProgress].attack));
            }
        }
    }
    
    
    func meleeStart() {
        
        for i in 0 ..< attack_list.count {
            
            var data: MeleeData = MeleeData(
                attack: (attack_list[i] < 1) ? 1 : attack_list[i]
                , attacker_name: "player"
                , target_name:  "enemy");
            meleeBuffer.append(data);
            
            if arc4random() % 3 == 0 {
                
                var edata: MeleeData = MeleeData(
                    attack: 1 + CGFloat(arc4random() % 200)
                    , attacker_name: "enemy"
                    , target_name:  "player");
                meleeBuffer.append(edata);
            }
        }
        
        meleeProgress = 0;
        meleeNextFlg = true;
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
        
        // ゲージを初期化
        reach_frame = reach_base;
        rise_speed = rise_speed_base;
        gauge.updateProgress(100);
        
        attack_list = [];
        attack_count_lbl.text = "\(attack_list.count)"
    }

    func meleeAction_Attack(attacker_name: String, target_name: String, damage: Int) {
        let attacker = char_list[attacker_name];
        let target = char_list[target_name];
        if attacker == nil || target == nil {
            meleeAction_AttackEnd();
        }

        let basePos = attacker!.position;
        let movePos = CGPointMake(target!.position.x, target!.position.y);
        let move = SKAction.moveTo(movePos, duration: 0.1);
        let attack_effect = SKAction.runBlock { () -> Void in
            // TODO:攻撃エフェクト
            
            self.meleeAction_Damage(target_name, damage: damage);
        }
        let recoil = SKActionEx.jumpTo(startPoint: movePos
            , targetPoint: basePos
            , height: attacker!.size.height
            , duration: 0.5);
        let attack_end = SKAction.runBlock { () -> Void in
            self.meleeAction_AttackEnd();
        }
        attacker!.runAction(SKAction.sequence([move, attack_effect, recoil, attack_end]));
    }
    func meleeAction_AttackEnd() {
        meleeProgress++;
        meleeNextFlg = true;
    }
    
    func meleeAction_Damage(target_name: String, damage: Int) {
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
                
                target!.gaugeHP.updateProgress(CGFloat(target!.HP) / CGFloat(target!.HP_base) * 100);
            })
            damage_lbl.runAction(SKAction.sequence([m1, f1, dend]));
        }
    }
}
