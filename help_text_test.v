module vhammll2

import os

const output_search_terms = [
	'Description:',
	'Usage:',
	'Options:',
]

const main_text = '// temphelp.v
module main
import vhammll2

fn main() {
	vhammll2.cli()!
}'

fn testsuite_begin() {
	os.chdir('..')!
	mut f := os.create(os.abs_path('') + '/temphelp.v') or { panic(err) }
	f.write_string(main_text)!
	f.close()

	os.exec_or_panic(['v -keepc run temphelp.v'])
	if os.is_dir('tempfolders/tempfolder_help_text') {
		os.rmdir_all('tempfolders/tempfolder_help_text') or { panic(err) }
	}
	os.mkdir_all('tempfolders/tempfolder_help_text') or { panic(err) }
}

fn testsuite_end() {
	if os.exists('temphelp') {
		os.rm('temphelp') or { panic(err) }
	}
	if os.exists('temphelp.v') {
		os.rm('temphelp.v') or { panic(err) }
	}
	os.rmdir_all('tempfolders/tempfolder_help_text') or { panic(err) }
}

fn test_help() {
	flags := ['', '--help', '-h']

	for flag in flags {
		result := os.exec_or_panic(['./temphelp ${flag}'])
		assert result.exit_code == 0
		for term in output_search_terms {
			assert result.output.contains(term)
		}
	}
}

fn test_command_help() {
	commands := ['analyze', 'append', 'cross', 'display', 'examples', 'explore', 'make', 'orange',
		'query', 'rank', 'validate', 'verify']
	flags := ['', '--help', '-h']
	for command in commands {
		for flag in flags {
			result := os.exec_or_panic(['./temphelp ${command} ${flag}'])
			assert result.exit_code == 0
			for term in output_search_terms {
				assert result.output.contains(term)
			}
		}
	}
}
