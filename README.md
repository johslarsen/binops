# binops, *Bin*ary Data Transformation *Op*eration*s*

This is a collection of UNIX-like utilities for doing collection-like
transformation operations on binary data files/pipes.

## Utilities

| Name             | Description |
| ---------------- | ----------- |
| `bstride`        | Given `-wNBYTE` sized records, extract `-fCUT-LIKE-FIELDS`.
| `uniq_cols.gawk` | Linewise field counter (e.g. `1 2 2 2 1` -> `1 2*3 1`).
| `xd`             | `od` wrapper for printing hex-based bytes.

### Future additions

| Name          | Description |
| ------------- | ----------- |
| ~~`bgrep`~~   | Copy fixed size records matching pattern.
| ~~`bscan`~~   | Scan for pattern and copy match/before/after/between.
| ~~`bmap `~~   | or extend `bstride` with expression on fixed sized records.
| ~~`baggre`~~  | or extend `bmap` with expression across fixed sized records.
| ~~`buniq`~~   | `uniq` tool with mask `-c` and `-d` for fixed sized records.
| ~~`bsearch`~~ | Binary search sorted fixed size records.
| ~~`bsort`~~   | Sort fixed size record by e.g. `-fCUT-LIKE-FIELDS`.

Note that names are only preliminary, order is kind of prioritized, and that
strikethrough is just to emphasize that these do not exist yet.

## Install

Add the `bin` directory to your path.

## Bugs

These utilities are initially being developed as prototypes in scripting
languages to see what sort utilities and functionality that is most useful.
However, this is certainly not the most efficient way of implementing them, so
the most performance critical ones may benefit from being reimplemented in a
compiled language (e.g. C/C++ or Julia) in the future.
