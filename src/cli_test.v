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

fn testsuite_begin() ? {
	os.chdir('..')!
	mut f := os.create(os.abs_path('') + '/temp.v')!
	f.write_string(main_text)!
	f.close()

	r := os.execute_or_panic('v temp.v')
	if os.is_dir('tempfolders/tempfolder_cli') {
		os.rmdir_all('tempfolders/tempfolder_cli')!
	}
	os.mkdir_all('tempfolders/tempfolder_cli')!
}

// fn testsuite_end() ? {
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
	mut r := os.execute_or_panic('./temp')
	assert r.output.contains('help, -h, --help to display this usage information.')
	assert os.execute_or_panic('./temp -h') == r
	assert os.execute_or_panic('./temp --help') == r
}

fn test_cli_append() {
	// this test is incomplete, because append.v needs fixing to deal with prevalence balancing
	mut r := os.execute_or_panic('./temp append')
	assert r.output.contains('"append" extends a classifier by adding one or more labeled cases.')
	assert os.execute_or_panic('./temp append -h') == r
	assert os.execute_or_panic('./temp append --help') == r
	// make a classifier
	datafile := 'vhammll2/datasets/testdata/test.tab'
	cl_file := 'tempfolders/tempfolder_cli/test.cl'
	val_file := 'vhammll2/datasets/testdata/test_validate.tab'
	inst_file := 'tempfolders/tempfolder_cli/instances'
	clr := os.execute_or_panic('./temp make -o ${cl_file} ${datafile}')
	assert clr.output.contains('make    vhammll2/datasets/testdata/test.tab                   6')
	assert os.is_file(cl_file)
	rv := os.execute_or_panic('./temp validate -o ${inst_file} -t ${val_file} ${datafile}')
	assert rv.output.contains('Validation of "vhammll2/datasets/testdata/test_validate.tab" using a classifier from "vhammll2/datasets/testdata/test.tab"')
	assert os.is_file(inst_file)

	dump(os.execute_or_panic('./temp append -k ${cl_file} ${inst_file}'))
	// dump(os.execute_or_panic('./temp append -k ${cl_file} v'))
}

fn test_cli_cross() {}

fn test_cli_display() {}

fn test_cli_examples() {}

// fn test_cli_explore() {
// 	opts := CliOptions{}
// 	mut r := os.execute_or_panic('./temp explore --help')
// 	assert r.output.contains('-bpt --balance-prevalences-threshold: ratio threshold below which class')
// 	r = os.execute_or_panic('./temp explore vhammll2/datasets/iris.tab')
// 	dump(r.output)
// 	assert r.output.contains('Explore leave-one-out cross-validation using classifiers from "vhammll2/datasets/iris.tab"')
// 	r = os.execute_or_panic('./temp explore -a 2 -b 6  vhammll2/datasets/leukemia34test.tab')
// 	dump(r.output)
// 	assert r.output.contains('Explore leave-one-out cross-validation using classifiers from "vhammll2/datasets/leukemia34test.tab"')
// 	r = os.execute_or_panic('./temp explore  -o tempfolders/tempfolder_cli/breast.exr vhammll2/datasets/breast-cancer-wisconsin-disc.tab')
// 	dump(r.output)
// 	assert r.output.contains('Explore leave-one-out cross-validation using classifiers from "vhammll2/datasets/breast-cancer-wisconsin-disc.tab"')
// 	r = os.execute_or_panic('./temp cross  -a 13 vhammll2/datasets/UCI/zoo.arff')
// 	dump(r.output)
// 	assert r.output.contains('Cross-validation of "vhammll2/datasets/UCI/zoo.arff"')
// }

fn test_cli_make() {}

fn test_cli_optimals() {}

fn test_cli_orange() {}

fn test_cli_partition() {}

fn test_cli_query() {}

fn test_cli_rank() {}

fn test_cli_validate() {}

// fn test_cli_verify() {
// 	mut r := os.execute_or_panic('./temp verify -h')
// 	r = os.execute_or_panic('./temp verify  -t vhammll2/datasets/bcw174test vhammll2/datasets/bcw350train')
// 	// save a classifier to a file
// 	r = os.execute_or_panic('./temp make -a 33 -b 2,16 -o tempfolders/tempfolder_cli/soybean.cl vhammll2/datasets/soybean-large-train.tab')
// 	r = os.execute_or_panic('./temp verify  -s -k tempfolders/tempfolder_cli/soybean.cl -t vhammll2/datasets/soybean-large-test.tab')
// }
