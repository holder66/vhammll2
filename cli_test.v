// cli_test.v tests that the functionality provided by the cli() function works
// a similar file, performance_test.v, tests that the various commands produce
// consistent results with the datasets in the datasets folder
module vhammll2

import os

const main_text = '// temp.v
module main
import vhammll2

fn main() {
	vhammll2.cli()!
}'

fn testsuite_begin() {
  if os.is_dir('tempfolders/tempfolder_cli') {
		os.rmdir_all('tempfolders/tempfolder_cli') or { panic(err) }
	}
	os.mkdir_all('tempfolders/tempfolder_cli') or { panic(err) }
	os.chdir('tempfolders/tempfolder_cli') or { panic(err) }
	mut f := os.create(os.abs_path('') + '/temp.v')!
	f.write_string(main_text)!
	f.close()
	r := os.exec_or_panic(['v', 'temp.v'])
	os.chdir('../..') or { panic(err) }
	dump(os.abs_path(''))
}

// fn testsuite_end() {
// 	if os.exists('temp') {
// 		os.rm('temp')!
// 	}
// 	if os.exists('temp.v') {
// 		os.rm('temp.v')!
// 	}
// 	os.rmdir_all('tempfolders/tempfolder_cli')!
// }

// fn test_parameter_to_cli() {
// cli(astr: 'rank')!
// cli(args: ['rank'])!
// }
fn test_help() {
	mut r := os.exec_or_panic(['tempfolders/tempfolder_cli/./temp'])
	assert r.output.contains('help, -h, --help to display this usage information.')
	assert os.exec_or_panic(['tempfolders/tempfolder_cli/./temp', '-h']) == r
	assert os.exec_or_panic(['tempfolders/tempfolder_cli/./temp', '--help']) == r
}

fn test_cli_append() {
	// this test is incomplete, because append.v needs fixing to deal with prevalence balancing
	mut r := os.exec_or_panic(['tempfolders/tempfolder_cli/./temp', 'append'])
	assert r.output.contains('"append" extends a classifier by adding one or more labeled cases.')
	assert os.exec_or_panic(['tempfolders/tempfolder_cli/./temp', 'append', '-h']) == r
	assert os.exec_or_panic(['tempfolders/tempfolder_cli/./temp', 'append', '--help']) == r
	// make a classifier
	datafile := 'datasets/testdata/test.tab'
	cl_file := 'tempfolders/tempfolder_cli/test.cl'
	val_file := 'datasets/testdata/test_validate.tab'
	inst_file := 'tempfolders/tempfolder_cli/instances'
	clr := os.exec_or_panic(['tempfolders/tempfolder_cli/./temp', 'make', '-o', '${cl_file}', '${datafile}'])
	assert clr.output.contains('Classifier from "datasets/testdata/test.tab"')
	assert os.is_file(cl_file)
	rv := os.exec_or_panic(['tempfolders/tempfolder_cli/./temp', 'validate', '-o', '${inst_file}', '-t', '${val_file}', '${datafile}'])
	assert rv.output.contains('Validation of "datasets/testdata/test_validate.tab" using a classifier from "datasets/testdata/test.tab"')
	assert os.is_file(inst_file)

	ap := os.exec_or_panic(['tempfolders/tempfolder_cli/./temp', 'append', '-k', '${cl_file}', '${inst_file}']))
	assert ap.output.contains('append  datasets/testdata/test_validate.tab          ')
}

fn test_cli_cross() {}

fn test_cli_display() {}

fn test_cli_examples() {}

fn test_cli_explore() {
	opts := CliOptions{}
	mut r := os.exec_or_panic('tempfolders/tempfolder_cli/./temp explore --help'.split(' '))
	assert r.output.contains('-bpt --balance-prevalences-threshold: ratio threshold below which class')
	r = os.exec_or_panic('tempfolders/tempfolder_cli/./temp explore datasets/iris.tab'.split(' '))
	dump(r.output)
	assert r.output.contains('Explore leave-one-out cross-validation using classifiers from "datasets/iris.tab"')
	r = os.exec_or_panic('tempfolders/tempfolder_cli/./temp explore -a 2 -b 6  datasets/leukemia34test.tab'.split(' '))
	dump(r.output)
	assert r.output.contains('Explore leave-one-out cross-validation using classifiers from "datasets/leukemia34test.tab"')
	r = os.exec_or_panic('tempfolders/tempfolder_cli/./temp explore  -o tempfolders/tempfolder_cli/breast.exr datasets/breast-cancer-wisconsin-disc.tab'.split(' '))
	dump(r.output)
	assert r.output.contains('Explore leave-one-out cross-validation using classifiers from "datasets/breast-cancer-wisconsin-disc.tab"')
	r = os.exec_or_panic('tempfolders/tempfolder_cli/./temp cross  -a 13 datasets/UCI/zoo.arff'.split(' '))
	dump(r.output)
	assert r.output.contains('Cross-validation of "datasets/UCI/zoo.arff"')
}

fn test_cli_make() {}

fn test_cli_optimals() {}

fn test_cli_orange() {}

fn test_cli_partition() {}

fn test_cli_query() {}

fn test_cli_rank() {}

fn test_cli_validate() {}

fn test_cli_verify() {
	mut r := os.exec_or_panic(['./temp verify -h'])
	r = os.exec_or_panic(['./temp verify  -t datasets/bcw174test.txt datasets/bcw350train.txt'])
	// save a classifier to a file
	r = os.exec_or_panic(['./temp make -a 33 -b 2,16 -o tempfolders/tempfolder_cli/soybean.cl datasets/soybean-large-train.tab'])
	r = os.exec_or_panic(['./temp verify  -s -k tempfolders/tempfolder_cli/soybean.cl -t datasets/soybean-large-test.tab'])
}
