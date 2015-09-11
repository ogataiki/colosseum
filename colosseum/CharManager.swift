import SpriteKit

final class CharManager
{
    static let instance = CharManager()
    
    private init() {
        characterInit();
    }
    
    var char_dic: [String : CharBase] = [:];
    static func getChar(name: String) -> CharBase! {
        return CharManager.instance.char_dic[name];
    }
    
    func characterInit() {
        
        let hero = CharHero();
        char_dic[hero.data.name!] = hero.data;

        let hardbodyFemale = CharHardbodyFemale();
        char_dic[hardbodyFemale.data.name!] = hardbodyFemale.data;
    }
}
