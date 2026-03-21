module visual

import vhammll2

fn testsuite_begin() ! {
}

fn testsuite_end() ! {
}

fn test_show_attributes_in_make_classifier() {
	vhammll2.make_classifier(vhammll2.opts('-s -ea datasets/testdata/developer.tab'))
}

fn test_show_attributes_with_switches() {
	// 2-class dataset with -sw: exercises the show_switches == true branch of
	// show_trained_attributes, adding a Switches column to the output
	vhammll2.make_classifier(vhammll2.opts('-sw -s -ea datasets/leukemia38train.tab'))
	// multi-class dataset with -sw: class_counts.len > 2 so show_switches == false;
	// exercises the guard condition that keeps the column hidden for multi-class
	vhammll2.make_classifier(vhammll2.opts('-sw -s -ea datasets/iris.tab'))
}
