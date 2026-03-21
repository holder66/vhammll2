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
