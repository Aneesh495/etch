#!/usr/bin/env python3
"""
Verification script: Ensures zero em dashes (or en dashes) exist in any
source files, documentation, markdown files, scripts, or comments.
Exits with code 0 if clean, or code 1 with line details if any are found.
"""

import os
import sys

# Unicode code points for em dash and en dash represented via chr()
FORBIDDEN_CHARS = [
    (chr(0x2014), 'EM DASH (Unicode U+2014)'),
    (chr(0x2013), 'EN DASH (Unicode U+2013)'),
]

# Patterns in text that act as em dashes
FORBIDDEN_PATTERNS = [
    (' ' + '-' * 2 + ' ', 'Double hyphen as em dash punctuation'),
]

IGNORE_DIRS = {
    '.git',
    'node_modules',
    'build',
    'dist',
    '.cache',
}

IGNORE_EXTENSIONS = {
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.ico',
    '.pdf',
    '.zip',
    '.gz',
    '.tar',
    '.pyc',
    '.dylib',
    '.so',
    '.o',
    '.a',
}

SELF_FILENAME = 'verify_no_em_dashes.py'

def scan_file(filepath):
    violations = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            for line_no, line in enumerate(f, start=1):
                for char, desc in FORBIDDEN_CHARS:
                    if char in line:
                        violations.append((line_no, desc, line.strip()))
                # For files other than this verification script, check patterns
                if os.path.basename(filepath) != SELF_FILENAME:
                    for pat, desc in FORBIDDEN_PATTERNS:
                        if pat in line:
                            violations.append((line_no, desc, line.strip()))
    except Exception as e:
        print(f"Error reading {filepath}: {e}", file=sys.stderr)
    return violations

def main():
    root_dir = os.path.abspath(os.path.dirname(__file__))
    total_violations = 0
    scanned_files = 0

    for dirpath, dirnames, filenames in os.walk(root_dir):
        dirnames[:] = [d for d in dirnames if d not in IGNORE_DIRS]

        for filename in filenames:
            ext = os.path.splitext(filename)[1].lower()
            if ext in IGNORE_EXTENSIONS:
                continue

            filepath = os.path.join(dirpath, filename)
            rel_path = os.path.relpath(filepath, root_dir)
            violations = scan_file(filepath)
            scanned_files += 1

            if violations:
                print(f"FAILED: {rel_path}")
                for line_no, desc, line in violations:
                    print(f"  Line {line_no}: Found {desc} -> {line[:80]}")
                total_violations += len(violations)

    print("--------------------------------------------------")
    print(f"Typography Scan: {scanned_files} files checked.")
    if total_violations == 0:
        print("PASS: Zero em dashes or forbidden punctuation found.")
        sys.exit(0)
    else:
        print(f"FAIL: {total_violations} forbidden character violations found.")
        sys.exit(1)

if __name__ == '__main__':
    main()
