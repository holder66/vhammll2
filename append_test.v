module vhammll2

import os

fn testsuite_begin() ! {
	if os.is_dir('tempfolders/tempfolder_append') {
		os.rmdir_all('tempfolders/tempfolder_append')!
	}
	os.mkdir_all('tempfolders/tempfolder_append')!
}

fn testsuite_end() ! {
	os.rmdir_all('tempfolders/tempfolder_append')!
}

fn test_append() ! {
	mut opts := Options{
		command: 'append'
		// show_flag: true
	}

	mut cl := Classifier{}
	mut tcl := Classifier{}
	mut ds := Dataset{}
	mut val_results := ValidateResult{}
	// create the classifier file and save it
	opts.outputfile_path = 'tempfolders/tempfolder_append/classifierfile'
	opts.datafile_path = 'datasets/testdata/test.tab'
	cl = make_classifier(opts)
	// do a validation and save the result
	opts.outputfile_path = 'tempfolders/tempfolder_append/instancesfile'
	opts.testfile_path = 'datasets/testdata/test_validate.tab'
	val_results = validate(cl, opts)!
	// now do the append, first from val_results, and
	// saving the extended classifier
	opts.outputfile_path = 'tempfolders/tempfolder_append/extclassifierfile'
	tcl = append_instances(cl, val_results, opts)
	assert tcl.class_counts == {
		'f': 9
		'm': 7
	}
	// repeat the append, this time with the saved files
	mut scl := load_classifier_file('tempfolders/tempfolder_append/extclassifierfile')!
	// dump(scl.history_events)
	stcl := append_instances(scl, load_instances_file('tempfolders/tempfolder_append/instancesfile')!, opts)
	// dump(stcl.history.len)
	assert stcl.instances.len == 26
	assert stcl.history_events.len == 3

	// test if the appended classifier works as a classifier
	opts.testfile_path = 'datasets/testdata/test_verify.tab'
	opts.classifierfile_path = 'tempfolders/tempfolder_append/extclassifierfile'
	verify(opts)
}
