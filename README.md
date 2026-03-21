[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

# VHamMLL2
A simplified machine learning (ML) library for classification using a nearest neighbor algorithm based on Hamming distances. VHamMLL2 is a fork of [VHamMLL](https://github.com/holder66/vhammll) with these key differences:

- Balance prevalences is applied automatically when class imbalance is detected
- Multiclass datasets automatically use one-vs-rest
- No concurrent processing
- No `purge` command
- For cross-validation with folds > 1, random selection is always used

You can incorporate the `vhammll2` functions into your own code, or use the included Command Line Interface app (`src/cli.v`).

You can use `vhammll2` with your own datasets, or with a selection of publicly available datasets in the `datasets` directory. These files are mostly in [Orange file format](https://orange3.readthedocs.io/projects/orange-data-mining-library/en/latest/reference/data.io.html); there are also datasets in [ARFF (Attribute-Relation File Format)](https://waikato.github.io/weka-wiki/formats_and_processing/arff_stable/) or in comma-separated-values (CSV) as used in [Kaggle](https://www.kaggle.com).

What, another AI package? [Is that necessary?](docs/AI_for_rest_of_us.md)
And have a look here for a more complete [description and potential use cases](docs/description.md).

[Glossary of terms](docs/glossary.md)

For interactive descriptions of the two key algorithms used by VHamMLL2, download the Numbers app spreadsheets: [Description of Ranking Algorithm](docs/description_of_attribute_ranking_algorithm.numbers) and [Description of Classification Algorithm](docs/description_of_classification_algorithm.numbers).

## Installation

Dependencies: [vsl](https://github.com/holder66/vsl) and [chalk](https://github.com/hungrybluedev/chalk)

First, install V if not already installed. On macOS/Linux you need `git` and a C compiler:

```sh
git clone https://github.com/vlang/v
cd v
make
sudo ./v symlink   # add v to your PATH
```

Then clone and build vhammll2:

```sh
git clone https://github.com/holder66/vhammll2
cd vhammll2
v install        # installs dependencies
v -o vhammll2 src/
```

### To use as a library in your own project:

Clone vhammll2 into your V modules path:
```sh
git clone https://github.com/holder66/vhammll2 ~/.vmodules/vhammll2
```

In your V code, add:
```v
import vhammll2
```

## Usage

```sh
./vhammll2 <command> [options] <path_to_datafile>
# or without compiling:
v run src/main.v <command> [options] <path_to_datafile>
```

For help:
```sh
./vhammll2 --help
./vhammll2 <command> --help
```

## Tutorial

```sh
./vhammll2 examples go
```

## Updating

```sh
cd vhammll2
git pull
```

## Getting help

The V lang community meets on [Discord](https://discord.gg/vlang)

For bug reports and feature requests, please raise an issue on [github](https://github.com/holder66/vhammll2/issues)

## Performance

For faster runtime, compile with the `-prod` (production) flag:

```sh
v -prod -o vhammll2 src/
./vhammll2 explore datasets/iris.tab
```

## Examples showing use of the Command Line Interface

Please see [examples_of_command_line_usage.md](docs/examples_of_command_line_usage.md)

## Using multiple classifiers

VHamMLL2 can combine several classifiers trained with different settings to improve
classification accuracy. Please see
[multiple_classifier_workflow.md](docs/multiple_classifier_workflow.md)
for a step-by-step guide.

## Example: typical use case, a clinical risk calculator

Please see [clinical_calculator_example.md](docs/clinical_calculator_example.md).

## Example: finding useful information embedded in noise

Please see a worked example here: [noisy_data.md](docs/noisy_data.md)

## MNIST dataset

The mnist_train.tab file is too large to keep in the repository. If you wish to experiment with it, it can be downloaded by right-clicking on [this link](https://henry.olders.ca/datasets/mnist_train.tab) in a web browser, or downloaded via the command line:
```
wget https://henry.olders.ca/datasets/mnist_train.tab
```

The process of development in its early stages is described in [this essay](https://henry.olders.ca/wordpress/?p=731) written in 1989.


Copyright (c) 2017, 2024: Henry Olders.
