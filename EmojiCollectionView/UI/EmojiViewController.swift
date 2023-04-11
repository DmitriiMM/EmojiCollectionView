import UIKit

final class EmojiViewController: UIViewController {
    private var visibleEmojies: [EmojiMix] = []
    private let emojiFactory = EmojiMixFactory()
    private let emojiStore = EmojiMixStore()

    private let collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewFlowLayout()
        )
        collectionView.register(EmojiCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let navBar = navigationController?.navigationBar {
            let rightButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNextEmoji))
            navBar.topItem?.setRightBarButton(rightButton, animated: false)

//            let leftButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(removeLastEmoji))
//            navBar.topItem?.setLeftBarButton(leftButton, animated: false)
        }
        setupCollectionView()
        emojiStore.delegate = self
        visibleEmojies = emojiStore.emojiMixes
    }

    @objc
    private func addNextEmoji() {
        let newMix = emojiFactory.makeNewMix()
        try! emojiStore.addNewEmojiMix(newMix)
    }

//    @objc
//    private func removeLastEmoji() {
//        guard visibleEmojies.count > 0 else { return }
//
//        let lastEmojiIndex = visibleEmojies.count - 1
//        visibleEmojies.removeLast()
//        collectionView.performBatchUpdates {
//            collectionView.deleteItems(at: [IndexPath(item: lastEmojiIndex, section: 0)])
//        }
//    }

    private func setupCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        collectionView.dataSource = self
        collectionView.delegate = self
    }
}

extension EmojiViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleEmojies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! EmojiCollectionViewCell
        
        cell.titleLabel.text = visibleEmojies[indexPath.row].emojies
        cell.contentView.backgroundColor = visibleEmojies[indexPath.row].backgroundColor
        
        return cell
    }
}

extension EmojiViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
}

extension EmojiViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width / 2 - 5, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}

extension EmojiViewController: EmojiMixStoreDelegate {
    func store(_ store: EmojiMixStore, didUpdate update: EmojiMixStoreUpdate) {
        visibleEmojies = emojiStore.emojiMixes
        collectionView.performBatchUpdates {
            let insertedIndexPaths = update.insertedIndexes.map { IndexPath(item: $0, section: 0) }
            let deletedIndexPaths = update.deletedIndexes.map { IndexPath(item: $0, section: 0) }
            let updatedIndexPaths = update.updatedIndexes.map { IndexPath(item: $0, section: 0) }
            collectionView.insertItems(at: insertedIndexPaths)
            collectionView.insertItems(at: deletedIndexPaths)
            collectionView.insertItems(at: updatedIndexPaths)
            for move in update.movedIndexes {
                collectionView.moveItem(
                    at: IndexPath(item: move.oldIndex, section: 0),
                    to: IndexPath(item: move.newIndex, section: 0)
                )
            }
        }
    }
}
