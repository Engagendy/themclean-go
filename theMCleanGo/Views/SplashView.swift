import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image("LaunchMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .green.opacity(0.22), radius: 24, y: 10)

                VStack(spacing: 6) {
                    Text("theMClean Go")
                        .font(.title2.bold())
                    Text("Preparing file review")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ProgressView()
                    .controlSize(.regular)
                    .tint(.green)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 32)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("theMClean Go is preparing file review")
    }
}
