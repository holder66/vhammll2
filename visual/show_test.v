module visual

import os
import vhammll2

fn testsuite_begin() {
	if os.is_dir('tempfolders/tempfolder_show') {
		os.rmdir_all('tempfolders/tempfolder_show') or { panic(err) }
	}
	os.mkdir_all('tempfolders/tempfolder_show')!
}

fn testsuite_end() {
	os.rmdir_all('tempfolders/tempfolder_show') or { panic(err) }
}

// test_show_analyze has no asserts; the console output needs
// to be verified visually.
fn test_show_analyze() {
	println(vhammll2.r_b('test_show_analyze should print out dataset analyses for developer.tab and for iris.tab'))
	mut ar := vhammll2.AnalyzeResult{}
	ar = vhammll2.analyze_dataset(vhammll2.get_opts('datasets/testdata/developer.tab'))
	vhammll2.show_analyze(ar)
	ar = vhammll2.analyze_dataset(vhammll2.get_opts('datasets/iris.tab'))
	vhammll2.show_analyze(ar)

	// with purging of instances whose class values are missing
	ar = vhammll2.analyze_dataset(vhammll2.get_opts('-pmc datasets/iris.tab'))
	vhammll2.show_analyze(ar)
	ar = vhammll2.analyze_dataset(vhammll2.get_opts('datasets/class_missing_iris.tab'))
	vhammll2.show_analyze(ar)
	ar = vhammll2.analyze_dataset(vhammll2.get_opts('-pmc datasets/class_missing_iris.tab'))
	vhammll2.show_analyze(ar)
}

fn test_show_append() ? {
	println(vhammll2.r_b('test_show_append should print out a test.tab classifier, with 6 instances, followed by a test.tab classifier with 16 instances, and then a test.tab classifier with 26 instances and 3 history events.'))

	mut cl := vhammll2.Classifier{}
	mut tcl := vhammll2.Classifier{}
	mut val_results := vhammll2.ValidateResult{}
	// create the classifier file and save it
	cl = vhammll2.make_classifier(vhammll2.get_opts('-o tempfolders/tempfolder_show/classifierfile datasets/testdata/test.tab'))
  vhammll2.show_classifier(cl)
	// do a validation and save the result
	val_results = vhammll2.validate(cl, vhammll2.get_opts('-o tempfolders/tempfolder_show/instancesfile -t datasets/testdata/test_validate.tab datasets/testdata/test.tab'))!
	// now do the append, first from val_results, and saving the extended classifier
	tcl = vhammll2.append_instances(cl, val_results, vhammll2.get_opts('-o tempfolders/tempfolder_show/classifierfile datasets/testdata/test.tab'))
	vhammll2.show_classifier(tcl)
	// now do it again but from the saved validate result,
	// appending to the previously extended classifier
	tcl = vhammll2.append_instances(vhammll2.load_classifier_file('tempfolders/tempfolder_show/classifierfile')!, vhammll2.load_instances_file('tempfolders/tempfolder_show/instancesfile')!, vhammll2.get_opts('-o tempfolders/tempfolder_show/classifierfile datasets/testdata/test.tab'))
	vhammll2.show_classifier(tcl)
}

fn test_show_classifier() {
	println(vhammll2.r_b('test_show_classifier prints out classifiers for iris.tab and for developer.tab'))
	mut cl := vhammll2.make_classifier(vhammll2.get_opts('-a 2 -b 3,10 datasets/iris.tab'))
	vhammll2.show_classifier(cl)
	// now with purging of instances with missing class values
	cl = vhammll2.make_classifier(vhammll2.get_opts('-s -pmc -a 2 -b 3,10 datasets/class_missing_iris.tab'))
	vhammll2.show_classifier(cl)
	// repeat with developer.tab, which is newer_orange format
	cl = vhammll2.make_classifier(vhammll2.get_opts('-s -a 2 -b 3,10 datasets/testdata/developer.tab'))
	vhammll2.show_classifier(cl)
	cl = vhammll2.make_classifier(vhammll2.get_opts('-s -pmc -a 2 -b 3,10 datasets/testdata/class_missing_developer.tab'))
	vhammll2.show_classifier(cl)
}

fn test_show_crossvalidation() ? {
	println(vhammll2.r_b('test_show_crossvalidation prints out cross-validation results for developer.tab, breast-cancer-wisconsin-disc.tab, and iris.tab'))
	mut cvr := vhammll2.CrossVerifyResult{}
	println(vhammll2.r_b('\n\ndeveloper.tab'))
	mut opts := vhammll2.get_opts('-s datasets/testdata/developer.tab'))
	opts.command = 'cross'
	cvr = vhammll2.cross_validate(opts)
	println(vhammll2.r_b('\ndeveloper.tab with expanded results'))
	opts.expanded_flag = true
	cvr = vhammll2.cross_validate(opts))
	println(vhammll2.r_b('\n\nbreast-cancer-wisconsin-disc.tab'))
	opts = vhammll2.get_opts('-s -a 4 datasets/breast-cancer-wisconsin-disc.tab'))
	opts.command = 'cross'
	cvr = vhammll2.cross_validate(opts)
	println('\nbreast-cancer-wisconsin-disc.tab with expanded results')
	opts.expanded_flag = true
	cvr = vhammll2.cross_validate(opts))
	println(vhammll2.r_b('\n\niris.tab'))
	opts = vhammll2.get_opts('-s -a 2 -b 3,6 datasets/iris.tab'))
	opts.command = 'cross'
	cvr = vhammll2.cross_validate(opts)
	println(vhammll2.r_b('\n\niris.tab with expanded results'))
	opts.expanded_flag = true
	cvr = vhammll2.cross_validate(opts))
	// now with purging for missing classes
	println(vhammll2.r_b('\n\nclass_missing_iris.tab with purging for missing classes'))
	opts = vhammll2.get_opts('-pmc -a 2 -b 3,6 datasets/class_missing_iris.tab'))
	opts.command = 'cross'
	opts.expanded_flag = true
	cvr = vhammll2.cross_validate(opts)
}

fn test_show_explore_cross() ? {
	println(vhammll2.r_b('\n\n test_show_explore_cross prints out explore results for cross-validation of developer.tab'))
	mut results := vhammll2.ExploreResult{}
	mut opts := vhammll2.get_opts('-s -rand -a 2,4 -b 2,5 -f 10 -r 50 datasets/testdata/developer.tab'))
	opts.command = 'explore'
	results = vhammll2.explore(opts)

	// repeat for class missing purge
	opts = vhammll2.get_opts('-s -rand -pmc -a 2,4 -b 2,5 -f 10 -r 50 datasets/testdata/class_missing_developer.tab'))
	println(vhammll2.r_b('\n\n test_show_explore_cross prints out explore results for cross-validation of class_missing_developer.tab'))
	opts.command = 'explore'
	results = vhammll2.explore(opts)
}

fn test_show_rank_attributes() {
	println(vhammll2.r_b('\n\ntest_show_rank_attributes prints out attribute rankings for developer.tab and iris.tab'))
	mut rr := vhammll2.RankingResult{}
	mut opts := vhammll2.get_opts('-s datasets/testdata/developer.tab'))
	opts.command = 'rank'
	rr = vhammll2.rank_attributes(opts)
	// repeat for class missing purge
	opts = vhammll2.get_opts('-s -pmc -b 3,3 datasets/class_missing_iris.tab'))
	opts.command = 'rank'
	rr = vhammll2.rank_attributes(opts)
}

fn test_show_validate() ? {
	println(vhammll2.r_b('\n\ntest_show_validate prints out results for validation of bcw350train.txt with bcw174validate.txt'))
	cl := vhammll2.make_classifier(vhammll2.get_opts('-s -a 4 -t datasets/bcw174validate.txt datasets/bcw350train.txt'))
	mut opts := vhammll2.get_opts('-s -a 4 -t datasets/bcw174validate.txt datasets/bcw350train.txt')
	opts.command = 'validate'
	_ = vhammll2.validate(cl, opts)!
}

fn test_show_verify() ? {
	println(vhammll2.r_b('\n\ntest_show_verify prints out results for verification of bcw350train.txt with bcw174test.txt, and of soybean-large-train.tab with soybean-large-test.tab'))
	_ = vhammll2.verify(vhammll2.get_opts('-s -a 4 -t datasets/bcw174test.txt datasets/bcw350train.txt'))
	// _ = vhammll2.verify(vhammll2.get_opts('-s -t datasets/soybean-large-test.tab datasets/soybean-large-train.tab'))
}

fn test_show_multiple_classifier_settings_options() ? {
	println(vhammll2.r_b('\n\ntest_show_multiple_classifier_settings_options prints out a table showing the classifier settings for the chosen classifiers in a multiple classifier cross-validation or verification'))
	mut result := vhammll2.CrossVerifyResult{}
}
