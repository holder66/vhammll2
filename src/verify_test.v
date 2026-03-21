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
	verify(opts('-a 2 -b 2,3 -t datasets/test_verify.tab datasets/test.tab'))
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

	result = verify(opts('-a 33 -b 2,16 -t datasets/soybean-large-test.tab datasets/soybean-large-train.tab'))
	println(r_b('Done with soybean-large-train.tab'))

	// now with a saved classifier
	cl = make_classifier(opts('-a 33 -b 2,16 -o tempfolders/tempfolder_verify/classifierfile datasets/soybean-large-train.tab'))
	assert result.Metrics == verify(opts('-a 33 -b 2,16 -k tempfolders/tempfolder_verify/classifierfile -t datasets/soybean-large-test.tab datasets/soybean-large-train.tab')).Metrics
	println(r_b('Done with soybean-large-train.tab using saved classifier'))

	if get_environment().arch_details[0] != '4 cpus' {
		result = verify(opts('-a 50 -b 2,2 -t datasets/mnist_test.tab datasets/mnist_test.tab'))
		println(r_b('Done with mnist_test.tab'))

		// now with a saved classifier
		cl = make_classifier(opts('-a 50 -b 2,2 -o tempfolders/tempfolder_verify/classifierfile datasets/mnist_test.tab'))
		assert result.Metrics == verify(opts('-a 50 -b 2,2 -k tempfolders/tempfolder_verify/classifierfile -t datasets/mnist_test.tab datasets/mnist_test.tab')).Metrics
		println(r_b('Done with mnist_test.tab using saved classifier'))
	}
}
