//
//  RankTests.swift
//  CoinTests
//

import XCTest
@testable import Coin

final class RankTests: XCTestCase {

    func testFirstRankInEmptyList() {
        let rank = Rank.between(nil, nil)
        XCTAssertFalse(rank.isEmpty)
    }

    func testInsertAtEnd() {
        let first = Rank.between(nil, nil)
        let second = Rank.between(first, nil)
        XCTAssertLessThan(first, second)
    }

    func testInsertAtBeginning() {
        let first = Rank.between(nil, nil)
        let zero = Rank.between(nil, first)
        XCTAssertLessThan(zero, first)
    }

    func testInsertBetweenTwoRanks() {
        let a = Rank.between(nil, nil)
        let c = Rank.between(a, nil)
        let b = Rank.between(a, c)
        XCTAssertLessThan(a, b)
        XCTAssertLessThan(b, c)
    }

    func testRepeatedInsertsAtEndStayOrdered() {
        var ranks = [Rank.between(nil, nil)]
        for _ in 0..<50 {
            ranks.append(Rank.between(ranks.last, nil))
        }
        XCTAssertEqual(ranks, ranks.sorted())
        XCTAssertEqual(Set(ranks).count, ranks.count)
    }

    func testRepeatedInsertsAtBeginningStayOrdered() {
        var ranks = [Rank.between(nil, nil)]
        for _ in 0..<50 {
            ranks.insert(Rank.between(nil, ranks.first), at: 0)
        }
        XCTAssertEqual(ranks, ranks.sorted())
        XCTAssertEqual(Set(ranks).count, ranks.count)
    }

    func testRepeatedInsertsInTheMiddleStayOrdered() {
        let low = Rank.between(nil, nil)
        var high = Rank.between(low, nil)
        for _ in 0..<50 {
            let mid = Rank.between(low, high)
            XCTAssertLessThan(low, mid)
            XCTAssertLessThan(mid, high)
            high = mid
        }
    }

    func testAdjacentCharactersStillProduceOrderedResult() {
        // "A" и "B" соседние по алфавиту — зазора на первой позиции нет,
        // ранг должен углубиться на следующий символ
        let mid = Rank.between("A", "B")
        XCTAssertGreaterThan(mid, "A")
        XCTAssertLessThan(mid, "B")
    }

    func testAlphabetOrderMatchesSwiftStringOrder() {
        let alphabet = Rank.alphabet
        for i in 0..<(alphabet.count - 1) {
            XCTAssertLessThan(String(alphabet[i]), String(alphabet[i + 1]))
        }
    }
}
