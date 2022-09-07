import SwiftUI

public protocol ListMarkdownStyle {
    associatedtype Body: View
    typealias Configuration = ListStyleMarkdownConfiguration
    @ViewBuilder func makeBody(configuration: Configuration) -> Body
}

public struct AnyListMarkdownStyle: ListMarkdownStyle {
    var label: (Configuration) -> AnyView
    init<S: ListMarkdownStyle>(_ style: S) {
        label = { AnyView(style.makeBody(configuration: $0)) }
    }
    public func makeBody(configuration: Configuration) -> some View {
        label(configuration)
    }
}

public struct ListStyleMarkdownConfiguration {
    private struct Label: View {
        @Environment(\.markdownListStyle) private var list
        @Environment(\.markdownUnorderedListItemStyle) private var unordered
        @Environment(\.markdownOrderedListItemStyle) private var ordered
        @Environment(\.markdownCheckListItemStyle) private var checklist
        @Backport.ScaledMetric private var spacing: CGFloat = 8

        let markdownList: MarkdownList
        let level: Int

        var body: some View {
            VStack(alignment: .leading, spacing: spacing) {
                ForEach(markdownList.elements.indices, id: \.self) { index in
                    switch markdownList.elements[index] {
                    case let .ordered(config):
                        ordered.makeBody(configuration: config)
                    case let .unordered(config):
                        unordered.makeBody(configuration: config)
                    case let .checklist(config):
                        checklist.makeBody(configuration: config)
                    case let .list(nested):
                        list.makeBody(configuration: .init(markdownList: nested, level: level + 1))
                    }
                }
            }
        }
    }

    let markdownList: MarkdownList
    public let level: Int

    public var label: some View {
        Label(markdownList: markdownList, level: level)
    }
}

public struct DefaultListMarkdownStyle: ListMarkdownStyle {
    public init() { }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

public extension ListMarkdownStyle where Self == DefaultListMarkdownStyle {
    static var `default`: Self { .init() }
}

private struct ListMarkdownEnvironmentKey: EnvironmentKey {
    static let defaultValue = AnyListMarkdownStyle(.default)
}

public extension EnvironmentValues {
    var markdownListStyle: AnyListMarkdownStyle {
        get { self[ListMarkdownEnvironmentKey.self] }
        set { self[ListMarkdownEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func markdownListStyle<S>(_ style: S) -> some View where S: ListMarkdownStyle {
        environment(\.markdownListStyle, .init(style))
    }
}