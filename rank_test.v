module vhammll2

fn test_sum_along_row_unweighted() {
	assert sum_along_row_unweighted([]int{}) == 0
	assert sum_along_row_unweighted([0]) == 0
	assert sum_along_row_unweighted([2, 3, 4]) == 4
	assert sum_along_row_unweighted([-2, 3, -4]) == 14
	assert sum_along_row_unweighted([0, 0, 8]) == 16
}

fn test_rank_attribute_sorting() {
	mut result := rank_attributes(get_opts('datasets/testdata/developer.tab'))
	mut atts := []string{}
	for att in result.array_of_ranked_attributes {
		atts << att.attribute_name
	}
	atts = []
	result = rank_attributes(get_opts('-b 3,3 datasets/testdata/developer.tab'))
	for att in result.array_of_ranked_attributes {
		atts << att.attribute_name
	}
	atts = []
	result = rank_attributes(get_opts('-b 4,9 datasets/testdata/developer.tab'))
	for att in result.array_of_ranked_attributes {
		atts << att.attribute_name
	}
	result = rank_attributes(get_opts('-b 4,9 datasets/testdata/developer.tab'))
	atts = []
	for att in result.array_of_ranked_attributes {
		atts << att.attribute_name
	}
	atts = []
	result = rank_attributes(get_opts('-b 3,3 datasets/testdata/developer.tab'))
	for att in result.array_of_ranked_attributes {
		atts << att.attribute_name
	}
	atts = []
	result = rank_attributes(get_opts('-b 4,9 datasets/testdata/developer.tab'))
	for att in result.array_of_ranked_attributes {
		atts << att.attribute_name
	}
}

fn test_pairs() {
	assert pairs(0) == []
	assert pairs(1) == []
	assert pairs(2) == [[0, 1]]
	assert pairs(3) == [[0, 1], [0, 2], [1, 2]]
	assert pairs(4) == [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]]
}

fn test_abs_diff() {
	assert abs_diff(0, 0) == 0
	assert abs_diff(0, 4) == 4
	assert abs_diff(3, -9) == 12
	assert abs_diff(-2, -8) == 6
	assert abs_diff(-0, 5) == 5
}
