import SpriteKit

class GameScene: SKScene {
    
    enum SceneStatus: Int {
        case gauge_stop = 1
        case melee = 2
    }
    var scene_status = SceneStatus.gauge_stop;
    
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
    
    var player_char: SKSpriteNode!;
    var enemy_char: SKSpriteNode!;
    var char_list: [String : SKSpriteNode] = [:];
    
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
        
        
        player_char = SKSpriteNode(imageNamed: "TestChar1");
        player_char.position = CGPointMake(self.size.width*0.85, self.size.height*0.9);
        player_char.xScale = -1.0;
        player_char.name = "player";
        self.addChild(player_char);
        char_list[player_char.name!] = player_char;

        enemy_char = SKSpriteNode(imageNamed: "TestChar2");
        enemy_char.position = CGPointMake(self.size.width*0.15, self.size.height*0.9);
        enemy_char.name = "enemy";
        self.addChild(enemy_char);
        char_list[enemy_char.name!] = enemy_char;
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch in (touches as! Set<UITouch>) {
            let location = touch.locationInNode(self)

            switch(scene_status) {
                
            case SceneStatus.gauge_stop:
                
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
                
                
            case SceneStatus.melee:
                
                meleeEnd();
                
                scene_status = SceneStatus.gauge_stop;
            }

        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        switch(scene_status) {
        case SceneStatus.gauge_stop:
            updateGaugeStop();
        case SceneStatus.melee:
            updateMelee();
        }
    }
    
    func updateGaugeStop() {
        
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
    
    func updateMelee() {
        
        if meleeNextFlg {
            meleeNextFlg = false;
            if meleeProgress >= meleeBuffer.count {
                meleeEnd();
                scene_status = SceneStatus.gauge_stop;
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
        }
        
        meleeProgress = 0;
        meleeNextFlg = true;
    }
    func meleeEnd() {
        
        // 乱戦状態のデータを初期化
        for i in 0 ..< char_list.count {
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
            })
            damage_lbl.runAction(SKAction.sequence([m1, f1, dend]));
        }
    }
}
