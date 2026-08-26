# ~/tools

Your toolbelt. Everything here is on `$PATH` and available from any directory.
Any language works — Python, Rust, shell, Go — as long as it's executable and has `--help`.

## The rules

1. **Do one thing.** If it does two things, it's two tools.
2. **Work from any directory.** Take file paths as arguments. Never assume cwd.
3. **Support `--help`.** `guide` reads this to generate interactive prompts.
4. **stdout is data.** Pipeable, composable, machine-readable.
5. **stderr is human.** Progress, warnings, errors.
6. **stdin when it makes sense.** Accept piped input as an alternative to file arguments.
7. **Exit 0 on success, 1 on error, 2 on bad usage.**
8. **Don't touch cwd.** No temp files, no logs, no dotfiles in the user's content directory.

## Creating a tool

### Python (argparse)

```python
#!/usr/bin/env python3
"""One-line description goes here."""

import argparse, sys

parser = argparse.ArgumentParser(description="One-line description goes here")
parser.add_argument("input", help="input file path")
parser.add_argument("--size", type=int, default=50, help="batch size (default: 50)")
parser.add_argument("--output", choices=["json", "csv", "table"], default="table",
                    help="output format (default: table)")
parser.add_argument("--dry-run", action="store_true", help="preview without writing")

args = parser.parse_args()

# stdout = results (pipeable)
print(f"processed {args.input}")

# stderr = progress (human-readable)
print(f"working...", file=sys.stderr)
```

```sh
cp myscript.py ~/tools/mytool
chmod +x ~/tools/mytool
```

### Python (click)

```python
#!/usr/bin/env python3
"""One-line description goes here."""

import click

@click.command()
@click.argument("input", type=click.Path(exists=True))
@click.option("--size", default=50, help="Batch size.")
@click.option("--output", type=click.Choice(["json", "csv", "table"]), default="table")
@click.option("--dry-run", is_flag=True, help="Preview without writing.")
def main(input, size, output, dry_run):
    """One-line description goes here."""
    click.echo(f"processed {input}")

if __name__ == "__main__":
    main()
```

### Rust (clap)

```rust
use clap::Parser;

/// One-line description goes here.
#[derive(Parser)]
struct Args {
    /// Input file path
    input: String,

    /// Batch size
    #[arg(short, long, default_value_t = 50)]
    size: usize,

    /// Output format
    #[arg(short, long, default_value = "table", value_parser = ["json", "csv", "table"])]
    output: String,

    /// Preview without writing
    #[arg(long)]
    dry_run: bool,
}

fn main() {
    let args = Args::parse();
    println!("processed {}", args.input);
}
```

Build and install:

```sh
cargo build --release
cp target/release/mytool ~/tools/
```

`guide` parses clap's `--help` output the same way it parses argparse.

### Shell script

```bash
#!/bin/bash
# One-line description goes here

show_help() {
    echo "Usage: mytool [OPTIONS] INPUT"
    echo ""
    echo "One-line description goes here"
    echo ""
    echo "positional arguments:"
    echo "  INPUT                 input file path"
    echo ""
    echo "options:"
    echo "  --size SIZE           batch size (default: 50)"
    echo "  --output FORMAT       output format: json, csv, table (default: table)"
    echo "  --dry-run             preview without writing"
    echo "  --help                show this help"
}

# Parse args
SIZE=50
OUTPUT="table"
DRY_RUN=""
INPUT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --size) SIZE="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --help|-h) show_help; exit 0 ;;
        *) INPUT="$1"; shift ;;
    esac
done

[ -z "$INPUT" ] && { show_help; exit 2; }

echo "processed $INPUT"
```

For shell scripts, write `--help` output that looks like the format above.
`guide` will parse it.

## Promoting a prototype

You have a script that works. Make it a tool:

```sh
# 1. Copy it
cp ~/projects/experiment/myscript.py ~/tools/analyze

# 2. Make it executable
chmod +x ~/tools/analyze

# 3. Verify
tools              # should appear in the list
tools analyze      # should show help
guide analyze      # should generate prompts
```

That's it. Available everywhere, immediately.

If the tool is a compiled binary (Rust, Go, C):

```sh
cp target/release/analyze ~/tools/
# already executable from the build
```

## stdin / stdout / stderr

```sh
# stdout is data — pipe it, redirect it, compose it
mytool data.csv > results.csv
mytool data.csv | grep error | wc -l
mytool data.csv | sort -k2 -t$'\t' | head -20

# stderr is progress — visible to the user, doesn't pollute pipes
mytool data.csv > results.csv    # stderr still shows progress
mytool data.csv 2>/dev/null      # silence progress

# stdin as alternative to file argument
cat data.csv | mytool --size 50
curl https://example.com/data.csv | mytool
```

**Rule of thumb:** if the output might be piped into another tool, it goes to stdout.
If it's for the human watching the terminal, it goes to stderr.

## The `--help` format that works best

`guide` parses `--help` output to generate interactive prompts. It handles
argparse, click, clap, and hand-written help. The key patterns it looks for:

```
Usage: toolname [OPTIONS] INPUT        ← usage line (skipped)

One-line description.                  ← first text after usage = description

positional arguments:                  ← section header
  INPUT                 what it is     ← name + help text

options:                               ← section header
  --size SIZE           help text (default: 50)         ← flag + VALUE = prompted input
  --output {json,csv}   help text                       ← {choices} = dropdown
  --output FORMAT       json, csv, table (default: csv) ← choices in text
  --dry-run             help text                       ← no VALUE = boolean flag
  -s, --size SIZE       help text                       ← short + long flag
```

**What matters:**
- First paragraph after usage line = description (shown by `tools`)
- `--flag VALUE` with uppercase VALUE = `guide` prompts for a value
- `--flag` alone (no value) = `guide` prompts yes/no
- `{a,b,c}` or `[possible values: a, b, c]` = `guide` shows choices
- `(default: X)` or `[default: X]` = `guide` uses as default

## The helpers

```
tools              list all tools with descriptions
tools <name>       show full --help for a tool
guide <tool>       interactive prompts, pre-filled from last use
again              show recent run history
again <tool>       re-run last invocation of that tool
again <tool> 2     re-run 2nd most recent
run <tool> <args>  log the invocation and execute (shell function)
```

`run` is a shell function in `.zshrc` — it logs every invocation to history.
`guide` also logs. `again` replays from the log. Direct invocations (without
`run`) work fine, they just don't appear in history.

## Files

```
~/tools/           tools on $PATH (this directory)
~/.tools/          config (not on PATH, not in your content)
  history.tsv      run log: timestamp, tool, command, cwd
  cache/           parsed --help cache (auto-invalidated by file mtime)
```

History is a plain TSV — grep it, tail it, awk it:

```sh
grep batches ~/.tools/history.tsv          # all batches runs
tail -5 ~/.tools/history.tsv               # last 5 runs of anything
grep "2026-02" ~/.tools/history.tsv        # everything this month
```
