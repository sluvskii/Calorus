import SwiftUI

struct RootView: View {
    @State private var selectedTab: Tab = .dashboard
    
    enum Tab {
        case dashboard, history, settings
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .history:
                    HistoryView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Floating Tab Bar
            HStack(spacing: 0) {
                TabBarButton(icon: "chart.pie.fill", isSelected: selectedTab == .dashboard) {
                    selectedTab = .dashboard
                }
                TabBarButton(icon: "list.bullet", isSelected: selectedTab == .history) {
                    selectedTab = .history
                }
                TabBarButton(icon: "gearshape.fill", isSelected: selectedTab == .settings) {
                    selectedTab = .settings
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                Capsule()
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .overlay(
                        Capsule()
                            .stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5)
                    )
            )
            .padding(.bottom, 16)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct TabBarButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
        }
    }
}
