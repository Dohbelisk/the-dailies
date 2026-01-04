/// Mock puzzle data for integration tests
library;

/// Mock Sudoku puzzle data (easy - solved state for testing completion)
const Map<String, dynamic> mockSudokuPuzzle = {
  'id': 'test-sudoku-1',
  'gameType': 'sudoku',
  'difficulty': 'easy',
  'date': '2025-01-01T00:00:00.000Z',
  'targetTime': 300,
  'isActive': true,
  'puzzleData': {
    'grid': [
      [5, 3, 0, 0, 7, 0, 0, 0, 0],
      [6, 0, 0, 1, 9, 5, 0, 0, 0],
      [0, 9, 8, 0, 0, 0, 0, 6, 0],
      [8, 0, 0, 0, 6, 0, 0, 0, 3],
      [4, 0, 0, 8, 0, 3, 0, 0, 1],
      [7, 0, 0, 0, 2, 0, 0, 0, 6],
      [0, 6, 0, 0, 0, 0, 2, 8, 0],
      [0, 0, 0, 4, 1, 9, 0, 0, 5],
      [0, 0, 0, 0, 8, 0, 0, 7, 9],
    ],
  },
  'solution': {
    'grid': [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ],
  },
};

/// Mock Killer Sudoku puzzle data
const Map<String, dynamic> mockKillerSudokuPuzzle = {
  'id': 'test-killer-sudoku-1',
  'gameType': 'killerSudoku',
  'difficulty': 'medium',
  'date': '2025-01-01T00:00:00.000Z',
  'targetTime': 900,
  'isActive': true,
  'puzzleData': {
    'grid': [
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
    'cages': [
      {'sum': 8, 'cells': [[0, 0], [0, 1]]},
      {'sum': 15, 'cells': [[0, 2], [0, 3], [0, 4]]},
      {'sum': 10, 'cells': [[0, 5], [0, 6]]},
      {'sum': 12, 'cells': [[0, 7], [0, 8]]},
    ],
  },
  'solution': {
    'grid': [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ],
  },
};

/// Mock Crossword puzzle data
const Map<String, dynamic> mockCrosswordPuzzle = {
  'id': 'test-crossword-1',
  'gameType': 'crossword',
  'difficulty': 'easy',
  'date': '2025-01-01T00:00:00.000Z',
  'targetTime': 360,
  'isActive': true,
  'puzzleData': {
    'rows': 5,
    'cols': 5,
    'grid': [
      ['F', 'L', 'U', 'T', 'T'],
      ['L', '#', '#', 'E', '#'],
      ['O', '#', '#', 'S', '#'],
      ['W', 'O', 'R', 'D', '#'],
      ['#', '#', '#', '#', '#'],
    ],
    'clues': [
      {
        'number': 1,
        'direction': 'across',
        'clue': 'Google UI toolkit',
        'answer': 'FLUTT',
        'startRow': 0,
        'startCol': 0,
      },
      {
        'number': 2,
        'direction': 'across',
        'clue': 'A single vocabulary item',
        'answer': 'WORD',
        'startRow': 3,
        'startCol': 0,
      },
      {
        'number': 1,
        'direction': 'down',
        'clue': 'Movement of water',
        'answer': 'FLOW',
        'startRow': 0,
        'startCol': 0,
      },
      {
        'number': 3,
        'direction': 'down',
        'clue': 'Examinations',
        'answer': 'TEST',
        'startRow': 0,
        'startCol': 3,
      },
    ],
  },
};

/// Mock Word Search puzzle data
const Map<String, dynamic> mockWordSearchPuzzle = {
  'id': 'test-word-search-1',
  'gameType': 'wordSearch',
  'difficulty': 'easy',
  'date': '2025-01-01T00:00:00.000Z',
  'targetTime': 180,
  'isActive': true,
  'puzzleData': {
    'rows': 5,
    'cols': 5,
    'theme': 'Test',
    'grid': [
      ['F', 'L', 'O', 'W', 'X'],
      ['X', 'X', 'X', 'O', 'X'],
      ['X', 'X', 'X', 'R', 'X'],
      ['X', 'X', 'X', 'D', 'X'],
      ['X', 'X', 'X', 'X', 'X'],
    ],
    'words': [
      {
        'word': 'FLOW',
        'startRow': 0,
        'startCol': 0,
        'endRow': 0,
        'endCol': 3,
      },
      {
        'word': 'WORD',
        'startRow': 0,
        'startCol': 3,
        'endRow': 3,
        'endCol': 3,
      },
    ],
  },
};

/// Mock Word Forge puzzle data
const Map<String, dynamic> mockWordForgePuzzle = {
  'id': 'test-word-forge-1',
  'gameType': 'wordForge',
  'difficulty': 'medium',
  'date': '2025-01-01T00:00:00.000Z',
  'targetTime': 600,
  'isActive': true,
  'puzzleData': {
    'letters': ['W', 'O', 'R', 'K', 'I', 'N', 'G'],
    'centerLetter': 'O',
    'words': [
      {'word': 'WORK', 'clue': 'Job or task', 'isPangram': false},
      {'word': 'WORKING', 'clue': 'Doing a job', 'isPangram': true},
      {'word': 'KING', 'clue': 'Royal ruler', 'isPangram': false},
      {'word': 'RING', 'clue': 'Circular band', 'isPangram': false},
      {'word': 'IRON', 'clue': 'Metal element', 'isPangram': false},
    ],
  },
  'solution': {
    'maxScore': 50,
    'pangramCount': 1,
  },
};

/// Mock Nonogram puzzle data (5x5)
const Map<String, dynamic> mockNonogramPuzzle = {
  'id': 'test-nonogram-1',
  'gameType': 'nonogram',
  'difficulty': 'easy',
  'date': '2025-01-01T00:00:00.000Z',
  'targetTime': 180,
  'isActive': true,
  'puzzleData': {
    'rows': 5,
    'cols': 5,
    'rowClues': [
      [1],
      [3],
      [5],
      [3],
      [1],
    ],
    'colClues': [
      [1],
      [3],
      [5],
      [3],
      [1],
    ],
    'grid': [
      [0, 0, 1, 0, 0],
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0],
      [0, 0, 1, 0, 0],
    ],
  },
  'solution': {
    'grid': [
      [0, 0, 1, 0, 0],
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0],
      [0, 0, 1, 0, 0],
    ],
  },
};

/// Mock Number Target puzzle data
const Map<String, dynamic> mockNumberTargetPuzzle = {
  'id': 'test-number-target-1',
  'gameType': 'numberTarget',
  'difficulty': 'medium',
  'date': '2025-01-01T00:00:00.000Z',
  'targetTime': 180,
  'isActive': true,
  'puzzleData': {
    'numbers': [2, 3, 4, 5],
    'target': 24,
  },
  'solution': {
    'solutions': ['(2+3)*4+4', '(5-2)*4*2'],
  },
};

/// Mock Ball Sort puzzle data
const Map<String, dynamic> mockBallSortPuzzle = {
  'id': 'test-ball-sort-1',
  'gameType': 'ballSort',
  'difficulty': 'easy',
  'date': '2025-01-01T00:00:00.000Z',
  'targetTime': 120,
  'isActive': true,
  'puzzleData': {
    'tubes': 4,
    'colors': 2,
    'tubeCapacity': 4,
    'initialState': [
      ['red', 'blue', 'red', 'blue'],
      ['blue', 'red', 'blue', 'red'],
      [],
      [],
    ],
  },
};

/// Mock Pipes puzzle data
const Map<String, dynamic> mockPipesPuzzle = {
  'id': 'test-pipes-1',
  'gameType': 'pipes',
  'difficulty': 'easy',
  'date': '2025-01-01T00:00:00.000Z',
  'targetTime': 120,
  'isActive': true,
  'puzzleData': {
    'rows': 3,
    'cols': 3,
    'endpoints': [
      {'color': 'red', 'row': 0, 'col': 0},
      {'color': 'red', 'row': 2, 'col': 2},
      {'color': 'blue', 'row': 0, 'col': 2},
      {'color': 'blue', 'row': 2, 'col': 0},
    ],
    'bridges': [],
  },
};

/// Mock Lights Out puzzle data
const Map<String, dynamic> mockLightsOutPuzzle = {
  'id': 'test-lights-out-1',
  'gameType': 'lightsOut',
  'difficulty': 'easy',
  'date': '2025-01-01T00:00:00.000Z',
  'targetTime': 60,
  'isActive': true,
  'puzzleData': {
    'rows': 3,
    'cols': 3,
    'initialState': [
      [true, false, true],
      [false, true, false],
      [true, false, true],
    ],
  },
};

/// Mock Word Ladder puzzle data
const Map<String, dynamic> mockWordLadderPuzzle = {
  'id': 'test-word-ladder-1',
  'gameType': 'wordLadder',
  'difficulty': 'medium',
  'date': '2025-01-01T00:00:00.000Z',
  'targetTime': 180,
  'isActive': true,
  'puzzleData': {
    'startWord': 'COLD',
    'targetWord': 'WARM',
    'wordLength': 4,
  },
};

/// Mock Connections puzzle data
const Map<String, dynamic> mockConnectionsPuzzle = {
  'id': 'test-connections-1',
  'gameType': 'connections',
  'difficulty': 'medium',
  'date': '2025-01-01T00:00:00.000Z',
  'targetTime': 180,
  'isActive': true,
  'puzzleData': {
    'words': [
      'APPLE', 'BANANA', 'ORANGE', 'GRAPE',
      'DOG', 'CAT', 'BIRD', 'FISH',
      'RED', 'BLUE', 'GREEN', 'YELLOW',
      'RUN', 'WALK', 'JUMP', 'SWIM',
    ],
    'categories': [
      {'name': 'Fruits', 'words': ['APPLE', 'BANANA', 'ORANGE', 'GRAPE'], 'difficulty': 1},
      {'name': 'Animals', 'words': ['DOG', 'CAT', 'BIRD', 'FISH'], 'difficulty': 2},
      {'name': 'Colors', 'words': ['RED', 'BLUE', 'GREEN', 'YELLOW'], 'difficulty': 3},
      {'name': 'Actions', 'words': ['RUN', 'WALK', 'JUMP', 'SWIM'], 'difficulty': 4},
    ],
  },
};

/// Mock Mathora puzzle data
const Map<String, dynamic> mockMathoraPuzzle = {
  'id': 'test-mathora-1',
  'gameType': 'mathora',
  'difficulty': 'easy',
  'date': '2025-01-01T00:00:00.000Z',
  'targetTime': 60,
  'isActive': true,
  'puzzleData': {
    'startNumber': 10,
    'targetNumber': 100,
    'moves': 3,
    'operations': [
      {'type': 'add', 'value': 50, 'display': '+50'},
      {'type': 'multiply', 'value': 10, 'display': 'x10'},
      {'type': 'subtract', 'value': 5, 'display': '-5'},
      {'type': 'divide', 'value': 2, 'display': '/2'},
      {'type': 'add', 'value': 10, 'display': '+10'},
      {'type': 'multiply', 'value': 2, 'display': 'x2'},
    ],
  },
  'solution': {
    'steps': [
      {'type': 'multiply', 'value': 10, 'display': 'x10'},
    ],
  },
};

/// Get all mock puzzles for testing
List<Map<String, dynamic>> get allMockPuzzles => [
  mockSudokuPuzzle,
  mockKillerSudokuPuzzle,
  mockCrosswordPuzzle,
  mockWordSearchPuzzle,
  mockWordForgePuzzle,
  mockNonogramPuzzle,
  mockNumberTargetPuzzle,
  mockBallSortPuzzle,
  mockPipesPuzzle,
  mockLightsOutPuzzle,
  mockWordLadderPuzzle,
  mockConnectionsPuzzle,
  mockMathoraPuzzle,
];
