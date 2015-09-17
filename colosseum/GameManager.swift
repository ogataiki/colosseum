import SpriteKit

final class GameManager
{
    private init() {
    }
    static let instance = GameManager()
    
    var player_character = CharManager.CharNames.hero;
    var enemy_character = CharManager.CharNames.mob;
}
