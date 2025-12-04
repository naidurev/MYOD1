#!/usr/bin/env python3

"""
Create final heatmaps with species and protein names
"""

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np
from Bio import AlignIO
from collections import Counter
import os

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.dpi'] = 300
plt.rcParams['savefig.dpi'] = 300

print("="*70)
print("Creating Final Heatmaps with Protein Names")
print("="*70)
print("")

# Load species mapping
species_mapping = {}
if os.path.exists('species_mapping.txt'):
    with open('species_mapping.txt', 'r') as f:
        for line in f:
            if line.strip():
                parts = line.strip().split('\t')
                if len(parts) == 2:
                    species_mapping[parts[0]] = parts[1]
    print(f"✓ Loaded {len(species_mapping)} species mappings")

# Load protein name mapping
protein_mapping = {}
if os.path.exists('protein_name_mapping.txt'):
    with open('protein_name_mapping.txt', 'r') as f:
        next(f)  # Skip header
        for line in f:
            if line.strip():
                parts = line.strip().split('\t')
                if len(parts) >= 2:
                    protein_mapping[parts[0]] = parts[1]
    print(f"✓ Loaded {len(protein_mapping)} protein name mappings")

print("")

def get_full_label(seq_id):
    """Get species + protein name label"""
    # Extract base accession
    if '_bHLH_' in seq_id or '_HLH_' in seq_id or '_Basic_' in seq_id:
        parts = seq_id.split('_')
        accession = parts[0] + '_' + parts[1]
    else:
        accession = seq_id.split()[0]
    
    # Get species name
    species = species_mapping.get(accession, "Unknown")
    
    # Get protein name
    protein = protein_mapping.get(accession, "MRF")
    
    # Format: Species protein (italicized species in actual plot)
    return f"{species} {protein}", species, protein

def create_conservation_heatmap(conservation_file, alignment_file, output_file, title):
    """Create conservation heatmap with species and protein names"""
    
    print(f"Creating: {title}...")
    
    # Load conservation scores
    cons_data = pd.read_csv(conservation_file, sep='\t')
    conservation = cons_data['Conservation_Score'].values
    
    # Load alignment
    alignment = AlignIO.read(alignment_file, 'fasta')
    n_seqs = len(alignment)
    aln_len = alignment.get_alignment_length()
    
    # Display only top 20 sequences
    n_display = min(20, n_seqs)
    
    # Get labels
    labels = []
    for i in range(n_display):
        original_id = alignment[i].id
        full_label, species, protein = get_full_label(original_id)
        
        # Truncate if too long
        if len(full_label) > 45:
            full_label = full_label[:42] + '...'
        
        labels.append(full_label)
    
    # Create matrix
    matrix = np.zeros((n_display, aln_len))
    
    for i in range(n_display):
        for pos in range(aln_len):
            aa = str(alignment[i].seq[pos])
            column = alignment[:, pos]
            non_gap = [a for a in column if a != '-']
            if non_gap and aa != '-':
                consensus = Counter(non_gap).most_common(1)[0][0]
                if aa == consensus:
                    matrix[i, pos] = conservation[pos]
                else:
                    matrix[i, pos] = 0
            else:
                matrix[i, pos] = 0
    
    # Create figure
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(18, 9), 
                                    gridspec_kw={'height_ratios': [1, 4]})
    
    # Top panel: conservation line plot
    positions = np.arange(1, aln_len + 1)
    ax1.fill_between(positions, conservation, alpha=0.6, color='steelblue', label='Conservation')
    ax1.plot(positions, conservation, linewidth=1.5, color='darkblue')
    ax1.axhline(y=0.9, color='red', linestyle='--', alpha=0.5, linewidth=1, label='High conservation (>0.9)')
    ax1.axhline(y=0.7, color='orange', linestyle='--', alpha=0.5, linewidth=1, label='Moderate conservation (>0.7)')
    ax1.set_xlim(0, aln_len)
    ax1.set_ylim(0, 1)
    ax1.set_ylabel('Conservation\nScore', fontsize=11, fontweight='bold')
    ax1.set_title(title, fontsize=15, fontweight='bold', pad=10)
    ax1.legend(loc='upper right', fontsize=9)
    ax1.grid(True, alpha=0.3)
    ax1.set_xticklabels([])
    
    # Bottom panel: heatmap
    im = ax2.imshow(matrix, aspect='auto', cmap='RdYlGn', interpolation='nearest', 
                    vmin=0, vmax=1)
    
    # Set labels - species in italics, protein in regular
    ax2.set_yticks(range(n_display))
    ax2.set_yticklabels(labels, fontsize=9, style='italic')
    ax2.set_ylabel('Species & Protein (top 20)', fontsize=12, fontweight='bold')
    
    # X-axis
    ax2.set_xlabel('Position in Domain', fontsize=12, fontweight='bold')
    tick_positions = list(range(0, aln_len, 10))
    ax2.set_xticks(tick_positions)
    ax2.set_xticklabels([str(i) for i in tick_positions], fontsize=10)
    
    # Add colorbar
    cbar = plt.colorbar(im, ax=ax2, orientation='vertical', pad=0.02)
    cbar.set_label('Conservation Score', fontsize=11)
    
    plt.tight_layout()
    plt.savefig(output_file, bbox_inches='tight', dpi=300)
    plt.close()
    
    # Count proteins
    protein_counts = Counter([get_full_label(alignment[i].id)[2] for i in range(n_display)])
    
    print(f"  ✓ Saved: {output_file}")
    print(f"  ✓ Showing top {n_display}/{n_seqs} sequences")
    print(f"  ✓ Protein distribution:", dict(protein_counts))
    print("")

# Create output directory
os.makedirs("05_domains/visualizations", exist_ok=True)

# Generate heatmaps
if os.path.exists('05_domains/hmmer/OG0000000_bHLH_conservation.txt'):
    create_conservation_heatmap(
        '05_domains/hmmer/OG0000000_bHLH_conservation.txt',
        '05_domains/hmmer/OG0000000_bHLH_aligned.fasta',
        '05_domains/visualizations/OG0000000_conservation_final.png',
        'OG0000000 (MYOD1/MYF5) bHLH Domain Conservation'
    )

if os.path.exists('05_domains/hmmer/OG0000001_bHLH_conservation.txt'):
    create_conservation_heatmap(
        '05_domains/hmmer/OG0000001_bHLH_conservation.txt',
        '05_domains/hmmer/OG0000001_bHLH_aligned.fasta',
        '05_domains/visualizations/OG0000001_conservation_final.png',
        'OG0000001 (MYOG) bHLH Domain Conservation'
    )

print("="*70)
print("✓ Final Heatmaps Complete!")
print("="*70)
print("")
print("Files created:")
print("  • OG0000000_conservation_final.png")
print("  • OG0000001_conservation_final.png")
print("")
print("These heatmaps now show:")
print("  ✓ Species names (italic)")
print("  ✓ Protein names (MYOD1, MYF5, MYF6, MYOG)")
print("  ✓ Conservation patterns across domains")
print("")

