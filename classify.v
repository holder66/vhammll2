module vhammll2

// to simplify the documentation, we will change "instance to be classified"
// to "case", and leave "instance" as referring to the classifier data.

// classify_case takes a trained classifier and a case to be
// classified; it returns the inferred class for the case and the
// counts of nearest neighbors to all the classes.
// The classification algorithm calculates Hamming distances between
// the case to be classified and all the instances in the trained
// classifier; for the minimum hamming distance, the class with the
// most neighbors at that distance is the inferred class. In case of
// ties, the algorithm moves on to the next minimum hamming distance.
fn classify_case(cl Classifier, case []u8, opts Options) ClassifyResult {
	mut result := ClassifyResult{
		classes: cl.classes
	}
	// to classify, get Hamming distances between the case to be classified and
	// all the instances in the classifier; return the class for the instance
	// giving the lowest Hamming distance.
	mut hamming_dist_array := []int{cap: cl.instances.len}
	mut hamming_dist := 0
	// get the hamming distance for each of the corresponding byte_values
	// in each classifier instance and the case to be classified
	for instance in cl.instances {
		hamming_dist = 0
		for i, byte_value in case {
			hamming_dist += get_hamming_distance(byte_value, instance[i])
		}
		hamming_dist_array << hamming_dist
	}

	// get unique values in hamming_dist_array; these are the radii
	// of the nearest-neighbor "spheres"
	mut radii := element_counts(hamming_dist_array).keys()
	radii.sort()

	mut radius_row := []int{len: cl.class_counts.len}
	for sphere_index, radius in radii {
		// populate the counts by class for this radius
		for class_index, class in cl.classes {
			weight := 1
			for instance, distance in hamming_dist_array {
				if distance <= radius && class == cl.class_values[instance] {
					radius_row[class_index] += weight
				}
			}
		}
		if !single_array_maximum(radius_row) {
			continue
		}
		result.inferred_class = cl.classes[idx_max(radius_row)]
		result.nearest_neighbors_by_class = radius_row
		result.hamming_distance = radii[sphere_index]
		result.sphere_index = sphere_index
		break
	}
	return result
}

// get_hamming_distance returns hamming distance between left and right,
// when both left and right are values which can be represented by a single
// bit if a bitstring were created
fn get_hamming_distance[T](left T, right T) int {
	if left == right {
		return 0
	}
	if left == u8(0) || right == u8(0) {
		return 1
	}
	return 2
}

// single_array_maximum returns true if a has only one maximum
fn single_array_maximum[T](a []T) bool {
	if a.len == 0 {
		panic('single_array_maximum was called on an empty array')
	}
	if a.len == 1 {
		return true
	}
	mut a_clone := a.clone()
	a_clone.sort(a > b)
	if a_clone[0] != a_clone[1] {
		return true
	}
	return false
}
