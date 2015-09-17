import SpriteKit

final class GameManager
{
    private init() {
        player_character = CharManager.getChar(CharHero.getName());
        enemy_character = CharManager.getChar(CharMob.getName());
    }
    static let instance = GameManager()
    
    var player_character: CharBase;
    var enemy_character: CharBase;
}
