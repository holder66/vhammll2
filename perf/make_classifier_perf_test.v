module perf

import os
import vhammll2

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
	mut cl := vhammll2.Classifier{}
	mut tcl := vhammll2.Classifier{}

	cl = vhammll2.make_classifier(vhammll2.get_opts('-a 6 -b 2,12 -o ${outputfile} datasets/anneal.tab'))
	tcl = vhammll2.load_classifier_file(outputfile)!
	assert tcl.trained_attributes == cl.trained_attributes
	assert tcl.instances == cl.instances
	assert tcl.maximum_hamming_distance == 32

	cl = vhammll2.make_classifier(vhammll2.get_opts('-a 6 -b 2,12 -o ${outputfile} datasets/soybean-large-train.tab'))
	tcl = vhammll2.load_classifier_file(outputfile)!
	assert tcl.trained_attributes == cl.trained_attributes
	assert tcl.instances == cl.instances
	assert tcl.maximum_hamming_distance == 30

	if vhammll2.get_environment().arch_details[0] != '4 cpus' {
		cl = vhammll2.make_classifier(vhammll2.get_opts('-a 6 -b 2,12 -o ${outputfile} datasets/mnist_test.tab'))
		tcl = vhammll2.load_classifier_file(outputfile)!
		assert tcl.trained_attributes == cl.trained_attributes
		assert tcl.instances == cl.instances
		assert tcl.maximum_hamming_distance == 72
	}
}
