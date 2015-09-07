import SpriteKit

final class GameManager
{
    private init() {}
    static let instance = GameManager()
    
    enum GameMode: Int {
        case home = 0
        case game_main = 1
    }
    var game_mode = GameMode.home;
    
}
