module vhammll2

import os

fn testsuite_begin() ! {
	if os.is_dir('tempfolders/tempfolder_verify') {
		os.rmdir_all('tempfolders/tempfolder_verify')!
	}
	os.mkdir_all('tempfolders/tempfolder_verify')!
}

fn testsuite_end() ! {
	os.rmdir_all('tempfolders/tempfolder_verify')!
}

fn test_verify() ? {
	mut result := CrossVerifyResult{}
	mut cl := Classifier{}

	// test verify with a non-saved classifier
	verify(opts('-a 2 -b 2,3 -t datasets/testdata/test_verify.tab datasets/testdata/test.tab'))
	println(r_b('Done with test.tab'))

	// now with a binary classifier with continuous values
	result = verify(opts('-a 1 -b 5,5 -t datasets/leukemia34test.tab datasets/leukemia38train.tab'))
	assert result.confusion_matrix_map == {
		'ALL': {
			'ALL': 17.0
			'AML': 3.0
		}
		'AML': {
			'ALL': 0.0
			'AML': 14.0
		}
	}
	println(r_b('Done with leukemia38train.tab & leukemia34test.tab'))

	// test verify with a binary classifier without continuous values
	result = verify(opts('-a 4 -b 2,4 -t datasets/bcw174test datasets/bcw350train'))
	println(r_b('Done with bcw350train for a non-saved classifier'))

	// now with a saved classifier
	cl = make_classifier(opts('-a 4 -b 2,4 -o tempfolders/tempfolder_verify/classifierfile datasets/bcw350train'))
	assert result.BinaryMetrics == verify(opts('-a 4 -b 2,4 -k tempfolders/tempfolder_verify/classifierfile -t datasets/bcw174test datasets/bcw350train')).BinaryMetrics
	println(r_b('Done with bcw350train using saved classifier'))
}
