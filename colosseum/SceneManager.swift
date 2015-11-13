import SpriteKit

final class SceneManager
{
    private init() {}
    static let instance = SceneManager()
    
    var skView: SKView!;
    
    enum Scenes: Int {
        case prologue = 0
        case home
        case char_select
        case battle
        case battle_result
        case pvp_match
    }
    var scene_buffer: [Scenes] = [];
    private func moveScene(next: Scenes) -> Bool {
        if let _ = skView {
            let tr = SKTransition.crossFadeWithDuration(0.5);
            if let scene = SceneManager.getSceneInstance(next) {
                scene.scaleMode = .AspectFill;
                scene.size = skView.frame.size;
                skView.presentScene(scene, transition: tr);
                return true;
            }
        }
        return false;
    }
    static func pushScene(next: Scenes) {
        let ins = SceneManager.instance;
        if ins.moveScene(next) {
            ins.scene_buffer.append(next);
        }
    }
    static func popScene(change: Bool = true) {
        let ins = SceneManager.instance;
        if change {
            if ins.scene_buffer.count >= 2 {
                if ins.moveScene(ins.scene_buffer[ins.scene_buffer.count-2]) {
                }
            }
        }
        if ins.scene_buffer.count == 1 {
            ins.scene_buffer.removeLast();
        }
    }
    static func changeScene(next: Scenes) {
        popScene(false);
        pushScene(next);
    }
    static func getSceneInstance(scene: Scenes) -> SKScene? {
        let sks = "GameScene";
        switch scene {
        case Scenes.prologue:
            return PrologueScene.unarchiveFromFile(sks) as? PrologueScene;
        case Scenes.home:
            return HomeScene.unarchiveFromFile(sks) as? HomeScene;
        case Scenes.char_select:
            return CharSelectScene.unarchiveFromFile(sks) as? CharSelectScene;
        case Scenes.battle:
            return BattleScene.unarchiveFromFile(sks) as? BattleScene;
        case Scenes.battle_result:
            return BattleResultScene.unarchiveFromFile(sks) as? BattleResultScene;
        case Scenes.pvp_match:
            return PvPMatchScene.unarchiveFromFile(sks) as? PvPMatchScene;            
        }
    }
}
