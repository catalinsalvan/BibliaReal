import SwiftUI
import PencilKit

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
    var onSwipeLeft: (() -> Void)? = nil
    var onSwipeRight: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.backgroundColor = backgroundColor
        canvas.isOpaque = backgroundColor != .clear
        canvas.drawingPolicy = .pencilOnly
        canvas.isScrollEnabled = false
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
        context.coordinator.parent = self
    }

    class Coordinator: NSObject, PKCanvasViewDelegate, UIGestureRecognizerDelegate {
        var parent: PencilCanvasView

        init(_ parent: PencilCanvasView) { self.parent = parent }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
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
