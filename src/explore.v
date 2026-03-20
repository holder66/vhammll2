module vhammll2

const explore_help = '
Description:
"explore" runs a series of cross-validations (or of verifies, if a
second file is given) over a range of parameter
settings, used when seeking optimal values for parameters. A parameter
range can be specified with up to 3 integers, with the first two for
lower and upper ends of the range, and the 3rd integer (optional) for
the interval. For example, --bins 2,12,3 would indicate to do
cross-validations for bins settings of 2, 5, 8, and 11. Note that a
single integer specifies the upper end of a range starting at 1.

Usage: v run main.v explore <options> <path_to_dataset_file>

Options:
  -a --attributes: a range for the number of attributes (picked from the list
      of ranked attributes) to be used in training the classifier;
  -af --all-flags: used with explore to repeat the explore operation for all
      possible combinations of -u (uniform_bins) settings;
  -b --bins: a range for the number of bins for continuous attributes;
  -bpt --balance-prevalences-threshold: ratio threshold below which class
      prevalences are considered imbalanced (default 0.9; range 0.0–1.0);
  -e --expanded: show expanded results on the console;
  -f --folds: number of cross-validation folds (default is leave-one-out);
  -g --graph: generates plots of accuracy vs number of attributes used; for
      binary classifiers (ie only 2 classes) also generates ROC plots;
  -ms: save the classifier parameters to an .opts file, using the file path
      following this option;
  -o --output: followed by the path to a file in which the ExploreResult
      struct will be saved;
  -r --reps: number of repetitions;
  -roc: collect settings for generating a Receiver Operating Characteristic (ROC)
      curve; if followed by a file path, appends classifier setting to this file;
  -s --show: show output on the console;
  -t --test: followed by the path to a second file, used for verifications;
  -u --uniform: specifies that the number of bins used will be the same
      for all attributes on a given cross-validation or verification;
'

// explore runs a series of cross-validations or verifications,
// over a range of attributes and a range of binning values.
// Balance prevalences is always applied when imbalance is detected.
// traverse_all_flags iterates over uniform_bins settings only.
// ```sh
// Options (also see the Options struct):
// append_settings_flag: if true, appends classifier settings to an
//  opts file;
// bins: range for binning or slicing of continuous attributes;
// uniform_bins: same number of bins for all continuous attributes;
// number_of_attributes: range for attributes to include;
// folds: number of folds n to use for n-fold cross-validation (default
// 	is leave-one-out cross-validation);
// repetitions: number of times to repeat n-fold cross-validations;
// Output options:
// show_flag: display results on the console;
// expanded_flag: display additional information on the console, including
// 	a confusion matrix for each explore step;
// graph_flag: generate plots of Receiver Operating Characteristics (ROC)
// 	by attributes used; ROC by bins used, and accuracy by attributes
//	used.
// balance_prevalences_threshold: duplicates minority-class instances until
//  prevalences are balanced; threshold is the min/max ratio below which
//  balancing triggers (default 0.9);
// traverse_all_flags: repeat the explore operation for both uniform_bins
//  settings (true and false);
// outputfile_path: saves the result to a file.
// ```
pub fn explore(opts Options) ExploreResult {
	mut af_opts := opts
	mut af_result := ExploreResult{}
	if opts.traverse_all_flags {
		ft := [false, true]
		for ub in ft {
			af_opts.uniform_bins = ub
			af_result = run_explore(af_opts)
		}
		return af_result // returns just the last result for multiple explores
	}
	return run_explore(opts)
}

fn run_explore(opts Options) ExploreResult {
	mut ds := load_file(opts.datafile_path, opts.LoadOptions)
	// always balance prevalences when imbalance is detected
	if evaluate_class_prevalence_imbalance(ds, opts) {
		ds = balance_prevalences(mut ds, opts.balance_prevalences_threshold)
	}
	mut ex_opts := opts
	mut results := ExploreResult{
		Parameters:      opts.Parameters
		LoadOptions:     ds.LoadOptions
		DisplaySettings: opts.DisplaySettings
		Class:           ds.Class
		path:            ds.path
		testfile_path:   opts.testfile_path
		AttributeRange:  get_attribute_range(opts.number_of_attributes,
			ds.useful_continuous_attributes.len + ds.useful_discrete_attributes.len)
		pos_neg_classes: get_pos_neg_classes(ds)
		args:            opts.args
	}
	mut result := CrossVerifyResult{
		pos_neg_classes: results.pos_neg_classes
	}
	// if there are no useful continuous attributes, skip the binning
	if ds.useful_continuous_attributes.len == 0 {
		ex_opts.bins = [0]
	}
	results.binning = get_binning(ex_opts.bins)
	binning := results.binning
	if opts.command == 'explore' && (opts.show_flag || opts.expanded_flag) {
		show_explore_header(results, results.DisplaySettings)
	}
	mut atts := results.start
	mut array_of_results := []CrossVerifyResult{}

	for atts <= results.end {
		ex_opts.number_of_attributes = [atts]
		mut bin := binning.lower
		for bin <= binning.upper {
			if ex_opts.uniform_bins {
				ex_opts.bins = [bin, bin]
			} else {
				ex_opts.bins = [1, bin]
			}
			if ex_opts.testfile_path == '' {
				result = cross_validate(ex_opts)
			} else {
				result = verify(ex_opts)
			}
			result.bin_values = ex_opts.bins
			result.attributes_used = atts
			show_explore_line(result, results.DisplaySettings)

			array_of_results << result
			bin += binning.interval
		}
		atts += results.att_interval
	}
	results.array_of_results = array_of_results
	if opts.outputfile_path != '' {
		save_json_file[ExploreResult](results, opts.outputfile_path)
	}
	mut explore_analytics_values := explore_analytics(results)
	if opts.command == 'explore' && (opts.show_flag || opts.expanded_flag) {
		show_explore_trailer(results, explore_analytics_values, opts)
	}
	if opts.graph_flag {
		plot_explore(results, opts)
		if ds.class_counts.len == 2 {
			plot_explore_roc(results, opts)
		}
	}
	if opts.append_settings_flag {
		append_explore_settings_to_file(results, explore_analytics_values, opts)
	}
	return results
}

// get_attribute_range
fn get_attribute_range(atts []int, max int) AttributeRange {
	if atts == [0] {
		return AttributeRange{
			start:        1
			end:          max
			att_interval: 1
		}
	}
	if atts.len == 1 {
		return AttributeRange{
			start:        1
			end:          atts[0]
			att_interval: 1
		}
	}
	if atts.len == 2 {
		return AttributeRange{
			start:        atts[0]
			end:          atts[1]
			att_interval: 1
		}
	}
	return AttributeRange{
		start:        atts[0]
		end:          atts[1]
		att_interval: atts[2]
	}
}
