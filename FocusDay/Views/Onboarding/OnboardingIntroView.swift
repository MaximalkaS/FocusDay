import SwiftUI

struct OnboardingIntroView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage: OnboardingIntroPage = .welcome
    @Namespace private var indicatorNamespace

    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(OnboardingIntroPage.allCases) { page in
                        OnboardingIntroPageContent(page: page, isCompact: isCompact(geometry))
                            .tag(page)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(introAnimation, value: currentPage)

                pageIndicator
                    .padding(.top, 6)
                    .padding(.bottom, currentPage == .premium ? 16 : 28)

                actionButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(14, geometry.safeAreaInsets.bottom + 8))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.screenBackground.ignoresSafeArea())
        }
        .preferredColorScheme(.light)
    }

    private var pageIndicator: some View {
        HStack(spacing: 14) {
            ForEach(OnboardingIntroPage.allCases) { page in
                Circle()
                    .fill(page == currentPage ? AppTheme.primaryBlue : Color(hex: "CBD5E1"))
                    .frame(width: 8, height: 8)
                    .matchedGeometryEffect(id: page.id, in: indicatorNamespace)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: currentPage)
        .accessibilityLabel(LocalizedStrings.onboardingIntroPageIndicator(currentPage.rawValue + 1, OnboardingIntroPage.allCases.count))
    }

    @ViewBuilder
    private var actionButtons: some View {
        if currentPage == .premium {
            VStack(spacing: 10) {
                primaryButton(title: LocalizedStrings.onboardingIntroTryPremium) {
                    finishIntro()
                }

                secondaryButton(title: LocalizedStrings.onboardingIntroContinueFree) {
                    finishIntro()
                }
            }
        } else {
            primaryButton(title: LocalizedStrings.continueTitle) {
                advance()
            }
        }
    }

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.primaryButton)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 58)
                .background(
                    LinearGradient(
                        colors: [AppTheme.primaryBlue, Color(hex: "0A6BFF")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.primaryButton)
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 58)
                .background(Color.white)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.primaryBlue, lineWidth: 1.4)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func advance() {
        guard let nextPage = currentPage.next else { return }
        withAnimation(introAnimation) {
            currentPage = nextPage
        }
    }

    private func finishIntro() {
        onFinish()
    }

    private func isCompact(_ geometry: GeometryProxy) -> Bool {
        geometry.size.height < 720 || geometry.size.width <= 340
    }

    private var introAnimation: Animation? {
        reduceMotion ? .easeInOut(duration: 0.16) : .easeInOut(duration: 0.32)
    }
}

private enum OnboardingIntroPage: Int, CaseIterable, Identifiable {
    case welcome
    case howItWorks
    case premium

    var id: Int { rawValue }

    var next: OnboardingIntroPage? {
        OnboardingIntroPage(rawValue: rawValue + 1)
    }
}

private struct OnboardingIntroPageContent: View {
    let page: OnboardingIntroPage
    let isCompact: Bool

    var body: some View {
        Group {
            if isCompact && page != .premium {
                ScrollView {
                    pageBody
                        .padding(.bottom, 12)
                }
                .scrollIndicators(.hidden)
            } else {
                pageBody
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var pageBody: some View {
        switch page {
        case .welcome:
            WelcomeIntroPage(isCompact: isCompact)
        case .howItWorks:
            HowItWorksIntroPage(isCompact: isCompact)
        case .premium:
            PremiumIntroPage(isCompact: isCompact)
        }
    }
}

private struct WelcomeIntroPage: View {
    let isCompact: Bool

    var body: some View {
        VStack(spacing: isCompact ? 18 : 26) {
            Spacer(minLength: isCompact ? 26 : 72)

            VStack(spacing: 14) {
                Text(LocalizedStrings.appName)
                    .font(.system(size: isCompact ? 38 : 42, weight: .bold))
                    .foregroundStyle(Color(hex: "0F172A"))
                    .multilineTextAlignment(.center)

                Text(LocalizedStrings.onboardingIntroWelcomeSubtitle)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(hex: "53627D"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: isCompact ? 14 : 28)

            Image("onboardingImage")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 340)
                .frame(height: isCompact ? 300 : 370)
                .accessibilityHidden(true)

            Spacer(minLength: isCompact ? 4 : 18)
        }
        .frame(maxWidth: .infinity, maxHeight: isCompact ? nil : .infinity)
    }
}

private struct HowItWorksIntroPage: View {
    let isCompact: Bool

    var body: some View {
        VStack(spacing: isCompact ? 16 : 22) {
            Spacer(minLength: isCompact ? 18 : 62)

            VStack(spacing: 14) {
                Text(LocalizedStrings.onboardingIntroHowTitle)
                    .font(.system(size: isCompact ? 24 : 28, weight: .bold))
                    .foregroundStyle(Color(hex: "0F172A"))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(LocalizedStrings.onboardingIntroHowSubtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "53627D"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: isCompact ? 12 : 16) {
                IntroFeatureCard(
                    icon: "target",
                    title: LocalizedStrings.onboardingIntroMainTaskTitle,
                    text: LocalizedStrings.onboardingIntroMainTaskText
                )
                IntroFeatureCard(
                    icon: "chart.bar",
                    title: LocalizedStrings.onboardingIntroProgressTitle,
                    text: LocalizedStrings.onboardingIntroProgressText
                )
                IntroFeatureCard(
                    icon: "checklist.checked",
                    title: LocalizedStrings.onboardingIntroEveningTitle,
                    text: LocalizedStrings.onboardingIntroEveningText
                )
            }

            Spacer(minLength: isCompact ? 4 : 18)
        }
        .frame(maxWidth: .infinity, maxHeight: isCompact ? nil : .infinity)
    }
}

private struct PremiumIntroPage: View {
    let isCompact: Bool

    var body: some View {
        VStack(spacing: isCompact ? 14 : 18) {
            Spacer(minLength: isCompact ? 16 : 42)

            VStack(spacing: 14) {
                Text(LocalizedStrings.onboardingIntroPremiumTitle)
                    .font(.system(size: isCompact ? 25 : 29, weight: .bold))
                    .foregroundStyle(Color(hex: "0F172A"))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(LocalizedStrings.onboardingIntroPremiumSubtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "53627D"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: isCompact ? 9 : 12) {
                IntroPremiumCard(
                    icon: "chart.bar.xaxis",
                    title: LocalizedStrings.onboardingIntroAllHistoryTitle,
                    text: LocalizedStrings.onboardingIntroAllHistoryText
                )
                IntroPremiumCard(
                    icon: "magnifyingglass",
                    title: LocalizedStrings.onboardingIntroSearchTitle,
                    text: LocalizedStrings.onboardingIntroSearchText
                )
                IntroPremiumCard(
                    icon: "rectangle.grid.2x2",
                    title: LocalizedStrings.onboardingIntroWidgetsTitle,
                    text: LocalizedStrings.onboardingIntroWidgetsText
                )
            }

            Spacer(minLength: isCompact ? 2 : 8)
        }
        .frame(maxWidth: .infinity, maxHeight: isCompact ? nil : .infinity)
    }
}

private struct IntroFeatureCard: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(spacing: 18) {
            IntroIcon(systemName: icon, size: 38)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "0F172A"))
                    .fixedSize(horizontal: false, vertical: true)

                Text(text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "53627D"))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color(hex: "2563EB").opacity(0.08), radius: 16, x: 0, y: 8)
    }
}

private struct IntroPremiumCard: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            IntroIcon(systemName: icon, size: 30)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "0F172A"))
                    .fixedSize(horizontal: false, vertical: true)

                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "53627D"))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color(hex: "2563EB").opacity(0.07), radius: 14, x: 0, y: 7)
    }
}

private struct IntroIcon: View {
    let systemName: String
    let size: CGFloat

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .regular))
            .foregroundStyle(AppTheme.primaryBlue)
            .frame(width: 72, height: 72)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "EAF4FF"), Color(hex: "D8EAFF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }
}

private struct FocusMountainIllustration: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Circle()
                .fill(Color(hex: "DCEEFF"))
                .frame(width: 285, height: 285)
                .offset(y: -28)

            Cloud(width: 70, height: 28)
                .offset(x: -122, y: -140)
            Cloud(width: 62, height: 26)
                .offset(x: 128, y: -220)

            MountainShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "B8D8FF"), Color(hex: "EAF4FF")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 238, height: 230)
                .offset(x: -18, y: -10)

            Path { path in
                path.move(to: CGPoint(x: 0, y: 42))
                path.addCurve(to: CGPoint(x: 54, y: 88), control1: CGPoint(x: 48, y: 46), control2: CGPoint(x: 46, y: 72))
                path.addCurve(to: CGPoint(x: 38, y: 154), control1: CGPoint(x: 66, y: 112), control2: CGPoint(x: 16, y: 118))
                path.addCurve(to: CGPoint(x: 88, y: 218), control1: CGPoint(x: 62, y: 188), control2: CGPoint(x: 98, y: 188))
            }
            .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 24, lineCap: .round, lineJoin: .round))
            .frame(width: 140, height: 240)
            .offset(x: -36, y: -4)

            FlagIllustration()
                .frame(width: 72, height: 95)
                .offset(x: 18, y: -216)

            PlantIllustration()
                .frame(width: 88, height: 140)
                .offset(x: -118, y: -8)

            ChecklistIllustration()
                .frame(width: 118, height: 140)
                .offset(x: 104, y: -44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MountainShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.38))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.58, y: rect.minY + rect.height * 0.48))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.05))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct FlagIllustration: View {
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(AppTheme.primaryBlue)
                .frame(width: 4, height: 92)
                .offset(x: 2)

            Path { path in
                path.move(to: CGPoint(x: 6, y: 4))
                path.addCurve(to: CGPoint(x: 58, y: 8), control1: CGPoint(x: 24, y: -8), control2: CGPoint(x: 42, y: 10))
                path.addCurve(to: CGPoint(x: 8, y: 32), control1: CGPoint(x: 46, y: 28), control2: CGPoint(x: 26, y: 34))
                path.closeSubpath()
            }
            .fill(AppTheme.primaryBlue)
            .offset(y: 2)
        }
    }
}

private struct ChecklistIllustration: View {
    var body: some View {
        VStack(spacing: 13) {
            HStack(spacing: 12) {
                Circle()
                    .fill(AppTheme.primaryBlue)
                    .frame(width: 24, height: 24)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                Capsule()
                    .fill(Color(hex: "BBD7FF"))
                    .frame(width: 52, height: 6)
            }

            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: 12) {
                    Circle()
                        .stroke(Color(hex: "BBD7FF"), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    Capsule()
                        .fill(Color(hex: "D7E7FF"))
                        .frame(width: 52, height: 6)
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color(hex: "2563EB").opacity(0.12), radius: 18, x: 0, y: 10)
    }
}

private struct PlantIllustration: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: "C9DFFF"))
                .frame(width: 48, height: 28)

            Path { path in
                path.move(to: CGPoint(x: 44, y: 118))
                path.addCurve(to: CGPoint(x: 34, y: 48), control1: CGPoint(x: 44, y: 90), control2: CGPoint(x: 28, y: 72))
            }
            .stroke(AppTheme.primaryBlue.opacity(0.55), lineWidth: 4)

            Leaf(rotation: .degrees(-28))
                .fill(Color(hex: "8DBEFF"))
                .frame(width: 28, height: 54)
                .offset(x: -24, y: -44)

            Leaf(rotation: .degrees(26))
                .fill(Color(hex: "9ECBFF"))
                .frame(width: 28, height: 56)
                .offset(x: 20, y: -60)
        }
    }
}

private struct Leaf: Shape {
    let rotation: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY), control1: CGPoint(x: rect.minX, y: rect.height * 0.72), control2: CGPoint(x: rect.minX, y: rect.height * 0.2))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control1: CGPoint(x: rect.maxX, y: rect.height * 0.2), control2: CGPoint(x: rect.maxX, y: rect.height * 0.72))
        return path.applying(CGAffineTransform(rotationAngle: CGFloat(rotation.radians)))
    }
}

private struct Cloud: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(Color.white.opacity(0.65))
                .frame(width: width, height: height * 0.48)
            Circle()
                .fill(Color.white.opacity(0.65))
                .frame(width: height, height: height)
                .offset(x: -width * 0.12, y: -height * 0.14)
        }
    }
}

#if DEBUG
#Preview("Intro Onboarding") {
    OnboardingIntroView {}
}

#Preview("Intro Onboarding · iPhone SE", traits: .fixedLayout(width: 320, height: 760)) {
    OnboardingIntroView {}
}
#endif
