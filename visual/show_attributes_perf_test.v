module visual

import vhammll2

fn testsuite_begin() ! {
}

fn testsuite_end() ! {
}

fn test_show_attributes_in_verify_perf() {
	vhammll2.verify(vhammll2.opts('-s -ea -t datasets/mobile_price_classification_test.csv datasets/mobile_price_classification_train.csv'))
}
