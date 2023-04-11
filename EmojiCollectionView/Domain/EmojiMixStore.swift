import UIKit
import CoreData

class EmojiMixStore {
    private let context: NSManagedObjectContext
    private let uiColorMarshalling = UIColorMarshalling()
    
    convenience init() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistantConteiner.viewContext
        self.init(context: context)
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func addNewEmojiMix(_ emojiMix: EmojiMix) throws {
        let newEmojiMix = EmojiMixCoreData(context: context)
        newEmojiMix.emojies = emojiMix.emojies
        newEmojiMix.colorHex = uiColorMarshalling.hexString(from: emojiMix.backgroundColor)
        
        try context.save()
    }
}
