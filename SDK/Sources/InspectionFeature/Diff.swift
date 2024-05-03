// Diff.swift

import Foundation

// Based on https://github.com/wzxha/Sdifft

enum DiffScript {
    case insert(into: Int)
    case delete(at: Int)
    case same(at: Int)
}

struct Vertice: Equatable {
    let x, y: Int
    static func == (lhs: Vertice, rhs: Vertice) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
}

struct Path {
    let from, to: Vertice
    let script: DiffScript
}

class Diff<T: Equatable & Hashable> {
    let scripts: [DiffScript]

    init(source: [T], target: [T]) {
        if source.isEmpty, target.isEmpty {
            self.scripts = []
        } else if source.isEmpty, !target.isEmpty {
            // Under normal circumstances, scripts is a reversed (index) array
            // you need to reverse the array youself if need.
            self.scripts = (0 ..< target.count).reversed().compactMap { DiffScript.insert(into: $0) }
        } else if !source.isEmpty, target.isEmpty {
            self.scripts = (0 ..< source.count).reversed().compactMap { DiffScript.delete(at: $0) }
        } else {
            let paths = Diff.exploreEditGraph(source: source, target: target)
            self.scripts = Diff.reverseTree(paths: paths, sinkVertice: .init(x: target.count, y: source.count))
        }
    }

    static func exploreEditGraph(source: [T], target: [T]) -> [Path] {
        let max = source.count + target.count
        var furthest = Array(repeating: 0, count: 2 * max + 1)
        var paths: [Path] = []

        let snake: (Int, Int, Int) -> Int = { x, _, k in
            var _x = x // swiftlint:disable:this identifier_name
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
                            from: .init(x: x - 1, y: y), to: .init(x: x, y: y),
                            script: .insert(into: x - 1)
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
}

extension String {
    subscript(_ idx: Int) -> String {
        String(self[index(startIndex, offsetBy: idx)])
    }
}

struct DiffAttributes {
    let insert, delete, same: [NSAttributedString.Key: Any]
    init(
        insert: [NSAttributedString.Key: Any],
        delete: [NSAttributedString.Key: Any],
        same: [NSAttributedString.Key: Any]
    ) {
        self.insert = insert
        self.delete = delete
        self.same = same
    }
}

extension [DiffScript] {
    func reverseIndex<T>(source: [T], target: [T]) -> [DiffScript] {
        map {
            switch $0 {
            case let .delete(at: idx):
                DiffScript.delete(at: source.count - 1 - idx)
            case let .insert(into: idx):
                DiffScript.insert(into: target.count - 1 - idx)
            case let .same(at: idx):
                DiffScript.same(at: target.count - 1 - idx)
            }
        }
    }
}

extension NSAttributedString {
    private static func script<T: Equatable & Hashable>(withSource source: [T], target: [T]) -> [DiffScript] {
        Diff(source: source.reversed(), target: target.reversed())
            .scripts
            .reverseIndex(source: source, target: target)
    }

    convenience init(source: String, target: String, attributes: DiffAttributes) {
        let attributedString = NSMutableAttributedString()
        let scripts = NSAttributedString.script(withSource: .init(source), target: .init(target))

        for script in scripts {
            switch script {
            case let .insert(into: idx):
                attributedString.append(NSAttributedString(string: target[idx], attributes: attributes.insert))
            case let .delete(at: idx):
                attributedString.append(NSAttributedString(string: source[idx], attributes: attributes.delete))
            case let .same(at: idx):
                attributedString.append(NSAttributedString(string: target[idx], attributes: attributes.same))
            }
        }

        self.init(attributedString: attributedString)
    }

    convenience init(
        source: [String], target: [String],
        attributes: DiffAttributes,
        handler: ((DiffScript, NSAttributedString) -> NSAttributedString)? = nil
    ) {
        let attributedString = NSMutableAttributedString()
        let scripts = NSAttributedString.script(withSource: source, target: target)
        for script in scripts {
            var scriptAttributedString: NSAttributedString = switch script {
            case let .insert(into: idx):
                NSAttributedString(string: target[idx], attributes: attributes.insert)
            case let .delete(at: idx):
                NSAttributedString(string: source[idx], attributes: attributes.delete)
            case let .same(at: idx):
                NSAttributedString(string: target[idx], attributes: attributes.same)
            }
            if let handler {
                scriptAttributedString = handler(script, scriptAttributedString)
            }
            attributedString.append(scriptAttributedString)
        }

        self.init(attributedString: attributedString)
    }
}
