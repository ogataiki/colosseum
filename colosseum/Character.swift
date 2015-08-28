import SpriteKit

class Character : SKSpriteNode {

    var HP_base: Int = 3000;
    var ATK_base: Int = 100;
    var DEF_base: Int = 100;

    var HP: Int = 3000;
    var ATK: Int = 100;
    var DEF: Int = 100;
    
    var gaugeHP: Gauge!;
    
    var position_base: CGPoint = CGPointZero;
}
