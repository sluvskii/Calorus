import SwiftUI

struct RootView: View {
    @State private var selectedTab: Tab = .dashboard
    
    enum Tab {
        case dashboard, history, settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Главная", systemImage: "chart.pie.fill")
                }
                .tag(Tab.dashboard)
            
            HistoryView()
                .tabItem {
                    Label("История", systemImage: "list.bullet")
                }
                .tag(Tab.history)
            
            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
    }
}
