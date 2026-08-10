//
//  TextDiff.swift
//  Coin
//

import Foundation

enum DiffLineKind {
    case unchanged, added, removed
}

struct DiffLine: Identifiable {
    let id = UUID()
    let kind: DiffLineKind
    let text: String
}

enum TextDiff {

    /// Построчный diff двух текстов через LCS (longest common subsequence) — тот же принцип,
    /// на котором строится `git diff`: находим наибольшую общую подпоследовательность строк,
    /// всё, что в неё не попало, помечаем как удалённое (было) или добавленное (стало).
    static func lineDiff(old: String, new: String) -> [DiffLine] {
        let oldLines = old.components(separatedBy: "\n")
        let newLines = new.components(separatedBy: "\n")
        return lineDiff(old: oldLines, new: newLines)
    }

    static func lineDiff(old oldLines: [String], new newLines: [String]) -> [DiffLine] {
        let m = oldLines.count
        let n = newLines.count

        // dp[i][j] — длина LCS для oldLines[i...] и newLines[j...]
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in stride(from: m - 1, through: 0, by: -1) {
            for j in stride(from: n - 1, through: 0, by: -1) {
                if oldLines[i] == newLines[j] {
                    dp[i][j] = dp[i + 1][j + 1] + 1
                } else {
                    dp[i][j] = max(dp[i + 1][j], dp[i][j + 1])
                }
            }
        }

        var result: [DiffLine] = []
        var i = 0, j = 0
        while i < m && j < n {
            if oldLines[i] == newLines[j] {
                result.append(DiffLine(kind: .unchanged, text: oldLines[i]))
                i += 1
                j += 1
            } else if dp[i + 1][j] >= dp[i][j + 1] {
                result.append(DiffLine(kind: .removed, text: oldLines[i]))
                i += 1
            } else {
                result.append(DiffLine(kind: .added, text: newLines[j]))
                j += 1
            }
        }
        while i < m {
            result.append(DiffLine(kind: .removed, text: oldLines[i]))
            i += 1
        }
        while j < n {
            result.append(DiffLine(kind: .added, text: newLines[j]))
            j += 1
        }
        return result
    }
}
