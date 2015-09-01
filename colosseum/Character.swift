import SpriteKit

class Character : SKSpriteNode {

    var HP_base: Int = 3000;
    var ATK_base: Int = 100;
    var DEF_base: Int = 100;

    var HP: Int = 3000;
    var ATK: Int = 100;
    var DEF: Int = 100;
    
    var gaugeLangeth: CGFloat = 200.0;
    var gaugeAcceleration: CGFloat = 20.0;
    
    var gaugeHP: Gauge!;
    
    var position_base: CGPoint = CGPointZero;
    
    struct Action {
        var name: String = "";
        var action = CharBtlAction();
    }
    var Actions: [Action] = [];
}
