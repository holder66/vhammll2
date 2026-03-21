module visual

import os
import vhammll2

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
	println(vhammll2.r_b('test_show_analyze should print out dataset analyses for developer.tab and for iris.tab'))
	mut ar := vhammll2.AnalyzeResult{}
	ar = vhammll2.analyze_dataset(vhammll2.opts('datasets/testdata/developer.tab'))
	vhammll2.show_analyze(ar)
	ar = vhammll2.analyze_dataset(vhammll2.opts('datasets/iris.tab'))
	vhammll2.show_analyze(ar)

	// with purging of instances whose class values are missing
	ar = vhammll2.analyze_dataset(vhammll2.opts('-pmc datasets/iris.tab'))
	vhammll2.show_analyze(ar)
	ar = vhammll2.analyze_dataset(vhammll2.opts('datasets/class_missing_iris.tab'))
	vhammll2.show_analyze(ar)
	ar = vhammll2.analyze_dataset(vhammll2.opts('-pmc datasets/class_missing_iris.tab'))
	vhammll2.show_analyze(ar)
}

fn test_show_append() ? {
	println(vhammll2.r_b('test_show_append should print out a test.tab classifier, with 6 instances, followed by a test.tab classifier with 16 instances, and then a test.tab classifier with 26 instances and 3 history events.'))

	mut cl := vhammll2.Classifier{}
	mut tcl := vhammll2.Classifier{}
	mut val_results := vhammll2.ValidateResult{}
	// create the classifier file and save it
	cl = vhammll2.make_classifier(vhammll2.opts('-o tempfolders/tempfolder_show/classifierfile datasets/testdata/test.tab'))
	// do a validation and save the result
	val_results = vhammll2.validate(cl, vhammll2.opts('-o tempfolders/tempfolder_show/instancesfile -t datasets/testdata/test_validate.tab datasets/testdata/test.tab'))!
	// now do the append, first from val_results, and saving the extended classifier
	tcl = vhammll2.append_instances(cl, val_results, vhammll2.opts('-o tempfolders/tempfolder_show/classifierfile datasets/testdata/test.tab'))

	// now do it again but from the saved validate result,
	// appending to the previously extended classifier
	tcl = vhammll2.append_instances(vhammll2.load_classifier_file('tempfolders/tempfolder_show/classifierfile')!,
		vhammll2.load_instances_file('tempfolders/tempfolder_show/instancesfile')!,
		vhammll2.opts('-o tempfolders/tempfolder_show/classifierfile datasets/testdata/test.tab'))
}

fn test_show_classifier() {
	println(vhammll2.r_b('test_show_classifier prints out classifiers for iris.tab and for developer.tab'))
	mut cl := vhammll2.make_classifier(vhammll2.opts('-a 2 -b 3,10 datasets/iris.tab'))

	// now with purging of instances with missing class values
	cl = vhammll2.make_classifier(vhammll2.opts('-s -pmc -a 2 -b 3,10 datasets/class_missing_iris.tab'))
	// repeat with developer.tab, which is newer_orange format
	cl = vhammll2.make_classifier(vhammll2.opts('-s -a 2 -b 3,10 datasets/testdata/developer.tab'))
	cl = vhammll2.make_classifier(vhammll2.opts('-s -pmc -a 2 -b 3,10 datasets/testdata/class_missing_developer.tab'))
}

fn test_show_crossvalidation() ? {
	println(vhammll2.r_b('test_show_crossvalidation prints out cross-validation results for developer.tab, breast-cancer-wisconsin-disc.tab, and iris.tab'))
	mut cvr := vhammll2.CrossVerifyResult{}

	println('\n\ndeveloper.tab')
	cvr = vhammll2.cross_validate(vhammll2.opts('-s datasets/testdata/developer.tab'))
	println('\ndeveloper.tab with expanded results')
	cvr = vhammll2.cross_validate(vhammll2.opts('-s datasets/testdata/developer.tab'))

	println('\n\nbreast-cancer-wisconsin-disc.tab')
	cvr = vhammll2.cross_validate(vhammll2.opts('-s -a 4 datasets/breast-cancer-wisconsin-disc.tab'))
	println('\nbreast-cancer-wisconsin-disc.tab with expanded results')
	cvr = vhammll2.cross_validate(vhammll2.opts('-s -a 4 datasets/breast-cancer-wisconsin-disc.tab'))

	println('\n\niris.tab')
	cvr = vhammll2.cross_validate(vhammll2.opts('-s -a 2 -b 3,6 datasets/iris.tab'))
	println('\niris.tab with expanded results')
	cvr = vhammll2.cross_validate(vhammll2.opts('-s -a 2 -b 3,6 datasets/iris.tab'))
	// now with purging for missing classes
	cvr = vhammll2.cross_validate(vhammll2.opts('-s -pmc -a 2 -b 3,6 datasets/class_missing_iris.tab'))
}

fn test_show_explore_cross() ? {
	println(vhammll2.r_b('\n\n test_show_explore_cross prints out explore results for cross-validation of developer.tab'))
	mut results := vhammll2.ExploreResult{}
	results = vhammll2.explore(vhammll2.opts('-s -rand -a 2,4 -b 2,5 -f 10 -r 50 datasets/testdata/developer.tab'))

	// repeat for class missing purge
	results = vhammll2.explore(vhammll2.opts('-s -rand -pmc -a 2,4 -b 2,5 -f 10 -r 50 datasets/testdata/class_missing_developer.tab'))
}

fn test_show_rank_attributes() {
	println(vhammll2.r_b('\n\ntest_show_rank_attributes prints out attribute rankings for developer.tab and iris.tab'))
	mut rr := vhammll2.RankingResult{}
	rr = vhammll2.rank_attributes(vhammll2.opts('-s datasets/testdata/developer.tab'))
	rr = vhammll2.rank_attributes(vhammll2.opts('-s -b 3,3 datasets/iris.tab'))
	// repeat for class missing purge
	rr = vhammll2.rank_attributes(vhammll2.opts('-s -pmc -b 3,3 datasets/class_missing_iris.tab'))
}

fn test_show_validate() ? {
	println(vhammll2.r_b('\n\ntest_show_validate prints out results for validation of bcw350train with bcw174validate'))
	cl := vhammll2.make_classifier(vhammll2.opts('-s -a 4 -t datasets/bcw174validate datasets/bcw350train'))
	_ = vhammll2.validate(cl, vhammll2.opts('-s -a 4 -t datasets/bcw174validate datasets/bcw350train'))!
}

fn test_show_verify() ? {
	println(vhammll2.r_b('\n\ntest_show_verify prints out results for verification of bcw350train with bcw174test, and of soybean-large-train.tab with soybean-large-test.tab'))
	mut result := vhammll2.CrossVerifyResult{}
	result = vhammll2.verify(vhammll2.opts('-s -a 4 -t datasets/bcw174test datasets/bcw350train'))
	vhammll2.show_verify(result)
}

fn test_show_multiple_classifier_settings_options() ? {
	println(vhammll2.r_b('\n\ntest_show_multiple_classifier_settings_options prints out a table showing the classifier settings for the chosen classifiers in a multiple classifier cross-validation or verification'))
	mut result := vhammll2.CrossVerifyResult{}
}
