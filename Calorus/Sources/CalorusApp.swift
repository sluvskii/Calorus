import SwiftUI
import SwiftData

@main
struct CalorusApp: App {
    private let bootstrap = AppBootstrapResult.make()

    var body: some Scene {
        WindowGroup {
            if let container = bootstrap.container {
                RootView()
                    .modelContainer(container)
            } else {
                LaunchDiagnosticsView(message: bootstrap.message)
            }
        }
    }
}

private struct AppBootstrapResult {
    let container: ModelContainer?
    let message: String

    static func make() -> AppBootstrapResult {
        // #region debug-point A:bootstrap-start
        let schema = Schema([
            Consumption.self,
            Activity.self,
            UserProfile.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        // #endregion

        do {
            // #region debug-point B:model-container-create
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return AppBootstrapResult(container: container, message: "ModelContainer created")
            // #endregion
        } catch {
            // #region debug-point C:model-container-error
            let message = "ModelContainer error: \(String(describing: error))"
            return AppBootstrapResult(container: nil, message: message)
            // #endregion
        }
    }
}

private struct LaunchDiagnosticsView: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Не удалось запустить приложение")
                .font(.title2)
                .fontWeight(.bold)

            Text("Диагностика старта")
                .font(.headline)

            Text(message)
                .font(.footnote)
                .textSelection(.enabled)

            Text("Сделай скрин этого экрана или пришли текст ошибки, и я исправлю точную причину.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .background(Color(uiColor: .systemBackground))
    }
}
