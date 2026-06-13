import SwiftUI
import UIKit

struct FirePresentedTopicRouteHost: UIViewControllerRepresentable {
    @EnvironmentObject private var topicDetailStore: FireTopicDetailStore

    let viewModel: FireAppViewModel
    let route: FireAppRoute

    func makeUIViewController(context: Context) -> UINavigationController {
        viewModel.topicRouteLogger()?.info("presented topic route host make ui controller start \(route.diagnosticsSummary)")
        let navigationController = FireAppRouteControllerFactory.makeNavigationController(
            viewModel: viewModel,
            topicDetailStore: topicDetailStore,
            route: route
        )
        viewModel.topicRouteLogger()?.info(
            "presented topic route host make ui controller complete \(route.diagnosticsSummary) stack_count=\(navigationController.viewControllers.count)"
        )
        return navigationController
    }

    func updateUIViewController(
        _ uiViewController: UINavigationController,
        context: Context
    ) {
        // Route inputs are immutable after presentation.
    }
}
