import SwiftUI
import PencilKit

// MARK: - Pencil Highlight Detector
// ONE instance covers the entire text column (not one per verse).
// hitTest returns nil for finger touches → scroll / long-press / context menus
// reach SwiftUI content unaffected. Pencil position is matched against
// verse frames collected in the "textColumn" named coordinate space.

final class PencilHighlightDetectorView: UIView {
    var onPencilAt: ((CGPoint) -> Void)?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(point) else { return nil }
        if event?.allTouches?.first?.type == .pencil { return self }
        return nil
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, t.type == .pencil else { return }
        onPencilAt?(t.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, t.type == .pencil else { return }
        onPencilAt?(t.location(in: self))
    }
}

struct PencilHighlightDetector: UIViewRepresentable {
    var verseFrames: [Int: CGRect]
    var onHighlightVerse: (Int) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PencilHighlightDetectorView {
        let v = PencilHighlightDetectorView()
        v.backgroundColor = .clear
        let coordinator = context.coordinator
        v.onPencilAt = { point in coordinator.pencilAt(point) }
        return v
    }

    func updateUIView(_ uiView: PencilHighlightDetectorView, context: Context) {
        context.coordinator.parent = self
    }

    class Coordinator {
        var parent: PencilHighlightDetector
        init(_ p: PencilHighlightDetector) { parent = p }

        func pencilAt(_ point: CGPoint) {
            for (num, frame) in parent.verseFrames where frame.contains(point) {
                parent.onHighlightVerse(num)
                return
            }
        }
    }
}

// MARK: - Swipe Detector

struct SwipeDetectorView: UIViewRepresentable {
    var onSwipeLeft: (() -> Void)? = nil
    var onSwipeRight: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan)
        )
        pan.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: SwipeDetectorView
        init(_ parent: SwipeDetectorView) { self.parent = parent }

        func gestureRecognizerShouldBegin(_ gr: UIGestureRecognizer) -> Bool {
            guard let pan = gr as? UIPanGestureRecognizer else { return true }
            let v = pan.velocity(in: pan.view)
            return abs(v.x) > abs(v.y) * 2.0
        }

        func gestureRecognizer(_ gr: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

        @objc func handlePan(_ pan: UIPanGestureRecognizer) {
            guard pan.state == .ended else { return }
            let t = pan.translation(in: pan.view)
            guard abs(t.x) > 60 else { return }
            if t.x < 0 { parent.onSwipeLeft?() } else { parent.onSwipeRight?() }
        }
    }
}

struct PencilCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var backgroundColor: UIColor = .clear
    var toolPicker: PKToolPicker
    /// Full chapter height — sets the canvas content size so the whole
    /// chapter is drawable even though the canvas frame is screen-sized.
    var scrollContentHeight: CGFloat? = nil
    /// When set, the canvas viewport is driven programmatically to stay in
    /// sync with the text column's current scroll offset.
    var syncedScrollOffset: CGFloat? = nil
    /// Called when the user scrolls the margin with a finger so the text
    /// column can be scrolled to the same position.
    var onMarginScrolled: ((CGFloat) -> Void)? = nil
    var onSwipeLeft: (() -> Void)? = nil
    var onSwipeRight: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.backgroundColor = backgroundColor
        canvas.isOpaque = backgroundColor != .clear
        canvas.drawingPolicy = .pencilOnly
        // Enable scroll when a content height is provided (landscape margin).
        // Finger scrolls fire scrollViewDidScroll → onMarginScrolled → text column
        // mirrors the offset. Programmatic setContentOffset is guarded by
        // isProgrammaticScroll so the delegate callback doesn't echo back.
        canvas.isScrollEnabled = scrollContentHeight != nil
        canvas.showsVerticalScrollIndicator = false
        canvas.showsHorizontalScrollIndicator = false
        canvas.alwaysBounceVertical = false
        canvas.delegate = context.coordinator

        toolPicker.addObserver(canvas)
        toolPicker.setVisible(true, forFirstResponder: canvas)
        canvas.becomeFirstResponder()

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan)
        )
        pan.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        pan.delegate = context.coordinator
        canvas.addGestureRecognizer(pan)

        return canvas
    }

    static func dismantleUIView(_ uiView: PKCanvasView, coordinator: Coordinator) {
        coordinator.parent.toolPicker.setVisible(false, forFirstResponder: uiView)
        coordinator.parent.toolPicker.removeObserver(uiView)
        uiView.resignFirstResponder()
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing { uiView.drawing = drawing }
        uiView.backgroundColor = backgroundColor
        uiView.isOpaque = backgroundColor != .clear
        // Keep content size in sync so the full chapter is drawable.
        if let h = scrollContentHeight, uiView.frame.width > 0 {
            let needed = CGSize(width: uiView.frame.width, height: h)
            if uiView.contentSize != needed { uiView.contentSize = needed }
        }
        // Mirror the text column scroll position — no gesture scrolling needed.
        if let offset = syncedScrollOffset {
            let target = CGPoint(x: 0, y: max(0, offset))
            if uiView.contentOffset != target {
                context.coordinator.isProgrammaticScroll = true
                uiView.setContentOffset(target, animated: false)
                context.coordinator.isProgrammaticScroll = false
            }
        }
        context.coordinator.parent = self
    }

    class Coordinator: NSObject, PKCanvasViewDelegate, UIGestureRecognizerDelegate {
        var parent: PencilCanvasView
        var isProgrammaticScroll = false

        init(_ parent: PencilCanvasView) { self.parent = parent }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !isProgrammaticScroll else { return }
            parent.onMarginScrolled?(scrollView.contentOffset.y)
        }

        // Only begin if the motion is clearly horizontal
        func gestureRecognizerShouldBegin(_ gr: UIGestureRecognizer) -> Bool {
            guard let pan = gr as? UIPanGestureRecognizer else { return true }
            let v = pan.velocity(in: pan.view)
            return abs(v.x) > abs(v.y) * 2.0
        }

        // Allow the scroll view to scroll at the same time
        func gestureRecognizer(_ gr: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            return true
        }

        @objc func handlePan(_ pan: UIPanGestureRecognizer) {
            guard pan.state == .ended else { return }
            let t = pan.translation(in: pan.view)
            guard abs(t.x) > 60 else { return }
            if t.x < 0 { parent.onSwipeLeft?() } else { parent.onSwipeRight?() }
        }
    }
}
