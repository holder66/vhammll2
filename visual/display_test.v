module visual

import os
import vhammll2

fn testsuite_begin() {
	os.execute('open -a "Firefox" --new --args -setDefaultBrowser')
	if os.is_dir('tempfolders/tempfolder_display') {
		os.rmdir_all('tempfolders/tempfolder_display')!
	}
	os.mkdir_all('tempfolders/tempfolder_display')!
}

fn testsuite_end() {
	os.rmdir_all('tempfolders/tempfolder_display') or { panic(err) }
}

fn test_display_multiple_classifier_settings() ? {
	displayfile := 'tempfolders/tempfolder_display/bcw.opts'
	datafile := 'datasets/bcw350train'
	testfile := 'datasets/bcw174test'
	// create a settings file with enough classifiers to include indices 3, 5, 6
	for a in [1, 2, 3, 4, 5, 6, 7] {
		vhammll2.verify(vhammll2.opts('-a ${a} -ms ${displayfile} -t ${testfile} ${datafile}'))
	}
	vhammll2.display_file(displayfile, vhammll2.opts('-m# 3,5,6'))
}

fn test_display_saved_classifier() ? {
	// make a classifier, show it, then save it, then display the saved classifier file
	outputfile := 'tempfolders/tempfolder_display/classifierfile'
	cl := vhammll2.make_classifier(vhammll2.opts('-s -a 8 -b 3,10 -o ${outputfile} datasets/testdata/developer.tab'))
	vhammll2.display_file(outputfile, vhammll2.opts('-s datasets/testdata/developer.tab'))
}

fn test_display_saved_analyze_result() ? {
	// analyze a dataset file and show the result; save the result, then display the saved file
	outputfile := 'tempfolders/tempfolder_display/analyze_result'
	_ = vhammll2.analyze_dataset(vhammll2.opts('-s -o ${outputfile} datasets/UCI/anneal.arff'))
	vhammll2.display_file(outputfile, vhammll2.opts('-s datasets/UCI/anneal.arff'))
}

fn test_display_saved_validate_result() ? {
	// validate a dataset file and show the result; save the result, then display the saved file
	outputfile := 'tempfolders/tempfolder_display/validate_result'
	cl := vhammll2.make_classifier(vhammll2.opts('-s -t datasets/bcw174validate datasets/bcw350train'))
	_ = vhammll2.validate(cl, vhammll2.opts('-s -o ${outputfile} -t datasets/bcw174validate datasets/bcw350train'))!
	vhammll2.display_file(outputfile, vhammll2.opts('-s datasets/bcw350train'))
}

fn test_display_saved_verify_result() ? {
	// verify a dataset file and show the result, with and without the expanded and
	// show_attributes flags; save the result, then display the saved result, again with
	// and without those flags
	datafile := 'datasets/bcw350train'
	testfile := 'datasets/bcw174test'
	outputfile := 'tempfolders/tempfolder_display/verify_result'

	println(vhammll2.r_b('\nTrain a classifier on bcw350train, use it to verify bcw174test'))
	println(vhammll2.r_b('with the expanded_flag not set:'))
	vhammll2.verify(vhammll2.opts('-s -a 5 -o ${outputfile} -t ${testfile} ${datafile}'))
	println(vhammll2.r_b('\nAnd with the expanded_flag set:'))
	vhammll2.verify(vhammll2.opts('-s -a 5 -o ${outputfile} -t ${testfile} ${datafile}'))
	println(vhammll2.r_b('\nAnd now with the show_attributes_flag set:'))
	vhammll2.verify(vhammll2.opts('-s -ea -a 5 -o ${outputfile} -t ${testfile} ${datafile}'))
	println(vhammll2.r_b('\nRepeat the above three, but displaying the saved result file:'))
	println(vhammll2.r_b('with the expanded_flag not set:'))
	vhammll2.display_file(outputfile, vhammll2.opts('-s ${datafile}'))
	println(vhammll2.r_b('\nAnd with the expanded_flag set:'))
	vhammll2.display_file(outputfile, vhammll2.opts('-s ${datafile}'))
	println(vhammll2.r_b('\nAnd now with the show_attributes_flag set:'))
	vhammll2.display_file(outputfile, vhammll2.opts('-s -ea ${datafile}'))
	println(vhammll2.r_b('\nAnd finally with the show_attributes_flag set and the expanded_flag not set:'))
	vhammll2.display_file(outputfile, vhammll2.opts('-s -ea ${datafile}'))
}

fn test_display_explore_result_cross() ? {
	datafile := 'datasets/UCI/iris.arff'
	outputfile := 'tempfolders/tempfolder_display/explore_result'

	vhammll2.explore(vhammll2.opts('-s -a 2,3 -b 2,3 -o ${outputfile} ${datafile}'))
	vhammll2.display_file(outputfile, vhammll2.opts('-s ${datafile}'))

	// repeat for a binary class dataset
	datafile2 := 'datasets/bcw174test'
	vhammll2.explore(vhammll2.opts('-s -g -a 0 -b 2,3 -o ${outputfile} ${datafile2}'))
	vhammll2.display_file(outputfile, vhammll2.opts('-s ${datafile2}'))
}
