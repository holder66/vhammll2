module vhammll2

import rand

// one_vs_rest_cross_validate performs n-fold cross-validation using a
// one-vs-rest strategy, consistent with how binary cross-validation works:
//   For each class k, remap the entire dataset to binary (class_k vs
//   not_class_k) and balance the full binary dataset before partitioning
//   into folds — exactly as cross_validate does for binary datasets.
//   The balanced-to-original index mapping is used to deposit each test
//   instance's score at the right slot in the original dataset.
//   After all K binary cross-validations, each original instance is
//   assigned the class whose binary classifier gave it the highest
//   positive-class share of nearest neighbors.
// For folds > 1 (non-LOO), random selection is always used.
pub fn one_vs_rest_cross_validate(opts Options) CrossVerifyResult {
	ds := load_file(opts.datafile_path, opts.LoadOptions)
	mut cross_opts := opts
	cross_opts.datafile_path = ds.path
	total_instances := ds.Class.class_values.len
	repeats := if opts.repetitions == 0 { 1 } else { opts.repetitions }

	mut confusion_matrix_map := map[string]StringFloatMap{}
	for key1, _ in ds.class_counts {
		for key2, _ in ds.class_counts {
			confusion_matrix_map[key2][key1] = 0
		}
	}
	mut inferences_map := map[string]int{}
	for key, _ in ds.class_counts {
		inferences_map[key] = 0
	}
	mut cross_result := CrossVerifyResult{
		Parameters: opts.Parameters
		LoadOptions: ds.LoadOptions
		DisplaySettings: opts.DisplaySettings
		MultipleOptions: opts.MultipleOptions
		Class: ds.Class
		datafile_path: ds.path
		multiple_classify_options_file_path: cross_opts.multiple_classify_options_file_path
		labeled_classes: ds.class_values
		pos_neg_classes: get_pos_neg_classes(ds)
		confusion_matrix_map: confusion_matrix_map
		correct_inferences: inferences_map.clone()
		incorrect_inferences: inferences_map.clone()
		wrong_inferences: inferences_map.clone()
		true_positives: inferences_map.clone()
		true_negatives: inferences_map.clone()
		false_positives: inferences_map.clone()
		false_negatives: inferences_map.clone()
	}
	cross_result.binning = get_binning(cross_opts.bins)

	for _ in 0 .. repeats {
		// best_scores and rep_inferred are indexed by original instance index
		mut best_scores := []f32{len: total_instances, init: f32(-1.0)}
		mut rep_inferred := []string{len: total_instances}

		// for each class: remap the entire dataset to binary, balance the full
		// binary dataset (consistent with binary cross_validate), then run an
		// independent cross-validation using the balanced dataset's own fold
		// structure; scores are mapped back to original instance indices
		for class in ds.classes {
			mut bin_ds := ds
			bin_ds.classes = [class, 'not_${class}']
			bin_ds.class_values = ds.class_values.map(if it == class {
				it
			} else {
				'not_${class}'
			})
			bin_ds.class_counts = element_counts(bin_ds.class_values)

			// balance before folding (mirrors cross_validate for binary datasets)
			mut mapping := []int{len: bin_ds.class_values.len, init: index}
			if evaluate_class_prevalence_imbalance(bin_ds, cross_opts) {
				bin_ds, mapping = balance_prevalences_with_mapping(mut bin_ds, cross_opts.balance_prevalences_threshold)
				// balance_prevalences_with_mapping rebuilds class_values from data,
				// which still has original class labels — remap to binary labels
				bin_ds.class_values = bin_ds.class_values.map(if it == class {
					it
				} else {
					'not_${class}'
				})
				bin_ds.class_counts = element_counts(bin_ds.class_values)
			}

			// use per-class optimal parameters if provided by a prior OvR explore
			mut class_opts := cross_opts
			if class in cross_opts.per_class_parameters {
				class_opts.Parameters = cross_opts.per_class_parameters[class]
			}
			binary_cross_validate(bin_ds, mapping, class, class_opts, mut best_scores, mut rep_inferred, mut cross_result)
		}

		// results in original dataset index order
		cross_result.inferred_classes << rep_inferred
		cross_result.actual_classes << ds.class_values
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

// binary_cross_validate runs a complete n-fold cross-validation on bin_ds
// (which is already balanced).  mapping[balanced_idx] gives the original
// dataset index for each balanced instance, so scores are deposited at the
// right slot in best_scores / inferred.
fn binary_cross_validate(bin_ds Dataset, mapping []int, positive_class string, opts Options, mut best_scores []f32, mut inferred []string, mut cross_result CrossVerifyResult) {
	balanced_total := bin_ds.class_values.len
	folds_count := if opts.folds == 0 { balanced_total } else { opts.folds }

	mut pick_list := []int{}
	if folds_count > 1 {
		mut n := 0
		for pick_list.len < balanced_total {
			n = rand.int_in_range(0, balanced_total) or { 0 }
			if n in pick_list {
				continue
			}
			pick_list << n
		}
	} else {
		for i in 0 .. balanced_total {
			pick_list << i
		}
	}

	for current_fold in 0 .. folds_count {
		mut part_ds, fold := partition(pick_list, current_fold, folds_count, bin_ds, opts)
		// skip folds where the positive class has no training instances
		if positive_class !in part_ds.class_counts {
			continue
		}
		classifier := make_classifier_using_ds(mut part_ds, opts)
		if cross_result.maximum_hamming_distance == 0 {
			cross_result.binning = classifier.binning
			cross_result.maximum_hamming_distance = classifier.maximum_hamming_distance
		}

		mut byte_values_array := [][]u8{}
		for attr in classifier.attribute_ordering {
			j := fold.attribute_names.index(attr)
			byte_values_array << process_fold_data(classifier.trained_attributes[attr], fold.data[j])
		}
		fold_cases := transpose(byte_values_array)

		// fold.data / fold_cases are ordered by ascending bin_ds index
		// (get_index_items iterates in array order), but fold.indices
		// preserves pick_list order — sort to align them.
		mut sorted_fold_indices := fold.indices.clone()
		sorted_fold_indices.sort()
		for j, case in fold_cases {
			// map balanced index back to original dataset index
			original_idx := mapping[sorted_fold_indices[j]]
			res := classify_case(classifier, case)
			total := array_sum(res.nearest_neighbors_by_class)
			if total == 0 {
				continue
			}
			score := f32(res.nearest_neighbors_by_class[0]) / f32(total)
			if score > best_scores[original_idx] {
				best_scores[original_idx] = score
				inferred[original_idx] = positive_class
			}
		}
	}
}
