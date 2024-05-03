// Diff.swift

import Foundation

// Based on https://github.com/wzxha/Sdifft

enum DiffScript {
    case insert(at: Int)
    case delete(at: Int)
    case same(at: Int)
}

struct Path {
    let from, to: Vertice
    let script: DiffScript
}

struct Vertice: Equatable {
    // swiftlint:disable identifier_name
    let x: Int
    let y: Int
    // swiftlint:enable identifier_name
    static func == (lhs: Vertice, rhs: Vertice) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
}

class Diff<Element: Equatable & Hashable> {
    let scripts: [DiffScript]

    init(source: [Element], target: [Element]) {
        if source.isEmpty, target.isEmpty {
            self.scripts = []
        } else if source.isEmpty, !target.isEmpty {
            // Under normal circumstances, scripts is a reversed (index) array
            // you need to reverse the array youself if needed.
            self.scripts = (0 ..< target.count).reversed().compactMap { DiffScript.insert(at: $0) }
        } else if !source.isEmpty, target.isEmpty {
            self.scripts = (0 ..< source.count).reversed().compactMap { DiffScript.delete(at: $0) }
        } else {
            let paths = Diff.exploreEditGraph(source: source, target: target)
            self.scripts = Diff.reverseTree(paths: paths, sinkVertice: .init(x: target.count, y: source.count))
        }
    }

    // swiftlint:disable identifier_name
    static func exploreEditGraph(source: [Element], target: [Element]) -> [Path] {
        let max = source.count + target.count
        var furthest = Array(repeating: 0, count: 2 * max + 1)
        var paths: [Path] = []

        let snake: (Int, Int, Int) -> Int = { x, _, k in
            var _x = x
            var y: Int { _x - k }
            while _x < target.count && y < source.count && source[y] == target[_x] {
                _x += 1
                paths.append(
                    Path(from: .init(x: _x - 1, y: y - 1), to: .init(x: _x, y: y), script: .same(at: _x - 1))
                )
            }
            return _x
        }

        for d in 0 ... max {
            for k in stride(from: -d, through: d, by: 2) {
                let index = k + max
                var x = 0
                var y: Int { x - k }

                if d == 0 {}
                else if k == -d || k != d && furthest[index - 1] < furthest[index + 1] {
                    // moving bottom
                    x = furthest[index + 1]
                    paths.append(
                        Path(
                            from: .init(x: x, y: y - 1), to: .init(x: x, y: y),
                            script: .delete(at: y - 1)
                        )
                    )
                } else {
                    // moving right
                    x = furthest[index - 1] + 1
                    paths.append(
                        Path(
                            from: .init(x: x - 1, y: y),
                            to: .init(x: x, y: y),
                            script: .insert(at: x - 1)
                        )
                    )
                }
                x = snake(x, d, k)
                if x == target.count, y == source.count {
                    return paths
                }
                furthest[index] = x
            }
        }

        return []
    }

    // swiftlint:enable identifier_name

    // Search for the path from the back to the front
    static func reverseTree(paths: [Path], sinkVertice: Vertice) -> [DiffScript] {
        var scripts: [DiffScript] = []
        var next = sinkVertice
        paths.reversed().forEach {
            guard $0.to == next else { return }
            next = $0.from
            scripts.append($0.script)
        }
        return scripts
    }

    static func script(source: [Element], target: [Element]) -> [DiffScript] {
        Diff(source: source.reversed(), target: target.reversed())
            .scripts
            .reverseIndex(source: source, target: target)
    }
}

extension String {
    fileprivate subscript(_ idx: Int) -> String {
        String(self[index(startIndex, offsetBy: idx)])
    }
}

struct DiffAttributes {
    var insert: [NSAttributedString.Key: Any] = [:]
    var delete: [NSAttributedString.Key: Any] = [:]
    var same: [NSAttributedString.Key: Any] = [:]
}

extension [DiffScript] {
    func reverseIndex<T>(source: [T], target: [T]) -> [DiffScript] {
        map {
            switch $0 {
            case let .delete(at: index):
                DiffScript.delete(at: source.endIndex - 1 - index)
            case let .insert(at: index):
                DiffScript.insert(at: target.endIndex - 1 - index)
            case let .same(at: index):
                DiffScript.same(at: target.endIndex - 1 - index)
            }
        }
    }
}

extension AttributedString {
    init(old: String, new: String, diffAttributes: DiffAttributes) {
        let scripts = Diff.script(source: .init(old), target: .init(new))

        var attributedString = AttributedString()

        for script in scripts {
            let attributedSubstring = switch script {
            case let .insert(at: index):
                AttributedString(new[index], attributes: .init(diffAttributes.insert))
            case let .delete(at: index):
                AttributedString(old[index], attributes: .init(diffAttributes.delete))
            case let .same(at: index):
                AttributedString(new[index], attributes: .init(diffAttributes.same))
            }
            attributedString.append(attributedSubstring)
        }

        self = attributedString
    }
}
