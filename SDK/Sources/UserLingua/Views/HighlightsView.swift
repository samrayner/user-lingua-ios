import SwiftUI

struct HighlightsView: View {
    let userLingua = UserLingua.shared
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(userLingua.highlightedStrings.keys), id: \.self) { recordedString in
                ForEach(userLingua.highlightedStrings[recordedString, default: []]) { rect in
                    Text("\(recordedString.original)")
                        .background(Color.red)
                        .opacity(0.5)
                        .frame(width: rect.width, height: rect.height)
                        .offset(x: rect.origin.x, y: rect.origin.y)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

extension CGRect: Identifiable {
    public var id: String {
        "\(self)"
    }
}
