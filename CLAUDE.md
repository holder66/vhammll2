# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About this project

`vhammll2` is a simplified V-language ML library for classification using Hamming distances. It is a fork of `vhammll` with these key differences:
- Balance prevalences is always applied automatically when class imbalance is detected
- Multiclass datasets automatically use one-vs-rest
- No concurrent processing
- No purge command
- For cross-validation with folds > 1, random selection is always used

Dependencies: `https://github.com/holder66/vsl` and `https://github.com/hungrybluedev/chalk`

## Commands

### Build and run
```sh
v run src/main.v <command> [options] <path_to_datafile>
# or after installing:
vhammll2 <command> [options] <path_to_datafile>
```

### Run all tests
```sh
v test src/
```

### Run a single test file
```sh
v test src/verify_test.v
```

### Run tests with verbose output
```sh
v -stats test src/
```

### Build the binary
```sh
v -o vhammll2 src/
```

## CLI commands

| Command | Description |
|---------|-------------|
| `analyze` | Print dataset statistics |
| `append` | Extend a saved classifier with new labeled instances (`-k` classifier file) |
| `cross` | n-fold cross-validation |
| `display` | Show a previously saved result file |
| `examples` | Walk through interactive usage examples |
| `explore` | Parameter sweep (bins × attributes) to find optimal classifier settings |
| `make` | Train a classifier from a dataset |
| `optimals` | Find best classifiers from a settings file |
| `partition` | Split a datafile into train/test partitions |
| `query` | Interactive instance builder + classifier |
| `rank` | Rank attributes by class-separating power |
| `validate` | Classify an unlabeled dataset |
| `verify` | Evaluate a classifier against a labeled test set |

Key flags: `-a` (number of attributes), `-b` (bin range, e.g. `2,16`), `-t` (test file), `-k` (classifier file), `-o` (output file), `-g` (generate plots), `-s` (short/summary output).

## Architecture

### Core data pipeline

```
load_file() -> Dataset -> make_classifier() -> Classifier -> verify()/cross_validate()/validate()
                                   ^
                             rank_attributes()
                             (ranks attributes before training)
```

1. **`load_file(path, LoadOptions)`** (`load_file.v`) — detects file type (Orange newer `.tab`, Orange older `.tab`, `.arff`, `.csv`) and delegates to the appropriate loader. Returns a `Dataset`.
2. **`rank_attributes(opts)`** (`rank.v`) — ranks attributes by their Hamming-distance-based discriminating power, returns `RankingResult`.
3. **`make_classifier(opts)`** (`make_classifier.v`) — calls `load_file`, optionally balances prevalences, calls `rank_attributes`, then encodes instances as `[]u8` arrays. Returns a `Classifier`.
4. **`verify(opts)`** / **`cross_validate(opts)`** (`verify.v`, `cross_validate.v`) — applies a classifier to labeled instances, returns `CrossVerifyResult` with confusion matrix and metrics.
5. **`validate(cl, opts)`** (`validate.v`) — applies a classifier to an unlabeled dataset, returns `ValidateResult`.
6. **`explore(opts)`** (`explore.v`) — sweeps over binning and attribute-count ranges, returns `ExploreResult` containing an array of `CrossVerifyResult`.

### Key structs (all in `structs.v`)

- **`Dataset`** — raw loaded data plus `useful_continuous_attributes` and `useful_discrete_attributes` maps ready for training.
- **`Classifier`** — trained model: `trained_attributes map[string]TrainedAttribute]`, encoded `instances [][]u8`, class info, and `History`.
- **`Options`** — the single all-in-one options struct (embeds `Parameters`, `LoadOptions`, `DisplaySettings`, `MultipleOptions`) passed through almost every public function.
- **`CrossVerifyResult`** — verification output: confusion matrix, `BinaryMetrics` (MCC, sensitivity, specificity, PPV, NPV), `Metrics` (per-class precision/recall/F1, balanced accuracy).
- **`RankingResult`** — ordered `[]RankedAttribute` with rank values, bin counts, and (optionally) dominant-class switch counts.

### Multi-class strategy

Multiclass problems are handled by `one_vs_rest_verify.v` and `rank_one_vs_rest.v` — each class is treated as the positive class in turn, and results are aggregated.

### File formats

Datasets use Orange `.tab` format (older 3-header-line or newer flag-prefixed), ARFF, or CSV. The `file_type()` function in `load_file.v` auto-detects format by checking the file extension and header content.

### Test patterns

Tests use `testsuite_begin()`/`testsuite_end()` to create/destroy temp directories under `tempfolders/`. The `get_opts(string)` helper in `cli.v` converts a space-separated arg string into an `Options` struct — use this in tests instead of constructing `Options{}` by hand:

```v
result := verify(get_opts('-a 2 -b 2,3 -t datasets/test_verify.tab datasets/test.tab'))
```
