module vhammll2

fn test_classify_case() {
	mut opts := Options{
		datafile_path: 'datasets/testdata/developer.tab'
		bins: [2, 12]
		command: 'classify'
		number_of_attributes: [6]
	}
	mut cl := make_classifier(opts)
	assert cl.pre_balance_prevalences_class_counts == {
		'm': 8
		'f': 3
		'X': 2
	}
	assert cl.class_counts == {
		'm': 16
		'f': 15
		'X': 16
	}
	assert classify_case(cl, cl.instances[0]).inferred_class == 'm'
	assert classify_case(cl, cl.instances[0]).nearest_neighbors_by_class == [
		2,
		0,
		0,
	]
}

fn test_get_hamming_distance() {
	assert get_hamming_distance(0, 0) == 0
	assert get_hamming_distance(0, 1) == 1
	assert get_hamming_distance(2, 0) == 1
	assert get_hamming_distance(1, 2) == 2
	assert get_hamming_distance(16, 128) == 2
}
