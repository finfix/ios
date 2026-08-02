//
//  Rank.swift
//  Coin
//

import Foundation

// Лексикографический ранг для сортировки счетов (fractional indexing / LexoRank).
// Перемещение счета — мутация только его собственного rank, без сдвига соседей.
enum Rank {

    // Упорядоченный алфавит base62: сортировка строк совпадает с сортировкой по этому алфавиту
    static let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
    private static let minChar = alphabet.first!
    private static let maxChar = alphabet.last!
    private static let midChar = alphabet[alphabet.count / 2]

    // Возвращает ранг строго между prev и next (nil означает начало/конец списка)
    static func between(_ prev: String?, _ next: String?) -> String {
        switch (prev, next) {
        case (nil, nil):
            return String(midChar)
        case (let prev?, nil):
            return above(prev)
        case (nil, let next?):
            return below(next)
        case (let prev?, let next?):
            precondition(prev < next, "prev должен быть строго меньше next")
            return mid(prev, next)
        }
    }

    // Ранг строго больше prev (вставка в конец списка)
    private static func above(_ prev: String) -> String {
        var chars = Array(prev)
        for i in chars.indices.reversed() {
            if let nextChar = charAfter(chars[i]) {
                chars[i] = nextChar
                return String(chars[0...i])
            }
        }
        // У всех символов был максимум алфавита — удлиняем строку
        return prev + String(midChar)
    }

    // Ранг строго меньше next (вставка в начало списка)
    private static func below(_ next: String) -> String {
        var chars = Array(next)
        for i in chars.indices.reversed() {
            if let prevChar = charBefore(chars[i]) {
                chars[i] = prevChar
                return String(chars[0...i])
            }
        }
        // У всех символов был минимум алфавита — уменьшить их некуда, но собственный
        // префикс строки всегда лексикографически меньше самой строки
        guard !chars.isEmpty else { return next }
        return String(chars.dropLast())
    }

    // Средняя строка между prev и next (посимвольный поиск зазора в алфавите)
    private static func mid(_ prev: String, _ next: String) -> String {
        let prevChars = Array(prev)
        let nextChars = Array(next)
        var result: [Character] = []

        var i = 0
        while true {
            let p = i < prevChars.count ? prevChars[i] : minChar
            let n = i < nextChars.count ? nextChars[i] : nil

            // next короче или закончился — значит на этой позиции у next неявный "конец строки",
            // всё что после p в prev идёт вверх до maxChar
            guard let n else {
                if let above = charAfter(p) {
                    result.append(above)
                    return String(result)
                }
                result.append(p)
                i += 1
                continue
            }

            if p == n {
                result.append(p)
                i += 1
                continue
            }

            let pIndex = index(of: p)
            let nIndex = index(of: n)

            // Зазор больше одного символа алфавита — берём средний символ и останавливаемся
            if nIndex - pIndex > 1 {
                let midIndex = pIndex + (nIndex - pIndex) / 2
                result.append(alphabet[midIndex])
                return String(result)
            }

            // Зазора нет (соседние символы) — фиксируем p, углубляемся в следующий символ prev
            result.append(p)
            i += 1
        }
    }

    private static func index(of char: Character) -> Int {
        alphabet.firstIndex(of: char)!
    }

    private static func charAfter(_ char: Character) -> Character? {
        let i = index(of: char)
        guard i + 1 < alphabet.count else { return nil }
        return alphabet[i + 1]
    }

    private static func charBefore(_ char: Character) -> Character? {
        let i = index(of: char)
        guard i - 1 >= 0 else { return nil }
        return alphabet[i - 1]
    }
}
