module vhammll2

import os

fn testsuite_begin() ! {
	if os.is_dir('tempfolders/tempfolder_append_perf') {
		os.rmdir_all('tempfolders/tempfolder_append_perf')!
	}
	os.mkdir_all('tempfolders/tempfolder_append_perf')!
}

fn testsuite_end() ! {
	os.rmdir_all('tempfolders/tempfolder_append_perf')!
}

fn test_append_perf() ! {
	mut opts := Options{
		command: 'append'
	}

	mut cl := Classifier{}
	mut tcl := Classifier{}
	mut val_results := ValidateResult{}

	// test with the soybean files
	// create the classifier file and save it
	opts.outputfile_path = 'tempfolders/tempfolder_append_perf/classifierfile'
	opts.datafile_path = 'datasets/soybean-large-train.tab'
	cl = make_classifier(opts)
	// do a validation and save the result
	opts.outputfile_path = 'tempfolders/tempfolder_append_perf/instancesfile'
	opts.testfile_path = 'datasets/soybean-large-validate.tab'
	val_results = validate(cl, opts)!
	// now do the append
	opts.outputfile_path = 'tempfolders/tempfolder_append_perf/extended_classifierfile'
	tcl = append_instances(cl, val_results, opts)
	assert tcl.class_counts == {
		'diaporthe-stem-canker':       300
		'charcoal-rot':                300
		'rhizoctonia-root-rot':        300
		'phytophthora-rot':            328
		'brown-stem-rot':              304
		'powdery-mildew':              300
		'downy-mildew':                299
		'brown-spot':                  325
		'bacterial-blight':            299
		'bacterial-pustule':           299
		'purple-seed-stain':           301
		'anthracnose':                 304
		'phyllosticta-leaf-spot':      303
		'alternarialeaf-spot':         333
		'frog-eye-leaf-spot':          335
		'diaporthe-pod-&-stem-blight': 309
		'cyst-nematode':               308
		'2-4-d-injury':                321
		'herbicide-injury':            304
	}

	// test if the appended classifier works as a classifier
	opts.testfile_path = 'datasets/soybean-large-test.tab'
	opts.classifierfile_path = 'tempfolders/tempfolder_append_perf/extended_classifierfile'
	verify(opts)
}
