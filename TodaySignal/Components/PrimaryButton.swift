import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String?
    var isFullWidth: Bool = true
    var isDisabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: 56)
            .padding(.horizontal, isFullWidth ? 0 : 22)
            .background(isDisabled ? Color.pinkSoft : Color.pink)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: isDisabled ? .clear : Color.pink.opacity(0.45), radius: 12, y: 6)
        }
        .disabled(isDisabled)
    }
}

struct SecondaryButton: View {
    let title: String
    var icon: String?
    var isFullWidth: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: 56)
            .padding(.horizontal, isFullWidth ? 0 : 22)
            .background(.white)
            .foregroundStyle(Color.ink)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.line2, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "上传聊天截图", icon: "camera.fill") {}
        SecondaryButton(title: "粘贴韩语文本", icon: "doc.on.clipboard") {}
        PrimaryButton(title: "Disabled", isDisabled: true) {}
    }
    .padding()
    .background(Color.bgPage)
}
