# Commit-Konvention

Format: `<typ>(<bereich>): <beschreibung>`

## Typ

| Typ | Beschreibung |
|-----|-------------|
| `build` | Änderungen am Build-System oder an externen Abhängigkeiten (npm, make …) |
| `ci` | Änderungen an CI-Konfigurationsdateien und -Skripten (Travis, Ansible, BrowserStack …) |
| `feat` | Hinzufügen eines neuen Features |
| `fix` | Behebung eines Fehlers |
| `perf` | Verbesserung der Performance |
| `refactor` | Änderung, die weder ein neues Feature noch eine Performance-Verbesserung bringt |
| `style` | Änderung ohne funktionale oder semantische Auswirkung (Einrückung, Formatierung, Leerzeichen …) |
| `docs` | Erstellung oder Aktualisierung von Dokumentation |
| `test` | Hinzufügen oder Ändern von Tests |
| `revert` | Einen vorherigen Commit rückgängig machen (Format: `revert <Betreff> <Hash>`) |

## Beschreibung

| Schlüsselwort | Bedeutung |
|---------------|-----------|
| `add` | Hinzufügen |
| `change` | Ändern |
| `update` | Aktualisieren |
| `remove` | Entfernen |

[Quelle](https://buzut.net/git-bien-nommer-ses-commits/)
