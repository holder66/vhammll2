module vhammll2

import os

fn testsuite_begin() {
	if os.is_dir('tempfolders/tempfolder_save_settings') {
		os.rmdir_all('tempfolders/tempfolder_save_settings') or { panic(err) }
	}
	os.mkdir_all('tempfolders/tempfolder_save_settings')!
}

fn testsuite_end() {
	os.rmdir_all('tempfolders/tempfolder_save_settings') or { panic(err) }
}

fn test_append_make_settings_to_file() ? {
	datafile := 'datasets/leukemia38train.tab'
	settingsfile := 'tempfolders/tempfolder_save_settings/make_leuk.opts'
	// first make call
	mut mo := get_opts('-a 2 -b 3,3 -ms ${settingsfile} ${datafile}')
	mo.command = 'make'
	make_classifier(mo)
	assert os.is_file(settingsfile)
	mut r := read_multiple_opts(settingsfile)!
	assert r.len == 1
	assert r[0].classifier_id == 0
	assert r[0].number_of_attributes == [2]
	// no metrics are produced by make
	assert r[0].correct_counts == []
	assert r[0].t_p == 0
	// second make call with different parameters: classifier_id increments
	mut mo2 := get_opts('-a 4 -b 5,5 -ms ${settingsfile} ${datafile}')
	mo2.command = 'make'
	make_classifier(mo2)
	r = read_multiple_opts(settingsfile)!
	assert r.len == 2
	assert r.map(it.classifier_id) == [0, 1]
	assert r[1].number_of_attributes == [4]
}

fn test_append_cross_validate_settings_to_file() {
	datafile := 'datasets/iris.tab'
	settingsfile := 'tempfolders/tempfolder_save_settings/iris1.opts'
	mut co := get_opts('-a 2 -b 2,2 -ms ${settingsfile} ${datafile}')
	co.command = 'cross'
	cross_validate(co)
	assert os.is_file(settingsfile)
	mut r := read_multiple_opts(settingsfile)!
	// add another classifier
	mut co2 := get_opts('-a 2 -b 3,3 -ms ${settingsfile} ${datafile}')
	co2.command = 'cross'
	cross_validate(co2)
	r = read_multiple_opts(settingsfile)!
	assert r.len == 2
	assert r.map(it.classifier_id) == [0, 1]
}

fn test_append_verify_settings_to_file() {
	datafile := 'datasets/bcw350train'
	testfile := 'datasets/bcw174test'
	settingsfile := 'tempfolders/tempfolder_save_settings/bcw1.opts'
	verify(get_opts('-ms ${settingsfile} -t ${testfile} ${datafile}'))
	assert os.is_file(settingsfile)
	mut r := read_multiple_opts(settingsfile)!
	assert r.len == 1
	verify(get_opts('-a 5 -ms ${settingsfile} -t ${testfile} ${datafile}'))
	r = read_multiple_opts(settingsfile)!
	assert r.len == 2
}

fn test_append_explore_cross_settings_to_file() {
	datafile := 'datasets/iris.tab'
	settingsfile := 'tempfolders/tempfolder_save_settings/iris2.opts'
	explore(opts('-a 1,4 -b 2,7 -ms ${settingsfile} ${datafile}'))
	assert os.is_file(settingsfile)
	mut r := read_multiple_opts(settingsfile)!
	// per-class OvR explore: 3 classes × 7 binary analytics entries = 21
	assert r.len == 21
	// now add another explore
	explore(opts('-a 1,4 -b 2,7 -ms ${settingsfile} ${datafile}'))
	r = read_multiple_opts(settingsfile)!
	assert r.len == 42
}

fn test_append_explore_verify_settings_to_file() {
	datafile := 'datasets/bcw350train'
	testfile := 'datasets/bcw174test'
	settingsfile := 'tempfolders/tempfolder_save_settings/bcw.opts'
	explore(opts('-a 1,4 -ms ${settingsfile} -t ${testfile} ${datafile}'))
	assert os.is_file(settingsfile)
	mut r := read_multiple_opts(settingsfile)!
	assert r.len == 11
	// now add another explore
	explore(opts('-a 2,4 -ms ${settingsfile} -t ${testfile} ${datafile}'))
	r = read_multiple_opts(settingsfile)!
	assert r.len == 21
}
