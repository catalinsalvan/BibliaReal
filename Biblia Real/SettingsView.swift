import SwiftUI

struct SettingsView: View {
    @Binding var selectedTranslation: Translation
    @Binding var isPresented: Bool

    @AppStorage("fontSize")         private var fontSize: Double = 18
    @AppStorage("lineSpacing")      private var lineSpacing: Double = 12
    @AppStorage("theme")            private var theme: ReadingTheme = .white
    @AppStorage("readingFont")      private var readingFont: ReadingFont = .inter
    @AppStorage("fontSizeAlertShown") private var fontSizeAlertShown = false
    @State private var showFontSizeAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Font size
                label("Tamaño de texto")
                HStack(spacing: 10) {
                    Text("A").font(.system(size: 13)).foregroundStyle(.secondary).frame(width: 16)
                    Slider(value: $fontSize, in: 14...26, step: 2)
                    Text("A").font(.system(size: 22)).foregroundStyle(.secondary).frame(width: 24)
                }
                .padding(.bottom, 24)
                .onChange(of: fontSize) { _, _ in
                    if !fontSizeAlertShown { showFontSizeAlert = true; fontSizeAlertShown = true }
                }
                .alert("Anotaciones por tamaño", isPresented: $showFontSizeAlert) {
                    Button("Entendido") { }
                } message: {
                    Text("Cada tamaño de texto guarda sus propias anotaciones. Al cambiar el tamaño verás un lienzo limpio, pero tus notas del tamaño anterior se conservan intactas.")
                }

                divider()

                // MARK: Line spacing
                label("Espacio entre líneas")
                HStack(spacing: 10) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    Slider(value: $lineSpacing, in: 6...28, step: 2)
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                }
                .padding(.bottom, 24)

                divider()

                // MARK: Theme
                label("Tema")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(ReadingTheme.allCases) { t in
                        Button { theme = t } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(t.background)
                                        .frame(width: 36, height: 36)
                                        .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
                                    if theme == t {
                                        Circle()
                                            .stroke(Color.accentColor, lineWidth: 2.5)
                                            .frame(width: 43, height: 43)
                                    }
                                }
                                Text(t.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(theme == t ? Color.accentColor : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 24)

                divider()

                // MARK: Font
                label("Fuente")
                VStack(spacing: 0) {
                    ForEach(ReadingFont.allCases) { f in
                        Button { readingFont = f } label: {
                            HStack(spacing: 12) {
                                Text("Aa")
                                    .font(f.font(size: 18))
                                    .frame(width: 32, alignment: .leading)
                                Text(f.displayName)
                                    .font(f.font(size: 15))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if readingFont == f {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        if f != ReadingFont.allCases.last { Divider() }
                    }
                }
                .padding(.bottom, 24)

                divider()

                // MARK: Translation
                label("Traducción")
                VStack(spacing: 0) {
                    row(.rv1960)
                    Divider()
                    row(.cornilescu)
                }
            }
            .padding(20)
        }
        .frame(width: 280)
        .frame(maxHeight: 560)
        .presentationCompactAdaptation(.popover)
    }

    // MARK: - Helpers

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.bottom, 12)
    }

    private func divider() -> some View {
        Divider().padding(.bottom, 16)
    }

    private func row(_ t: Translation) -> some View {
        Button {
            selectedTranslation = t
            isPresented = false
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(t.displayName).fontWeight(.medium).foregroundStyle(.primary)
                    Text(t.language).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if selectedTranslation == t {
                    Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}
