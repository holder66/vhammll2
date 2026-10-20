module visual

import os
import vhammll2

fn testsuite_begin() {
	if os.is_dir('tempfolders/tempfolder_display_perf') {
		os.rmdir_all('tempfolders/tempfolder_display_perf') or { panic(err) }
	}
	os.mkdir_all('tempfolders/tempfolder_display_perf')!
}

fn testsuite_end() {
	os.rmdir_all('tempfolders/tempfolder_display_perf') or { panic(err) }
}

fn test_display_saved_ranking_result_perf() ? {
	// rank a dataset file and show the result; save the result, then display the saved file
	outputfile := 'tempfolders/tempfolder_display_perf/rank_result'
	_ = vhammll2.rank_attributes(vhammll2.opts('-s -o ${outputfile} datasets/UCI/anneal.arff'))
	vhammll2.display_file(outputfile, vhammll2.opts('-s datasets/UCI/anneal.arff'))
}

fn test_display_cross_result_perf() ? {
	// cross-validate a dataset file and display the result; save the result, then display
	// the saved result file
	datafile := 'datasets/UCI/segment.arff'
	outputfile := 'tempfolders/tempfolder_display_perf/cross_result'

	vhammll2.cross_validate(vhammll2.opts('-s -a 4 -b 12 -f 5 -o ${outputfile} ${datafile}'))
	vhammll2.display_file(outputfile, vhammll2.opts('-s ${datafile}'))
	vhammll2.cross_validate(vhammll2.opts('-s -a 4 -b 12 -f 10 -r 10 -rand -o ${outputfile} ${datafile}'))
	vhammll2.display_file(outputfile, vhammll2.opts('-s ${datafile}'))
	println(vhammll2.r_b('\nDone for test_display_cross_result_perf'))
}

fn test_display_explore_result_verify_perf() ? {
	datafile := 'datasets/soybean-large-train.tab'
	testfile := 'datasets/soybean-large-test.tab'
	outputfile := 'tempfolders/tempfolder_display_perf/explore_result'

	vhammll2.explore(vhammll2.opts('-s -a 12,15 -b 2,6 -o ${outputfile} -t ${testfile} ${datafile}'))
	vhammll2.display_file(outputfile, vhammll2.opts('-s ${datafile}'))

	// repeat for a binary class dataset
	datafile2 := 'datasets/bcw350train'
	testfile2 := 'datasets/bcw174test'
	vhammll2.explore(vhammll2.opts('-s -a 0 -b 2,6 -o ${outputfile} -t ${testfile2} ${datafile2}'))
	vhammll2.display_file(outputfile, vhammll2.opts('-s ${datafile2}'))
}
