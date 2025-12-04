#!/bin/bash

# Complete script to fix species names in domain visualizations
# Run this from ~/PGB/MYOD1_project

echo "========================================================================"
echo "Setting up species name mapping and running domain visualizations"
echo "========================================================================"
echo ""

# Step 1: Create phylogeny directory
echo "Step 1: Creating directory structure..."
mkdir -p 04_phylogeny
echo "  ✓ Created 04_phylogeny/"

# Step 2: Create species mapping from BLAST results
echo ""
echo "Step 2: Extracting species names from BLAST results..."

# Try to find BLAST results file
BLAST_FILE=""
if [ -f "MYOD1_blast_unique_species_with_header.csv" ]; then
    BLAST_FILE="MYOD1_blast_unique_species_with_header.csv"
elif [ -f "$HOME/PGB/project/blast/MYOD1_blast_unique_species_with_header.csv" ]; then
    BLAST_FILE="$HOME/PGB/project/blast/MYOD1_blast_unique_species_with_header.csv"
elif [ -f "MYOD1_blast_unique_species.csv" ]; then
    BLAST_FILE="MYOD1_blast_unique_species.csv"
elif [ -f "$HOME/PGB/project/blast/MYOD1_blast_unique_species.csv" ]; then
    BLAST_FILE="$HOME/PGB/project/blast/MYOD1_blast_unique_species.csv"
fi

if [ -z "$BLAST_FILE" ]; then
    echo "  ⚠ Warning: Could not find BLAST results file"
    echo "  Please make sure one of these files exists:"
    echo "    - MYOD1_blast_unique_species_with_header.csv"
    echo "    - ~/PGB/project/blast/MYOD1_blast_unique_species_with_header.csv"
    echo ""
    echo "  The script will still run but may use accession numbers instead of species names"
else
    echo "  Found BLAST results: $BLAST_FILE"
    
    # Extract accession-to-species mapping
    awk -F',' '
    {
        # Skip header if present
        if (NR == 1 && $0 ~ /Accession/) next
        
        # Extract accession (column 2) and species from title (column 3)
        if (NF >= 3) {
            accession = $2
            gsub(/"/, "", accession)  # Remove quotes
            gsub(/\.[0-9]+$/, "", accession)  # Remove version number
            
            title = $3
            # Extract species name from [Species name] in title
            if (match(title, /\[([^\]]+)\]/, arr)) {
                species = arr[1]
                print accession "\t" species
            }
        }
    }' "$BLAST_FILE" | sort -u > 04_phylogeny/accession_to_species.txt
    
    num_species=$(wc -l < 04_phylogeny/accession_to_species.txt)
    echo "  ✓ Extracted $num_species species mappings"
    echo "  ✓ Saved to: 04_phylogeny/accession_to_species.txt"
    
    # Show sample of mappings
    echo ""
    echo "  Sample mappings (first 10):"
    head -10 04_phylogeny/accession_to_species.txt | sed 's/^/    /'
fi

# Step 3: Run the corrected visualization script
echo ""
echo "Step 3: Running domain visualization with species names..."
echo ""

python3 ~/visualize_domains_with_species.py

echo ""
echo "========================================================================"
echo "Done! Check 05_domains/visualizations/ for your plots with species names"
echo "========================================================================"
