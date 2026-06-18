import SwiftUI

#if !canImport(FoundationModels) // Fallback for older Xcode versions on CI
extension View {
    func glassEffect(in shape: some Shape) -> some View {
        self.background(
            shape.fill(Color(UIColor.systemBackground).opacity(0.8))
        )
        .overlay(
            shape.stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
        )
    }
    
    func glassEffect(_ style: GlassEffectStyle, in shape: some Shape) -> some View {
        self.background(
            shape.fill(Color(UIColor.secondarySystemBackground).opacity(0.8))
        )
    }
}

enum GlassEffectStyle {
    case regular
}
#endif
