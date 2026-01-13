import mongoose from "mongoose";

const MONGODB_URI =
  process.env.MONGODB_URI || "mongodb://localhost:27017/the-dailies";

// Puzzle Schema (simplified for migration)
const puzzleSchema = new mongoose.Schema(
  {
    gameType: String,
    difficulty: String,
    date: Date,
    puzzleData: Object,
    solution: Object,
    targetTime: Number,
    isActive: Boolean,
    status: String,
    title: String,
    description: String,
  },
  { timestamps: true },
);

const Puzzle = mongoose.model("Puzzle", puzzleSchema);

async function migrate() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log("Connected to MongoDB");

    // Count puzzles to migrate
    const totalPuzzles = await Puzzle.countDocuments();
    const puzzlesWithStatus = await Puzzle.countDocuments({
      status: { $exists: true },
    });
    const puzzlesWithoutStatus = await Puzzle.countDocuments({
      status: { $exists: false },
    });

    console.log(`\nTotal puzzles: ${totalPuzzles}`);
    console.log(`Puzzles with status field: ${puzzlesWithStatus}`);
    console.log(`Puzzles without status field: ${puzzlesWithoutStatus}`);

    if (puzzlesWithoutStatus === 0) {
      console.log("\nAll puzzles already have status field. Nothing to migrate.");
      await mongoose.disconnect();
      return;
    }

    console.log("\nMigrating puzzles...");

    // Migrate active puzzles to status: 'active'
    const activeResult = await Puzzle.updateMany(
      { isActive: true, status: { $exists: false } },
      { $set: { status: "active" } },
    );
    console.log(`  - Set ${activeResult.modifiedCount} active puzzles to status: 'active'`);

    // Migrate inactive puzzles to status: 'inactive'
    const inactiveResult = await Puzzle.updateMany(
      { isActive: false, status: { $exists: false } },
      { $set: { status: "inactive" } },
    );
    console.log(`  - Set ${inactiveResult.modifiedCount} inactive puzzles to status: 'inactive'`);

    // Handle any puzzles without isActive field (shouldn't happen, but just in case)
    const nullResult = await Puzzle.updateMany(
      { isActive: { $exists: false }, status: { $exists: false } },
      { $set: { status: "active", isActive: true } },
    );
    if (nullResult.modifiedCount > 0) {
      console.log(`  - Set ${nullResult.modifiedCount} puzzles without isActive to status: 'active'`);
    }

    // Verify migration
    const verifyTotal = await Puzzle.countDocuments();
    const verifyWithStatus = await Puzzle.countDocuments({
      status: { $exists: true },
    });
    const verifyPending = await Puzzle.countDocuments({ status: "pending" });
    const verifyActive = await Puzzle.countDocuments({ status: "active" });
    const verifyInactive = await Puzzle.countDocuments({ status: "inactive" });

    console.log("\nMigration complete!");
    console.log(`  - Total puzzles: ${verifyTotal}`);
    console.log(`  - With status field: ${verifyWithStatus}`);
    console.log(`  - Status breakdown:`);
    console.log(`    - pending: ${verifyPending}`);
    console.log(`    - active: ${verifyActive}`);
    console.log(`    - inactive: ${verifyInactive}`);

    await mongoose.disconnect();
    console.log("\nDisconnected from MongoDB");
  } catch (error) {
    console.error("Migration failed:", error);
    process.exit(1);
  }
}

migrate();
