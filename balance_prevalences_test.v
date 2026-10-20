module vhammll2

import os

fn testsuite_begin() {
	if os.is_dir('tempfolders/tempfolder_balance_prevalences') {
		os.rmdir_all('tempfolders/tempfolder_balance_prevalences') or { panic(err) }
	}
	os.mkdir_all('tempfolders/tempfolder_balance_prevalences')!
}

fn testsuite_end() {
	os.rmdir_all('tempfolders/tempfolder_balance_prevalences') or { panic(err) }
}

fn test_evaluate_class_prevalence_imbalance() {
	mut o := Options{
		balance_prevalences_threshold: 0.25
	}
	mut ds := load_file('datasets/testdata/developer.tab', o.LoadOptions)
	assert evaluate_class_prevalence_imbalance(ds, o)
	o.balance_prevalences_threshold = 0.25
	assert evaluate_class_prevalence_imbalance(ds, o)
	o.balance_prevalences_threshold = 0.2
	assert !evaluate_class_prevalence_imbalance(ds, o)
	o.balance_prevalences_threshold = 0.0
	assert !evaluate_class_prevalence_imbalance(ds, o)
	o.balance_prevalences_threshold = 1.0
	assert evaluate_class_prevalence_imbalance(ds, o)
	ds = load_file('datasets/iris.tab', o.LoadOptions)
	o.balance_prevalences_threshold = Options{}.balance_prevalences_threshold
	assert !evaluate_class_prevalence_imbalance(ds, o)
	o.balance_prevalences_threshold = 0.2
	assert !evaluate_class_prevalence_imbalance(ds, o)
	o.balance_prevalences_threshold = 0.0
	assert !evaluate_class_prevalence_imbalance(ds, o)
	o.balance_prevalences_threshold = 1.0
	assert evaluate_class_prevalence_imbalance(ds, o)
	ds = load_file('datasets/UCI/ionosphere.arff', o.LoadOptions)
	o.balance_prevalences_threshold = 0.9
	assert evaluate_class_prevalence_imbalance(ds, o)
	o.balance_prevalences_threshold = 0.5
	assert !evaluate_class_prevalence_imbalance(ds, o)
	o.balance_prevalences_threshold = 0.0
	assert !evaluate_class_prevalence_imbalance(ds, o)
	o.balance_prevalences_threshold = 1.0
	assert evaluate_class_prevalence_imbalance(ds, o)
	o.balance_prevalences_threshold = 0.57
	assert evaluate_class_prevalence_imbalance(ds, o)
}

fn test_balance_prevalences() {
	mut ds := load_file('datasets/testdata/developer.tab')
	mut threshold := 0.8
	mut counts := ds.class_counts.clone()
	assert counts == {
		'm': 8
		'f': 3
		'X': 2
	}
	mut ds_balanced := balance_prevalences(mut ds, threshold)
	assert ds.pre_balance_prevalences_class_counts == counts
	assert ds.class_counts == {
		'm': 8
		'f': 9
		'X': 10
	}
	threshold = 0.7
	ds = load_file('datasets/leukemia38train.tab')
	counts = ds.class_counts.clone()
	assert counts == {
		'ALL': 27
		'AML': 11
	}
	ds_balanced = balance_prevalences(mut ds, threshold)
	assert ds.pre_balance_prevalences_class_counts == counts
	assert ds_balanced.class_counts == {
		'ALL': 27
		'AML': 22
	}
	threshold = 0.9
	ds = load_file('datasets/leukemia38train.tab')
	ds_balanced = balance_prevalences(mut ds, threshold)
	assert ds.pre_balance_prevalences_class_counts == counts
	assert ds_balanced.class_counts == {
		'ALL': 54
		'AML': 55
	}
	ds = load_file('datasets/UCI/diabetes.arff')
	counts = ds.class_counts.clone()
	assert counts == {
		'tested_positive': 268
		'tested_negative': 500
	}
	ds_balanced = balance_prevalences(mut ds, threshold)
	assert ds.pre_balance_prevalences_class_counts == counts
	assert ds_balanced.class_counts == {
		'tested_positive': 536
		'tested_negative': 500
	}
}

fn test_bpt_cli_flag() {
	// leukemia38train: ALL=27, AML=11, ratio ≈ 0.407
	// Note: load_file always initialises pre_balance_prevalences_class_counts from
	// class_counts; after balancing triggers, class_counts diverges from it.
	//
	// with threshold 0.9: ratio (0.407) < threshold, so balancing IS triggered
	cl_balanced := make_classifier(get_opts('-bpt 0.9 -a 3 -b 4,4 datasets/leukemia38train.tab'))
	// original counts preserved in pre_balance_prevalences_class_counts
	assert cl_balanced.pre_balance_prevalences_class_counts == {
		'ALL': 27
		'AML': 11
	}
	// class_counts expanded by balancing
	assert cl_balanced.class_counts != {
		'ALL': 27
		'AML': 11
	}
	// with threshold 0.3: ratio (0.407) > threshold, so balancing is NOT triggered
	cl_not_balanced := make_classifier(get_opts('-bpt 0.3 -a 3 -b 4,4 datasets/leukemia38train.tab'))
	// no balancing: class_counts unchanged and equal to pre_balance_prevalences_class_counts
	assert cl_not_balanced.class_counts == {
		'ALL': 27
		'AML': 11
	}
	assert cl_not_balanced.class_counts == cl_not_balanced.pre_balance_prevalences_class_counts
	// omitting -bpt uses the default threshold of 0.9: result identical to explicit -bpt 0.9
	cl_default := make_classifier(get_opts('-a 3 -b 4,4 datasets/leukemia38train.tab'))
	assert cl_default.class_counts == cl_balanced.class_counts
}
