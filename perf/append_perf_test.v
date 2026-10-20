module perf

import os
import vhammll2

fn testsuite_begin() {
	if os.is_dir('tempfolders/tempfolder_append_perf') {
		os.rmdir_all('tempfolders/tempfolder_append_perf') or { panic(err) }
	}
	os.mkdir_all('tempfolders/tempfolder_append_perf')!
}

fn testsuite_end() {
	os.rmdir_all('tempfolders/tempfolder_append_perf') or { panic(err) }
}

fn test_append_perf() ! {
	mut o := vhammll2.Options{
		command: 'append'
	}

	mut cl := vhammll2.Classifier{}
	mut tcl := vhammll2.Classifier{}
	mut val_results := vhammll2.ValidateResult{}

	// test with the soybean files
	// create the classifier file and save it
	o.outputfile_path = 'tempfolders/tempfolder_append_perf/classifierfile'
	o.datafile_path = 'datasets/soybean-large-train.tab'
	cl = vhammll2.make_classifier(o)
	// do a validation and save the result
	o.outputfile_path = 'tempfolders/tempfolder_append_perf/instancesfile'
	o.testfile_path = 'datasets/soybean-large-validate.tab'
	val_results = vhammll2.validate(cl, o)!
	// now do the append
	o.outputfile_path = 'tempfolders/tempfolder_append_perf/extended_classifierfile'
	tcl = vhammll2.append_instances(cl, val_results, o)
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
	o.testfile_path = 'datasets/soybean-large-test.tab'
	o.classifierfile_path = 'tempfolders/tempfolder_append_perf/extended_classifierfile'
	vhammll2.verify(o)
}
