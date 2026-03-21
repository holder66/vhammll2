// performance_test.v measures classification accuracy on specific datasets.
//
// These are NOT unit tests — they verify that the library produces expected
// accuracy metrics on real datasets, and are intentionally kept separate so
// that `v test src/` remains fast.
//
// Run with:
//   v test perf/ -I ..
//
// Dataset path is resolved relative to this file's location so the tests
// work regardless of the current working directory.
module perf

import vhammll2
import os

// datasets_path returns the absolute path to the vhammll2 datasets directory.
fn datasets_path() string {
	// @FILE resolves to this file's absolute path at compile time;
	// perf/ sits inside vhammll2/, and datasets/ is a sibling of perf/
	return os.abs_path(os.join_path(@FILE, '..', '..', 'datasets'))
}

fn testsuite_begin() ? {
	if !os.is_dir(datasets_path()) {
		eprintln('datasets directory not found at ${datasets_path()}; skipping performance tests')
	}
	tmp := os.join_path(os.temp_dir(), 'vhammll2_perf')
	if os.is_dir(tmp) {
		os.rmdir_all(tmp)!
	}
	os.mkdir_all(tmp)!
}

fn testsuite_end() ? {
	os.rmdir_all(os.join_path(os.temp_dir(), 'vhammll2_perf'))!
}

fn tmp(filename string) string {
	return os.join_path(os.temp_dir(), 'vhammll2_perf', filename)
}

fn ds(relative_path string) string {
	return os.join_path(datasets_path(), relative_path)
}

// test_cross_iris checks leave-one-out cross-validation on the classic iris dataset.
// With 3 classes, vhammll2 automatically uses one-vs-rest.
fn test_cross_iris() {
	result := vhammll2.cross_validate(vhammll2.opts('-a 2 -b 3,3 ${ds('iris.tab')}'))
	assert result.balanced_accuracy == 98.0
}

// test_cross_bcw checks leave-one-out cross-validation on the breast cancer
// Wisconsin dataset (2-class binary classifier).
fn test_cross_bcw() {
	result := vhammll2.cross_validate(vhammll2.opts('${ds('breast-cancer-wisconsin-disc.tab')}'))
	assert result.balanced_accuracy > 95.0
	assert result.mcc > 0.90
}

// test_verify_bcw checks verify accuracy using train/test split files.
fn test_verify_bcw() {
	result := vhammll2.verify(vhammll2.opts('-t ${ds('bcw174test')} ${ds('bcw350train')}'))
	assert result.balanced_accuracy > 95.0
}

// test_explore_saves_output checks that explore runs and saves a result file.
fn test_explore_saves_output() {
	outfile := tmp('breast.exr')
	vhammll2.explore(vhammll2.opts('-o ${outfile} ${ds('breast-cancer-wisconsin-disc.tab')}'))
	assert os.exists(outfile)
}

// test_cross_nfold checks n-fold (10-fold) cross-validation, which in vhammll2
// always uses random instance selection.
fn test_cross_nfold() {
	result := vhammll2.cross_validate(vhammll2.opts('-f 10 -r 3 ${ds('breast-cancer-wisconsin-disc.tab')}'))
	assert result.balanced_accuracy > 94.0
}
