module vhammll2

import strconv
import rand
import os

const cross_help = '
Description:
"cross": When verifying the accuracy of a ML tool, it is common practice
to train the tool on a subset of the instances in a datafile, and then
test that trained tool on the instances excluded from the subset.
Two schemes are: leave one out, where a single instance is kept aside
for testing; and n-fold partitioning, where n is often chosen to be 10.
The training and testing is repeated for every possible fold.
For example, suppose the total dataset has 700 instances. That would
give 70 instances for each fold, in the case of 10-fold partitioning.
Thus, 70 instances would be kept aside and the tool trained on the
remaining 630 instances, and this process would be repeated 10 times
to ensure that testing is done on all the instances.
Picking the instances to be kept aside can be done sequentially (for LOO)
or randomly (for folds > 1, always random in vhammll2).
An important consideration is that when training on a subset of instances,
the dataset characteristics used in the training NOT be those of the
whole dataset. For example, the maximum and minimum values for continuous
attributes need to be recalculated for the subset, and the map of unique
values for discrete attributes may be different also for the subset
compared to the whole dataset.

Usage: v run main.v cross <path_to_dataset_file>

Options:
  -a --attributes: the number of attributes (picked from the list of
      ranked attributes) to be used in training the classifier
  -b --bins: eg, "3,6" specifies the lower and upper limits for the
      number of slices or bins for continuous attributes;
  -bpt --balance-prevalences-threshold: ratio threshold below which class
      prevalences are considered imbalanced (default 0.9; range 0.0–1.0);
  -e --expanded: expanded results on the console;
  -f --folds: number of cross-validation folds (default is leave-one-out);
  -m --multiple:    classify using more than one trained classifier, followed
       by the path to a json file with parameters to generate
       each classifier;
  -ma: when multiple classifiers are used, stop classifying when
       matches have been found for all classifiers;
  -mc: sets multi_strategy to combined: combine the possible
       hamming distances for each classifier into a single list;
  -ms: when followed by a file path, appends the classifier settings
       to that settings file (for use in multiple classifier operations);
  -mt: sets multi_strategy to totalnn: add the nearest neighbors
       from each classifier, weight by class prevalences, and then
       infer from the totals; takes precedence over -mc if both
       are specified;
  -m#: followed by a list of which classifiers to apply in a
       multiple classification run (zero-indexed);
  -r --reps: number of repetitions;

'

fn multi_classify_balance_prevalence(opts Options) bool {
	path := opts.multiple_classify_options_file_path
	if path != '' && os.is_file(path) {
		s := os.read_file(path.trim_space()) or { panic('failed to open ${path}') }
		if s.contains('"balance_prevalences_flag":true') {
			return true
		}
	}
	return false
}

// cross_validate performs n-fold cross-validation on a dataset: it
// partitions the instances in a dataset into a fold, trains
// a classifier on all the dataset instances not in the fold, and
// then uses this classifier to classify the fold cases. This
// process is repeated for each of n folds, and the classification
// results are summarized.
// For multiclass datasets (ds.classes.len > 2), automatically uses
// one-vs-rest approach.
// Balance prevalences is always applied when imbalance is detected.
// For folds > 1 (non-LOO), random selection is always used.
// ```sh
// Options (also see the Options struct):
// bins: range for binning or slicing of continuous attributes;
// number_of_attributes: the number of attributes to use, in descending
// 	order of rank value;
// folds: number of folds n to use for n-fold cross-validation (default
// 	is leave-one-out cross-validation);
// repetitions: number of times to repeat n-fold cross-validations;
// balance_prevalences_threshold: the min/max ratio below which balancing triggers (default 0.9).
// Output options:
// show_flag: prints results to the console;
// expanded_flag: prints additional information to the console, including
// 	a confusion matrix.
// outputfile_path: saves the result as a json file.
// ```
pub fn cross_validate(opts Options) CrossVerifyResult {
	if opts.one_vs_rest_flag {
		return one_vs_rest_cross_validate(opts)
	}
	// auto-detect multiclass and use one-vs-rest
	ds_check := load_file(opts.datafile_path, opts.LoadOptions)
	if ds_check.classes.len > 2 {
		return one_vs_rest_cross_validate(opts)
	}
	mut ds := ds_check
	// always balance prevalences when imbalance is detected, or if any multiple classifier
	// settings file requires it
	if evaluate_class_prevalence_imbalance(ds, opts) || multi_classify_balance_prevalence(opts) {
		ds = balance_prevalences(mut ds, opts.balance_prevalences_threshold)
	}
	result := run_cross_validate(ds, opts)
	if opts.show_flag && opts.command == 'cross' {
		println('corrects: ${result.correct_counts} balanced_accuracy: ${result.balanced_accuracy:-6.2f} MCC: ${result.mcc:-7.3f} sens: ${result.sens:-7.3f} spec: ${result.spec:-4.3f} ma ${result.break_on_all_flag} strategy ${result.multi_strategy} ${opts.classifiers}')
	}
	return result
}

fn run_cross_validate(ds Dataset, opts Options) CrossVerifyResult {
	mut cross_opts := opts
	cross_opts.datafile_path = ds.path
	mut total_instances := ds.Class.class_values.len
	repeats := if opts.repetitions == 0 { 1 } else { opts.repetitions }
	// for each class, instantiate an entry in the confusion matrix map
	mut confusion_matrix_map := map[string]StringFloatMap{}
	for key1, _ in ds.class_counts {
		for key2, _ in ds.class_counts {
			confusion_matrix_map[key2][key1] = 0
		}
	}
	// instantiate a struct for the result
	mut inferences_map := map[string]int{}
	for key, _ in ds.class_counts {
		inferences_map[key] = 0
	}
	mut cross_result := CrossVerifyResult{
		Parameters:                          opts.Parameters
		LoadOptions:                         ds.LoadOptions
		DisplaySettings:                     opts.DisplaySettings
		MultipleOptions:                     opts.MultipleOptions
		Class:                               ds.Class
		datafile_path:                       ds.path
		multiple_classify_options_file_path: cross_opts.multiple_classify_options_file_path
		labeled_classes:                     ds.class_values
		pos_neg_classes:                     get_pos_neg_classes(ds)
		confusion_matrix_map:                confusion_matrix_map
		correct_inferences:                  inferences_map.clone()
		incorrect_inferences:                inferences_map.clone()
		wrong_inferences:                    inferences_map.clone()
		true_positives:                      inferences_map.clone()
		true_negatives:                      inferences_map.clone()
		false_positives:                     inferences_map.clone()
		false_negatives:                     inferences_map.clone()
	}
	cross_result.binning = get_binning(cross_opts.bins)

	if opts.multiple_flag {
		// disable concurrency, as not implemented for multiple classifiers
		cross_opts.multiple_classifier_settings = pick_classifiers(cross_opts.multiple_classify_options_file_path, cross_opts.classifiers) or {
			panic('Unable to load file ${cross_opts.multiple_classify_options_file_path}')
		}
		cross_result.multiple_classifier_settings = cross_opts.multiple_classifier_settings
		mut maximum_hamming_distance_array := []int{}
		for cl in cross_result.multiple_classifier_settings {
			maximum_hamming_distance_array << cl.maximum_hamming_distance
		}
		cross_opts.maximum_hamming_distance_array = maximum_hamming_distance_array
		cross_opts.total_max_ham_dist = array_sum(maximum_hamming_distance_array)
		cross_opts.lcm_max_ham_dist = lcm(maximum_hamming_distance_array)
		cross_opts.classifiers = cross_opts.multiple_classifier_settings.map(it.classifier_id)
	}
	mut repetition_result := CrossVerifyResult{}
	for rep in 0 .. repeats {
		// generate a pick list of indices
		// for folds > 1 (non-LOO), always use random selection
		folds_for_check := if cross_opts.folds == 0 {
			ds.class_values.len
		} else {
			cross_opts.folds
		}
		mut pick_list := []int{}
		if folds_for_check > 1 {
			// always random for non-LOO
			mut n := 0
			for pick_list.len < total_instances {
				n = rand.int_in_range(0, total_instances) or { 0 }
				if n in pick_list {
					continue
				}
				pick_list << n
			}
		} else {
			for i in 0 .. total_instances {
				pick_list << i
			}
		}
		repetition_result = do_repetition(pick_list, rep, ds, cross_opts) or { panic('panic in do_repetition') }
		cross_result.inferred_classes << repetition_result.inferred_classes
		cross_result.actual_classes << repetition_result.actual_classes
		cross_result.binning = repetition_result.binning
		cross_result.classifier_instances_counts << repetition_result.classifier_instances_counts
		cross_result.prepurge_instances_counts_array << repetition_result.prepurge_instances_counts_array
		cross_result.maximum_hamming_distance = repetition_result.maximum_hamming_distance
	}
	cross_result = summarize_results(repeats, mut cross_result)
	cross_result.Metrics = get_metrics(cross_result)
	if cross_result.pos_neg_classes.len == 2 {
		cross_result.BinaryMetrics = get_binary_stats(cross_result)
	}
	if opts.command != 'explore' && opts.expanded_flag {
		show_crossvalidation(cross_result, cross_opts)
	}
	if opts.outputfile_path != '' {
		cross_result.command = 'cross'
		save_json_file[CrossVerifyResult](cross_result, opts.outputfile_path)
	}
	if opts.append_settings_flag && opts.command == 'cross' {
		append_cross_verify_settings_to_file(cross_result, opts)
	}
	return cross_result
}

// do_repetition
fn do_repetition(pick_list []int, rep int, ds Dataset, cross_opts Options) ?CrossVerifyResult {
	mut fold_result := CrossVerifyResult{}
	// instantiate a struct for the result
	mut repetition_result := CrossVerifyResult{}
	// test if leave-one-out crossvalidation is requested
	folds := if cross_opts.folds == 0 { ds.class_values.len } else { cross_opts.folds }
	// non-concurrent: for each fold
	for current_fold in 0 .. folds {
		fold_result = do_one_fold(pick_list, current_fold, folds, ds, cross_opts)
		repetition_result.inferred_classes << fold_result.inferred_classes
		repetition_result.actual_classes << fold_result.labeled_classes
		repetition_result.binning = fold_result.binning
		repetition_result.classifier_instances_counts << fold_result.classifier_instances_counts
		repetition_result.prepurge_instances_counts_array << fold_result.prepurge_instances_counts_array
		repetition_result.maximum_hamming_distance = fold_result.maximum_hamming_distance
	}
	return repetition_result
}

// summarize_results
fn summarize_results(repeats int, mut result CrossVerifyResult) CrossVerifyResult {
	mut inferred := ''
	for i, actual in result.actual_classes {
		inferred = result.inferred_classes[i]

		result.labeled_instances[actual] += 1
		result.total_count += 1
		if inferred != '' {
			result.confusion_matrix_map[actual][inferred] += 1
		}
		if actual == inferred {
			result.correct_inferences[actual] += 1
			result.correct_count += 1
			result.true_positives[actual] += 1
		} else {
			if inferred != '' {
				result.wrong_inferences[inferred] += 1
				result.false_positives[inferred] += 1
			}
			result.incorrect_inferences[actual] += 1
			result.false_negatives[actual] += 1
			result.incorrects_count += 1
			result.wrong_count += 1
		}
	}
	if repeats > 1 {
		result.correct_count /= repeats
		result.incorrects_count /= repeats
		result.wrong_count /= repeats
		result.total_count /= repeats

		for k, v in result.labeled_instances {
			result.labeled_instances[k] = v / repeats
		}
		for k, v in result.correct_inferences {
			result.correct_inferences[k] = v / repeats
		}
		for k, v in result.incorrect_inferences {
			result.incorrect_inferences[k] = v / repeats
		}
		for k, v in result.wrong_inferences {
			result.wrong_inferences[k] = v / repeats
		}
		for k, v in result.true_positives {
			result.true_positives[k] = v / repeats
		}
		for k, v in result.false_positives {
			result.false_positives[k] = v / repeats
		}
		for k, v in result.false_negatives {
			result.false_negatives[k] = v / repeats
		}

		for k1, m in result.confusion_matrix_map {
			for k2, v in m {
				result.confusion_matrix_map[k1][k2] = v / f64(repeats)
			}
		}
	}
	return result
}

// div_map
fn div_map(n int, mut m map[string]int) map[string]int {
	for k, v in m {
		m[k] = v / n
	}
	return m
}

// do_one_fold
fn do_one_fold(pick_list []int, current_fold int, folds int, ds Dataset, cross_opts Options) CrossVerifyResult {
	mut byte_values_array := [][]u8{}
	// partition the dataset into a partial dataset and a fold
	mut part_ds, fold := partition(pick_list, current_fold, folds, ds, cross_opts)
	mut fold_result := CrossVerifyResult{
		labeled_classes:  fold.class_values
		instance_indices: fold.indices
	}
	// if not a multiple classifier situation
	if !cross_opts.multiple_flag {
		part_cl := make_classifier_using_ds(mut part_ds, cross_opts)
		fold_result.binning = part_cl.binning
		fold_result.maximum_hamming_distance = part_cl.maximum_hamming_distance

		fold_result.classifier_instances_counts << part_cl.instances.len
		fold_result.prepurge_instances_counts_array << part_cl.history_events[0].prepurge_instances_count
		for attr in part_cl.attribute_ordering {
			// get the index of the corresponding attribute in the fold
			j := fold.attribute_names.index(attr)
			// create byte_values for the fold data
			byte_values_array << process_fold_data(part_cl.trained_attributes[attr], fold.data[j])
		}
		// since the arrays in byte_values_array correspond to attributes,
		// we need to transpose the array so that the top level corresponds to the cases in a fold
		// to be classified, and the values in each array correspond to the trained attributes.
		fold_cases := transpose(byte_values_array)
		// for each class, instantiate an entry in the class table for the result
		// note that this needs to use the classes in the partition portion, not
		// the fold, so that wrong inferences get recorded properly.
		mut confusion_matrix_row := map[string]int{}
		// for each class, instantiate an entry in the confusion matrix row
		for key, _ in ds.Class.class_counts {
			confusion_matrix_row[key] = 0
		}
		for i, case in fold_cases {
			classify_result := classify_case(part_cl, case)
			fold_result.inferred_classes << classify_result.inferred_class
			fold_result.actual_classes << fold_result.labeled_classes[i]
		}
	} else { // ie, asking for multiple classifiers...
		// note that in this situation, a case will consist of an array of arrays of differing lengths,
		// corresponding to the differing classifiers.
		// conceptually, doing one fold with multiple classifiers is like doing
		// a multi_verify,
		mut classifier_array := []Classifier{}
		mut mult_fold_cases := [][][]u8{}
		mut mult_opts := cross_opts
		// create an array of classifiers, one for each index in classifiers
		for setting_params in mult_opts.multiple_classifier_settings.map(it.Parameters) {
			mult_opts.Parameters = setting_params
			fold_result.Parameters = setting_params
			part_cl := make_classifier_using_ds(mut part_ds, mult_opts)
			classifier_array << part_cl
			byte_values_array = [][]u8{}
			for attr in part_cl.attribute_ordering {
				j := fold.attribute_names.index(attr)
				byte_values_array << process_fold_data(part_cl.trained_attributes[attr], fold.data[j])
			}
			fold_cases := transpose(byte_values_array)
			mult_fold_cases << [fold_cases]
		}
		for i, case in transpose(mult_fold_cases) {
			m_classify_result := if mult_opts.multi_strategy == 'totalnn' {
				multiple_classifier_classify_totalnn(classifier_array, case, fold_result.labeled_classes, mult_opts)
			} else {
				multiple_classifier_classify(classifier_array, case, fold_result.labeled_classes, mult_opts)
			}
			fold_result.inferred_classes << m_classify_result.inferred_class
			fold_result.actual_classes << fold_result.labeled_classes[i]
			fold_result.nearest_neighbors_by_class << m_classify_result.nearest_neighbors_by_class
		}

		fold_result.MultipleOptions = mult_opts.MultipleOptions
	}
	return fold_result
}

// process_fold_data takes the data array corresponding to a specific attribute for all the
// cases to be classified, and for each case to be classified,
// gets either the translation table value for that case's value if a discrete attribute,
// or gets the bin number for the value if a continuous attribute.
// These byte values are returned in an array, one byte value for each case to be classified.
fn process_fold_data(part_attr TrainedAttribute, fold_data []string) []u8 {
	mut byte_vals := []u8{cap: fold_data.len}
	// for a continuous attribute
	if part_attr.attribute_type == 'C' {
		values := fold_data.map(f32(strconv.atof_quick(it)))
		byte_vals << bin_values_array(values, part_attr.minimum, part_attr.maximum, part_attr.bins)
	} else {
		byte_vals << fold_data.map(u8(part_attr.translation_table[it]))
	}
	return byte_vals
}
