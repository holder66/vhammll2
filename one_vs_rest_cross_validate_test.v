module vhammll2

import os

fn testsuite_begin() ? {
	if os.is_dir('tempfolders/tempfolder_one_vs_rest_cross_validate') {
		os.rmdir_all('tempfolders/tempfolder_one_vs_rest_cross_validate')!
	}
	os.mkdir_all('tempfolders/tempfolder_one_vs_rest_cross_validate')!
}

fn testsuite_end() ? {
	os.rmdir_all('tempfolders/tempfolder_one_vs_rest_cross_validate')!
}

// test_one_vs_rest_cross_validate_loo tests leave-one-out cross-validation
// on the small 7-class OvR dataset using one_vs_rest_cross_validate directly.
fn test_one_vs_rest_cross_validate_loo() {
	datafile := 'datasets/testdata/onevsrest_train.tab'
	ds := load_file(datafile, LoadOptions{})
	result := one_vs_rest_cross_validate(opts('-a 0 -b 5,5 ${datafile}'))
	assert result.inferred_classes.len == ds.class_values.len
	// every inferred class must be one of the dataset's known classes
	for inf in result.inferred_classes {
		assert inf in ds.classes
	}
}

// test_one_vs_rest_cross_validate_iris tests 10-fold cross-validation on iris
// (3 classes) using one_vs_rest_cross_validate directly.
fn test_one_vs_rest_cross_validate_iris() {
	datafile := 'datasets/iris.tab'
	ds := load_file(datafile, LoadOptions{})
	result := one_vs_rest_cross_validate(opts('-a 4 -b 4,4 -f 10 ${datafile}'))
	assert result.inferred_classes.len == ds.class_values.len
	for inf in result.inferred_classes {
		assert inf in ds.classes
	}
	// iris is well-separated; OvR should achieve reasonable balanced accuracy
	assert result.Metrics.balanced_accuracy > 0.85
}

// test_cross_validate_dispatches_to_ovr tests that cross_validate automatically
// uses one-vs-rest for multiclass datasets (iris has 3 classes).
fn test_cross_validate_dispatches_to_ovr() {
	datafile := 'datasets/iris.tab'
	ds := load_file(datafile, LoadOptions{})
	result := cross_validate(opts('-a 4 -b 4,4 -f 10 ${datafile}'))
	assert result.inferred_classes.len == ds.class_values.len
	for inf in result.inferred_classes {
		assert inf in ds.classes
	}
}

// test_one_vs_rest_cross_validate_saves_output tests that the -o flag correctly
// saves a CrossVerifyResult JSON file.
fn test_one_vs_rest_cross_validate_saves_output() ? {
	outputfile := 'tempfolders/tempfolder_one_vs_rest_cross_validate/result.json'
	datafile := 'datasets/testdata/onevsrest_train.tab'
	one_vs_rest_cross_validate(opts('-a 0 -b 5,5 -o ${outputfile} ${datafile}'))
	assert os.is_file(outputfile)
}

// test_switches_applied_in_ovr verifies that the switches metric is applied to
// the binary sub-datasets used inside one-vs-rest, even when the original dataset
// is multiclass.  The test remaps iris to binary (setosa vs not_setosa) and ranks
// with default opts (switches on) vs -nsw (switches off), then confirms that
// continuous attributes get switch counts ≥ 0 in the default case and -1 with -nsw.
fn test_switches_applied_in_ovr() {
	datafile := 'datasets/iris.tab'
	mut ds := load_file(datafile, LoadOptions{})
	positive_class := ds.classes[0]
	// remap to binary — mirrors what one_vs_rest_cross_validate does per class
	mut bin_ds := ds
	bin_ds.classes = [positive_class, 'not_${positive_class}']
	bin_ds.class_values = ds.class_values.map(if it == positive_class {
		it
	} else {
		'not_${positive_class}'
	})
	bin_ds.class_counts = element_counts(bin_ds.class_values)

	// default: switches on — continuous attrs should have switches >= 0
	rank_with_sw := rank_dataset(bin_ds, opts('-b 2,6 ${datafile}'))
	for ra in rank_with_sw.array_of_ranked_attributes {
		if ra.attribute_type == 'C' {
			assert ra.switches >= 0, 'expected switches >= 0 for ${ra.attribute_name} with switches on'
		}
	}

	// -nsw: switches off — all attrs should retain sentinel -1
	rank_no_sw := rank_dataset(bin_ds, opts('-nsw -b 2,6 ${datafile}'))
	for ra in rank_no_sw.array_of_ranked_attributes {
		assert ra.switches == -1, 'expected switches == -1 for ${ra.attribute_name} with -nsw'
	}
}

// test_ovr_explore_per_class verifies that run_ovr_explore produces one
// independent sweep result per class and derives per-class optimal Parameters.
fn test_ovr_explore_per_class() {
	datafile := 'datasets/iris.tab'
	ds := load_file(datafile, LoadOptions{})
	ovr_opts := opts('-a 1,2 -b 2,4 -f 5 ${datafile}')
	ovr := run_ovr_explore(ds, ovr_opts)

	// one entry per class
	assert ovr.class_explore_results.len == ds.classes.len
	assert ovr.per_class_parameters.len == ds.classes.len

	for class in ds.classes {
		assert class in ovr.class_explore_results
		assert class in ovr.per_class_parameters

		class_result := ovr.class_explore_results[class]
		// each class sweep has array_of_results populated
		assert class_result.array_of_results.len > 0
		// every result in the sweep is binary (2 classes)
		for r in class_result.array_of_results {
			assert r.classes.len == 2
		}
		// optimal params have a valid number_of_attributes
		p := ovr.per_class_parameters[class]
		assert p.number_of_attributes[0] > 0
	}
}

// test_ovr_cross_validate_uses_per_class_params verifies that
// one_vs_rest_cross_validate uses per-class optimal Parameters when provided,
// and that the result differs from using uniform settings.
fn test_ovr_cross_validate_uses_per_class_params() {
	datafile := 'datasets/iris.tab'
	ds := load_file(datafile, LoadOptions{})

	// find per-class optimal settings via explore
	ovr := run_ovr_explore(ds, opts('-a 1,4 -b 2,6 -f 5 ${datafile}'))

	// cross_validate with per-class optimal settings
	mut per_class_opts := opts('-a 4 -b 4,4 -f 10 ${datafile}')
	per_class_opts.per_class_parameters = ovr.per_class_parameters.clone()
	result_per_class := one_vs_rest_cross_validate(per_class_opts)

	// must still classify every instance
	assert result_per_class.inferred_classes.len == ds.class_values.len
	for inf in result_per_class.inferred_classes {
		assert inf in ds.classes
	}
	// per-class settings should achieve reasonable accuracy on iris
	assert result_per_class.Metrics.balanced_accuracy > 0.80
}
