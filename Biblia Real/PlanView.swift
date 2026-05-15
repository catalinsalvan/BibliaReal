import SwiftUI

struct PlanView: View {
    let books: [Book]
    let translation: Translation
    let onNavigate: (Int, Int) -> Void   // bookId, firstChapter

    @AppStorage("planDay") private var planDay: Int = 1
    @Environment(\.dismiss) private var dismiss

    private var bookNames: [Int: String] {
        Dictionary(uniqueKeysWithValues: books.map { ($0.id, $0.name) })
    }

    private var currentDay: PlanDay {
        let idx = min(max(planDay - 1, 0), BiblePlan.fiveDayWeek.count - 1)
        return BiblePlan.fiveDayWeek[idx]
    }

    private var isComplete: Bool { planDay > 260 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressHeader

                if isComplete {
                    completionView
                } else {
                    List {
                        Section(translation.planTodayLabel) {
                            ForEach(currentDay.passages.indices, id: \.self) { i in
                                let passage = currentDay.passages[i]
                                Button {
                                    onNavigate(passage.bookId, passage.firstChapter)
                                } label: {
                                    HStack {
                                        Text(passage.label(using: bookNames))
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption.bold())
                                            .foregroundStyle(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)

                    Button(translation.planMarkRead) {
                        planDay = min(planDay + 1, 261)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(translation.planTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translation.closeLabel) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(translation.planReset) { planDay = 1 }
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Subviews

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(translation.planDayOf) \(min(planDay, 260)) \(translation.planOf260)")
                    .font(.headline)
                Spacer()
            }
            ProgressView(value: Double(min(planDay, 260)), total: 260)
                .tint(Color.accentColor)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }

    private var completionView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
            Text(translation.planComplete)
                .font(.title2.bold())
            Text(translation.planCompleteDesc)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(32)
    }
}
