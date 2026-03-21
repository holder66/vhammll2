module vhammll2

import os

fn testsuite_begin() ! {
	if os.is_dir('tempfolders/tempfolder_make_classifier_perf') {
		os.rmdir_all('tempfolders/tempfolder_make_classifier_perf')!
	}
	os.mkdir_all('tempfolders/tempfolder_make_classifier_perf')!
}

fn testsuite_end() ! {
	os.rmdir_all('tempfolders/tempfolder_make_classifier_perf')!
}

fn test_save_classifier_perf() ? {
	outputfile := 'tempfolders/tempfolder_make_classifier_perf/classifierfile'
	mut cl := Classifier{}
	mut tcl := Classifier{}

	cl = make_classifier(opts('-a 6 -b 2,12 -o ${outputfile} datasets/anneal.tab'))
	tcl = load_classifier_file(outputfile)!
	assert tcl.trained_attributes == cl.trained_attributes
	assert tcl.instances == cl.instances
	assert tcl.maximum_hamming_distance == 32

	cl = make_classifier(opts('-a 6 -b 2,12 -o ${outputfile} datasets/soybean-large-train.tab'))
	tcl = load_classifier_file(outputfile)!
	assert tcl.trained_attributes == cl.trained_attributes
	assert tcl.instances == cl.instances
	assert tcl.maximum_hamming_distance == 27

	if get_environment().arch_details[0] != '4 cpus' {
		cl = make_classifier(opts('-a 6 -b 2,12 -o ${outputfile} datasets/mnist_test.tab'))
		tcl = load_classifier_file(outputfile)!
		assert tcl.trained_attributes == cl.trained_attributes
		assert tcl.instances == cl.instances
		assert tcl.maximum_hamming_distance == 72
	}
}
