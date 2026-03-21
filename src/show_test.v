module vhammll2

import os

fn testsuite_begin() ! {
	if os.is_dir('tempfolders/tempfolder_show') {
		os.rmdir_all('tempfolders/tempfolder_show')!
	}
	os.mkdir_all('tempfolders/tempfolder_show')!
}

fn testsuite_end() ! {
	os.rmdir_all('tempfolders/tempfolder_show')!
}

// test_show_analyze has no asserts; the console output needs
// to be verified visually.

fn test_show_analyze() {
	println(r_b('test_show_analyze should print out dataset analyses for developer.tab and for iris.tab'))
	mut ar := AnalyzeResult{}
	ar = analyze_dataset(opts('datasets/testdata/developer.tab'))
	show_analyze(ar)
	ar = analyze_dataset(opts('datasets/iris.tab'))
	show_analyze(ar)

	// with purging of instances whose class values are missing
	ar = analyze_dataset(opts('-pmc datasets/iris.tab'))
	show_analyze(ar)
	ar = analyze_dataset(opts('datasets/class_missing_iris.tab'))
	show_analyze(ar)
	ar = analyze_dataset(opts('-pmc datasets/class_missing_iris.tab'))
	show_analyze(ar)
}

fn test_show_append() ? {
	println(r_b('test_show_append should print out a test.tab classifier, with 6 instances, followed by a test.tab classifier with 16 instances, and then a test.tab classifier with 26 instances and 3 history events.'))

	mut cl := Classifier{}
	mut tcl := Classifier{}
	mut val_results := ValidateResult{}
	// create the classifier file and save it
	cl = make_classifier(opts('-o tempfolders/tempfolder_show/classifierfile datasets/testdata/test.tab'))
	// do a validation and save the result
	val_results = validate(cl, opts('-o tempfolders/tempfolder_show/instancesfile -t datasets/testdata/test_validate.tab datasets/testdata/test.tab'))!
	// now do the append, first from val_results, and saving the extended classifier
	tcl = append_instances(cl, val_results, opts('-o tempfolders/tempfolder_show/classifierfile datasets/testdata/test.tab'))

	// now do it again but from the saved validate result,
	// appending to the previously extended classifier
	tcl = append_instances(load_classifier_file('tempfolders/tempfolder_show/classifierfile')!,
		load_instances_file('tempfolders/tempfolder_show/instancesfile')!, opts('-o tempfolders/tempfolder_show/classifierfile datasets/testdata/test.tab'))
}

fn test_show_classifier() {
	println(r_b('test_show_classifier prints out classifiers for iris.tab and for developer.tab'))
	mut cl := make_classifier(opts('-a 2 -b 3,10 datasets/iris.tab'))

	// now with purging of instances with missing class values
	cl = make_classifier(opts('-s -pmc -a 2 -b 3,10 datasets/class_missing_iris.tab'))

	// repeat with developer.tab, which is newer_orange format
	cl = make_classifier(opts('-s -a 2 -b 3,10 datasets/testdata/developer.tab'))
	cl = make_classifier(opts('-s -pmc -a 2 -b 3,10 datasets/testdata/class_missing_developer.tab'))
}

fn test_show_crossvalidation() ? {
	println(r_b('test_show_crossvalidation prints out cross-validation results for developer.tab, breast-cancer-wisconsin-disc.tab, and iris.tab'))
	mut cvr := CrossVerifyResult{}

	println('\n\ndeveloper.tab')
	cvr = cross_validate(opts('-s datasets/testdata/developer.tab'))
	println('\ndeveloper.tab with expanded results')
	cvr = cross_validate(opts('-s datasets/testdata/developer.tab'))

	println('\n\nbreast-cancer-wisconsin-disc.tab')
	cvr = cross_validate(opts('-s -a 4 datasets/breast-cancer-wisconsin-disc.tab'))
	println('\nbreast-cancer-wisconsin-disc.tab with expanded results')
	cvr = cross_validate(opts('-s -a 4 datasets/breast-cancer-wisconsin-disc.tab'))

	println('\n\niris.tab')
	cvr = cross_validate(opts('-s -a 2 -b 3,6 datasets/iris.tab'))
	println('\niris.tab with expanded results')
	cvr = cross_validate(opts('-s -a 2 -b 3,6 datasets/iris.tab'))
	// now with purging for missing classes
	cvr = cross_validate(opts('-s -pmc -a 2 -b 3,6 datasets/class_missing_iris.tab'))
}

fn test_show_explore_cross() ? {
	println(r_b('\n\n test_show_explore_cross prints out explore results for cross-validation of developer.tab'))
	mut results := ExploreResult{}
	results = explore(opts('-s -rand -a 2,4 -b 2,5 -f 10 -r 50 datasets/testdata/developer.tab'))

	// repeat for class missing purge
	results = explore(opts('-s -rand -pmc -a 2,4 -b 2,5 -f 10 -r 50 datasets/testdata/class_missing_developer.tab'))
}

fn test_show_rank_attributes() {
	println(r_b('\n\ntest_show_rank_attributes prints out attribute rankings for developer.tab and iris.tab'))
	mut rr := RankingResult{}
	rr = rank_attributes(opts('-s datasets/testdata/developer.tab'))
	rr = rank_attributes(opts('-s -b 3,3 datasets/iris.tab'))
	// repeat for class missing purge
	rr = rank_attributes(opts('-s -pmc -b 3,3 datasets/class_missing_iris.tab'))
}

fn test_show_validate() ? {
	println(r_b('\n\ntest_show_validate prints out results for validation of bcw350train with bcw174validate'))
	cl := make_classifier(opts('-s -a 4 -t datasets/bcw174validate datasets/bcw350train'))
	_ = validate(cl, opts('-s -a 4 -t datasets/bcw174validate datasets/bcw350train'))!
}

fn test_show_verify() ? {
	println(r_b('\n\ntest_show_verify prints out results for verification of bcw350train with bcw174test, and of soybean-large-train.tab with soybean-large-test.tab'))
	mut result := CrossVerifyResult{}
	result = verify(opts('-s -a 4 -t datasets/bcw174test datasets/bcw350train'))
	show_verify(result)
}

fn test_show_multiple_classifier_settings_options() ? {
	println(r_b('\n\ntest_show_multiple_classifier_settings_options prints out a table showing the classifier settings for the chosen classifiers in a multiple classifier cross-validation or verification'))
	mut result := CrossVerifyResult{}
}
