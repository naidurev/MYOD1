#!/bin/bash

echo "========================================"
echo "Phase 2A: Full BLAST Search"
echo "========================================"
echo ""

cd ~/PGB/MYOD1_project

# Run full BLAST with 5000 targets
echo "Running comprehensive BLAST search..."
echo "Start time: $(date)"
echo "This will take 10-30 minutes..."
echo ""

blastp \
    -query 01_sequences/query/MYOD1_human.fasta \
    -db refseq_protein \
    -remote \
    -evalue 1e-5 \
    -max_target_seqs 5000 \
    -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qcovs staxids sscinames sblastnames sskingdoms stitle" \
    -out 02_blast_results/MYOD1_homologs_raw.tsv

if [ $? -eq 0 ] && [ -s 02_blast_results/MYOD1_homologs_raw.tsv ]; then
    echo ""
    echo "✓ BLAST completed successfully!"
    echo "End time: $(date)"
    echo ""
    
    # Quick statistics
    TOTAL_HITS=$(wc -l < 02_blast_results/MYOD1_homologs_raw.tsv)
    echo "Total hits found: $TOTAL_HITS"
    echo ""
    
    # Add header
    echo "Adding header to results..."
    cat > 02_blast_results/MYOD1_homologs_annotated.tsv << 'HEADER'
query_id	subject_id	percent_identity	alignment_length	mismatches	gap_opens	query_start	query_end	subject_start	subject_end	evalue	bitscore	query_coverage	tax_id	species_name	blast_name	kingdom	description
HEADER
    
    cat 02_blast_results/MYOD1_homologs_raw.tsv >> 02_blast_results/MYOD1_homologs_annotated.tsv
    
    echo "✓ Annotated file created"
    echo ""
    
    # Filter high-quality hits (coverage ≥30%, identity ≥25%)
    echo "Filtering high-quality hits..."
    awk -F'\t' 'NR==1 || ($13 >= 30 && $3 >= 25)' 02_blast_results/MYOD1_homologs_annotated.tsv > 02_blast_results/MYOD1_homologs_filtered.tsv
    
    FILTERED=$(( $(wc -l < 02_blast_results/MYOD1_homologs_filtered.tsv) - 1 ))
    echo "Filtered hits: $FILTERED"
    echo ""
    
    # Get unique species (best hit per species)
    echo "Selecting best hit per species..."
    tail -n +2 02_blast_results/MYOD1_homologs_filtered.tsv | \
        sort -t$'\t' -k15,15 -k12,12rn | \
        awk -F'\t' '!seen[$15]++' > 02_blast_results/MYOD1_homologs_unique_species.tsv
    
    UNIQUE=$(wc -l < 02_blast_results/MYOD1_homologs_unique_species.tsv)
    echo "Unique species: $UNIQUE"
    echo ""
    
    # Top 10 hits
    echo "Top 10 hits:"
    echo "Species	Identity%	BitScore"
    sort -k12 -rn 02_blast_results/MYOD1_homologs_raw.tsv | head -n 10 | cut -f15,3,12
    echo ""
    
    # Identity distribution
    echo "Identity distribution:"
    echo "  >90%: $(awk -F'\t' '$3 > 90' 02_blast_results/MYOD1_homologs_filtered.tsv | wc -l)"
    echo "  70-90%: $(awk -F'\t' '$3 >= 70 && $3 <= 90' 02_blast_results/MYOD1_homologs_filtered.tsv | wc -l)"
    echo "  50-70%: $(awk -F'\t' '$3 >= 50 && $3 < 70' 02_blast_results/MYOD1_homologs_filtered.tsv | wc -l)"
    echo "  25-50%: $(awk -F'\t' '$3 >= 25 && $3 < 50' 02_blast_results/MYOD1_homologs_filtered.tsv | wc -l)"
    echo ""
    
    # Get accession list for sequence download
    echo "Creating accession list for top 100 hits..."
    cut -f2 02_blast_results/MYOD1_homologs_unique_species.tsv | head -n 100 > 02_blast_results/top100_accessions.txt
    echo "✓ Accession list created"
    echo ""
    
    echo "========================================"
    echo "Phase 2A Complete!"
    echo "========================================"
    echo ""
    echo "Files created:"
    echo "  - MYOD1_homologs_raw.tsv (all hits)"
    echo "  - MYOD1_homologs_filtered.tsv (quality filtered)"
    echo "  - MYOD1_homologs_unique_species.tsv (best per species)"
    echo "  - top100_accessions.txt (for sequence retrieval)"
    echo ""
    
else
    echo "✗ BLAST failed"
    exit 1
fi
