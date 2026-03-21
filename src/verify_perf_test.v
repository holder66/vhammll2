module vhammll2

import os

fn testsuite_begin() ! {
	if os.is_dir('tempfolders/tempfolder_verify_perf') {
		os.rmdir_all('tempfolders/tempfolder_verify_perf')!
	}
	os.mkdir_all('tempfolders/tempfolder_verify_perf')!
}

fn testsuite_end() ! {
	os.rmdir_all('tempfolders/tempfolder_verify_perf')!
}

fn test_verify_perf() ? {
	mut result := CrossVerifyResult{}
	mut cl := Classifier{}

	result = verify(opts('-a 33 -b 2,16 -t datasets/soybean-large-test.tab datasets/soybean-large-train.tab'))
	println(r_b('Done with soybean-large-train.tab'))

	// now with a saved classifier
	cl = make_classifier(opts('-a 33 -b 2,16 -o tempfolders/tempfolder_verify_perf/classifierfile datasets/soybean-large-train.tab'))
	assert result.Metrics == verify(opts('-a 33 -b 2,16 -k tempfolders/tempfolder_verify_perf/classifierfile -t datasets/soybean-large-test.tab datasets/soybean-large-train.tab')).Metrics
	println(r_b('Done with soybean-large-train.tab using saved classifier'))

	if get_environment().arch_details[0] != '4 cpus' {
		result = verify(opts('-a 50 -b 2,2 -t datasets/mnist_test.tab datasets/mnist_test.tab'))
		println(r_b('Done with mnist_test.tab'))

		// now with a saved classifier
		cl = make_classifier(opts('-a 50 -b 2,2 -o tempfolders/tempfolder_verify_perf/classifierfile datasets/mnist_test.tab'))
		assert result.Metrics == verify(opts('-a 50 -b 2,2 -k tempfolders/tempfolder_verify_perf/classifierfile -t datasets/mnist_test.tab datasets/mnist_test.tab')).Metrics
		println(r_b('Done with mnist_test.tab using saved classifier'))
	}
}
