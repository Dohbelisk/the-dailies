import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import toast from 'react-hot-toast'
import { ArrowLeft, Loader2, Wand2, Calendar, Sparkles } from 'lucide-react'
import api from '../lib/api'

export default function PuzzleGenerate() {
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState<'single' | 'week'>('single')
  
  // Single puzzle state
  const [gameType, setGameType] = useState('sudoku')
  const [difficulty, setDifficulty] = useState('medium')
  const [date, setDate] = useState(new Date().toISOString().split('T')[0])
  const [title, setTitle] = useState('')
  
  // Word search specific
  const [words, setWords] = useState('FLUTTER\nDART\nREACT\nNODE\nPYTHON')
  const [theme, setTheme] = useState('Programming')

  // Crossword specific
  const [crosswordWords, setCrosswordWords] = useState(
    'FLUTTER:Google UI toolkit for mobile apps\nREACT:Popular JavaScript library\nCODE:What programmers write\nDEBUG:Find and fix errors\nAPI:Application Programming Interface'
  )
  
  // Week generation state
  const [weekStartDate, setWeekStartDate] = useState(
    new Date().toISOString().split('T')[0]
  )
  const [selectedTypes, setSelectedTypes] = useState(['sudoku', 'wordSearch'])

  const generateSingleMutation = useMutation({
    mutationFn: async () => {
      if (gameType === 'sudoku') {
        return api.post('/generate/sudoku', { difficulty, date, title })
      } else if (gameType === 'killerSudoku') {
        return api.post('/generate/killer-sudoku', { difficulty, date, title })
      } else if (gameType === 'crossword') {
        const wordsWithClues = crosswordWords
          .split('\n')
          .map(line => line.trim())
          .filter(Boolean)
          .map(line => {
            const [word, clue] = line.split(':')
            return { word: word.trim().toUpperCase(), clue: clue?.trim() || '' }
          })
        return api.post('/generate/crossword', {
          wordsWithClues,
          difficulty,
          date,
          title,
          rows: 10,
          cols: 10,
        })
      } else if (gameType === 'wordSearch') {
        const wordList = words.split('\n').map(w => w.trim().toUpperCase()).filter(Boolean)
        return api.post('/generate/word-search', {
          words: wordList,
          theme,
          difficulty,
          date,
          title,
          rows: 12,
          cols: 12,
        })
      } else if (gameType === 'wordForge') {
        return api.post('/generate/word-forge', { difficulty, date, title })
      } else if (gameType === 'nonogram') {
        return api.post('/generate/nonogram', { difficulty, date, title })
      } else if (gameType === 'numberTarget') {
        return api.post('/generate/number-target', { difficulty, date, title })
      } else if (gameType === 'ballSort') {
        return api.post('/generate/ball-sort', { difficulty, date, title })
      } else if (gameType === 'pipes') {
        return api.post('/generate/pipes', { difficulty, date, title })
      } else if (gameType === 'lightsOut') {
        return api.post('/generate/lights-out', { difficulty, date, title })
      } else if (gameType === 'wordLadder') {
        return api.post('/generate/word-ladder', { difficulty, date, title })
      } else if (gameType === 'connections') {
        return api.post('/generate/connections', { difficulty, date, title })
      } else if (gameType === 'mathora') {
        return api.post('/generate/mathora', { difficulty, date, title })
      }
    },
    onSuccess: () => {
      toast.success('Puzzle generated successfully!')
      navigate('/puzzles')
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to generate puzzle')
    },
  })

  const generateWeekMutation = useMutation({
    mutationFn: () =>
      api.post('/generate/week', {
        startDate: weekStartDate,
        gameTypes: selectedTypes,
      }),
    onSuccess: (response) => {
      toast.success(`Generated ${response.data.puzzles.length} puzzles!`)
      navigate('/puzzles')
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to generate puzzles')
    },
  })

  const toggleGameType = (type: string) => {
    setSelectedTypes(prev =>
      prev.includes(type)
        ? prev.filter(t => t !== type)
        : [...prev, type]
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={() => navigate(-1)}
          className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Generate Puzzles
          </h1>
          <p className="text-gray-500 dark:text-gray-400">
            Auto-generate puzzles using built-in algorithms
          </p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-2">
        <button
          onClick={() => setActiveTab('single')}
          className={`px-4 py-2 rounded-lg font-medium transition-colors ${
            activeTab === 'single'
              ? 'bg-primary-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300'
          }`}
        >
          <Wand2 className="w-4 h-4 inline mr-2" />
          Single Puzzle
        </button>
        <button
          onClick={() => setActiveTab('week')}
          className={`px-4 py-2 rounded-lg font-medium transition-colors ${
            activeTab === 'week'
              ? 'bg-primary-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300'
          }`}
        >
          <Calendar className="w-4 h-4 inline mr-2" />
          Generate Week
        </button>
      </div>

      {activeTab === 'single' ? (
        <div className="card p-6 space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Left column */}
            <div className="space-y-4">
              <div>
                <label className="label">Puzzle Type</label>
                <select
                  value={gameType}
                  onChange={(e) => setGameType(e.target.value)}
                  className="input"
                >
                  <option value="sudoku">Sudoku</option>
                  <option value="killerSudoku">Killer Sudoku</option>
                  <option value="crossword">Crossword</option>
                  <option value="wordSearch">Word Search</option>
                  <option value="wordForge">Word Forge</option>
                  <option value="nonogram">Nonogram</option>
                  <option value="numberTarget">Number Target</option>
                  <option value="ballSort">Ball Sort</option>
                  <option value="pipes">Pipes</option>
                  <option value="lightsOut">Lights Out</option>
                  <option value="wordLadder">Word Ladder</option>
                  <option value="connections">Connections</option>
                  <option value="mathora">Mathora</option>
                </select>
                <p className="mt-1 text-sm text-gray-500">
                  {gameType === 'sudoku' && 'Generates a valid Sudoku puzzle with unique solution'}
                  {gameType === 'killerSudoku' && 'Generates Killer Sudoku with cages and sum constraints'}
                  {gameType === 'crossword' && 'Generates crossword puzzle with intersecting words'}
                  {gameType === 'wordSearch' && 'Generates a word search grid with hidden words'}
                  {gameType === 'wordForge' && 'Generates Word Forge with 7 letters and valid words'}
                  {gameType === 'nonogram' && 'Generates Nonogram picture logic puzzle'}
                  {gameType === 'numberTarget' && 'Generates Number Target math puzzle'}
                  {gameType === 'ballSort' && 'Generates Ball Sort puzzle with colored balls to sort'}
                  {gameType === 'pipes' && 'Connect colored dots without crossing paths'}
                  {gameType === 'lightsOut' && 'Toggle lights to turn them all off'}
                  {gameType === 'wordLadder' && 'Transform one word to another, one letter at a time'}
                  {gameType === 'connections' && 'Group 16 words into 4 categories'}
                  {gameType === 'mathora' && 'Solve math equations to reach target numbers'}
                </p>
              </div>

              <div>
                <label className="label">Difficulty</label>
                <select
                  value={difficulty}
                  onChange={(e) => setDifficulty(e.target.value)}
                  className="input"
                >
                  <option value="easy">Easy</option>
                  <option value="medium">Medium</option>
                  <option value="hard">Hard</option>
                  <option value="expert">Expert</option>
                </select>
              </div>

              <div>
                <label className="label">Date</label>
                <input
                  type="date"
                  value={date}
                  onChange={(e) => setDate(e.target.value)}
                  className="input"
                />
              </div>

              <div>
                <label className="label">Title (optional)</label>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="input"
                  placeholder="e.g., Monday Challenge"
                />
              </div>
            </div>

            {/* Right column - Type specific */}
            {gameType === 'wordSearch' && (
              <div className="space-y-4">
                <div>
                  <label className="label">Theme</label>
                  <input
                    type="text"
                    value={theme}
                    onChange={(e) => setTheme(e.target.value)}
                    className="input"
                    placeholder="e.g., Animals, Food, Sports"
                  />
                </div>

                <div>
                  <label className="label">Words (one per line)</label>
                  <textarea
                    value={words}
                    onChange={(e) => setWords(e.target.value)}
                    className="input h-48 font-mono"
                    placeholder="WORD1&#10;WORD2&#10;WORD3"
                  />
                  <p className="mt-1 text-sm text-gray-500">
                    {words.split('\n').filter(w => w.trim()).length} words entered
                  </p>
                </div>
              </div>
            )}

            {gameType === 'crossword' && (
              <div className="space-y-4">
                <div>
                  <label className="label">Words & Clues (WORD:Clue format)</label>
                  <textarea
                    value={crosswordWords}
                    onChange={(e) => setCrosswordWords(e.target.value)}
                    className="input h-64 font-mono text-sm"
                    placeholder="FLUTTER:Google UI toolkit&#10;REACT:JavaScript library&#10;CODE:What programmers write"
                  />
                  <p className="mt-1 text-sm text-gray-500">
                    {crosswordWords.split('\n').filter(w => w.trim()).length} clues entered
                  </p>
                  <p className="mt-1 text-xs text-gray-400">
                    Format: One word per line as WORD:Clue description
                  </p>
                </div>
              </div>
            )}

            {gameType === 'sudoku' && (
              <div className="flex items-center justify-center bg-gray-50 dark:bg-gray-700/50 rounded-xl p-8">
                <div className="text-center">
                  <Sparkles className="w-16 h-16 mx-auto text-primary-500 mb-4" />
                  <h3 className="font-medium text-gray-900 dark:text-white mb-2">
                    Sudoku Generator
                  </h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    Creates a valid 9x9 Sudoku puzzle with a unique solution.
                    Difficulty determines how many cells are pre-filled.
                  </p>
                  <ul className="mt-4 text-sm text-left text-gray-600 dark:text-gray-400 space-y-1">
                    <li>• Easy: ~51 cells given</li>
                    <li>• Medium: ~41 cells given</li>
                    <li>• Hard: ~31 cells given</li>
                    <li>• Expert: ~26 cells given</li>
                  </ul>
                </div>
              </div>
            )}

            {gameType === 'killerSudoku' && (
              <div className="flex items-center justify-center bg-gray-50 dark:bg-gray-700/50 rounded-xl p-8">
                <div className="text-center">
                  <Sparkles className="w-16 h-16 mx-auto text-primary-500 mb-4" />
                  <h3 className="font-medium text-gray-900 dark:text-white mb-2">
                    Killer Sudoku Generator
                  </h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    Generates Killer Sudoku with cages (outlined regions) that sum to specific totals.
                    No duplicate numbers within cages.
                  </p>
                  <ul className="mt-4 text-sm text-left text-gray-600 dark:text-gray-400 space-y-1">
                    <li>• Easy: 2-3 cells per cage</li>
                    <li>• Medium: 2-4 cells per cage</li>
                    <li>• Hard: 2-5 cells per cage</li>
                    <li>• Expert: 2-6 cells per cage</li>
                  </ul>
                </div>
              </div>
            )}

            {gameType === 'wordForge' && (
              <div className="flex items-center justify-center bg-gray-50 dark:bg-gray-700/50 rounded-xl p-8">
                <div className="text-center">
                  <span className="text-6xl mb-4 block">⚒️</span>
                  <h3 className="font-medium text-gray-900 dark:text-white mb-2">
                    Word Forge Generator
                  </h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    Word game with 7 letters. Center letter must appear in every word.
                    Minimum 4-letter words. Pangram bonus for using all letters.
                  </p>
                  <ul className="mt-4 text-sm text-left text-gray-600 dark:text-gray-400 space-y-1">
                    <li>• 7 unique letters in honeycomb</li>
                    <li>• Center letter required in all words</li>
                    <li>• 4+ letter words only</li>
                    <li>• +7 bonus for pangrams</li>
                  </ul>
                </div>
              </div>
            )}

            {gameType === 'nonogram' && (
              <div className="flex items-center justify-center bg-gray-50 dark:bg-gray-700/50 rounded-xl p-8">
                <div className="text-center">
                  <span className="text-6xl mb-4 block">🖼️</span>
                  <h3 className="font-medium text-gray-900 dark:text-white mb-2">
                    Nonogram Generator
                  </h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    Picture logic puzzle. Use number clues to fill cells and reveal a hidden image.
                    Also known as Picross or Griddlers.
                  </p>
                  <ul className="mt-4 text-sm text-left text-gray-600 dark:text-gray-400 space-y-1">
                    <li>• Easy: 5x5 grid</li>
                    <li>• Medium: 10x10 grid</li>
                    <li>• Hard: 12x12 grid</li>
                    <li>• Expert: 15x15 grid</li>
                  </ul>
                </div>
              </div>
            )}

            {gameType === 'numberTarget' && (
              <div className="flex items-center justify-center bg-gray-50 dark:bg-gray-700/50 rounded-xl p-8">
                <div className="text-center">
                  <span className="text-6xl mb-4 block">🎯</span>
                  <h3 className="font-medium text-gray-900 dark:text-white mb-2">
                    Number Target Generator
                  </h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    Combine 4 numbers using +, -, ×, ÷ to reach the target.
                    Similar to Countdown or 24 Game.
                  </p>
                  <ul className="mt-4 text-sm text-left text-gray-600 dark:text-gray-400 space-y-1">
                    <li>• Easy: Target = 10</li>
                    <li>• Medium: Target = 24</li>
                    <li>• Hard: Target = 100</li>
                    <li>• Expert: Random target 50-500</li>
                  </ul>
                </div>
              </div>
            )}

            {gameType === 'ballSort' && (
              <div className="flex items-center justify-center bg-gray-50 dark:bg-gray-700/50 rounded-xl p-8">
                <div className="text-center">
                  <span className="text-6xl mb-4 block">🔴</span>
                  <h3 className="font-medium text-gray-900 dark:text-white mb-2">
                    Ball Sort Generator
                  </h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    Sort colored balls into tubes so each tube has only one color.
                    Move one ball at a time to matching colors or empty tubes.
                  </p>
                  <ul className="mt-4 text-sm text-left text-gray-600 dark:text-gray-400 space-y-1">
                    <li>• Easy: 6 tubes, 4 colors</li>
                    <li>• Medium: 8 tubes, 6 colors</li>
                    <li>• Hard: 10 tubes, 8 colors</li>
                    <li>• Expert: 12 tubes, 10 colors</li>
                  </ul>
                </div>
              </div>
            )}

            {gameType === 'pipes' && (
              <div className="flex items-center justify-center bg-gray-50 dark:bg-gray-700/50 rounded-xl p-8">
                <div className="text-center">
                  <span className="text-6xl mb-4 block">🔗</span>
                  <h3 className="font-medium text-gray-900 dark:text-white mb-2">
                    Pipes Generator
                  </h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    Connect matching colored dots with pipes.
                    Paths cannot cross unless using a bridge tile.
                    All cells must be filled.
                  </p>
                  <ul className="mt-4 text-sm text-left text-gray-600 dark:text-gray-400 space-y-1">
                    <li>• Easy: 5x5 grid, 4 colors</li>
                    <li>• Medium: 6x6 grid, 5 colors, 1 bridge</li>
                    <li>• Hard: 7x7 grid, 6 colors, 2 bridges</li>
                    <li>• Expert: 8x8 grid, 8 colors, 3 bridges</li>
                  </ul>
                </div>
              </div>
            )}

            {gameType === 'lightsOut' && (
              <div className="flex items-center justify-center bg-gray-50 dark:bg-gray-700/50 rounded-xl p-8">
                <div className="text-center">
                  <span className="text-6xl mb-4 block">💡</span>
                  <h3 className="font-medium text-gray-900 dark:text-white mb-2">
                    Lights Out Generator
                  </h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    Tap a light to toggle it and its 4 neighbors.
                    Goal: Turn all lights off in minimum moves.
                  </p>
                  <ul className="mt-4 text-sm text-left text-gray-600 dark:text-gray-400 space-y-1">
                    <li>• Easy: 3x3 grid, 3-4 lights on</li>
                    <li>• Medium: 4x4 grid, 5-7 lights on</li>
                    <li>• Hard: 5x5 grid, 8-12 lights on</li>
                    <li>• Expert: 5x5 grid, 12-16 lights on</li>
                  </ul>
                </div>
              </div>
            )}

            {gameType === 'wordLadder' && (
              <div className="flex items-center justify-center bg-gray-50 dark:bg-gray-700/50 rounded-xl p-8">
                <div className="text-center">
                  <span className="text-6xl mb-4 block">🪜</span>
                  <h3 className="font-medium text-gray-900 dark:text-white mb-2">
                    Word Ladder Generator
                  </h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    Transform the start word into the target word,
                    changing one letter at a time. Each step must be a valid word.
                  </p>
                  <ul className="mt-4 text-sm text-left text-gray-600 dark:text-gray-400 space-y-1">
                    <li>• Easy: 3-4 letter words, 3-4 steps</li>
                    <li>• Medium: 4 letter words, 5-6 steps</li>
                    <li>• Hard: 4-5 letter words, 7-8 steps</li>
                    <li>• Expert: 5 letter words, 9+ steps</li>
                  </ul>
                </div>
              </div>
            )}

            {gameType === 'connections' && (
              <div className="flex items-center justify-center bg-gray-50 dark:bg-gray-700/50 rounded-xl p-8">
                <div className="text-center">
                  <span className="text-6xl mb-4 block">🔗</span>
                  <h3 className="font-medium text-gray-900 dark:text-white mb-2">
                    Connections Generator
                  </h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    Group 16 words into 4 categories of 4 words each.
                    Categories range from easy (yellow) to hard (purple).
                    4 mistakes allowed.
                  </p>
                  <ul className="mt-4 text-sm text-left text-gray-600 dark:text-gray-400 space-y-1">
                    <li>• Easy: 2 easy + 2 medium categories</li>
                    <li>• Medium: 1 easy + 2 medium + 1 hard</li>
                    <li>• Hard: 1 medium + 2 hard + 1 tricky</li>
                    <li>• Expert: All tricky categories</li>
                  </ul>
                </div>
              </div>
            )}
          </div>

          <div className="flex justify-end gap-4 pt-4 border-t border-gray-200 dark:border-gray-700">
            <button
              onClick={() => navigate(-1)}
              className="btn btn-secondary"
            >
              Cancel
            </button>
            <button
              onClick={() => generateSingleMutation.mutate()}
              disabled={generateSingleMutation.isPending}
              className="btn btn-primary"
            >
              {generateSingleMutation.isPending ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Generating...
                </>
              ) : (
                <>
                  <Wand2 className="w-4 h-4" />
                  Generate Puzzle
                </>
              )}
            </button>
          </div>
        </div>
      ) : (
        <div className="card p-6 space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <div>
                <label className="label">Start Date</label>
                <input
                  type="date"
                  value={weekStartDate}
                  onChange={(e) => setWeekStartDate(e.target.value)}
                  className="input"
                />
                <p className="mt-1 text-sm text-gray-500">
                  Will generate puzzles for 7 consecutive days
                </p>
              </div>

              <div>
                <label className="label">Puzzle Types to Generate</label>
                <div className="space-y-2 mt-2">
                  {[
                    { id: 'sudoku', label: 'Sudoku', desc: 'Classic number puzzle' },
                    { id: 'killerSudoku', label: 'Killer Sudoku', desc: 'Sudoku with sum cages' },
                    { id: 'crossword', label: 'Crossword', desc: 'Intersecting word puzzle' },
                    { id: 'wordSearch', label: 'Word Search', desc: 'Find hidden words' },
                    { id: 'wordForge', label: 'Word Forge', desc: 'Forge words from letters' },
                    { id: 'nonogram', label: 'Nonogram', desc: 'Picture logic puzzle' },
                    { id: 'numberTarget', label: 'Number Target', desc: 'Math puzzle' },
                    { id: 'ballSort', label: 'Ball Sort', desc: 'Sort colored balls' },
                    { id: 'pipes', label: 'Pipes', desc: 'Connect colored dots' },
                    { id: 'lightsOut', label: 'Lights Out', desc: 'Toggle lights puzzle' },
                    { id: 'wordLadder', label: 'Word Ladder', desc: 'Transform words step by step' },
                    { id: 'connections', label: 'Connections', desc: 'Group words into categories' },
                  ].map((type) => (
                    <label
                      key={type.id}
                      className={`flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors ${
                        selectedTypes.includes(type.id)
                          ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20'
                          : 'border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700/50'
                      }`}
                    >
                      <input
                        type="checkbox"
                        checked={selectedTypes.includes(type.id)}
                        onChange={() => toggleGameType(type.id)}
                        className="w-4 h-4 rounded"
                      />
                      <div>
                        <p className="font-medium text-gray-900 dark:text-white">
                          {type.label}
                        </p>
                        <p className="text-sm text-gray-500">{type.desc}</p>
                      </div>
                    </label>
                  ))}
                </div>
              </div>
            </div>

            <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-6">
              <h3 className="font-medium text-gray-900 dark:text-white mb-4">
                Generation Preview
              </h3>
              <div className="space-y-2 text-sm">
                {Array.from({ length: 7 }).map((_, i) => {
                  const date = new Date(weekStartDate)
                  date.setDate(date.getDate() + i)
                  const difficulties = ['easy', 'medium', 'medium', 'hard', 'hard', 'expert', 'medium']
                  
                  return (
                    <div
                      key={i}
                      className="flex items-center justify-between py-2 border-b border-gray-200 dark:border-gray-600 last:border-0"
                    >
                      <span className="text-gray-600 dark:text-gray-400">
                        {date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}
                      </span>
                      <div className="flex items-center gap-2">
                        <span className={`px-2 py-0.5 text-xs rounded-full ${
                          difficulties[i] === 'easy' ? 'bg-green-100 text-green-700' :
                          difficulties[i] === 'medium' ? 'bg-yellow-100 text-yellow-700' :
                          difficulties[i] === 'hard' ? 'bg-orange-100 text-orange-700' :
                          'bg-red-100 text-red-700'
                        }`}>
                          {difficulties[i]}
                        </span>
                        <span className="text-gray-500">
                          {selectedTypes.length} puzzle{selectedTypes.length !== 1 ? 's' : ''}
                        </span>
                      </div>
                    </div>
                  )
                })}
              </div>
              <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-600">
                <p className="text-gray-600 dark:text-gray-400">
                  Total: <span className="font-bold text-gray-900 dark:text-white">{7 * selectedTypes.length}</span> puzzles
                </p>
              </div>
            </div>
          </div>

          <div className="flex justify-end gap-4 pt-4 border-t border-gray-200 dark:border-gray-700">
            <button
              onClick={() => navigate(-1)}
              className="btn btn-secondary"
            >
              Cancel
            </button>
            <button
              onClick={() => generateWeekMutation.mutate()}
              disabled={generateWeekMutation.isPending || selectedTypes.length === 0}
              className="btn btn-primary"
            >
              {generateWeekMutation.isPending ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Generating {7 * selectedTypes.length} puzzles...
                </>
              ) : (
                <>
                  <Calendar className="w-4 h-4" />
                  Generate Week
                </>
              )}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
