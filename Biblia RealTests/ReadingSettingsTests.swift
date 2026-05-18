import XCTest
@testable import Biblia_Real

final class ReadingSettingsTests: XCTestCase {

    // MARK: - ReadingTheme

    func testReadingTheme_has6Cases() {
        XCTAssertEqual(ReadingTheme.allCases.count, 6)
    }

    func testReadingTheme_allHaveNonEmptyDisplayNames() {
        for theme in ReadingTheme.allCases {
            XCTAssertFalse(theme.displayName(for: .rv1960).isEmpty, "\(theme) has empty displayName for rv1960")
            XCTAssertFalse(theme.displayName(for: .cornilescu).isEmpty, "\(theme) has empty displayName for cornilescu")
        }
    }

    func testReadingTheme_idMatchesRawValue() {
        for theme in ReadingTheme.allCases {
            XCTAssertEqual(theme.id, theme.rawValue)
        }
    }

    func testReadingTheme_white_hasWhiteBackground() {
        // We can't compare Color values directly; verify it doesn't crash and returns something
        _ = ReadingTheme.white.background
        _ = ReadingTheme.white.text
        _ = ReadingTheme.white.secondaryText
        _ = ReadingTheme.white.separator
    }

    func testReadingTheme_allCases_colorsAccessibleWithoutCrash() {
        for theme in ReadingTheme.allCases {
            _ = theme.background
            _ = theme.text
            _ = theme.secondaryText
            _ = theme.separator
        }
    }

    // MARK: - ReadingFont

    func testReadingFont_has5Cases() {
        XCTAssertEqual(ReadingFont.allCases.count, 5)
    }

    func testReadingFont_allHaveNonEmptyDisplayNames() {
        for font in ReadingFont.allCases {
            XCTAssertFalse(font.displayName(for: .rv1960).isEmpty, "\(font) has empty displayName for rv1960")
            XCTAssertFalse(font.displayName(for: .cornilescu).isEmpty, "\(font) has empty displayName for cornilescu")
        }
    }

    func testReadingFont_idMatchesRawValue() {
        for font in ReadingFont.allCases {
            XCTAssertEqual(font.id, font.rawValue)
        }
    }

    func testReadingFont_fontAtSize18_doesNotCrash() {
        for font in ReadingFont.allCases {
            _ = font.font(size: 18)
        }
    }

    // MARK: - Translation

    func testTranslation_has2Cases() {
        XCTAssertEqual(Translation.allCases.count, 2)
    }

    func testTranslation_displayNamesNonEmpty() {
        XCTAssertFalse(Translation.rv1960.displayName.isEmpty)
        XCTAssertFalse(Translation.cornilescu.displayName.isEmpty)
    }

    func testTranslation_languagesNonEmpty() {
        XCTAssertFalse(Translation.rv1960.language.isEmpty)
        XCTAssertFalse(Translation.cornilescu.language.isEmpty)
    }

    func testTranslation_idMatchesRawValue() {
        XCTAssertEqual(Translation.rv1960.id,     Translation.rv1960.rawValue)
        XCTAssertEqual(Translation.cornilescu.id, Translation.cornilescu.rawValue)
    }

    // MARK: - AppStrings (spot-check key strings are non-empty)

    func testAppStrings_allUILabels_nonEmpty() {
        for t in Translation.allCases {
            XCTAssertFalse(t.closeLabel.isEmpty,              "\(t).closeLabel is empty")
            XCTAssertFalse(t.searchNavTitle.isEmpty,          "\(t).searchNavTitle is empty")
            XCTAssertFalse(t.bookmarksNavTitle.isEmpty,       "\(t).bookmarksNavTitle is empty")
            XCTAssertFalse(t.planTitle.isEmpty,               "\(t).planTitle is empty")
            XCTAssertFalse(t.verseDayLabel.isEmpty,           "\(t).verseDayLabel is empty")
            XCTAssertFalse(t.highlightRemove.isEmpty,         "\(t).highlightRemove is empty")
            XCTAssertFalse(t.fontSizeAlertTitle.isEmpty,      "\(t).fontSizeAlertTitle is empty")
            XCTAssertFalse(t.fontSizeAlertMessage.isEmpty,    "\(t).fontSizeAlertMessage is empty")
        }
    }

    func testAppStrings_searchResultCount_singular() {
        XCTAssertTrue(Translation.rv1960.searchResultCount(1).contains("1"))
        XCTAssertTrue(Translation.cornilescu.searchResultCount(1).contains("1"))
    }

    func testAppStrings_searchResultCount_plural() {
        XCTAssertTrue(Translation.rv1960.searchResultCount(5).contains("5"))
        XCTAssertTrue(Translation.cornilescu.searchResultCount(5).contains("5"))
    }
}
