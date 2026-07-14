import UIKit

final class ClipboardBarView: UIView {
    var items: [ClipItem] = [] { didSet { collectionView.reloadData(); updateEmptyState() } }
    var onTapClip: ((ClipItem) -> Void)?
    var onClear: (() -> Void)?
    var onOpenApp: (() -> Void)?

    private let collectionView: UICollectionView
    private let emptyLabel = UILabel()
    private let clearButton = UIButton(type: .system)
    private let pipButton = UIButton(type: .system)
    private let logoLabel = UILabel()
    private let accentLine = UIView()

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 6
        layout.itemSize = CGSize(width: 132, height: 36)
        layout.sectionInset = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { nil }

    private func setupViews() {
        backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1)

        // Orange accent line at top
        accentLine.backgroundColor = UIColor.systemOrange
        accentLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(accentLine)

        // Logo
        logoLabel.text = "CF"
        logoLabel.font = roundedFont(ofSize: 12, weight: .bold)
        logoLabel.textColor = UIColor.systemOrange.withAlphaComponent(0.9)
        logoLabel.textAlignment = .center
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(logoLabel)

        // Collection
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.clipsToBounds = false
        collectionView.register(ClipCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)

        // Empty label
        emptyLabel.text = "\u{1F4CB} ClipFlow prêt"
        emptyLabel.font = roundedFont(ofSize: 12, weight: .medium)
        emptyLabel.textColor = UIColor.white.withAlphaComponent(0.2)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emptyLabel)

        // Clear button
        clearButton.setImage(UIImage(systemName: "trash"), for: .normal)
        clearButton.tintColor = UIColor.red.withAlphaComponent(0.5)
        clearButton.addTarget(self, action: #selector(didTapClear), for: .touchUpInside)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(clearButton)

        // PiP button
        pipButton.setImage(UIImage(systemName: "pip.fill"), for: .normal)
        pipButton.tintColor = UIColor.systemOrange.withAlphaComponent(0.5)
        pipButton.addTarget(self, action: #selector(didTapOpenApp), for: .touchUpInside)
        pipButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pipButton)

        NSLayoutConstraint.activate([
            accentLine.topAnchor.constraint(equalTo: topAnchor),
            accentLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            accentLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            accentLine.heightAnchor.constraint(equalToConstant: 1.5),

            logoLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            logoLabel.centerXAnchor.constraint(equalTo: clearButton.centerXAnchor),

            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 44),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -44),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),

            clearButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 26),
            clearButton.heightAnchor.constraint(equalToConstant: 26),

            pipButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            pipButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            pipButton.widthAnchor.constraint(equalToConstant: 26),
            pipButton.heightAnchor.constraint(equalToConstant: 26),
        ])

        updateEmptyState()
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !items.isEmpty
    }

    @objc private func didTapClear() { onClear?(); UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    @objc private func didTapOpenApp() { onOpenApp?(); UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}

private func roundedFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
    let base = UIFont.systemFont(ofSize: size, weight: weight)
    let descriptor = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
    return UIFont(descriptor: descriptor, size: size)
}

// MARK: - Collection View

extension ClipboardBarView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int { items.count }

    func collectionView(_: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ClipCell
        cell.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onTapClip?(items[indexPath.item])
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

final class ClipCell: UICollectionViewCell {
    private let label = UILabel()
    private let iconView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1)
        contentView.layer.cornerRadius = 10
        contentView.layer.borderWidth = 0.5
        contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.06).cgColor

        iconView.tintColor = UIColor.systemOrange
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)

        label.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.85)
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 5),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(with item: ClipItem) {
        iconView.image = UIImage(systemName: item.type.icon)
        label.text = item.preview
        if item.isPinned {
            contentView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
            contentView.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.15).cgColor
        } else {
            contentView.backgroundColor = UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1)
            contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.06).cgColor
        }
    }
}
