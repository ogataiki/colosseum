import SpriteKit

final class CharManager
{
    static let instance = CharManager()
    
    private init() {
        characterInit();
    }
    
    var char_dic: [String : Character] = [:];
    static func getCharacter(name: String) -> Character! {
        return CharManager.instance.char_dic[name];
    }
    
    func characterInit() {
        
        let hero = CharacterHero();
        char_dic[hero.data.name!] = hero.data;

        let hardbodyFemale = CharacterHardbodyFemale();
        char_dic[hardbodyFemale.data.name!] = hardbodyFemale.data;
    }
}
