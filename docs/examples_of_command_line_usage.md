# Examples of Command Line usage

## Build the binary
In your terminal, navigate to the vhammll2 directory:
```sh
% cd <vhammll2 directory>
% v -prod -o vhammll2 src/
```

Now you can run the app with command line entries starting with `% ./vhammll2`,
as in `% ./vhammll2 analyze datasets/anneal.tab`.
Sometimes, it may be more convenient to start with `% v run src/main.v`, as in
`% v run src/main.v verify -t datasets/bcw174test datasets/bcw350train`.

## Getting help
`% v run src/main.v --help` or
`% v run src/main.v -h` or simply,
`% v run src/main.v`

For individual commands, use this pattern:

`% v run src/main.v analyze --help` or

`% v run src/main.v analyze -h` or

`% v run src/main.v analyze`

## Analyzing a dataset
`% ./vhammll2 analyze datasets/anneal.tab`

## Discovering which attributes are most useful
`% ./vhammll2 rank --show --graph datasets/anneal.tab` or

`% ./vhammll2 rank -s -g datasets/anneal.tab`

To specify a range for the number of bins for continuous attributes (if unspecified, the default range is 2 through 16 inclusive):

`% ./vhammll2 rank --show --bins 3,6 datasets/iris.tab` or

`% ./vhammll2 rank -s -b 3,6 datasets/iris.tab`

To calculate rank values using the same number of bins for all attributes:

`% ./vhammll2 rank -s -b 3,3 datasets/iris.tab`

To exclude missing values from the rank value calculations:

`% ./vhammll2 rank --exclude --show --graph datasets/anneal.tab` or

`% ./vhammll2 rank -s -g -e datasets/anneal.tab`

## Working with large datasets
Doing a leave-one-out cross-validation on a large dataset can be time-consuming.
Save time by doing fewer folds, eg 10-fold (`-f 10`).
Repeat the exercise 5 times (`-r 5`); results are averaged over the 5 repetitions, since random selection of instances for folding means that results will be different from one repetition to another:

`% ./vhammll2 analyze datasets/mnist_test.tab`

`% ./vhammll2 cross -s -e -f 10 -r 5 -a 310 -b 2,2 datasets/mnist_test.tab`

## To explore how varying parameters affect classification accuracy
`% ./vhammll2 explore --expand --graph --weight datasets/breast-cancer-wisconsin-disc.tab` or

`% ./vhammll2 explore -e -g -w datasets/breast-cancer-wisconsin-disc.tab`

To specify how the number of attributes should be varied (eg, from 2 through 8 attributes, inclusive, stepping by 2):

`% ./vhammll2 explore -e -g -w --attributes 2,8,2 datasets/breast-cancer-wisconsin-disc.tab`

For datasets with continuous attributes, specify the binning range (eg, from 3 through 30 bins, stepping by 3):

`% ./vhammll2 explore -s -g -w --bins 3,30,3 datasets/iris.tab`

To use the same number of bins for each attribute, add the -u or --uniform flag:

`% ./vhammll2 explore -s -g -w -b 3,30,3 -u datasets/iris.tab`
