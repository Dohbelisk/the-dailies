import mongoose from "mongoose";
import * as bcrypt from "bcrypt";

const MONGODB_URI =
  process.env.MONGODB_URI || "mongodb://localhost:27017/the-dailies";

// User Schema
const userSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    username: String,
    role: { type: String, enum: ["user", "admin"], default: "user" },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true },
);

// Puzzle Schema
const puzzleSchema = new mongoose.Schema(
  {
    gameType: {
      type: String,
      required: true,
      enum: ["sudoku", "killerSudoku", "crossword", "wordSearch"],
    },
    difficulty: {
      type: String,
      required: true,
      enum: ["easy", "medium", "hard", "expert"],
    },
    date: { type: Date, required: true },
    puzzleData: { type: Object, required: true },
    solution: Object,
    targetTime: Number,
    isActive: { type: Boolean, default: true },
    title: String,
    description: String,
  },
  { timestamps: true },
);

const User = mongoose.model("User", userSchema);
const Puzzle = mongoose.model("Puzzle", puzzleSchema);

async function seed() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log("Connected to MongoDB");

    // Create admin user
    const adminPassword = await bcrypt.hash("5nifrenypro", 10);
    await User.findOneAndUpdate(
      { email: "admin@dohbelisk.com" },
      {
        email: "admin@dohbelisk.com",
        password: adminPassword,
        username: "Admin",
        role: "admin",
        isActive: true,
      },
      { upsert: true },
    );
    console.log("✅ Admin user created: admin@dohbelisk.com / 5nifrenypro");

    // Create sample puzzles for today
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const samplePuzzles = [
      {
        gameType: "sudoku",
        difficulty: "medium",
        date: today,
        targetTime: 600,
        title: "Daily Sudoku",
        isActive: true,
        puzzleData: {
          grid: [
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
          solution: [
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
      },
      {
        gameType: "wordSearch",
        difficulty: "easy",
        date: today,
        targetTime: 300,
        title: "Programming Terms",
        isActive: true,
        puzzleData: {
          rows: 10,
          cols: 10,
          theme: "Programming",
          grid: [
            ["F", "L", "U", "T", "T", "E", "R", "X", "P", "Q"],
            ["A", "P", "I", "K", "O", "T", "L", "I", "N", "Z"],
            ["D", "A", "R", "T", "B", "Y", "T", "E", "S", "W"],
            ["K", "R", "E", "A", "C", "T", "V", "U", "I", "D"],
            ["C", "O", "D", "E", "N", "O", "D", "E", "F", "G"],
            ["S", "W", "I", "F", "T", "P", "R", "O", "G", "H"],
            ["J", "A", "V", "A", "M", "N", "O", "P", "Q", "R"],
            ["R", "U", "S", "T", "U", "V", "W", "X", "Y", "Z"],
            ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"],
            ["K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"],
          ],
          words: [
            { word: "FLUTTER", startRow: 0, startCol: 0, endRow: 0, endCol: 6 },
            { word: "DART", startRow: 2, startCol: 0, endRow: 2, endCol: 3 },
            { word: "API", startRow: 1, startCol: 0, endRow: 1, endCol: 2 },
            { word: "KOTLIN", startRow: 1, startCol: 3, endRow: 1, endCol: 8 },
            { word: "REACT", startRow: 3, startCol: 1, endRow: 3, endCol: 5 },
            { word: "CODE", startRow: 4, startCol: 0, endRow: 4, endCol: 3 },
            { word: "NODE", startRow: 4, startCol: 4, endRow: 4, endCol: 7 },
            { word: "SWIFT", startRow: 5, startCol: 0, endRow: 5, endCol: 4 },
            { word: "JAVA", startRow: 6, startCol: 0, endRow: 6, endCol: 3 },
            { word: "RUST", startRow: 7, startCol: 0, endRow: 7, endCol: 3 },
          ],
        },
      },
    ];

    for (const puzzle of samplePuzzles) {
      await Puzzle.findOneAndUpdate(
        { gameType: puzzle.gameType, date: puzzle.date },
        puzzle,
        { upsert: true },
      );
    }
    console.log(`✅ Created ${samplePuzzles.length} sample puzzles for today`);

    console.log("\n🎉 Seed completed successfully!");
    process.exit(0);
  } catch (error) {
    console.error("Seed failed:", error);
    process.exit(1);
  }
}

seed();
