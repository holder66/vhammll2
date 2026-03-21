module vhammll2

// Tests for count_switches and the -sw / -swt behaviour in rank_attributes.

// ---------------------------------------------------------------------------
// count_switches — pure unit tests using hand-constructed hits arrays
// ---------------------------------------------------------------------------

fn test_count_switches_non_two_class() {
	// Returns -1 for anything other than exactly 2 classes
	assert count_switches([], [], false) == -1
	assert count_switches([[1, 2, 3]], [10], false) == -1
	assert count_switches([[1, 2], [3, 4], [5, 6]], [10, 10, 10], false) == -1
}

fn test_count_switches_all_empty_or_tied() {
	// All bins empty → 0
	assert count_switches([[0, 0, 0], [0, 0, 0]], [0, 0], false) == 0
	// All bins tied → 0
	assert count_switches([[0, 5, 5], [0, 5, 5]], [10, 10], false) == 0
}

fn test_count_switches_bin0_skipped() {
	// Bin 0 holds missing values and must never influence the count.
	// Class 0 "wins" bin 0 massively but that should be ignored;
	// only bin 1 is non-empty and class 1 wins there → 0 switches.
	assert count_switches([[100, 2], [0, 8]], [102, 8], false) == 0
}

fn test_count_switches_zero_switches() {
	// One class wins every non-empty bin → 0 switches
	// hits[0]=[0,10,8,5], hits[1]=[0,2,3,4] — class 0 wins bins 1-3
	assert count_switches([[0, 10, 8, 5], [0, 2, 3, 4]], [23, 9], false) == 0
}

fn test_count_switches_one_switch() {
	// Clean monotone threshold: class 0 wins low bins, class 1 wins high bins
	// hits[0]=[0,10,8,2,1], hits[1]=[0,1,2,8,10]
	assert count_switches([[0, 10, 8, 2, 1], [0, 1, 2, 8, 10]], [21, 21], false) == 1
}

fn test_count_switches_two_switches() {
	// U-shaped: class 0 wins bin 1, class 1 wins bin 2, class 0 wins bin 3
	assert count_switches([[0, 10, 2, 10], [0, 1, 8, 1]], [22, 10], false) == 2
}

fn test_count_switches_three_switches() {
	// Fully alternating over 4 bins → 3 switches
	assert count_switches([[0, 8, 1, 8, 1], [0, 1, 8, 1, 8]], [18, 18], false) == 3
}

fn test_count_switches_ties_skipped() {
	// bin 1: class 0 wins; bin 2: tie (skipped); bin 3: class 1 wins → 1 switch
	assert count_switches([[0, 5, 5, 3], [0, 3, 5, 5]], [13, 13], false) == 1
}

fn test_count_switches_empty_bins_skipped() {
	// bin 1: class 0 wins; bins 2 and 3: both zero (skipped); bin 4: class 1 wins → 1 switch
	assert count_switches([[0, 10, 0, 0, 0], [0, 0, 0, 0, 8]], [10, 8], false) == 1
}

fn test_count_switches_weighting() {
	// hits[0]=[0,3,8], hits[1]=[0,10,1], weights=[100,5]
	//
	// Unweighted:
	//   bin 1: 3 vs 10  → class 1 wins
	//   bin 2: 8 vs 1   → class 0 wins  → 1 switch
	//
	// Weighted (cross-multiply by other class's total count):
	//   bin 1: eff0 = 3*5=15,  eff1 = 10*100=1000 → class 1 wins
	//   bin 2: eff0 = 8*5=40,  eff1 =  1*100= 100 → class 1 wins → 0 switches
	assert count_switches([[0, 3, 8], [0, 10, 1]], [100, 5], false) == 1
	assert count_switches([[0, 3, 8], [0, 10, 1]], [100, 5], true) == 0
}
