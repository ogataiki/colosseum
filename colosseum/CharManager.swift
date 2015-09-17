import SpriteKit

final class CharManager
{
    static let instance = CharManager()
    
    private init() {
    }
    
    enum CharNames: String {
        case mob = "Mob"
        case hero = "Hero"
        case hardbodyFemale = "HardbodyFemale"
    }
    static func getChar(name: String) -> CharBase {
        switch name {
        case CharNames.mob.rawValue:              return CharMob().data;
        case CharNames.hardbodyFemale.rawValue:   return CharHardbodyFemale().data;
        default: return CharHero().data;
        }
    }
}
