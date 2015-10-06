import SpriteKit

final class CharManager
{
    static let instance = CharManager()
    
    private init() {
    }
    
    enum CharNames: String {
        case hero = "Hero"
        case mob = "Mob"
        case hardbodyFemale = "HardbodyFemale"
        case fat = "Fat"
        case poorHealth = "PoorHealth"
        case ugly = "Ugly"
        case tease = "Tease"
        case toxic = "Toxic"
        case elite = "Elite"
        case majority = "Majority"
    }
    static func cnvStringToCharNames(name: String) -> CharManager.CharNames? {
        switch name {
        case CharManager.CharNames.hero.rawValue:
            return CharManager.CharNames.hero;
        case CharManager.CharNames.mob.rawValue:
            return CharManager.CharNames.mob;
        case CharManager.CharNames.hardbodyFemale.rawValue:
            return CharManager.CharNames.hardbodyFemale;
        case CharManager.CharNames.fat.rawValue:
            return CharManager.CharNames.fat;
        case CharManager.CharNames.poorHealth.rawValue:
            return CharManager.CharNames.poorHealth;
        case CharManager.CharNames.ugly.rawValue:
            return CharManager.CharNames.ugly;
        case CharManager.CharNames.tease.rawValue:
            return CharManager.CharNames.tease;
        case CharManager.CharNames.toxic.rawValue:
            return CharManager.CharNames.toxic;
        case CharManager.CharNames.elite.rawValue:
            return CharManager.CharNames.elite;
        case CharManager.CharNames.majority.rawValue:
            return CharManager.CharNames.majority;
        default:
            return nil;
        }
    }
    static func getChar(name: String) -> CharBase {
        switch name {
        case CharNames.mob.rawValue:                return CharMob().data;
        case CharNames.hardbodyFemale.rawValue:     return CharHardbodyFemale().data;
        case CharNames.fat.rawValue:                return CharFat().data;
        default:                                    return CharHero().data;
        }
    }
    
    
    /*
    　主人公
    　　特徴がない。全てにおいて平均的。(ユーザの影となる扱いの為)
    　
    　筋肉女「マリー」
    　　筋肉がコンプレックス。
    　　コンプレックスと向き合うためにコロシアムに参加。
    　　攻撃が得意。
    　
    　デブ男「ファド」
    　　デブでモテないのがコンプレックス。
    　　とても卑屈で話しているとイライラする。
    　　防御が得意。
    　
    　病弱賢人のおっさん「パーヘル」
    　　病弱がコンプレックス。
    　　頭が良いので心の中では常に人を見下している。
    　　妨害が得意。
    　
    　ブサイク男「ウーグ」
    　　ブサイクがコンプレックス。
    　　あまりにもモテない反動で女性を見下す態度をとってしまう。
    　　ある宗教団体に所属しており、強くなりモテると噂の怪しい薬に手を出している。
    　　強化が得意。
    　
    　いじめられた男「ティーズ」
    　　義務教育時期にいじめられたため他人が怖い。
    　　その経験から人が苦しんでいるのを見るのが快感となった。
    　　攻撃と防御がやや得意。
    　　
    　親切美女「トクスィ」
    　　幼い頃に毒親に身勝手な愛情を受けたため歪んだ性格をしている。
    　　普段は物腰柔らかで美しい人だが優しさが拒否されるとヒステリーをおこす。
    　　強化と妨害がやや得意。
    　　
    　エリート男「ユーリード」
    　　エリート一家にて一人だけ冴えなかったことがコンプレックス。
    　　親も扱いに困りあまり愛されなかったことで態度が大きい寂しがり屋となった。
    　　得意不得意はない。
    　　
    　マジョリティ女「マーショリー」
    　　自分がなく常に多数派の意見に流される。
    　　多数派が正しいと思い込んでおり少数派の意見にはとても攻撃的になる。
    　　妨害が得意、強化がやや得意、防御がやや苦手。

    */
}
