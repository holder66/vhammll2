module vhammll2

import os

fn testsuite_begin() ! {
	if os.is_dir('tempfolders/tempfolder_display_perf') {
		os.rmdir_all('tempfolders/tempfolder_display_perf')!
	}
	os.mkdir_all('tempfolders/tempfolder_display_perf')!
}

fn testsuite_end() ! {
	os.rmdir_all('tempfolders/tempfolder_display_perf')!
}

fn test_display_saved_ranking_result_perf() ? {
	// rank a dataset file and show the result; save the result, then display the saved file
	outputfile := 'tempfolders/tempfolder_display_perf/rank_result'
	_ = rank_attributes(opts('-s -o ${outputfile} datasets/UCI/anneal.arff'))
	display_file(outputfile, opts('-s datasets/UCI/anneal.arff'))
}

fn test_display_cross_result_perf() ? {
	// cross-validate a dataset file and display the result; save the result, then display
	// the saved result file
	datafile := 'datasets/UCI/segment.arff'
	outputfile := 'tempfolders/tempfolder_display_perf/cross_result'

	cross_validate(opts('-s -a 4 -b 12 -f 5 -o ${outputfile} ${datafile}'))
	display_file(outputfile, opts('-s ${datafile}'))
	cross_validate(opts('-s -a 4 -b 12 -f 10 -r 10 -rand -o ${outputfile} ${datafile}'))
	display_file(outputfile, opts('-s ${datafile}'))
	println(r_b('\nDone for test_display_cross_result_perf'))
}

fn test_display_explore_result_verify_perf() ? {
	datafile := 'datasets/soybean-large-train.tab'
	testfile := 'datasets/soybean-large-test.tab'
	outputfile := 'tempfolders/tempfolder_display_perf/explore_result'

	explore(opts('-s -a 12,15 -b 2,6 -o ${outputfile} -t ${testfile} ${datafile}'))
	display_file(outputfile, opts('-s ${datafile}'))

	// repeat for a binary class dataset
	datafile2 := 'datasets/bcw350train'
	testfile2 := 'datasets/bcw174test'
	explore(opts('-s -a 0 -b 2,6 -o ${outputfile} -t ${testfile2} ${datafile2}'))
	display_file(outputfile, opts('-s ${datafile2}'))
}
