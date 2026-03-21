module vhammll2

// one_vs_rest_verify classifies all the cases in a verification datafile (specified
// by `opts.testfile_path`) using an array of trained Classifiers, one per class;
// each classifier is trained using a one class vs all the other classes. It returns metrics
// comparing the inferred classes to the labeled (assigned) classes
// of the verification datafile.
// ```sh
// Optional (also see `make_classifier.v` for options in training a classifier)
// Output options:
// show_flag: display results on the console;
// expanded_flag: display additional information on the console, including
// 		a confusion matrix.
// outputfile_path: saves the result as a json file
// ```
pub fn one_vs_rest_verify(opts Options) CrossVerifyResult {
	// load the testfile as a Dataset struct
	mut test_ds := load_file(opts.testfile_path, opts.LoadOptions)
	mut confusion_matrix_map := map[string]StringFloatMap{}
	// for each class, instantiate an entry in the confusion matrix map
	for key1, _ in test_ds.class_counts {
		for key2, _ in test_ds.class_counts {
			confusion_matrix_map[key2][key1] = 0
		}
	}
	// instantiate a struct for the result
	mut verify_result := CrossVerifyResult{
		LoadOptions:                         opts.LoadOptions
		Parameters:                          opts.Parameters
		DisplaySettings:                     opts.DisplaySettings
		MultipleOptions:                     opts.MultipleOptions
		datafile_path:                       opts.datafile_path
		testfile_path:                       opts.testfile_path
		multiple_classify_options_file_path: opts.multiple_classify_options_file_path
		multiple_classifier_settings:        opts.multiple_classifier_settings
		labeled_classes:                     test_ds.class_values
		actual_classes:                      test_ds.class_values
		class_counts:                        test_ds.class_counts
		classes:                             test_ds.classes
		pos_neg_classes:                     get_pos_neg_classes(test_ds)
		confusion_matrix_map:                confusion_matrix_map
	}
	verify_result.binning = get_binning(opts.bins)
	mut ds := load_file(opts.datafile_path, opts.LoadOptions)

	mut one_vs_rest_cl_array := []Classifier{len: ds.classes.len}
	one_vs_rest_cl_array.clear()
	for class in ds.classes {
		mut one_vs_rest_ds := ds
		one_vs_rest_ds.classes = [class, 'not_${class}']
		one_vs_rest_ds.class_values = ds.class_values.map(if it == class {
			it
		} else {
			'not_${class}'
		})
		one_vs_rest_ds.class_counts = element_counts(one_vs_rest_ds.class_values)
		mut one_vs_rest_cl := make_classifier_using_ds(mut one_vs_rest_ds, opts)
		one_vs_rest_cl_array << one_vs_rest_cl
	}

	mut cases := [][]u8{}
	mut inferred_classes := []string{len: test_ds.class_values.len}
	for classifier in one_vs_rest_cl_array {
		cases = generate_case_array(classifier, test_ds)
		for j, case in cases {
			inf_class := classify_case(classifier, case, opts).inferred_class
			if !inf_class.contains('not_') {
				inferred_classes[j] = inf_class
			}
		}
	}
	verify_result.inferred_classes = inferred_classes
	verify_result = summarize_results(1, mut verify_result)
	verify_result.Metrics = get_metrics(verify_result)
	if verify_result.pos_neg_classes.len == 2 {
		verify_result.BinaryMetrics = get_binary_stats(verify_result)
	}

	if opts.command == 'verify' && (opts.show_flag || opts.expanded_flag) {
		show_verify(verify_result, opts)
	}
	if opts.outputfile_path != '' {
		verify_result.command = 'verify'
		save_json_file[CrossVerifyResult](verify_result, opts.outputfile_path)
	}
	if opts.append_settings_flag {
		append_cross_verify_settings_to_file(verify_result, opts)
	}
	return verify_result
}
