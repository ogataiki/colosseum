import SpriteKit

final class GameManager
{
    private init() {
    }
    static let instance = GameManager()
    
    var player_character = CharManager.CharNames.hero;
    var enemy_character = CharManager.CharNames.mob;
    
    static func getBattleCharList() -> [CharBase] {
        return [
            CharManager.getChar(CharManager.CharNames.mob.rawValue),
            CharManager.getChar(CharManager.CharNames.hardbodyFemale.rawValue),
            CharManager.getChar(CharManager.CharNames.fat.rawValue),
        ];
    }
}
