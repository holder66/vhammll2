module vhammll2

import os

fn testsuite_begin() ? {
	if os.is_dir('tempfolders/tempfolder_explore') {
		os.rmdir_all('tempfolders/tempfolder_explore')!
	}
	os.mkdir_all('tempfolders/tempfolder_explore')!
}

fn testsuite_end() ? {
	os.rmdir_all('tempfolders/tempfolder_explore')!
}

// test_explore_cross tests cross-validation explore for binary and multiclass datasets.
// Binary datasets use run_explore directly; multiclass datasets dispatch to OvR.
fn test_explore_cross() ? {
	// binary dataset with continuous attributes (leukemia, ALL vs AML)
	mut datafile := 'datasets/leukemia38train.tab'
	mut result := explore(opts('-b 2,5 -u -a 1,2 ${datafile}'))
	// bins 2–5 with -u and attrs 1–2: 2 × 4 = 8 results
	assert result.array_of_results.len == 8
	// leave-one-out cross-validation over balanced dataset (27 ALL × 2 + 11 AML × 5 = 109)
	assert result.array_of_results[0].total_count == 109
	// leukemia is well-separable; expect well above chance
	assert result.array_of_results[0].correct_count > 50

	// multiclass dataset (iris, 3 classes) dispatches to OvR:
	// run_explore returns an ExploreResult with empty array_of_results
	datafile = 'datasets/iris.tab'
	result = explore(opts('-b 2,5 -u -a 1,2 ${datafile}'))
	assert result.array_of_results.len == 0
	assert result.path != ''
}

// test_explore_verify tests explore with a separate test file (binary, discrete dataset).
fn test_explore_verify() ? {
	datafile := 'datasets/bcw350train'
	testfile := 'datasets/bcw174test'
	// bcw is all-discrete: bins are bypassed; 4 attr values × 1 bin level = 4 results
	result := explore(opts('-a 1,4 -t ${testfile} ${datafile}'))
	assert result.array_of_results.len == 4
	// test file has 174 instances
	assert result.array_of_results[0].total_count == 174
	// bcw is a well-known easy dataset; expect good accuracy
	assert result.array_of_results[3].correct_count > 160
	println('done with explore_verify of bcw')
}

// test_explore_traverse_all_flags tests -af (traverse all flags) sweeping over
// uniform_bins settings for both binary and multiclass datasets.
fn test_explore_traverse_all_flags() ? {
	// binary dataset: leukemia with verify testfile
	mut datafile := 'datasets/leukemia38train.tab'
	mut testfile := 'datasets/leukemia34test.tab'
	mut settingsfile := 'tempfolders/tempfolder_explore/leuk.opts'
	mut ex := opts('-a 1,2 -b 2,5 -af -ms ${settingsfile} -t ${testfile} ${datafile}')
	ex.command = 'explore' // prevent individual verify() calls from also appending
	explore(ex)
	assert os.is_file(settingsfile)
	mut r := read_multiple_opts(settingsfile)!
	// -af runs twice (uniform_bins false and true): 7 analytics × 2 = 14
	assert r.len == 14

	// multiclass dataset: iris dispatches to OvR per class; settings created via OvR path
	datafile = 'datasets/iris.tab'
	settingsfile = 'tempfolders/tempfolder_explore/iris.opts'
	ex = opts('-a 1,2 -b 2,4 -af -ms ${settingsfile} ${datafile}')
	ex.command = 'explore'
	explore(ex)
	assert os.is_file(settingsfile)
	r = read_multiple_opts(settingsfile)!
	// OvR: 3 classes × 7 analytics × 2 af runs = 42
	assert r.len == 42
}
