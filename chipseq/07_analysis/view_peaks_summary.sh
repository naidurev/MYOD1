#!/bin/bash
echo "Peak Summary:"
cat 07_analysis/peak_summary.txt
echo ""
echo "Alignment Statistics:"
for f in 05_alignment/*_stats.txt; do
    echo ""
    echo "$(basename $f):"
    head -5 $f
done
