# Puzzle Data Formats

JSON structure for each puzzle type stored in the `puzzleData` field.

## Sudoku

```json
{
  "grid": [[5,3,0,...], ...],     // 9x9, 0 = empty
  "solution": [[5,3,4,...], ...]  // 9x9, complete
}
```

## Killer Sudoku

```json
{
  "grid": [[0,0,0,...], ...],
  "solution": [[5,3,4,...], ...],
  "cages": [
    {"sum": 8, "cells": [[0,0], [0,1]]},
    {"sum": 15, "cells": [[0,2], [1,2], [2,2]]}
  ]
}
```

## Crossword

```json
{
  "rows": 10, "cols": 10,
  "grid": [["F","L","U",...], ...],  // Letters and "#" for black
  "clues": [{
    "number": 1,
    "direction": "across",
    "clue": "Google UI toolkit",
    "answer": "FLUTTER",
    "startRow": 0, "startCol": 0
  }]
}
```

## Word Search

```json
{
  "rows": 10, "cols": 10,
  "theme": "Programming",
  "grid": [["F","L","U",...], ...],  // Uppercase letters
  "words": [{
    "word": "FLUTTER",
    "startRow": 0, "startCol": 0,
    "endRow": 0, "endCol": 6
  }]
}
```

## Word Forge

```json
{
  "letters": ["A", "C", "E", "L", "N", "R", "T"],  // 7 unique letters
  "centerLetter": "A"                              // Must be in every word
}
```

**Client-side Dictionary Validation:**
- Local dictionary at `assets/data/words.txt` (~85k words)
- Valid words computed client-side based on 7 letters + center letter
- Pangrams (words using all 7 letters) identified automatically
- Scoring: NYT Spelling Bee style with levels (Beginner → Queen Bee)
- Completion at "Genius" level (70% of max score)

**Hint System:**
- Two-letter grid (FREE): Shows word counts by first two letters
- Pangram hint (costs 1 hint): Reveals first letter + length of unfound pangram
- Word reveal (costs 1 hint): Reveals a random unfound word

**DictionaryService** (`lib/services/dictionary_service.dart`):
- `load()` - Loads dictionary from assets
- `findValidWords(letters, centerLetter)` - Returns valid words for puzzle
- `findPangrams(letters, centerLetter)` - Returns pangrams
- `getTwoLetterHints(letters, centerLetter, foundWords)` - Returns hint grid

## Nonogram

```json
{
  "rows": 5, "cols": 5,
  "rowClues": [[1, 1], [5], [1, 1, 1], [5], [1, 1]],
  "colClues": [[1, 1], [5], [1, 1, 1], [5], [1, 1]],
  "solution": [[1,0,1,0,1], [1,1,1,1,1], ...]  // 1=filled, 0=empty
}
```

## Number Target

```json
{
  "numbers": [2, 5, 7, 3],           // 4 numbers to use
  "target": 24,                       // Target to reach
  "solutions": ["(7-5)*(3+2)*2", ...] // Valid expressions
}
```

## Ball Sort

```json
{
  "tubes": 6,                          // Total tubes
  "colors": 4,                         // Number of colors
  "tubeCapacity": 4,                   // Balls per tube
  "initialState": [                    // 2D array of color strings per tube
    ["red", "blue", "green", "yellow"],
    ["blue", "green", "red", "yellow"],
    // ... more tubes, last 2 typically empty
  ]
}
```

## Pipes

```json
{
  "rows": 5, "cols": 5,
  "endpoints": [                       // 2 endpoints per color
    { "color": "red", "row": 0, "col": 0 },
    { "color": "red", "row": 4, "col": 4 }
  ],
  "bridges": []                        // Optional bridge cells [row, col]
}
```

## Lights Out

```json
{
  "rows": 3, "cols": 3,
  "initialState": [                    // 2D boolean array (true=on)
    [true, false, true],
    [false, true, false],
    [true, false, true]
  ]
}
```

## Word Ladder

```json
{
  "startWord": "COLD",                 // Starting word
  "targetWord": "WARM",                // Target word (same length)
  "wordLength": 4
}
```

## Connections

```json
{
  "words": [                           // 16 shuffled words
    "APPLE", "DOG", "RED", "RUN", ...
  ],
  "categories": [                      // 4 categories of 4 words each
    { "name": "Fruits", "words": ["APPLE", "BANANA", "ORANGE", "GRAPE"], "difficulty": 1 },
    { "name": "Animals", "words": ["DOG", "CAT", "BIRD", "FISH"], "difficulty": 2 },
    { "name": "Colors", "words": ["RED", "BLUE", "GREEN", "YELLOW"], "difficulty": 3 },
    { "name": "Actions", "words": ["RUN", "WALK", "JUMP", "SWIM"], "difficulty": 4 }
  ]
}
```

## Mathora

```json
{
  "startNumber": 8,                    // Starting value
  "targetNumber": 200,                 // Target to reach
  "moves": 3,                          // Maximum moves allowed
  "operations": [                      // Grid of available operations
    { "type": "add", "value": 50, "display": "+50" },
    { "type": "multiply", "value": 10, "display": "×10" },
    { "type": "subtract", "value": 5, "display": "-5" },
    { "type": "divide", "value": 2, "display": "÷2" },
    ...
  ]
}
// Solution: array of operations that solve the puzzle
// Example: 8 × 10 = 80 → 80 + 100 = 180 → 180 + 20 = 200
```
