import UIKit

final class KeyboardViewController: UIInputViewController {
    private let store = ClipboardStore.shared
    private var barView: ClipboardBarView?
    private var lastReloadCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBar()
        store.load()
        reloadBar()
        observeClipboardUpdates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        barView?.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 54)
    }

    private func setupBar() {
        let bar = ClipboardBarView(frame: .zero)
        bar.onTapClip = { [weak self] item in
            self?.pasteItem(item)
        }
        bar.onClear = { [weak self] in
            self?.store.clear()
            self?.reloadBar()
        }
        bar.onOpenApp = { [weak self] in
            self?.openApp()
        }
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)
        self.barView = bar
    }

    private func reloadBar() {
        barView?.items = Array(store.allItems.prefix(10))
    }

    private func pasteItem(_ item: ClipItem) {
        UIPasteboard.general.string = item.content
        textDocumentProxy.insertText(item.content)
        Haptics.copy()
    }

    private func openApp() {
        let url = URL(string: "clipflow://")!
        if #available(iOS 10.0, *) {
            extensionContext?.open(url)
        }
    }

    private func observeClipboardUpdates() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            let current = UIPasteboard.general.changeCount
            if current != self?.lastReloadCount {
                self?.lastReloadCount = current
                self?.store.load()
                self?.reloadBar()
            }
        }
    }

    override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
        reloadBar()
    }
}
