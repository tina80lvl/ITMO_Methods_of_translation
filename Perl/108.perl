while (<>) {
	print if /\([^()]*\w+[^()]*\)/;
}