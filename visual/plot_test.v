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

fn testsuite_begin() {
  os.exec('open -a "firefox" --new --args -silent -nosplash -setDefaultBrowser'.split(' '))
	time.sleep(10 * time.second)
	os.chdir('..')!
	mut f := os.create(os.abs_path('') + '/temp.v')!
	f.write_string(main_text)!
	f.close()

	os.exec_or_panic(['v', 'temp.v'])
	if os.is_dir('tempfolders/tempfolder_plot') {
		os.rmdir_all('tempfolders/tempfolder_plot')!
	}
	os.mkdir_all('tempfolders/tempfolder_plot')!
}

fn testsuite_end() {
	if os.exists('temp') {
		os.rm('temp') or { panic(err) }
	}
	if os.exists('temp.v') {
		os.rm('temp.v')!
	}
	os.rmdir_all('tempfolders/tempfolder_plot')!
	os.exec('open -a "Safari" --new --args -setDefaultBrowser'.split(' '))
}

fn test_plot_roc() {
	// generate a multiple classifier settings file from a 2-class dataset
	test := os.join_path(@DIR, '..', 'datasets/bcw174test.txt')
	train := os.join_path(@DIR, '..', 'datasets/bcw350train.txt')
	mut output := os.exec_or_panic(['./temp', 'explore', '-ms', 'tempfolders/tempfolder_plot/bcw.opts', '-t', test, train])
	assert !output.output.contains('Listening on')
	// display the ROC curve from the settings file (exercises plot_roc)
	output = os.exec_or_panic('./temp display -g tempfolders/tempfolder_plot/bcw.opts'.split(' '))
	assert output.output.count('Listening on') == 1
	println(vhammll2.r_b('Done with test_plot_roc'))
}

fn test_plot_multi_roc() {
	// generate multiple ROC curve traces from the settings file (exercises plot_mult_roc)
	mut output := os.exec_or_panic(['./temp', 'optimals', '-g', 'tempfolders/tempfolder_plot/bcw.opts'])
	assert output.output.count('Listening on') == 1
	output = os.exec_or_panic(['./temp', 'optimals', '-g', '-cl', '2,3', 'tempfolders/tempfolder_plot/bcw.opts'])
	assert output.output.count('Listening on') == 1
	println(vhammll2.r_b('Done with test_plot_multi_roc'))
}

fn test_plot_roc_multiclass() {
	// generate a settings file from a multi-class dataset (iris: 3 classes)
	iris := os.join_path(@DIR, '..', 'datasets/iris.tab')
	mut output := os.exec_or_panic('./temp explore -ms tempfolders/tempfolder_plot/iris.opts ${iris}'.split(' '))
	assert !output.output.contains('Listening on')
	// display -g with multi-class settings: the 2-class guard skips plot_roc but must not crash
	output = os.exec_or_panic('./temp display -g tempfolders/tempfolder_plot/iris.opts'.split(' '))
	assert output.output.contains('Listening on')
	// optimals -g with multi-class settings: exercises plot_mult_roc with multi-class sens/spec values
	output = os.exec_or_panic('./temp optimals -g tempfolders/tempfolder_plot/iris.opts'.split(' '))
	assert output.output.contains('Listening on')
	println(vhammll2.r_b('Done with test_plot_roc_multiclass'))
}

fn test_plot_rank() {
  developer := os.join_path(@DIR, '..', 'datasets/testdata/developer.tab')
  iris := os.join_path(@DIR, '..', 'datasets/iris.tab')
  anneal := os.join_path(@DIR, '..', 'datasets/anneal.tab')
  bcw := os.join_path(@DIR, '..', 'datasets/bcw350train.txt')
	mut output := os.exec_or_panic('./temp rank -g ${developer}'.split(' '))
	assert output.output.count('Listening on') == 1
	output = os.exec_or_panic('./temp rank -g -b 2,7 ${iris}'.split(' '))
	assert output.output.count('Listening on') == 1
	output = os.exec_or_panic('./temp rank -g ${anneal}'.split(' '))
	assert output.output.count('Listening on') == 1
	output = os.exec_or_panic('./temp rank -g -l 3 ${anneal}'.split(' '))
	assert output.output.count('Listening on') == 1
	// bcw350train.txt attributes are integers 1-10 (discrete) → no continuous traces → no plot
	// output = os.exec_or_panic('./temp rank -g -b 2,7 -l 5 ${bcw}'.split(' '))
	// assert output.output.count('Listening on') == 0
	println(vhammll2.r_b('Done with test_plot_rank'))
}

fn test_plot_switches() {
	// exercises plot_switches: rank with -sw flag on a 2-class dataset
	// leukemia34test: binary + truly continuous attributes
	// → plot_rank fires AND plot_switches fires = 2 total
	leuk := os.join_path(@DIR, '..', 'datasets/leukemia34test.tab')
	bcw := os.join_path(@DIR, '..', 'datasets/bcw350train.txt')
	iris := os.join_path(@DIR, '..', 'datasets/iris.tab')
	mut output := os.exec_or_panic('./temp rank -g -sw -lc 5 ${leuk}'.split(' '))
	assert output.output.count('Listening on') == 2

	// with a bin range and per-trace limit: still 2 plots
	output = os.exec_or_panic('./temp rank -g -sw -b 2,6 -lc 5 ${leuk}'.split(' '))
	assert output.output.count('Listening on') == 2

	// stricter threshold (-swt 1): both plots still appear; threshold reference line at 1
	output = os.exec_or_panic('./temp rank -g -sw -swt 1 -lc 5 ${leuk}'.split(' '))
	assert output.output.count('Listening on') == 2

	// exclude missing values from bin 0: both plots still appear
	output = os.exec_or_panic('./temp rank -g -sw -x  -lc 5 ${leuk}'.split(' '))
	assert output.output.count('Listening on') == 2

	// bcw350train.txt: all attributes are integers 1-10 → treated as discrete → no continuous
	// attributes → both plot_rank and plot_switches return early = 0 plots
	output = os.exec_or_panic('./temp rank -g -sw ${bcw}'.split(' '))
	assert output.output.count('Listening on') == 0

	// -sw without -g: no plots produced at all
	output = os.exec_or_panic('./temp rank -sw ${leuk}'.split(' '))
	assert output.output.count('Listening on') == 0

	// multi-class (iris, 3 classes): plot_switches guard skips; only plot_rank fires = 1
	output = os.exec_or_panic('./temp rank -g -sw ${iris}'.split(' '))
	assert output.output.count('Listening on') == 1
	println(vhammll2.r_b('Done with test_plot_switches'))
}

fn test_plot_hits() {
	// multi-class datasets: original layout (x = bin, y = hits, fill tozeroy)
	dev := os.join_path(@DIR, '..', 'datasets/testdata/developer.tab')
	leuk := os.join_path(@DIR, '..', 'datasets/leukemia34test.tab')
	anneal := os.join_path(@DIR, '..', 'datasets/anneal.tab')
	iris := os.join_path(@DIR, '..', 'datasets/iris.tab')
	mut output := os.exec_or_panic('./temp rank -of -lc 1 -b 2,2 ${dev}'.split(' '))
	assert output.output.count('Listening on') == 1
	output = os.exec_or_panic('./temp rank -of -b 2,3 -lc 1 ${iris}'.split(' '))
	assert output.output.count('Listening on') == 2
	output = os.exec_or_panic('./temp rank -of -lc 1 -b 3,6 ${anneal}'.split(' '))
	assert output.output.count('Listening on') == 4
	// binary dataset: butterfly layout (x = ±hits, y = bin, fill tozerox)
	output = os.exec_or_panic('./temp rank -of -lc 1 -b 4,5 ${leuk}'.split(' '))
	assert output.output.count('Listening on') == 2
	// weighted butterfly: normalised to percentages, symmetric x range [-100, 100]
	output = os.exec_or_panic('./temp rank -of -wr -lc 1 -b 4,5 ${leuk}'.split(' '))
	assert output.output.count('Listening on') == 2
	println(vhammll2.r_b('Done with test_plot_hits'))
}

fn test_plot_explore_cross() {
	// for a multi-class dataset, we only get a plot of balanced accuracy by number of attributes used
	// (ROC curves only apply to 2-class datasets)
	leuk := os.join_path(@DIR, '..', 'datasets/leukemia34test.tab')
	breast := os.join_path(@DIR, '..', 'datasets/breast-cancer-wisconsin-disc.tab')
	iris := os.join_path(@DIR, '..', 'datasets/iris.tab')
	mut output := os.exec_or_panic('./temp explore -e -g -a 1,3 -b 2,4 ${iris}'.split(' '))
	// dump(output.output)
	assert output.output.count('Listening on') == 3
	// for binary datasets with continuous variables, get 3 plots
	output = os.exec_or_panic('./temp explore -e -g -a 2 -b 5,6  ${leuk}'.split(' '))
	assert output.output.count('Listening on') == 3
	// for binary datasets with no continuous variables, only get 2 plots
	output = os.exec_or_panic('./temp explore -e -g -a 2,3 ${breast}'.split(' '))
	assert output.output.count('Listening on') == 2
	println(vhammll2.r_b('Done with test_plot_explore_cross'))
}
//
fn test_plot_optimals_roc() {
	// exercises plot_mult_roc via the optimals command;
	// reuses the bcw.opts settings file generated in test_plot_roc
	output := os.exec_or_panic('./temp optimals -g tempfolders/tempfolder_plot/bcw.opts'.split(' '))
	assert output.output.count('Listening on') == 1
	println(vhammll2.r_b('Done with test_plot_optimals_roc'))
}
//
fn test_plot_auc_combinations() {
	// exercises plot_auc_combinations via optimals with -cl (combination limits) flag;
	// reuses the bcw.opts settings file generated in test_plot_roc
	output := os.exec_or_panic('./temp optimals -g -cl 2,4 tempfolders/tempfolder_plot/bcw.opts'.split(' '))
	assert output.output.count('Listening on') == 1
	println(vhammll2.r_b('Done with test_plot_auc_combinations'))
}
