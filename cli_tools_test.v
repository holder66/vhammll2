module vhammll2

// import os

fn test_flag() {
	// basic match — short form
	assert flag(['rank', '-h'], ['-h', '--help', 'help']) == true
	// basic non-match
	assert flag(['rank', '-h'], ['']) == false
	assert flag(['rank', '-h'], []) == false
	// non-flag string match
	assert flag(['rank', '-h'], ['rank']) == true
	// empty args — never matches
	assert flag([], ['-h', '--help', 'help']) == false
	assert flag([], []) == false

	// long-form flag match
	assert flag(['explore', '--graph'], ['--graph']) == true
	assert flag(['explore', '--graph'], ['-g', '--graph']) == true

	// case-sensitive: uppercase flag does not match lowercase entry in what
	assert flag(['-H'], ['-h', '--help', 'help']) == false
	assert flag(['--Help'], ['--help']) == false

	// match is the last element of args
	assert flag(['-a', '4', '-b', '2,8', '-g'], ['-g', '--graph']) == true

	// match is the last element of what (linear scan of args checks each against what)
	assert flag(['-g'], ['-s', '--short', '-g', '--graph']) == true

	// flag appears more than once in args — still true
	assert flag(['-g', '-s', '-g'], ['-g']) == true

	// single-element slices
	assert flag(['-s'], ['-s']) == true
	assert flag(['-s'], ['-g']) == false

	// value-like strings are not treated specially — plain equality check
	assert flag(['4'], ['4']) == true
	assert flag(['4'], ['-b']) == false

	// what contains only empty string, args contains only empty string
	assert flag([''], ['']) == true
	assert flag([''], ['-h']) == false
}

fn test_option() {
	// basic match — short and long form
	assert option(['-b', '2,6', 'datasets/iris.tab'], ['-b', '--bins']) == '2,6'
	assert option(['--bins', '2,6', 'datasets/iris.tab'], ['-b', '--bins']) == '2,6'

	// no match — returns empty string
	assert option(['-g', 'datasets/iris.tab'], ['-b', '--bins']) == ''

	// empty args — returns empty string
	assert option([], ['-b', '--bins']) == ''

	// empty what — returns empty string
	assert option(['-b', '2,6', 'datasets/iris.tab'], []) == ''

	// both empty
	assert option([], []) == ''

	// option is the last arg with no value following — returns empty string
	assert option(['datasets/iris.tab', '-b'], ['-b', '--bins']) == ''

	// value is the last element in args (no trailing datafile)
	assert option(['-pos', 'malignant'], ['-pos', '--positive-class']) == 'malignant'

	// option appears multiple times — returns the value after the first match
	assert option(['-b', '3,6', '-b', '2,8', 'datasets/iris.tab'], ['-b', '--bins']) == '3,6'

	// the value itself looks like a flag — still returned verbatim
	assert option(['-t', '-g', 'datasets/iris.tab'], ['-t', '--test']) == '-g'

	// what has multiple entries; match is on the second entry
	assert option(['--test', 'datasets/testdata/test.tab', 'datasets/iris.tab'], [
		'-t',
		'--test',
	]) == 'datasets/testdata/test.tab'

	// case-sensitive: wrong case does not match
	assert option(['-B', '3,6', 'datasets/iris.tab'], ['-b', '--bins']) == ''
	assert option(['--Bins', '3,6', 'datasets/iris.tab'], ['-b', '--bins']) == ''

	// value is an empty string (adjacent empty token)
	assert option(['-b', '', 'datasets/iris.tab'], ['-b', '--bins']) == ''

	// option buried in a longer arg list — still found
	assert option(['-a', '4', '-f', '5', '-b', '2,8', 'datasets/iris.tab'], ['-b', '--bins']) == '2,8'
}

fn test_get_options() {
	// --- defaults (empty args) ---
	mut o := get_options([])
	assert o.help_flag // args.len <= 1 triggers help

	assert o.bins == [2, 16]
	assert o.number_of_attributes == [0]
	assert o.switches_threshold == 2
	assert o.balance_prevalences_threshold == 0.9
	assert o.balance_prevalences_flag == true
	assert !o.graph_flag
	assert !o.show_flag
	assert !o.traverse_all_flags
	assert o.switches_flag
	assert !o.uniform_bins
	assert !o.show_attributes_flag
	assert !o.multiple_flag
	assert !o.break_on_all_flag
	assert o.multi_strategy == ''
	assert !o.one_vs_rest_flag
	assert !o.append_settings_flag
	assert !o.overfitting_flag
	assert !o.class_missing_purge_flag
	assert !o.random_pick
	assert !o.generate_roc_flag
	assert !o.all_attributes_flag
	assert o.datafile_path == ''
	assert o.testfile_path == ''
	assert o.outputfile_path == ''
	assert o.classifierfile_path == ''
	assert o.multiple_classify_options_file_path == ''
	assert o.settingsfile_path == ''
	assert o.kagglefile_path == ''
	assert o.roc_settingsfile_path == ''
	assert o.folds == 0
	assert o.repetitions == 0
	assert o.limit_output == 0
	assert o.limit_continuous == 0
	assert o.positive_class == ''
	assert o.classifiers == []
	assert o.partition_sizes == []
	assert o.partitionfiles_paths == []
	assert o.explore_rank == []

	// --- help flag triggering ---
	// single arg triggers help (args.len == 1)
	o = get_options(['-h'])
	assert o.help_flag
	o = get_options(['help'])
	assert o.help_flag
	// -h as first of exactly 2 args triggers help
	o = get_options(['-h', 'datasets/iris.tab'])
	assert o.help_flag
	o = get_options(['--help', 'datasets/iris.tab'])
	assert o.help_flag
	// -h among more than 2 args does NOT trigger help
	o = get_options(['rank', '-h', 'datasets/iris.tab'])
	assert !o.help_flag

	// --- boolean flags — short forms ---
	o = get_options(['-af', 'datasets/iris.tab'])
	assert o.traverse_all_flags
	o = get_options(['-g', 'datasets/iris.tab'])
	assert o.graph_flag
	o = get_options(['-nsw', 'datasets/iris.tab'])
	assert !o.switches_flag
	o = get_options(['-u', 'datasets/iris.tab'])
	assert o.uniform_bins
	o = get_options(['-s', 'datasets/iris.tab'])
	assert o.show_flag
	o = get_options(['-ea', 'datasets/iris.tab'])
	assert o.show_attributes_flag
	o = get_options(['-ma', 'datasets/iris.tab'])
	assert o.break_on_all_flag
	o = get_options(['-mt', 'datasets/iris.tab'])
	assert o.multi_strategy == 'totalnn'
	o = get_options(['-mc', 'datasets/iris.tab'])
	assert o.multi_strategy == 'combined'
	o = get_options(['-mr', 'datasets/iris.tab'])
	assert o.one_vs_rest_flag
	o = get_options(['-of', 'datasets/iris.tab'])
	assert o.overfitting_flag
	o = get_options(['-pmc', 'datasets/iris.tab'])
	assert o.class_missing_purge_flag
	o = get_options(['-rand', 'datasets/iris.tab'])
	assert o.random_pick
	o = get_options(['-aa', 'datasets/iris.tab'])
	assert o.all_attributes_flag

	// --- boolean flags — long forms ---
	o = get_options(['--all-flags', 'datasets/iris.tab'])
	assert o.traverse_all_flags
	o = get_options(['--graph', 'datasets/iris.tab'])
	assert o.graph_flag
	o = get_options(['--no-switches', 'datasets/iris.tab'])
	assert !o.switches_flag
	o = get_options(['--uniform', 'datasets/iris.tab'])
	assert o.uniform_bins
	o = get_options(['--short', 'datasets/iris.tab'])
	assert o.show_flag
	o = get_options(['--overfitting', 'datasets/iris.tab'])
	assert o.overfitting_flag
	o = get_options(['--purge-missing-classes', 'datasets/iris.tab'])
	assert o.class_missing_purge_flag
	o = get_options(['--all_attributes', 'datasets/iris.tab'])
	assert o.all_attributes_flag

	// --- options with values — short forms ---
	o = get_options(['-swt', '5', 'datasets/iris.tab'])
	assert o.switches_threshold == 5
	o = get_options(['-bpt', '0.75', 'datasets/iris.tab'])
	assert o.balance_prevalences_threshold == 0.75
	o = get_options(['-a', '3', 'datasets/iris.tab'])
	assert o.number_of_attributes == [3]
	o = get_options(['-a', '2,8', 'datasets/iris.tab'])
	assert o.number_of_attributes == [2, 8]
	o = get_options(['-b', '3,10', 'datasets/iris.tab'])
	assert o.bins == [3, 10]
	o = get_options(['-b', '5', 'datasets/iris.tab'])
	assert o.bins == [5]
	o = get_options(['-f', '10', 'datasets/iris.tab'])
	assert o.folds == 10
	o = get_options(['-r', '5', 'datasets/iris.tab'])
	assert o.repetitions == 5
	o = get_options(['-l', '20', 'datasets/iris.tab'])
	assert o.limit_output == 20
	o = get_options(['-lc', '8', 'datasets/iris.tab'])
	assert o.limit_continuous == 8
	o = get_options(['-pos', 'Iris-setosa', 'datasets/iris.tab'])
	assert o.positive_class == 'Iris-setosa'
	o = get_options(['-exr', '3,9', 'datasets/iris.tab'])
	assert o.explore_rank == [3, 9]
	o = get_options(['-m#', '0,5,10', 'datasets/iris.tab'])
	assert o.classifiers == [0, 5, 10]
	o = get_options(['-p#', '70,30', 'datasets/iris.tab'])
	assert o.partition_sizes == [70, 30]
	o = get_options(['-ps', 'out_a.tab,out_b.tab', 'datasets/iris.tab'])
	assert o.partitionfiles_paths == ['out_a.tab', 'out_b.tab']
	o = get_options(['-t', 'datasets/testdata/test_verify.tab', 'datasets/iris.tab'])
	assert o.testfile_path == 'datasets/testdata/test_verify.tab'
	o = get_options(['-o', '/tmp/result.json', 'datasets/iris.tab'])
	assert o.outputfile_path == '/tmp/result.json'
	o = get_options(['-k', '/tmp/classifier.json', 'datasets/iris.tab'])
	assert o.classifierfile_path == '/tmp/classifier.json'
	// -m sets both multiple_flag and multiple_classify_options_file_path
	o = get_options(['-m', 'multi.json', 'datasets/iris.tab'])
	assert o.multiple_flag
	assert o.multiple_classify_options_file_path == 'multi.json'
	// -ms sets both append_settings_flag and settingsfile_path
	o = get_options(['-ms', 'settings.json', 'datasets/iris.tab'])
	assert o.append_settings_flag
	assert o.settingsfile_path == 'settings.json'
	o = get_options(['-ka', 'submission.csv', 'datasets/iris.tab'])
	assert o.kagglefile_path == 'submission.csv'
	// -roc sets both generate_roc_flag and roc_settingsfile_path
	o = get_options(['-roc', 'roc.json', 'datasets/iris.tab'])
	assert o.generate_roc_flag
	assert o.roc_settingsfile_path == 'roc.json'
	// -cl sets generate_combinations_flag, min, and max
	o = get_options(['-cl', '2,5', 'datasets/iris.tab'])
	assert o.DisplaySettings.CombinationSizeLimits.generate_combinations_flag
	assert o.DisplaySettings.CombinationSizeLimits.min == 2
	assert o.DisplaySettings.CombinationSizeLimits.max == 5

	// --- options with values — long forms ---
	o = get_options(['--switch-threshold', '3', 'datasets/iris.tab'])
	assert o.switches_threshold == 3
	o = get_options(['--balance-prevalences-threshold', '0.8', 'datasets/iris.tab'])
	assert o.balance_prevalences_threshold == 0.8
	o = get_options(['--attributes', '5', 'datasets/iris.tab'])
	assert o.number_of_attributes == [5]
	o = get_options(['--bins', '4,12', 'datasets/iris.tab'])
	assert o.bins == [4, 12]
	o = get_options(['--folds', '5', 'datasets/iris.tab'])
	assert o.folds == 5
	o = get_options(['--reps', '3', 'datasets/iris.tab'])
	assert o.repetitions == 3
	o = get_options(['--limit-output', '15', 'datasets/iris.tab'])
	assert o.limit_output == 15
	o = get_options(['--limit-continuous', '6', 'datasets/iris.tab'])
	assert o.limit_continuous == 6
	o = get_options(['--positive-class', 'benign', 'datasets/iris.tab'])
	assert o.positive_class == 'benign'
	o = get_options(['--explore-rank', '2,7', 'datasets/iris.tab'])
	assert o.explore_rank == [2, 7]
	o = get_options(['--test', 'datasets/testdata/test_verify.tab', 'datasets/iris.tab'])
	assert o.testfile_path == 'datasets/testdata/test_verify.tab'
	o = get_options(['--output', '/tmp/out.json', 'datasets/iris.tab'])
	assert o.outputfile_path == '/tmp/out.json'
	o = get_options(['--classifier', '/tmp/cl.json', 'datasets/iris.tab'])
	assert o.classifierfile_path == '/tmp/cl.json'
	o = get_options(['--combination-limits', '3,6', 'datasets/iris.tab'])
	assert o.DisplaySettings.CombinationSizeLimits.generate_combinations_flag
	assert o.DisplaySettings.CombinationSizeLimits.min == 3
	assert o.DisplaySettings.CombinationSizeLimits.max == 6

	// --- non-options / datafile_path ---
	o = get_options(['analyze', 'datasets/iris.tab'])
	assert o.datafile_path == 'datasets/iris.tab'
	assert o.non_options == ['analyze', 'datasets/iris.tab']
	// flags only — no datafile_path
	o = get_options(['-g', '-s'])
	assert o.datafile_path == ''
	assert o.non_options == []
	// args field is always the raw input
	o = get_options(['garbage', 'more garbage'])
	assert o.args == ['garbage', 'more garbage']

	// --- edge cases ---
	// unknown flags are silently ignored
	o = get_options(['--unknown-flag', 'datasets/iris.tab'])
	assert o.datafile_path == 'datasets/iris.tab'
	assert !o.graph_flag
	// trailing value-option with no following arg — default is retained
	o = get_options(['datasets/iris.tab', '-swt'])
	assert o.switches_threshold == 2
	o = get_options(['datasets/iris.tab', '-b'])
	assert o.bins == [2, 16]
	o = get_options(['datasets/iris.tab', '-a'])
	assert o.number_of_attributes == [0]
	// -mt takes precedence over -mc when both are present (checked first in get_options)
	o = get_options(['-mt', '-mc', 'datasets/iris.tab'])
	assert o.multi_strategy == 'totalnn'

	// --- combined multi-option invocation ---
	o = get_options(['-g', '-u', '-s', '-mr', '-rand', '-a', '4', '-b', '2,8', '-f', '5', '-r',
		'3', '-swt', '4', '-bpt', '0.6', '-pos', 'malignant', '-t', 'datasets/testdata/test_verify.tab',
		'-o', '/tmp/result.json', '-k', '/tmp/cl.json', 'datasets/iris.tab'])
	assert o.graph_flag
	assert o.switches_flag
	assert o.uniform_bins
	assert o.show_flag
	assert o.one_vs_rest_flag
	assert o.random_pick
	assert o.number_of_attributes == [4]
	assert o.bins == [2, 8]
	assert o.folds == 5
	assert o.repetitions == 3
	assert o.switches_threshold == 4
	assert o.balance_prevalences_threshold == 0.6
	assert o.positive_class == 'malignant'
	assert o.testfile_path == 'datasets/testdata/test_verify.tab'
	assert o.outputfile_path == '/tmp/result.json'
	assert o.classifierfile_path == '/tmp/cl.json'
	assert o.datafile_path == 'datasets/iris.tab'
}

fn test_opts_function() {
	// empty string produces a single-element args slice
	assert get_opts('').args == ['']

	mut result := Options{}

	// flags and value-options together with a datafile
	result = get_opts('-g -b 2,7 -pos malignant datasets/breast-cancer-wisconsin-disc.tab')
	assert result.args == ['-g', '-b', '2,7', '-pos', 'malignant',
		'datasets/breast-cancer-wisconsin-disc.tab']
	assert result.graph_flag
	assert result.bins == [2, 7]
	assert result.positive_class == 'malignant'
	assert result.datafile_path == 'datasets/breast-cancer-wisconsin-disc.tab'
	assert result.command == ''

	// multiple-classifier options: -m path, -m# classifier ids
	result = get_opts('-pos ALL -m datasets/testdata/multiples-train.tab -m# 0,20,40 datasets/leukemia38train.tab')
	assert result.args == ['-pos', 'ALL', '-m', 'datasets/testdata/multiples-train.tab', '-m#',
		'0,20,40', 'datasets/leukemia38train.tab']
	assert result.command == ''
	assert result.positive_class == 'ALL'
	assert result.multiple_classify_options_file_path == 'datasets/testdata/multiples-train.tab'
	assert result.multiple_flag
	assert result.classifiers == [0, 20, 40]
	assert result.datafile_path == 'datasets/leukemia38train.tab'

	// attributes, bins, and test file — verify all parsed fields, not just args
	result = get_opts('-pos ALL -a 4 -b 1,4 -t datasets/leukemia34test.tab datasets/leukemia38train.tab')
	assert result.args == ['-pos', 'ALL', '-a', '4', '-b', '1,4', '-t', 'datasets/leukemia34test.tab',
		'datasets/leukemia38train.tab']
	assert result.positive_class == 'ALL'
	assert result.number_of_attributes == [4]
	assert result.bins == [1, 4]
	assert result.testfile_path == 'datasets/leukemia34test.tab'
	assert result.datafile_path == 'datasets/leukemia38train.tab'

	// multiple-classifier with test file
	result = get_opts('-pos ALL -m datasets/testdata/multiples-train.tab -m# 0,10 -t datasets/leukemia34test.tab datasets/leukemia38train.tab')
	assert result.args == ['-pos', 'ALL', '-m', 'datasets/testdata/multiples-train.tab', '-m#',
		'0,10', '-t', 'datasets/leukemia34test.tab', 'datasets/leukemia38train.tab']
	assert result.positive_class == 'ALL'
	assert result.multiple_classify_options_file_path == 'datasets/testdata/multiples-train.tab'
	assert result.classifiers == [0, 10]
	assert result.testfile_path == 'datasets/leukemia34test.tab'
	assert result.datafile_path == 'datasets/leukemia38train.tab'
}

fn test_show_help() {
	// each known command returns its own help constant
	assert show_help(Options{ command: 'analyze' }) == analyze_help
	assert show_help(Options{ command: 'append' }) == append_help
	assert show_help(Options{ command: 'cross' }) == cross_help
	assert show_help(Options{ command: 'display' }) == display_help
	assert show_help(Options{ command: 'examples' }) == examples_help
	assert show_help(Options{ command: 'explore' }) == explore_help
	assert show_help(Options{ command: 'make' }) == make_help
	assert show_help(Options{ command: 'optimals' }) == optimals_help
	assert show_help(Options{ command: 'orange' }) == orange_help
	assert show_help(Options{ command: 'partition' }) == partition_help
	assert show_help(Options{ command: 'query' }) == query_help
	assert show_help(Options{ command: 'rank' }) == rank_help
	assert show_help(Options{ command: 'validate' }) == validate_help
	assert show_help(Options{ command: 'verify' }) == verify_help
	// unknown and empty commands fall through to the general help
	assert show_help(Options{ command: '' }) == vhammll_help
	assert show_help(Options{ command: 'nonsense' }) == vhammll_help
}

fn test_print_array() ? {
	mut array := ['first line', 'second line']
	print_array(array)
	array = ['single line']
	print_array(array)
	array = ['']
	print_array(array)
	array = []
	print_array(array)
}
