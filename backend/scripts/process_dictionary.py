#!/usr/bin/env python3
"""
Dictionary Processor for Word Forge

Downloads a dictionary, filters words, and generates short clues.
Target audience: Young teenagers

Filtering Rules:
1. Remove words < 4 letters
2. Remove words > 7 distinct letters (Word Forge uses 7 letter honeycomb)
3. Remove inappropriate content
4. Generate 2-5 word contextual clue for each word

Output: JSON file ready for MongoDB seeding
"""

import json
import os
import re
import urllib.request
from datetime import datetime
from collections import defaultdict

# Dictionary URL
DICT_URL = "https://gist.githubusercontent.com/deostroll/7693b6f3d48b44a89ee5f57bf750bd32/raw/426f564cf73b4c87d2b2c46ccded8a5b98658ce1/dictionary.txt"

# Output path
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'src', 'seeds', 'data')
OUTPUT_FILE = os.path.join(OUTPUT_DIR, 'dictionary-with-clues.json')

# Inappropriate words to filter (basic list - expand as needed)
INAPPROPRIATE_WORDS = {
    # Profanity
    'FUCK', 'SHIT', 'DAMN', 'HELL', 'ASS', 'BITCH', 'BASTARD', 'CRAP',
    'PISS', 'DICK', 'COCK', 'PUSSY', 'CUNT', 'WHORE', 'SLUT', 'FAG',
    # Drug references
    'METH', 'HEROIN', 'COCAINE', 'CRACK',
    # Violence
    'MURDER', 'RAPE', 'KILL', 'KILLING',
    # Add word stems that catch variations
}

# Words that START with these prefixes should be filtered
INAPPROPRIATE_PREFIXES = [
    'FUCK', 'SHIT', 'DICK', 'COCK', 'CUNT', 'PUSSY', 'WHORE', 'SLUT',
]


def download_dictionary():
    """Download dictionary from URL"""
    print(f"Downloading dictionary from {DICT_URL}...")
    with urllib.request.urlopen(DICT_URL) as response:
        content = response.read().decode('utf-8')
    words = [w.strip().upper() for w in content.split('\n') if w.strip()]
    print(f"Downloaded {len(words)} words")
    return words


def get_distinct_letters(word):
    """Get count of unique letters in a word"""
    return len(set(word.upper()))


def is_inappropriate(word):
    """Check if word is inappropriate for young teenagers"""
    word_upper = word.upper()

    # Exact match
    if word_upper in INAPPROPRIATE_WORDS:
        return True

    # Prefix match (catches variations like FUCKING, SHITTY, etc.)
    for prefix in INAPPROPRIATE_PREFIXES:
        if word_upper.startswith(prefix):
            return True

    return False


def filter_words(words):
    """Apply all filtering rules"""
    stats = {
        'total_input': len(words),
        'removed_short': 0,
        'removed_distinct': 0,
        'removed_inappropriate': 0,
        'removed_non_alpha': 0,
    }

    filtered = []

    for word in words:
        word = word.upper().strip()

        # Skip non-alphabetic words
        if not word.isalpha():
            stats['removed_non_alpha'] += 1
            continue

        # Rule 1: Remove words < 4 letters
        if len(word) < 4:
            stats['removed_short'] += 1
            continue

        # Rule 2: Remove words > 7 distinct letters
        if get_distinct_letters(word) > 7:
            stats['removed_distinct'] += 1
            continue

        # Rule 3: Remove inappropriate content
        if is_inappropriate(word):
            stats['removed_inappropriate'] += 1
            continue

        filtered.append(word)

    stats['total_output'] = len(filtered)
    return filtered, stats


def generate_placeholder_clue(word):
    """
    Generate a placeholder clue for a word.
    These can be edited in the admin portal later.

    Format: "Define: WORD (X letters)"
    """
    return f"Define: {word}"


def process_dictionary():
    """Main processing function"""
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Download
    words = download_dictionary()

    # Filter
    print("Filtering words...")
    filtered_words, filter_stats = filter_words(words)

    # Sort alphabetically
    filtered_words.sort()

    # Generate word entries with placeholder clues
    print("Generating entries...")
    word_entries = []
    length_distribution = defaultdict(int)
    distinct_distribution = defaultdict(int)

    for word in filtered_words:
        distinct_count = get_distinct_letters(word)
        length_distribution[len(word)] += 1
        distinct_distribution[distinct_count] += 1

        word_entries.append({
            'word': word,
            'clue': generate_placeholder_clue(word),
            'length': len(word),
            'distinctLetters': distinct_count
        })

    # Build output JSON
    output = {
        'metadata': {
            'totalWords': len(word_entries),
            'generatedAt': datetime.now().isoformat(),
            'source': DICT_URL,
            'filters': {
                'minLength': 4,
                'maxDistinctLetters': 7,
                'inappropriateRemoved': filter_stats['removed_inappropriate']
            },
            'filterStats': filter_stats,
            'lengthDistribution': dict(sorted(length_distribution.items())),
            'distinctLetterDistribution': dict(sorted(distinct_distribution.items()))
        },
        'words': word_entries
    }

    # Write output
    print(f"Writing to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(output, f, indent=2)

    # Print summary
    print("\n" + "="*50)
    print("PROCESSING COMPLETE")
    print("="*50)
    print(f"Input words:  {filter_stats['total_input']:,}")
    print(f"Output words: {filter_stats['total_output']:,}")
    print(f"\nFiltered out:")
    print(f"  - Too short (<4):     {filter_stats['removed_short']:,}")
    print(f"  - Too many distinct:  {filter_stats['removed_distinct']:,}")
    print(f"  - Inappropriate:      {filter_stats['removed_inappropriate']:,}")
    print(f"  - Non-alphabetic:     {filter_stats['removed_non_alpha']:,}")
    print(f"\nLength distribution:")
    for length, count in sorted(length_distribution.items()):
        print(f"  {length} letters: {count:,}")
    print(f"\nDistinct letter distribution:")
    for distinct, count in sorted(distinct_distribution.items()):
        print(f"  {distinct} distinct: {count:,}")
    print(f"\nOutput: {OUTPUT_FILE}")

    return output


if __name__ == '__main__':
    process_dictionary()
