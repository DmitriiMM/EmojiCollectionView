import UIKit
import CoreData

enum EmojiMixStoreError: Error {
    case decodingErrorInvalidEmojies
    case decodingErrorInvalidColorHex
}

struct EmojiMixStoreUpdate {
    struct Move: Hashable {
        let oldIndex: Int
        let newIndex: Int
    }
    let insertedIndexes: IndexSet
    let deletedIndexes: IndexSet
    let updatedIndexes: IndexSet
    let movedIndexes: Set<Move>
}

protocol EmojiMixStoreDelegate: AnyObject {
    func store(_ store: EmojiMixStore, didUpdate update: EmojiMixStoreUpdate)
}

final class EmojiMixStore: NSObject {
    private let context: NSManagedObjectContext
    private let uiColorMarshalling = UIColorMarshalling()
    weak var delegate: EmojiMixStoreDelegate?
    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?
    private var updatedIndexes: IndexSet?
    private var movedIndexes: Set<EmojiMixStoreUpdate.Move>?

    
    private lazy var fetchedResultsController: NSFetchedResultsController<EmojiMixCoreData> = {
        let fetchRequest = NSFetchRequest<EmojiMixCoreData>(entityName: "EmojiMixCoreData")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \EmojiMixCoreData.emojies, ascending: true)
        ]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
        
        return fetchedResultsController
    }()
    
    convenience override init() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistantConteiner.viewContext
        self.init(context: context)
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    var emojiMixes: [EmojiMix] {
        guard
            let objects = self.fetchedResultsController.fetchedObjects,
            let emojiMixes = try? objects.map({ try self.emojiMix(from: $0) })
        else { return [] }
        return emojiMixes
    }
    
    func addNewEmojiMix(_ emojiMix: EmojiMix) throws {
        let newEmojiMix = EmojiMixCoreData(context: context)
        newEmojiMix.emojies = emojiMix.emojies
        newEmojiMix.colorHex = uiColorMarshalling.hexString(from: emojiMix.backgroundColor)
        
        try context.save()
    }
    
    func updateExistingEmojiMix(_ emojiMixCorData: EmojiMixCoreData, with mix: EmojiMix) {
        emojiMixCorData.emojies = mix.emojies
        emojiMixCorData.colorHex = uiColorMarshalling.hexString(from: mix.backgroundColor)
    }

    func emojiMix(from emojiMixCorData: EmojiMixCoreData) throws -> EmojiMix {
        guard let emojies = emojiMixCorData.emojies else {
            throw EmojiMixStoreError.decodingErrorInvalidEmojies
        }
        guard let colorHex = emojiMixCorData.colorHex else {
            throw EmojiMixStoreError.decodingErrorInvalidEmojies
        }
        return EmojiMix(
            emojies: emojies,
            backgroundColor: uiColorMarshalling.color(from: colorHex)
        )
    }
}

extension EmojiMixStore: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexes = IndexSet()
        deletedIndexes = IndexSet()
        updatedIndexes = IndexSet()
        movedIndexes = Set<EmojiMixStoreUpdate.Move>()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.store(
            self,
            didUpdate: EmojiMixStoreUpdate(
                insertedIndexes: insertedIndexes!,
                deletedIndexes: deletedIndexes!,
                updatedIndexes: updatedIndexes!,
                movedIndexes: movedIndexes!
            )
        )
        insertedIndexes = nil
        deletedIndexes = nil
        updatedIndexes = nil
        movedIndexes = nil
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        switch type {
        case .insert:
            guard let indexPath = newIndexPath else { fatalError() }
            insertedIndexes?.insert(indexPath.item)
        case .delete:
            guard let indexPath = indexPath else { fatalError() }
            deletedIndexes?.insert(indexPath.item)
        case .update:
            guard let indexPath = indexPath else { fatalError() }
            updatedIndexes?.insert(indexPath.item)
        case .move:
            guard let oldIndexPath = indexPath, let newIndexPath = newIndexPath else { fatalError() }
            movedIndexes?.insert(.init(oldIndex: oldIndexPath.item, newIndex: newIndexPath.item))
        @unknown default:
            fatalError()
        }
    }
}
