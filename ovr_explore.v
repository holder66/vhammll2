module vhammll2

// run_ovr_explore performs a per-class parameter sweep for multiclass datasets.
// For each class the dataset is remapped to binary (class vs not_class) and
// balanced once; an independent bins × attributes sweep is then run on that
// binary dataset.  All per-class sweeps run concurrently on separate threads.
// The returned OvrExploreResult carries per_class_parameters so callers can
// use the best per-class settings for subsequent cross_validate / verify calls.
fn run_ovr_explore(ds Dataset, opts Options) OvrExploreResult {
	mut ovr_result := OvrExploreResult{
		Class: ds.Class
		Parameters: opts.Parameters
		LoadOptions: ds.LoadOptions
		DisplaySettings: opts.DisplaySettings
		path: ds.path
		testfile_path: opts.testfile_path
		args: opts.args
	}

	// Prepare binary datasets for all classes before spawning threads.
	// Each binary dataset is a value copy — safe to pass to spawned threads.
	mut binary_datasets := []Dataset{}
	for class in ds.classes {
		mut bin_ds := ds
		bin_ds.classes = [class, 'not_${class}']
		bin_ds.class_values = ds.class_values.map(if it == class {
			it
		} else {
			'not_${class}'
		})
		bin_ds.class_counts = element_counts(bin_ds.class_values)
		if evaluate_class_prevalence_imbalance(bin_ds, opts) {
			bin_ds = balance_prevalences(mut bin_ds, opts.balance_prevalences_threshold)
			bin_ds.class_values = bin_ds.class_values.map(if it == class {
				it
			} else {
				'not_${class}'
			})
			bin_ds.class_counts = element_counts(bin_ds.class_values)
		}
		binary_datasets << bin_ds
	}

	// Spawn one concurrent thread per class.
	mut threads := []thread OvrClassExploreResult{}
	for i, class in ds.classes {
		threads << spawn explore_binary_ds(binary_datasets[i], class, opts)
	}

	// Collect results in class order (wait() blocks until each thread finishes).
	for i, class in ds.classes {
		class_result := threads[i].wait()
		ovr_result.class_explore_results[class] = class_result
		ovr_result.per_class_parameters[class] = best_params_from_explore(class_result)
	}

	if opts.command == 'explore' && (opts.show_flag || opts.expanded_flag) {
		show_ovr_explore_results(ovr_result, opts)
	}
	if opts.graph_flag {
		for class in ds.classes {
			syn := ovr_class_to_explore_result(ovr_result.class_explore_results[class])
			plot_explore(syn, opts)
		}
	}
	if opts.append_settings_flag {
		for class in ds.classes {
			syn := ovr_class_to_explore_result(ovr_result.class_explore_results[class])
			mut av := explore_analytics(syn)
			append_explore_settings_to_file(syn, av, opts)
		}
	}
	if opts.outputfile_path != '' {
		save_json_file[OvrExploreResult](ovr_result, opts.outputfile_path)
	}
	return ovr_result
}

// explore_binary_ds sweeps bins × attributes on a pre-balanced binary Dataset.
// Called in a spawned thread; all inputs are value copies so there is no shared
// mutable state.  Calls run_cross_validate directly (no file reload).
fn explore_binary_ds(bin_ds Dataset, class_label string, opts Options) OvrClassExploreResult {
	mut ex_opts := opts
	total_attrs := bin_ds.useful_continuous_attributes.len + bin_ds.useful_discrete_attributes.len
	mut result := OvrClassExploreResult{
		Class: bin_ds.Class
		Parameters: opts.Parameters
		LoadOptions: bin_ds.LoadOptions
		DisplaySettings: opts.DisplaySettings
		class_label: class_label
		path: bin_ds.path
		pos_neg_classes: [class_label, 'not_${class_label}']
		AttributeRange: get_attribute_range(opts.number_of_attributes, total_attrs)
		args: opts.args
	}
	if bin_ds.useful_continuous_attributes.len == 0 {
		ex_opts.bins = [0]
	}
	result.binning = get_binning(ex_opts.bins)
	binning := result.binning
	mut atts := result.start
	mut array_of_results := []CrossVerifyResult{}
	for atts <= result.end {
		ex_opts.number_of_attributes = [atts]
		mut bin := binning.lower
		for bin <= binning.upper {
			if ex_opts.uniform_bins {
				ex_opts.bins = [bin, bin]
			} else {
				ex_opts.bins = [1, bin]
			}
			mut cv := run_cross_validate(bin_ds, ex_opts)
			cv.bin_values = ex_opts.bins
			cv.attributes_used = atts
			array_of_results << cv
			bin += binning.interval
		}
		atts += result.att_interval
	}
	result.array_of_results = array_of_results
	return result
}

// best_params_from_explore returns the Parameters from the OvrClassExploreResult
// entry with the highest balanced accuracy.
fn best_params_from_explore(class_result OvrClassExploreResult) Parameters {
	if class_result.array_of_results.len == 0 {
		return Parameters{}
	}
	best_idx := idx_max(class_result.array_of_results.map(it.Metrics.balanced_accuracy))
	best := class_result.array_of_results[best_idx]
	mut p := best.Parameters
	p.number_of_attributes = [best.attributes_used]
	return p
}

// ovr_class_to_explore_result builds a synthetic ExploreResult from an
// OvrClassExploreResult so that existing show_explore_* and plot_explore
// functions can be reused without modification.
fn ovr_class_to_explore_result(cr OvrClassExploreResult) ExploreResult {
	return ExploreResult{
		Class: cr.Class
		Parameters: cr.Parameters
		LoadOptions: cr.LoadOptions
		AttributeRange: cr.AttributeRange
		DisplaySettings: cr.DisplaySettings
		path: cr.path
		pos_neg_classes: cr.pos_neg_classes
		array_of_results: cr.array_of_results
		args: cr.args
	}
}

// show_ovr_explore_results displays per-class explore output, reusing the
// existing show_explore_header / show_explore_line / show_explore_trailer
// functions via a synthetic ExploreResult built for each class.
fn show_ovr_explore_results(ovr OvrExploreResult, opts Options) {
	for class in ovr.classes {
		if class !in ovr.class_explore_results {
			continue
		}
		println('\n--- ${class} vs not_${class} ---')
		syn := ovr_class_to_explore_result(ovr.class_explore_results[class])
		show_explore_header(syn, opts.DisplaySettings)
		for r in syn.array_of_results {
			show_explore_line(r, opts.DisplaySettings)
		}
		mut av := explore_analytics(syn)
		show_explore_trailer(syn, av, opts)
	}
}
