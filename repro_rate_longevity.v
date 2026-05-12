module vhammll2

import vsl.plot
import math

struct ReproPoint {
	species  string
	lifespan f64
	repro    f64
}

fn load_repro_data() []ReproPoint {
	return [
		ReproPoint{'Small rodent', 3, 20.0},
		ReproPoint{'Songbird', 5, 10.0},
		ReproPoint{'Salmon', 4, 200.0},
		ReproPoint{'Human', 80, 0.5},
		ReproPoint{'Arctica islandica', 300, 0.02},
		ReproPoint{'Bristlecone pine', 4000, 0.005},
		ReproPoint{'Naked mole-rat colony', 3, 24.0},
	]
}

// Fit y = k * x^alpha by linear regression in log-log space
fn fit_power_law(xs []f64, ys []f64) (f64, f64) {
	mut lx := []f64{}
	mut ly := []f64{}
	for i in 0 .. xs.len {
		if xs[i] > 0 && ys[i] > 0 {
			lx << math.log10(xs[i])
			ly << math.log10(ys[i])
		}
	}
	assert lx.len == ly.len && lx.len > 1

	// Simple least-squares fit to ly = a * lx + b
	n := f64(lx.len)
	mut sum_x := 0.0
	mut sum_y := 0.0
	mut sum_xx := 0.0
	mut sum_xy := 0.0
	for i in 0 .. lx.len {
		sx := lx[i]
		sy := ly[i]
		sum_x += sx
		sum_y += sy
		sum_xx += sx * sx
		sum_xy += sx * sy
	}
	denom := n * sum_xx - sum_x * sum_x
	a := (n * sum_xy - sum_x * sum_y) / denom
	b := (sum_y * sum_xx - sum_x * sum_xy) / denom

	return a, math.pow(10.0, b)
}

pub fn plot_repro_rate_longevity() {
	data := load_repro_data()

	// Extract x, y
	mut xs := []f64{}
	mut ys := []f64{}
	mut labels := []string{}
	for p in data {
		if p.lifespan > 0 && p.repro > 0 {
			xs << f64(p.lifespan)
			ys << f64(p.repro)
			labels << p.species
		}
	}

	// Fit power law
	alpha, k := fit_power_law(xs, ys)
	println('Fitted power law: repro ≈ ${k:.3g} * lifespan^${alpha:.3g}')

	// Prepare log10 coordinates for plotting
	mut logx := []f64{}
	mut logy := []f64{}
	for i in 0 .. xs.len {
		logx << math.log10(xs[i])
		logy << math.log10(ys[i])
	}

	mut plt := plot.Plot.new()
	plt.scatter(
		x:    logx
		y:    logy
		mode: 'markers'
		name: 'Species'
	)

	// Add text labels as separate scatter so we can offset them slightly
	mut label_x := []f64{}
	mut label_y := []f64{}
	for i in 0 .. logx.len {
		label_x << logx[i] + 0.02
		label_y << logy[i] + 0.02
	}
	plt.scatter(
		x:    label_x
		y:    label_y
		mode: 'text'
		text: labels
		name: ''
	)

	// Add power-law fit line in log-log space
	mut fit_x := []f64{}
	mut fit_y := []f64{}
	mut min_x := xs[0]
	mut max_x := xs[0]
	for x in xs {
		if x < min_x {
			min_x = x
		}
		if x > max_x {
			max_x = x
		}
	}
	steps := 100
	min_log := math.log10(min_x)
	max_log := math.log10(max_x)
	for i in 0 .. steps {
		t := f64(i) / f64(steps)
		lx := min_log + t * (max_log - min_log)
		x := math.pow(10.0, lx)
		y := k * math.pow(x, alpha)
		fit_x << math.log10(x)
		fit_y << math.log10(y)
	}
	plt.scatter(
		x:    fit_x
		y:    fit_y
		mode: 'lines'
		name: ''
	)

	plt.layout(
		title: 'Lifespan vs reproductive rate (log-log with power-law fit)'
		xaxis: plot.Axis{
			title: plot.AxisTitle{
				text: 'log10(lifespan)'
			}
		}
		yaxis: plot.Axis{
			title: plot.AxisTitle{
				text: 'log10(reproductive rate)'
			}
		}
	)
	plt.show() or { panic(err) }
}
