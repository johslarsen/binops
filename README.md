# binops, *Bin*ary Data Transformation *Op*eration*s*

This is a collection of UNIX-like utilities for doing collection-like
transformation operations on binary data files/pipes.

## Utilities

| Name             | Description |
| ---------------- | ----------- |
| `bvisualize`     | An interactive hexdump GUI where the color of a pixel indicates the byte value.
| `bstride`        | Output date relative to fixed/variable length records.
| `hex2bin`        | Given hex data like `10 0-f f*a`, write it as binary data.
| `uniq_cols.gawk` | Linewise field counter (e.g. `1 2 2 2 1` -> `1 2*3 1`).
| `xd`             | `od` wrapper for printing hex-based bytes.

### Future additions

| Name          | Description |
| ------------- | ----------- |
| ~~`bgrep`~~   | Copy records matching pattern.
| ~~`bscan`~~   | Scan for pattern and copy match/before/after/between.
| ~~`bmap `~~   | or extend `bstride` with expression on data within records.
| ~~`baggre`~~  | or extend `bmap` with expression across records.
| ~~`buniq`~~   | `uniq` tool with mask `-c` and `-d` for records.
| ~~`bsearch`~~ | Binary search sorted fixed size records.
| ~~`bsort`~~   | Sort records by e.g. `-fCUT-LIKE-FIELDS`.

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
