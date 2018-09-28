#!/bin/gawk -f
# Copyright UNLICENSE https://github.com/johslarsen/binop/blob/master/bin/uniq_cols.gawk
BEGIN{if (length(npad) == 0) npad=2}
NF >= 1 {
	printf "%s", $1
	count = 1
	for (i = 2; i <= NF; i++) {
		p = i-1
		if ($p != $i) {
		    if (count <= 1) printf "%s", OFS $i
			else printf "*%0*x%s", npad, count, OFS $i
			count = 0
		}
		count += 1
	}
	if (count > 1) printf "*%0*x", npad, count
	printf "\n"
}
