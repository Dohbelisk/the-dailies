#!/usr/bin/env python3
"""
Batch Clue Generator for Word Forge Dictionary

Uses Claude API to generate short (2-5 word) clues for dictionary words.
Processes in batches of 100 words and saves progress incrementally.

Usage:
    export ANTHROPIC_API_KEY="your-key-here"
    python3 generate_clues.py

Or:
    python3 generate_clues.py --api-key "your-key-here"
"""

import json
import os
import sys
import time
import argparse
from datetime import datetime

try:
    import anthropic
except ImportError:
    print("Installing anthropic package...")
    os.system(f"{sys.executable} -m pip install anthropic")
    import anthropic

# File paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(SCRIPT_DIR, '..', 'src', 'seeds', 'data')
INPUT_FILE = os.path.join(DATA_DIR, 'dictionary-with-clues.json')
OUTPUT_FILE = os.path.join(DATA_DIR, 'dictionary-with-clues.json')
PROGRESS_FILE = os.path.join(DATA_DIR, 'clue-generation-progress.json')

# Batch settings
BATCH_SIZE = 100  # Words per API call
MODEL = "claude-3-5-haiku-20241022"  # Fast and cheap
MAX_RETRIES = 3
RETRY_DELAY = 5  # seconds


def load_dictionary():
    """Load the dictionary JSON file"""
    with open(INPUT_FILE, 'r') as f:
        return json.load(f)


def load_progress():
    """Load progress file if it exists"""
    if os.path.exists(PROGRESS_FILE):
        with open(PROGRESS_FILE, 'r') as f:
            return json.load(f)
    return {'completed_indices': [], 'clues': {}}


def save_progress(progress):
    """Save progress to file"""
    with open(PROGRESS_FILE, 'w') as f:
        json.dump(progress, f)


def generate_clues_batch(client, words):
    """Generate clues for a batch of words using Claude API"""

    word_list = "\n".join([f"{i+1}. {w}" for i, w in enumerate(words)])

    prompt = f"""Generate very short clues (2-5 words each) for these words.
Target audience: young teenagers playing a word game.
Mix of straightforward definitions and slightly clever/fun clues.
Keep it simple and age-appropriate.

Words:
{word_list}

Respond with ONLY a JSON array of clues in the same order, like:
["clue for word 1", "clue for word 2", ...]

No explanations, just the JSON array."""

    for attempt in range(MAX_RETRIES):
        try:
            response = client.messages.create(
                model=MODEL,
                max_tokens=4096,
                messages=[{"role": "user", "content": prompt}]
            )

            # Extract JSON from response
            content = response.content[0].text.strip()

            # Handle potential markdown code blocks
            if content.startswith("```"):
                content = content.split("```")[1]
                if content.startswith("json"):
                    content = content[4:]
                content = content.strip()

            clues = json.loads(content)

            if len(clues) != len(words):
                print(f"Warning: Got {len(clues)} clues for {len(words)} words")
                # Pad or truncate
                while len(clues) < len(words):
                    clues.append(f"Define: {words[len(clues)]}")
                clues = clues[:len(words)]

            return clues

        except json.JSONDecodeError as e:
            print(f"JSON parse error (attempt {attempt+1}): {e}")
            print(f"Response was: {content[:200]}...")
            if attempt < MAX_RETRIES - 1:
                time.sleep(RETRY_DELAY)
        except anthropic.APIError as e:
            print(f"API error (attempt {attempt+1}): {e}")
            if attempt < MAX_RETRIES - 1:
                time.sleep(RETRY_DELAY * (attempt + 1))

    # Fallback: return placeholder clues
    return [f"Define: {w}" for w in words]


def main():
    parser = argparse.ArgumentParser(description='Generate clues for dictionary words')
    parser.add_argument('--api-key', help='Anthropic API key')
    parser.add_argument('--start', type=int, default=0, help='Start index (for resuming)')
    parser.add_argument('--limit', type=int, help='Limit number of words to process')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be done without calling API')
    args = parser.parse_args()

    # Get API key
    api_key = args.api_key or os.environ.get('ANTHROPIC_API_KEY')
    if not api_key and not args.dry_run:
        print("Error: No API key provided.")
        print("Set ANTHROPIC_API_KEY environment variable or use --api-key flag")
        sys.exit(1)

    # Load dictionary
    print(f"Loading dictionary from {INPUT_FILE}...")
    data = load_dictionary()
    words = data['words']
    total_words = len(words)

    print(f"Total words: {total_words:,}")

    # Load progress
    progress = load_progress()
    completed_set = set(progress['completed_indices'])
    clues_cache = progress['clues']

    print(f"Already completed: {len(completed_set):,} words")

    # Calculate batches to process
    start_idx = args.start
    end_idx = min(total_words, args.limit + start_idx) if args.limit else total_words

    # Find indices that need processing
    indices_to_process = [i for i in range(start_idx, end_idx) if i not in completed_set]

    print(f"Words to process: {len(indices_to_process):,}")

    if args.dry_run:
        print("\nDry run - showing first 10 words that would be processed:")
        for i in indices_to_process[:10]:
            print(f"  {i}: {words[i]['word']}")
        return

    # Initialize client
    client = anthropic.Anthropic(api_key=api_key)

    # Process in batches
    batch_count = (len(indices_to_process) + BATCH_SIZE - 1) // BATCH_SIZE
    print(f"\nProcessing {batch_count} batches of {BATCH_SIZE} words...")
    print("Progress will be saved after each batch.\n")

    processed = 0
    start_time = time.time()

    for batch_num in range(batch_count):
        batch_start = batch_num * BATCH_SIZE
        batch_end = min(batch_start + BATCH_SIZE, len(indices_to_process))
        batch_indices = indices_to_process[batch_start:batch_end]

        batch_words = [words[i]['word'] for i in batch_indices]

        print(f"Batch {batch_num + 1}/{batch_count}: {batch_words[0]} - {batch_words[-1]}", end=" ")

        # Generate clues
        clues = generate_clues_batch(client, batch_words)

        # Update data and cache
        for idx, clue in zip(batch_indices, clues):
            words[idx]['clue'] = clue
            clues_cache[str(idx)] = clue
            completed_set.add(idx)

        # Save progress
        progress['completed_indices'] = list(completed_set)
        progress['clues'] = clues_cache
        save_progress(progress)

        processed += len(batch_indices)
        elapsed = time.time() - start_time
        rate = processed / elapsed if elapsed > 0 else 0
        eta = (len(indices_to_process) - processed) / rate if rate > 0 else 0

        print(f"[{processed}/{len(indices_to_process)}] {rate:.1f} words/sec, ETA: {eta/60:.1f} min")

        # Small delay between batches to avoid rate limits
        if batch_num < batch_count - 1:
            time.sleep(0.5)

    # Save final dictionary
    print(f"\nSaving updated dictionary to {OUTPUT_FILE}...")

    # Update metadata
    data['metadata']['cluesGeneratedAt'] = datetime.now().isoformat()
    data['metadata']['cluesModel'] = MODEL

    with open(OUTPUT_FILE, 'w') as f:
        json.dump(data, f, indent=2)

    # Clean up progress file
    if os.path.exists(PROGRESS_FILE):
        os.remove(PROGRESS_FILE)

    total_time = time.time() - start_time
    print(f"\nComplete! Processed {processed:,} words in {total_time/60:.1f} minutes")
    print(f"Output: {OUTPUT_FILE}")


if __name__ == '__main__':
    main()
