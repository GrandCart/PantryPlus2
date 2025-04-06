import SwiftUI

struct IconPreview: View {
    var body: some View {
        VStack {
            Image(uiImage: IconGenerator.generateIcon(size: 120))
                .resizable()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .onAppear {
                    IconGenerator.generateAllIcons()
                }
        }
    }
}

#Preview {
    IconPreview()
} 