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
	one_vs_rest_verify(get_opts('-a 0 -b 5,5 -ms ${settingsfile} -t datasets/testdata/onevsrest_test.tab datasets/testdata/onevsrest_train.tab'))
}
