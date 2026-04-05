import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }

            PetListView()
                .tabItem {
                    Label("My Pets", systemImage: "pawprint.fill")
                }
        }
        .tint(.indigo)
    }
}

#Preview {
    ContentView()
        .environmentObject(DataStore())
}
