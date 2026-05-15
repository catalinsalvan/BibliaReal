import Foundation

extension Translation {
    private var ro: Bool { self == .cornilescu }

    // MARK: General
    var closeLabel: String { ro ? "Închide" : "Cerrar" }
    var noContentLabel: String { ro ? "Fără conținut" : "Sin contenido" }
    var appSubtitle: String { ro ? "Cuvântul lui Dumnezeu" : "La Palabra de Dios" }
    var continueReadingLabel: String { ro ? "Continuă lectura" : "Continuar leyendo" }

    // MARK: Settings
    var fontSizeLabel: String { ro ? "Dimensiune text" : "Tamaño de texto" }
    var lineSpacingLabel: String { ro ? "Spațiere rânduri" : "Espacio entre líneas" }
    var themeLabel: String { ro ? "Temă" : "Tema" }
    var fontLabel: String { ro ? "Font" : "Fuente" }
    var translationLabel: String { ro ? "Traducere" : "Traducción" }
    var fontSizeAlertTitle: String { ro ? "Adnotări după dimensiune" : "Anotaciones por tamaño" }
    var fontSizeAlertButton: String { ro ? "Înțeles" : "Entendido" }
    var fontSizeAlertMessage: String {
        ro  ? "Fiecare dimensiune de text are propriile adnotări. La schimbarea dimensiunii vei vedea un spațiu gol, dar notițele anterioare sunt păstrate intacte."
            : "Cada tamaño de texto guarda sus propias anotaciones. Al cambiar el tamaño verás un lienzo limpio, pero tus notas del tamaño anterior se conservan intactas."
    }

    // MARK: Search
    var searchNavTitle: String { ro ? "Caută" : "Buscar" }
    var searchEmptyTitle: String { ro ? "Caută versete" : "Buscar versículos" }
    var searchEmptyDescription: String {
        ro  ? "Scrie o referință (Ioan 3:16) sau un cuvânt"
            : "Escribe una referencia (Juan 3:16) o una palabra"
    }
    var searchPrompt: String { ro ? "Referință sau cuvânt..." : "Referencia o palabra..." }
    var searchReferenceSection: String { ro ? "Referință" : "Referencia" }
    var searchGoToChapter: String { ro ? "Mergi la capitol" : "Ir al capítulo" }
    var searchFirst200: String { ro ? "Primele 200 rezultate" : "Primeros 200 resultados" }
    func searchResultCount(_ n: Int) -> String {
        ro  ? (n == 1 ? "1 rezultat" : "\(n) rezultate")
            : (n == 1 ? "1 resultado" : "\(n) resultados")
    }

    // MARK: Bookmarks
    var removeBookmarkLabel: String { ro ? "Șterge marcaj" : "Quitar marcador" }
    var addBookmarkLabel: String { ro ? "Adaugă marcaj" : "Añadir marcador" }
    var bookmarksSavedSection: String { ro ? "Salvate" : "Guardados" }
    var bookmarksEmptyTitle: String { ro ? "Fără marcaje" : "Sin marcadores" }
    var bookmarksEmptyDescription: String {
        ro  ? "Apasă \"Adaugă marcaj\" pentru a salva acest capitol"
            : "Toca \"Añadir marcador\" para guardar este capítulo"
    }
    var bookmarksNavTitle: String { ro ? "Marcaje" : "Marcadores" }

    // MARK: Home
    var verseDayLabel: String { ro ? "Versetul zilei" : "Verso del día" }
    var plansLabel: String { ro ? "Plan de lectură" : "Plan de lectura" }
    var randomLabel: String { ro ? "Verset aleatoriu" : "Verso aleatorio" }

    // MARK: Plan
    var planTitle: String { ro ? "Plan 5 zile/săptămână" : "Plan 5 días/semana" }
    var planTodayLabel: String { ro ? "Lecturile de azi" : "Lecturas de hoy" }
    var planDayOf: String { ro ? "Ziua" : "Día" }
    var planOf260: String { ro ? "din 260" : "de 260" }
    var planMarkRead: String { ro ? "Marchează ca citit" : "Marcar como leído" }
    var planReset: String { ro ? "Resetează" : "Reiniciar" }
    var planComplete: String { ro ? "Plan complet!" : "¡Plan completado!" }
    var planCompleteDesc: String {
        ro  ? "Ai citit toată Biblia în 260 de zile."
            : "Has leído toda la Biblia en 260 días."
    }

    // MARK: Highlights
    var highlightRemove: String { ro ? "Elimină evidențierea" : "Quitar resaltado" }
}
