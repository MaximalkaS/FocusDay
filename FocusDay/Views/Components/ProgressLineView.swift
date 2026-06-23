import SwiftUI

struct ProgressLineView: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.softBlue.opacity(0.55))

                Capsule()
                    .fill(AppTheme.primaryBlue)
                    .frame(width: max(0, min(proxy.size.width, proxy.size.width * value)))
            }
        }
        .frame(height: 10)
        .accessibilityValue(Text("\(Int(value * 100))%"))
    }
}

#if DEBUG
#Preview {
    ProgressLineView(value: 0.65)
        .padding()
}
#endif
