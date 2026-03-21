module vhammll2

import os

fn testsuite_begin() ! {
	if os.is_dir('tempfolders/tempfolder_show_perf') {
		os.rmdir_all('tempfolders/tempfolder_show_perf')!
	}
	os.mkdir_all('tempfolders/tempfolder_show_perf')!
}

fn testsuite_end() ! {
	os.rmdir_all('tempfolders/tempfolder_show_perf')!
}

fn test_show_append_perf() ? {
	println(r_b('test_show_append_perf should print out 3 classifiers based on soybean-large-train.tab.'))

	mut cl := Classifier{}
	mut tcl := Classifier{}
	mut val_results := ValidateResult{}

	// repeat with soybean
	cl = make_classifier(opts('-o tempfolders/tempfolder_show_perf/classifierfile datasets/soybean-large-train.tab'))
	// do a validation and save the result
	val_results = validate(cl, opts('-o tempfolders/tempfolder_show_perf/instancesfile -t datasets/soybean-large-validate.tab datasets/soybean-large-train.tab'))!
	// now do the append, first from val_results, and saving the extended classifier
	tcl = append_instances(cl, val_results, opts('-o tempfolders/tempfolder_show_perf/classifierfile datasets/soybean-large-train.tab'))

	// now do it again but from the saved validate result,
	// appending to the previously extended classifier
	tcl = append_instances(load_classifier_file('tempfolders/tempfolder_show_perf/classifierfile')!,
		load_instances_file('tempfolders/tempfolder_show_perf/instancesfile')!, opts('-o tempfolders/tempfolder_show_perf/classifierfile datasets/soybean-large-train.tab'))
}

fn test_show_classifier_perf() {
	println(r_b('test_show_classifier_perf prints out a classifier for anneal.tab'))
	make_classifier(opts('-s -a 2 -b 3,10 datasets/anneal.tab'))
}

fn test_show_explore_verify_perf() ? {
	println(r_b('\n\ntest_show_explore_verify_perf prints out explore results for verification of bcw350train with bcw174test'))
	mut results := ExploreResult{}
	results = explore(opts('-s -a 2,6 -t datasets/bcw174test datasets/bcw350train'))
	results = explore(opts('-s -a 0 -t datasets/bcw174test datasets/bcw350train'))
}

fn test_show_rank_attributes_perf() {
	println(r_b('\n\ntest_show_rank_attributes_perf prints out attribute rankings for anneal.tab (without and with missing values)'))
	mut rr := RankingResult{}
	rr = rank_attributes(opts('-s -b 3,3 datasets/anneal.tab'))
	rr = rank_attributes(opts('-s -b 3,3 datasets/anneal.tab'))
}
