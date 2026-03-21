module visual

import os

const main_text = '// temp.v
module main
import vhammll2

fn main() {
	vhammll2.cli()!
}'

fn testsuite_begin() ? {
	os.execute('open -a "Firefox" --new --args -setDefaultBrowser')
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
	os.execute('open -a "Safari" --new --args -setDefaultBrowser')
}

fn test_plot_roc() {
	// generate a multiple classifier settings file from a 2-class dataset
	mut output := os.execute_or_panic('./temp explore -ms tempfolders/tempfolder_plot/bcw.opts -t vhammll2/datasets/bcw174test vhammll2/datasets/bcw350train')
	assert !output.output.contains('Listening on')
	// display the ROC curve from the settings file (exercises plot_roc)
	output = os.execute_or_panic('./temp display -g tempfolders/tempfolder_plot/bcw.opts')
	assert output.output.contains('Listening on')
}

fn test_plot_rank() {
	// exercises plot_rank with a multiclass dataset
	output := os.execute_or_panic('./temp rank -g vhammll2/datasets/iris.tab')
	assert output.output.contains('Listening on')
}

fn test_plot_switches() {
	// exercises plot_switches: rank with -sw flag on a 2-class dataset
	output := os.execute_or_panic('./temp rank -g -sw vhammll2/datasets/bcw350train')
	assert output.output.contains('Listening on')
}

fn test_plot_hits() {
	// exercises plot_hits: triggered by -of flag (not -g); limit to 1 continuous
	// attribute and 2 bin counts to keep the number of browser windows small
	output := os.execute_or_panic('./temp rank -of -b 2,3 -lc 1 vhammll2/datasets/iris.tab')
	assert output.output.contains('Listening on')
}

fn test_plot_explore_cross() {
	// exercises plot_explore with cross-validation (no -t flag)
	output := os.execute_or_panic('./temp explore -g -a 1,3 -b 2,4 vhammll2/datasets/iris.tab')
	assert output.output.contains('Listening on')
}

fn test_plot_optimals_roc() {
	// exercises plot_mult_roc via the optimals command;
	// reuses the bcw.opts settings file generated in test_plot_roc
	output := os.execute_or_panic('./temp optimals -g tempfolders/tempfolder_plot/bcw.opts')
	assert output.output.contains('Listening on')
}

fn test_plot_auc_combinations() {
	// exercises plot_auc_combinations via optimals with -cl (combination limits) flag;
	// reuses the bcw.opts settings file generated in test_plot_roc
	output := os.execute_or_panic('./temp optimals -g -cl 2,4 tempfolders/tempfolder_plot/bcw.opts')
	assert output.output.contains('Listening on')
}
