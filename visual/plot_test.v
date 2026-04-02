module visual

import os
import time
import vhammll2

const main_text = '// temp.v
module main
import vhammll2

fn main() {
	vhammll2.cli()!
}'

fn testsuite_begin() ? {
	os.execute('open -a "Firefox" --new --args -setDefaultBrowser')
	time.sleep(5 * time.second)
	os.chdir('..')!
	mut f := os.create(os.abs_path('') + '/temp.v')!
	f.write_string(main_text)!
	f.close()

	os.execute_or_panic('v temp.v')
	if os.is_dir('tempfolders/tempfolder_plot') {
		os.rmdir_all('tempfolders/tempfolder_plot')!
	}
	os.mkdir_all('tempfolders/tempfolder_plot')!
}

fn testsuite_end() ? {
	if os.exists('temp') {
		os.rm('temp')!
	}
	if os.exists('temp.v') {
		os.rm('temp.v')!
	}
	os.rmdir_all('tempfolders/tempfolder_plot')!
	// os.execute('open -a "Safari" --new --args -setDefaultBrowser')
}

fn test_plot_roc() {
	// generate a multiple classifier settings file from a 2-class dataset
	mut output := os.execute_or_panic('./temp explore -ms tempfolders/tempfolder_plot/bcw.opts -t vhammll2/datasets/bcw174test vhammll2/datasets/bcw350train')
	assert !output.output.contains('Listening on')
	// display the ROC curve from the settings file (exercises plot_roc)
	output = os.execute_or_panic('./temp display -g tempfolders/tempfolder_plot/bcw.opts')
	assert output.output.count('Listening on') == 1
	println(vhammll2.r_b('Done with test_plot_roc'))
}

fn test_plot_multi_roc() {
	// generate multiple ROC curve traces from the settings file (exercises plot_mult_roc)
	mut output := os.execute_or_panic('./temp optimals -g vhammll/src/testdata/bcw.opts')
	assert output.output.count('Listening on') == 1
	output = os.execute_or_panic('./temp optimals -g -cl 2,3 vhammll/src/testdata/bcw.opts')
	assert output.output.count('Listening on') == 1
	println(vhammll2.r_b('Done with test_plot_multi_roc'))
}

fn test_plot_roc_multiclass() {
	// generate a settings file from a multi-class dataset (iris: 3 classes)
	mut output := os.execute_or_panic('./temp explore -ms tempfolders/tempfolder_plot/iris.opts vhammll/datasets/iris.tab')
	assert !output.output.contains('Listening on')
	// display -g with multi-class settings: the 2-class guard skips plot_roc but must not crash
	output = os.execute_or_panic('./temp display -g tempfolders/tempfolder_plot/iris.opts')
	assert !output.output.contains('Listening on')
	// optimals -g with multi-class settings: exercises plot_mult_roc with multi-class sens/spec values
	output = os.execute_or_panic('./temp optimals -g tempfolders/tempfolder_plot/iris.opts')
	assert !output.output.contains('Listening on')
	println(vhammll2.r_b('Done with test_plot_roc_multiclass'))
}

fn test_plot_rank() {
	mut output := os.execute_or_panic('./temp rank -g vhammll/datasets/developer.tab')
	assert output.output.count('Listening on') == 1
	output = os.execute_or_panic('./temp rank -g -b 2,7 vhammll/datasets/iris.tab')
	assert output.output.count('Listening on') == 1
	output = os.execute_or_panic('./temp rank -g vhammll/datasets/anneal.tab')
	assert output.output.count('Listening on') == 1
	output = os.execute_or_panic('./temp rank -g -l 3 vhammll/datasets/anneal.tab')
	assert output.output.count('Listening on') == 1
	// bcw350train attributes are integers 1-10 (discrete) → no continuous traces → no plot
	output = os.execute_or_panic('./temp rank -g -b 2,7 -l 5 vhammll/datasets/bcw350train')
	assert output.output.count('Listening on') == 0
	println(vhammll2.r_b('Done with test_plot_rank'))
}

fn test_plot_switches() {
	// exercises plot_switches: rank with -sw flag on a 2-class dataset
	// leukemia34test: binary + truly continuous attributes
	// → plot_rank fires AND plot_switches fires = 2 total
	mut output := os.execute_or_panic('./temp rank -g -sw -lc 5 vhammll/datasets/leukemia34test.tab')
	assert output.output.count('Listening on') == 2

	// with a bin range and per-trace limit: still 2 plots
	output = os.execute_or_panic('./temp rank -g -sw -b 2,6 -lc 5 vhammll/datasets/leukemia34test.tab')
	assert output.output.count('Listening on') == 2

	// stricter threshold (-swt 1): both plots still appear; threshold reference line at 1
	output = os.execute_or_panic('./temp rank -g -sw -swt 1 -lc 5 vhammll/datasets/leukemia34test.tab')
	assert output.output.count('Listening on') == 2

	// exclude missing values from bin 0: both plots still appear
	output = os.execute_or_panic('./temp rank -g -sw -x  -lc 5 vhammll/datasets/leukemia34test.tab')
	assert output.output.count('Listening on') == 2

	// bcw350train: all attributes are integers 1-10 → treated as discrete → no continuous
	// attributes → both plot_rank and plot_switches return early = 0 plots
	output = os.execute_or_panic('./temp rank -g -sw vhammll/datasets/bcw350train')
	assert output.output.count('Listening on') == 0

	// -sw without -g: no plots produced at all
	output = os.execute_or_panic('./temp rank -sw vhammll/datasets/leukemia34test.tab')
	assert output.output.count('Listening on') == 0

	// multi-class (iris, 3 classes): plot_switches guard skips; only plot_rank fires = 1
	output = os.execute_or_panic('./temp rank -g -sw vhammll/datasets/iris.tab')
	assert output.output.count('Listening on') == 1
	println(vhammll2.r_b('Done with test_plot_switches'))
}

fn test_plot_hits() {
	// multi-class datasets: original layout (x = bin, y = hits, fill tozeroy)
	mut output := os.execute_or_panic('./temp rank -of -lc 1 -b 2,2 vhammll/datasets/developer.tab')
	assert output.output.count('Listening on') == 1
	output = os.execute_or_panic('./temp rank -of -b 2,3 -lc 1 vhammll/datasets/iris.tab')
	assert output.output.count('Listening on') == 2
	output = os.execute_or_panic('./temp rank -of -lc 1 -b 3,6 vhammll/datasets/anneal.tab')
	assert output.output.count('Listening on') == 4
	// binary dataset: butterfly layout (x = ±hits, y = bin, fill tozerox)
	output = os.execute_or_panic('./temp rank -of -lc 1 -b 4,5 vhammll/datasets/leukemia34test.tab')
	assert output.output.count('Listening on') == 2
	// weighted butterfly: normalised to percentages, symmetric x range [-100, 100]
	output = os.execute_or_panic('./temp rank -of -wr -lc 1 -b 4,5 vhammll/datasets/leukemia34test.tab')
	assert output.output.count('Listening on') == 2
	println(vhammll2.r_b('Done with test_plot_hits'))
}

fn test_plot_explore_cross() {
	// for a multi-class dataset, we only get a plot of balanced accuracy by number of attributes used
	// (ROC curves only apply to 2-class datasets)
	mut output := os.execute_or_panic('./temp explore -e -g -a 1,3 -b 2,4 vhammll/datasets/iris.tab')
	dump(output.output)
	assert output.output.count('Listening on') == 1
	// for binary datasets with continuous variables, get 3 plots
	output = os.execute_or_panic('./temp explore -e -g -a 2 -b 5,6  vhammll/datasets/leukemia34test.tab')
	assert output.output.count('Listening on') == 3
	// for binary datasets with no continuous variables, only get 2 plots
	output = os.execute_or_panic('./temp explore -e -g -a 2,3 vhammll/datasets/breast-cancer-wisconsin-disc.tab')
	assert output.output.count('Listening on') == 2
	println(vhammll2.r_b('Done with test_plot_explore_cross'))
}

// fn test_plot_explore_cross() {
// 	// exercises plot_explore with cross-validation (no -t flag)
// 	output := os.execute_or_panic('./temp explore -g -a 1,3 -b 2,4 vhammll2/datasets/iris.tab')
// 	assert output.output.count('Listening on') == 1
// }

fn test_plot_optimals_roc() {
	// exercises plot_mult_roc via the optimals command;
	// reuses the bcw.opts settings file generated in test_plot_roc
	output := os.execute_or_panic('./temp optimals -g tempfolders/tempfolder_plot/bcw.opts')
	assert output.output.count('Listening on') == 1
	println(vhammll2.r_b('Done with test_plot_optimals_roc'))
}

fn test_plot_auc_combinations() {
	// exercises plot_auc_combinations via optimals with -cl (combination limits) flag;
	// reuses the bcw.opts settings file generated in test_plot_roc
	output := os.execute_or_panic('./temp optimals -g -cl 2,4 tempfolders/tempfolder_plot/bcw.opts')
	assert output.output.count('Listening on') == 1
	println(vhammll2.r_b('Done with test_plot_auc_combinations'))
}
