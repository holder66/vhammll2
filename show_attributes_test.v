module vhammll2

import os

fn testsuite_begin() ? {
	if os.is_dir('tempfolders/tempfolder_show_attr') {
		os.rmdir_all('tempfolders/tempfolder_show_attr')!
	}
	os.mkdir_all('tempfolders/tempfolder_show_attr')!
}

fn testsuite_end() ? {
	os.rmdir_all('tempfolders/tempfolder_show_attr')!
}

fn test_multiple_classifier_verify_totalnn() ? {
	datafile := 'datasets/leukemia38train.tab'
	testfile := 'datasets/leukemia34test.tab'
	settingsfile := 'tempfolders/tempfolder_show_attr/leuk.opts'
	mut result := CrossVerifyResult{}

	println(r_b('Do two verifications to populate a settings file:'))
	// populate a settings file, doing individual verifications
	result0 := verify(opts('-ma -a 1 -b 5,5 -ms ${settingsfile} -t ${testfile} ${datafile}'))
	assert result0.confusion_matrix_map == {
		'ALL': {
			'ALL': 17.0
			'AML': 3.0
		}
		'AML': {
			'ALL': 0.0
			'AML': 14.0
		}
	}, 'verify with 1 attribute and binning [5,5]'
	result1 := verify(opts('-ma -a 6 -b 1,10 -ms ${settingsfile} -t ${testfile} ${datafile}'))
	assert result1.confusion_matrix_map == {
		'ALL': {
			'ALL': 19.0
			'AML': 1.0
		}
		'AML': {
			'ALL': 6.0
			'AML': 8.0
		}
	}
	println(r_b('Next, verify that the settings file was saved, and display it:'))
	// verify that the settings file was saved, and is the right length
	assert os.is_file(settingsfile)
	mut r := read_multiple_opts(settingsfile)!
	assert r.len == 2
	display_file(settingsfile, opts('-ea ${datafile}'))

	println(r_b('Do a multi-classifier verification with both saved classifiers:'))
	result = verify(opts('-s -ea -m ${settingsfile} -t ${testfile} ${datafile}'))
	println(r_b('Do a multi-classifier verification with saved classifier #0 only:'))
	result = verify(opts('-s -ea -m ${settingsfile} -m# 0 -t ${testfile} ${datafile}'))
	assert result.confusion_matrix_map == result0.confusion_matrix_map
	println(r_b('Do a multi-classifier verification with saved classifier #1 only:'))
	result = verify(opts('-s -ea -m ${settingsfile} -m# 1 -t ${testfile} ${datafile}'))
	assert result.confusion_matrix_map == result1.confusion_matrix_map
}
