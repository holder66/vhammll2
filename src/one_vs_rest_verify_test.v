module vhammll2

import os
// import vtl

fn testsuite_begin() ? {
	if os.is_dir('tempfolders/tempfolder_one_vs_rest_verify') {
		os.rmdir_all('tempfolders/tempfolder_one_vs_rest_verify')!
	}
	os.mkdir_all('tempfolders/tempfolder_one_vs_rest_verify')!
}

fn testsuite_end() ? {
	os.rmdir_all('tempfolders/tempfolder_one_vs_rest_verify')!
}

// test_one_vs_rest_verify
fn test_one_vs_rest_verify() ? {
	settingsfile := 'tempfolders/tempfolder_one_vs_rest_verify/onevsrest.opts'
	mut result := CrossVerifyResult{}

	result0 := one_vs_rest_verify(opts('-a 0 -b 5,5 -ms ${settingsfile} -t datasets/onevsrest_test.tab datasets/onevsrest_train.tab'))

	result1 := one_vs_rest_verify(opts('-a 25 -b 1,16 -ms ${settingsfile} -t datasets/soybean-large-test.tab datasets/soybean-large-train.tab'))
}
