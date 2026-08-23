# Quran Database Schema Report

Generated: 2026-06-02

Source asset: `assets/db/quran.db`

## File

- Size: 2,007,040 bytes
- SQLite open mode used for inspection: read-only

## Schema

### Table: `quran_text`

```sql
CREATE TABLE quran_text (
    idx INTEGER PRIMARY KEY,
    sura INTEGER NOT NULL,
    aya INTEGER NOT NULL,
    text TEXT NOT NULL,
    qcf_text TEXT
)
```

Columns discovered through `PRAGMA table_info(quran_text)`:

| Column | Type | Not Null | Primary Key |
|---|---:|---:|---:|
| `idx` | `INTEGER` | no | yes |
| `sura` | `INTEGER` | yes | no |
| `aya` | `INTEGER` | yes | no |
| `text` | `TEXT` | yes | no |
| `qcf_text` | `TEXT` | no | no |

Indexes discovered: none.

Views discovered: none.

## Integrity Summary

| Check | Result |
|---|---:|
| Total rows | 6,236 |
| Minimum `idx` | 1 |
| Maximum `idx` | 6,236 |
| Missing `idx` gaps | 0 |
| Minimum `sura` | 1 |
| Maximum `sura` | 114 |
| Minimum `aya` | 1 |
| Maximum `aya` | 286 |
| Duplicate `(sura, aya)` rows | 0 |
| Missing or empty `qcf_text` rows | 0 |

## Sample Rows

First rows:

| idx | sura | aya | text |
|---:|---:|---:|---|
| 1 | 1 | 1 | بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ |
| 2 | 1 | 2 | ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ |
| 3 | 1 | 3 | ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ |

The `qcf_text` column contains page-font glyph text imported from the QCF
dataset used by the linked Quran reference project. It is used only for page
rendering; copy/share actions continue to use the normalized `text` column.

Last rows:

| idx | sura | aya | text |
|---:|---:|---:|---|
| 6234 | 114 | 4 | مِن شَرِّ ٱلْوَسْوَاسِ ٱلْخَنَّاسِ |
| 6235 | 114 | 5 | ٱلَّذِى يُوَسْوِسُ فِى صُدُورِ ٱلنَّاسِ |
| 6236 | 114 | 6 | مِنَ ٱلْجِنَّةِ وَٱلنَّاسِ |

## Phase 2 Implementation Requirements

- Open `quran.db` from the app database directory in read-only mode.
- Copy `assets/db/quran.db` to the database directory when it does not already
  exist, or when the copied database has an outdated schema.
- Validate that table `quran_text` exists.
- Validate required columns: `idx`, `sura`, `aya`, `text`, `qcf_text`.
- Validate row count and ranges: 6,236 rows, `idx` 1-6,236, `sura` 1-114.
- Validate that every row has non-empty `qcf_text`.
- Fail with a feature-specific exception if the copied database does not match the inspected schema.
