import SpriteKit

final class SceneManager
{
    private init() {}
    static let instance = SceneManager()
    
    enum Scenes: Int {
        case prologue = 0
        case home
        case char_select
        case story_battle_befor
        case battle
        case story_battle_after
        case battle_result
        case pvp_match
    }
    var now_scene = Scenes.prologue;
}
