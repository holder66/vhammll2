module vhammll2

import os

fn testsuite_begin() ? {
	if os.is_dir('tempfolder3') {
		os.rmdir_all('tempfolder3')!
	}
	os.mkdir_all('tempfolder3')!
}

fn testsuite_end() ? {
	os.rmdir_all('tempfolder3')!
}

fn test_validate_save_result() ? {
	mut result := ValidateResult{}
	mut test_result := ValidateResult{}
	mut cl := Classifier{}
}

fn test_kaggle() ! {
	kagglefile := 'tempfolder3/kagglefile'
	datafile := 'datasets/testdata/test.tab'
	testfile := 'datasets/testdata/test_validate.tab'

	cl := make_classifier(opts('-a 2 -b 2,3 -ka ${kagglefile} -t ${testfile} ${datafile}'))
	result := validate(cl, opts('-a 2 -b 2,3 -ka ${kagglefile} -t ${testfile} ${datafile}'))!
	content := os.read_lines(kagglefile) or { panic('failed to open ${kagglefile}') }
	assert content.len > 0
	assert content[0] == 'id,gender'
	println('Done kaggle test')
}
