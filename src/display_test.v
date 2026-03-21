module vhammll2

import os

fn testsuite_begin() ! {
	if os.is_dir('tempfolders/tempfolder_display') {
		os.rmdir_all('tempfolders/tempfolder_display')!
	}
	os.mkdir_all('tempfolders/tempfolder_display')!
}

fn testsuite_end() ! {
	os.rmdir_all('tempfolders/tempfolder_display')!
}

fn test_display_multiple_classifier_settings() ? {
	displayfile := 'src/testdata/bcw.opts'
	display_file(displayfile, opts('-m# 3,5,6'))
}

fn test_display_saved_classifier() ? {
	// make a classifier, show it, then save it, then display the saved classifier file
	outputfile := 'tempfolders/tempfolder_display/classifierfile'
	cl := make_classifier(opts('-s -a 8 -b 3,10 -o ${outputfile} datasets/testdata/developer.tab'))
	display_file(outputfile, opts('-s datasets/testdata/developer.tab'))
}

fn test_display_saved_analyze_result() ? {
	// analyze a dataset file and show the result; save the result, then display the saved file
	outputfile := 'tempfolders/tempfolder_display/analyze_result'
	_ = analyze_dataset(opts('-s -o ${outputfile} datasets/UCI/anneal.arff'))
	display_file(outputfile, opts('-s datasets/UCI/anneal.arff'))
}

fn test_display_saved_ranking_result() ? {
	// rank a dataset file and show the result; save the result, then display the saved file
	outputfile := 'tempfolders/tempfolder_display/rank_result'
	_ = rank_attributes(opts('-s -o ${outputfile} datasets/UCI/anneal.arff'))
	display_file(outputfile, opts('-s datasets/UCI/anneal.arff'))
}

fn test_display_saved_validate_result() ? {
	// validate a dataset file and show the result; save the result, then display the saved file
	outputfile := 'tempfolders/tempfolder_display/validate_result'
	cl := make_classifier(opts('-s -t datasets/bcw174validate datasets/bcw350train'))
	_ = validate(cl, opts('-s -o ${outputfile} -t datasets/bcw174validate datasets/bcw350train'))!
	display_file(outputfile, opts('-s datasets/bcw350train'))
}

fn test_display_saved_verify_result() ? {
	// verify a dataset file and show the result, with and without the expanded and
	// show_attributes flags; save the result, then display the saved result, again with
	// and without those flags
	datafile := 'datasets/bcw350train'
	testfile := 'datasets/bcw174test'
	outputfile := 'tempfolders/tempfolder_display/verify_result'

	println(r_b('\nTrain a classifier on bcw350train, use it to verify bcw174test'))
	println(r_b('with the expanded_flag not set:'))
	verify(opts('-s -a 5 -o ${outputfile} -t ${testfile} ${datafile}'))
	println(r_b('\nAnd with the expanded_flag set:'))
	verify(opts('-s -a 5 -o ${outputfile} -t ${testfile} ${datafile}'))
	println(r_b('\nAnd now with the show_attributes_flag set:'))
	verify(opts('-s -ea -a 5 -o ${outputfile} -t ${testfile} ${datafile}'))
	println(r_b('\nRepeat the above three, but displaying the saved result file:'))
	println(r_b('with the expanded_flag not set:'))
	display_file(outputfile, opts('-s ${datafile}'))
	println(r_b('\nAnd with the expanded_flag set:'))
	display_file(outputfile, opts('-s ${datafile}'))
	println(r_b('\nAnd now with the show_attributes_flag set:'))
	display_file(outputfile, opts('-s -ea ${datafile}'))
	println(r_b('\nAnd finally with the show_attributes_flag set and the expanded_flag not set:'))
	display_file(outputfile, opts('-s -ea ${datafile}'))
}

fn test_display_cross_result() ? {
	// cross-validate a dataset file and display the result; save the result, then display
	// the saved result file
	datafile := 'datasets/UCI/segment.arff'
	outputfile := 'tempfolders/tempfolder_display/cross_result'

	cross_validate(opts('-s -a 4 -b 12 -f 5 -o ${outputfile} ${datafile}'))
	display_file(outputfile, opts('-s ${datafile}'))
	cross_validate(opts('-s -a 4 -b 12 -f 10 -r 10 -rand -o ${outputfile} ${datafile}'))
	display_file(outputfile, opts('-s ${datafile}'))
	println(r_b('\nDone for test_display_cross_result'))
}

fn test_display_explore_result_cross() ? {
	datafile := 'datasets/UCI/iris.arff'
	outputfile := 'tempfolders/tempfolder_display/explore_result'

	explore(opts('-s -a 2,3 -b 2,3 -o ${outputfile} ${datafile}'))
	display_file(outputfile, opts('-s ${datafile}'))

	// repeat for a binary class dataset
	datafile2 := 'datasets/bcw174test'
	explore(opts('-s -g -a 0 -b 2,3 -o ${outputfile} ${datafile2}'))
	display_file(outputfile, opts('-s ${datafile2}'))
}

fn test_display_explore_result_verify() ? {
	datafile := 'datasets/soybean-large-train.tab'
	testfile := 'datasets/soybean-large-test.tab'
	outputfile := 'tempfolders/tempfolder_display/explore_result'

	explore(opts('-s -a 12,15 -b 2,6 -o ${outputfile} -t ${testfile} ${datafile}'))
	display_file(outputfile, opts('-s ${datafile}'))

	// repeat for a binary class dataset
	datafile2 := 'datasets/bcw350train'
	testfile2 := 'datasets/bcw174test'
	explore(opts('-s -a 0 -b 2,6 -o ${outputfile} -t ${testfile2} ${datafile2}'))
	display_file(outputfile, opts('-s ${datafile2}'))
}
