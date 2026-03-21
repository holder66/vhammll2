module perf

import os
import vhammll2

fn testsuite_begin() ! {
	if os.is_dir('tempfolders/tempfolder_one_vs_rest_verify_perf') {
		os.rmdir_all('tempfolders/tempfolder_one_vs_rest_verify_perf')!
	}
	os.mkdir_all('tempfolders/tempfolder_one_vs_rest_verify_perf')!
}

fn testsuite_end() ! {
	os.rmdir_all('tempfolders/tempfolder_one_vs_rest_verify_perf')!
}

fn test_one_vs_rest_verify_perf() ? {
	settingsfile := 'tempfolders/tempfolder_one_vs_rest_verify_perf/onevsrest.opts'
	vhammll2.one_vs_rest_verify(vhammll2.opts('-a 25 -b 1,16 -ms ${settingsfile} -t datasets/soybean-large-test.tab datasets/soybean-large-train.tab'))
}
