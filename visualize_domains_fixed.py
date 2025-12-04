#!/usr/bin/env python3

"""
Phase 5 Part 2: Domain Architecture and Conservation Visualization (Fixed)
"""

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import Rectangle, FancyBboxPatch
import seaborn as sns
import pandas as pd
import numpy as np
from Bio import AlignIO, SeqIO
from collections import Counter
import json
import os

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.dpi'] = 300
plt.rcParams['savefig.dpi'] = 300

print("="*70)
print("Domain Visualization - Phase 5 Part 2 (Fixed)")
print("="*70)
print("")

# Create output directory
os.makedirs("05_domains/visualizations", exist_ok=True)

# Load species name mapping
name_mapping = {}
if os.path.exists('04_phylogeny/accession_to_species.txt'):
    with open('04_phylogeny/accession_to_species.txt', 'r') as f:
        for line in f:
            if line.strip():
                parts = line.strip().split('\t')
                if len(parts) == 2:
                    name_mapping[parts[0]] = parts[1]

def get_species_name(accession_id):
    """Convert accession ID to species name"""
    # Remove domain suffix if present (e.g., _HLH_100-150)
    clean_id = accession_id.split('_')[0] if '_' in accession_id else accession_id
    
    species_name = name_mapping.get(clean_id, clean_id)
    
    # Clean up the name for display
    species_name = species_name.replace('_', ' ')
    
    # If still looks like accession, try to extract from it
    if species_name.startswith(('NP', 'XP')):
        # Keep just the base part
        species_name = clean_id
    
    return species_name

# ============================================================================
# 1. DOMAIN ARCHITECTURE DIAGRAM
# ============================================================================

def create_domain_architecture(output_file):
    """Create beautiful domain architecture diagram"""
    
    print("Creating domain architecture diagram...")
    
    fig, axes = plt.subplots(3, 1, figsize=(14, 10))
    fig.suptitle('MRF Family Domain Architecture', fontsize=18, fontweight='bold')
    
    # Define domain architecture for each protein
    proteins = {
        'MYOD1': {
            'length': 320,
            'domains': [
                {'name': 'TAD', 'start': 1, 'end': 80, 'color': '#FF6B6B'},
                {'name': 'Basic', 'start': 100, 'end': 125, 'color': '#4ECDC4'},
                {'name': 'HLH', 'start': 126, 'end': 180, 'color': '#45B7D1'}
            ]
        },
        'MYF5': {
            'length': 255,
            'domains': [
                {'name': 'TAD', 'start': 1, 'end': 60, 'color': '#FF6B6B'},
                {'name': 'Basic', 'start': 80, 'end': 105, 'color': '#4ECDC4'},
                {'name': 'HLH', 'start': 106, 'end': 160, 'color': '#45B7D1'}
            ]
        },
        'MYOG': {
            'length': 224,
            'domains': [
                {'name': 'TAD', 'start': 1, 'end': 50, 'color': '#FF6B6B'},
                {'name': 'Basic', 'start': 70, 'end': 95, 'color': '#4ECDC4'},
                {'name': 'HLH', 'start': 96, 'end': 150, 'color': '#45B7D1'}
            ]
        }
    }
    
    for idx, (protein, info) in enumerate(proteins.items()):
        ax = axes[idx]
        
        # Draw protein backbone
        backbone = FancyBboxPatch((0, 0.3), info['length'], 0.4,
                                   boxstyle="round,pad=0.01",
                                   edgecolor='black', facecolor='lightgray',
                                   linewidth=2, zorder=1)
        ax.add_patch(backbone)
        
        # Draw domains
        for domain in info['domains']:
            width = domain['end'] - domain['start']
            domain_box = FancyBboxPatch(
                (domain['start'], 0.25), width, 0.5,
                boxstyle="round,pad=0.01",
                edgecolor='black', facecolor=domain['color'],
                linewidth=2, zorder=2
            )
            ax.add_patch(domain_box)
            
            # Add domain label
            mid_pos = domain['start'] + width/2
            ax.text(mid_pos, 0.5, domain['name'],
                   ha='center', va='center', fontsize=10,
                   fontweight='bold', color='white', zorder=3)
        
        # Protein name
        ax.text(-20, 0.5, protein, fontsize=14, fontweight='bold',
               ha='right', va='center')
        
        # Length annotation
        ax.text(info['length'] + 10, 0.5, f"{info['length']} aa",
               fontsize=10, ha='left', va='center')
        
        # Axis settings
        ax.set_xlim(-30, info['length'] + 50)
        ax.set_ylim(0, 1)
        ax.axis('off')
    
    # Legend
    legend_elements = [
        mpatches.Patch(facecolor='#FF6B6B', edgecolor='black', label='TAD (Transactivation)'),
        mpatches.Patch(facecolor='#4ECDC4', edgecolor='black', label='Basic (DNA binding)'),
        mpatches.Patch(facecolor='#45B7D1', edgecolor='black', label='HLH (Helix-Loop-Helix)')
    ]
    fig.legend(handles=legend_elements, loc='lower center', ncol=3,
              fontsize=11, frameon=True, fancybox=True)
    
    plt.tight_layout(rect=[0, 0.05, 1, 0.96])
    plt.savefig(output_file, bbox_inches='tight', dpi=300)
    plt.close()
    
    print(f"  ✓ Saved: {output_file}")

create_domain_architecture("05_domains/visualizations/domain_architecture.png")
print("")

# ============================================================================
# 2. CONSERVATION HEATMAP (WITH SPECIES NAMES)
# ============================================================================

def create_conservation_heatmap(conservation_file, alignment_file, output_file, title):
    """Create conservation heatmap with species names"""
    
    print(f"Creating conservation heatmap: {title}...")
    
    # Load conservation scores
    cons_data = pd.read_csv(conservation_file, sep='\t')
    
    # Load alignment
    alignment = AlignIO.read(alignment_file, 'fasta')
    n_seqs = len(alignment)
    aln_len = alignment.get_alignment_length()
    
    # Create matrix for heatmap (first 20 sequences)
    n_display = min(20, n_seqs)
    matrix = np.zeros((n_display, aln_len))
    
    # Get species names for labels
    species_labels = []
    for i in range(n_display):
        original_id = alignment[i].id
        species_name = get_species_name(original_id)
        
        # Truncate long names
        if len(species_name) > 30:
            species_name = species_name[:27] + '...'
        
        species_labels.append(species_name)
    
    # Fill matrix
    for i in range(n_display):
        for j in range(aln_len):
            aa = alignment[i, j]
            if aa != '-':
                matrix[i, j] = cons_data.iloc[j]['Conservation_Score']
            else:
                matrix[i, j] = 0
    
    # Create figure
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(16, 10), 
                                    gridspec_kw={'height_ratios': [1, 4]})
    
    # Top panel: Conservation line plot
    positions = cons_data['Position'].values
    scores = cons_data['Conservation_Score'].values
    
    ax1.plot(positions, scores, linewidth=2, color='#2C3E50')
    ax1.fill_between(positions, scores, alpha=0.3, color='#3498DB')
    ax1.axhline(y=0.9, color='red', linestyle='--', linewidth=1, alpha=0.5, label='High conservation (>0.9)')
    ax1.axhline(y=0.7, color='orange', linestyle='--', linewidth=1, alpha=0.5, label='Moderate conservation (>0.7)')
    ax1.set_ylabel('Conservation\nScore', fontsize=11, fontweight='bold')
    ax1.set_ylim(0, 1)
    ax1.set_xlim(0, aln_len)
    ax1.legend(loc='upper right', fontsize=9)
    ax1.set_title(title, fontsize=14, fontweight='bold', pad=10)
    ax1.grid(True, alpha=0.3)
    
    # Bottom panel: Heatmap with species names
    sns.heatmap(matrix, cmap='RdYlGn', vmin=0, vmax=1, 
                cbar_kws={'label': 'Conservation Score'},
                ax=ax2, xticklabels=50, yticklabels=species_labels)
    
    ax2.set_xlabel('Position', fontsize=11, fontweight='bold')
    ax2.set_ylabel('Species (top 20)', fontsize=11, fontweight='bold')
    
    # Adjust y-axis labels
    ax2.set_yticklabels(ax2.get_yticklabels(), fontsize=9)
    
    plt.tight_layout()
    plt.savefig(output_file, bbox_inches='tight', dpi=300)
    plt.close()
    
    print(f"  ✓ Saved: {output_file}")

# Create heatmaps for both orthogroups
if os.path.exists('05_domains/hmmer/OG0000000_bHLH_conservation.txt'):
    create_conservation_heatmap(
        '05_domains/hmmer/OG0000000_bHLH_conservation.txt',
        '05_domains/hmmer/OG0000000_bHLH_aligned.fasta',
        '05_domains/visualizations/OG0000000_conservation_heatmap.png',
        'OG0000000 (MYOD1/MYF5) bHLH Domain Conservation'
    )

if os.path.exists('05_domains/hmmer/OG0000001_bHLH_conservation.txt'):
    create_conservation_heatmap(
        '05_domains/hmmer/OG0000001_bHLH_conservation.txt',
        '05_domains/hmmer/OG0000001_bHLH_aligned.fasta',
        '05_domains/visualizations/OG0000001_conservation_heatmap.png',
        'OG0000001 (MYOG) bHLH Domain Conservation'
    )

print("")

# ============================================================================
# 3. SEQUENCE LOGO
# ============================================================================

def create_sequence_logo(alignment_file, output_file, title):
    """Create sequence logo showing conserved motifs"""
    
    print(f"Creating sequence logo: {title}...")
    
    try:
        import logomaker
        
        # Load alignment
        alignment = AlignIO.read(alignment_file, 'fasta')
        
        # Convert to position frequency matrix
        aln_len = alignment.get_alignment_length()
        aa_freq = []
        
        for pos in range(aln_len):
            column = [str(alignment[i, pos]) for i in range(len(alignment))]
            column = [aa for aa in column if aa != '-']
            
            if column:
                counts = Counter(column)
                total = len(column)
                freq = {aa: counts.get(aa, 0) / total for aa in 'ACDEFGHIKLMNPQRSTVWY'}
                aa_freq.append(freq)
            else:
                aa_freq.append({aa: 0 for aa in 'ACDEFGHIKLMNPQRSTVWY'})
        
        # Create dataframe
        df = pd.DataFrame(aa_freq)
        
        # Create logo
        fig, ax = plt.subplots(figsize=(max(12, aln_len * 0.15), 4))
        
        logo = logomaker.Logo(df, ax=ax, color_scheme='chemistry')
        ax.set_ylabel('Bits', fontsize=12, fontweight='bold')
        ax.set_xlabel('Position', fontsize=12, fontweight='bold')
        ax.set_title(title, fontsize=14, fontweight='bold', pad=15)
        
        plt.tight_layout()
        plt.savefig(output_file, bbox_inches='tight', dpi=300)
        plt.close()
        
        print(f"  ✓ Saved: {output_file}")
        return True
        
    except Exception as e:
        print(f"  ⚠ Could not create logo: {e}")
        return False

# Create sequence logos
if os.path.exists('05_domains/hmmer/OG0000000_bHLH_aligned.fasta'):
    create_sequence_logo(
        '05_domains/hmmer/OG0000000_bHLH_aligned.fasta',
        '05_domains/visualizations/OG0000000_sequence_logo.png',
        'OG0000000 (MYOD1/MYF5) bHLH Domain Sequence Logo'
    )

if os.path.exists('05_domains/hmmer/OG0000001_bHLH_aligned.fasta'):
    create_sequence_logo(
        '05_domains/hmmer/OG0000001_bHLH_aligned.fasta',
        '05_domains/visualizations/OG0000001_sequence_logo.png',
        'OG0000001 (MYOG) bHLH Domain Sequence Logo'
    )

print("")

# ============================================================================
# 4. DOMAIN CONSERVATION COMPARISON
# ============================================================================

def compare_domain_conservation(output_file):
    """Compare conservation between OG0000000 and OG0000001"""
    
    print("Creating domain conservation comparison...")
    
    # Load conservation data
    og0_cons = pd.read_csv('05_domains/hmmer/OG0000000_bHLH_conservation.txt', sep='\t')
    og1_cons = pd.read_csv('05_domains/hmmer/OG0000001_bHLH_conservation.txt', sep='\t')
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle('Domain Conservation Comparison: MYOD1/MYF5 vs MYOG', 
                 fontsize=16, fontweight='bold')
    
    # 1. Distribution histograms
    ax = axes[0, 0]
    ax.hist(og0_cons['Conservation_Score'], bins=30, alpha=0.6, 
            color='#3498DB', label='MYOD1/MYF5', edgecolor='black')
    ax.hist(og1_cons['Conservation_Score'], bins=30, alpha=0.6, 
            color='#E74C3C', label='MYOG', edgecolor='black')
    ax.set_xlabel('Conservation Score', fontsize=11, fontweight='bold')
    ax.set_ylabel('Frequency', fontsize=11, fontweight='bold')
    ax.set_title('Conservation Score Distribution', fontsize=12, fontweight='bold')
    ax.legend()
    ax.grid(True, alpha=0.3)
    
    # 2. Box plot comparison
    ax = axes[0, 1]
    data = [og0_cons['Conservation_Score'].values, 
            og1_cons['Conservation_Score'].values]
    bp = ax.boxplot(data, labels=['MYOD1/MYF5\n(OG0000000)', 'MYOG\n(OG0000001)'],
                    patch_artist=True, widths=0.6)
    bp['boxes'][0].set_facecolor('#3498DB')
    bp['boxes'][1].set_facecolor('#E74C3C')
    ax.set_ylabel('Conservation Score', fontsize=11, fontweight='bold')
    ax.set_title('Conservation Comparison', fontsize=12, fontweight='bold')
    ax.grid(True, alpha=0.3, axis='y')
    
    # 3. Cumulative conservation
    ax = axes[1, 0]
    
    # Calculate highly/moderately conserved positions
    og0_high = (og0_cons['Conservation_Score'] > 0.9).sum()
    og0_mod = ((og0_cons['Conservation_Score'] >= 0.7) & 
               (og0_cons['Conservation_Score'] <= 0.9)).sum()
    og0_low = (og0_cons['Conservation_Score'] < 0.7).sum()
    
    og1_high = (og1_cons['Conservation_Score'] > 0.9).sum()
    og1_mod = ((og1_cons['Conservation_Score'] >= 0.7) & 
               (og1_cons['Conservation_Score'] <= 0.9)).sum()
    og1_low = (og1_cons['Conservation_Score'] < 0.7).sum()
    
    categories = ['High\n(>0.9)', 'Moderate\n(0.7-0.9)', 'Low\n(<0.7)']
    og0_counts = [og0_high, og0_mod, og0_low]
    og1_counts = [og1_high, og1_mod, og1_low]
    
    x = np.arange(len(categories))
    width = 0.35
    
    ax.bar(x - width/2, og0_counts, width, label='MYOD1/MYF5', 
           color='#3498DB', edgecolor='black')
    ax.bar(x + width/2, og1_counts, width, label='MYOG', 
           color='#E74C3C', edgecolor='black')
    
    ax.set_ylabel('Number of Positions', fontsize=11, fontweight='bold')
    ax.set_title('Conservation Categories', fontsize=12, fontweight='bold')
    ax.set_xticks(x)
    ax.set_xticklabels(categories)
    ax.legend()
    ax.grid(True, alpha=0.3, axis='y')
    
    # 4. Statistics table
    ax = axes[1, 1]
    ax.axis('off')
    
    stats_data = [
        ['Metric', 'MYOD1/MYF5', 'MYOG'],
        ['Mean Conservation', f"{og0_cons['Conservation_Score'].mean():.3f}", 
         f"{og1_cons['Conservation_Score'].mean():.3f}"],
        ['Median Conservation', f"{og0_cons['Conservation_Score'].median():.3f}", 
         f"{og1_cons['Conservation_Score'].median():.3f}"],
        ['Highly Conserved', f"{og0_high} ({og0_high/len(og0_cons)*100:.1f}%)", 
         f"{og1_high} ({og1_high/len(og1_cons)*100:.1f}%)"],
        ['Domain Length', f"{len(og0_cons)} aa", f"{len(og1_cons)} aa"],
        ['Sequences', '71', '39']
    ]
    
    table = ax.table(cellText=stats_data, cellLoc='center', loc='center',
                    colWidths=[0.35, 0.325, 0.325])
    table.auto_set_font_size(False)
    table.set_fontsize(10)
    table.scale(1, 2)
    
    # Style header
    for i in range(3):
        table[(0, i)].set_facecolor('#34495E')
        table[(0, i)].set_text_props(weight='bold', color='white')
    
    # Color code rows
    for i in range(1, len(stats_data)):
        table[(i, 0)].set_facecolor('#ECF0F1')
        table[(i, 1)].set_facecolor('#D6EAF8')
        table[(i, 2)].set_facecolor('#F5B7B1')
    
    ax.set_title('Conservation Statistics Summary', fontsize=12, 
                fontweight='bold', pad=20)
    
    plt.tight_layout()
    plt.savefig(output_file, bbox_inches='tight', dpi=300)
    plt.close()
    
    print(f"  ✓ Saved: {output_file}")

compare_domain_conservation('05_domains/visualizations/conservation_comparison.png')
print("")

# ============================================================================
# 5. FUNCTIONAL SITES IDENTIFICATION
# ============================================================================

def identify_functional_sites(conservation_file, alignment_file, output_file, title):
    """Identify and visualize putative functional sites"""
    
    print(f"Identifying functional sites: {title}...")
    
    # Load data
    cons_data = pd.read_csv(conservation_file, sep='\t')
    alignment = AlignIO.read(alignment_file, 'fasta')
    
    # Identify highly conserved positions (putative functional sites)
    functional_sites = cons_data[cons_data['Conservation_Score'] > 0.9]
    
    # Create figure
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(16, 10))
    
    # Top panel: Conservation with functional sites marked
    ax1.plot(cons_data['Position'], cons_data['Conservation_Score'], 
            linewidth=2, color='#2C3E50', label='Conservation')
    ax1.axhline(y=0.9, color='red', linestyle='--', linewidth=1, alpha=0.5)
    
    # Mark functional sites
    ax1.scatter(functional_sites['Position'], functional_sites['Conservation_Score'],
               color='red', s=100, marker='*', zorder=5, 
               label=f'Putative Functional Sites (n={len(functional_sites)})')
    
    # Annotate conserved residues
    for idx, row in functional_sites.head(10).iterrows():
        ax1.annotate(row['Residue'], 
                    xy=(row['Position'], row['Conservation_Score']),
                    xytext=(0, 10), textcoords='offset points',
                    fontsize=9, fontweight='bold', color='red',
                    ha='center',
                    bbox=dict(boxstyle='round,pad=0.3', facecolor='yellow', alpha=0.7))
    
    ax1.set_ylabel('Conservation Score', fontsize=11, fontweight='bold')
    ax1.set_ylim(0, 1.05)
    ax1.set_title(title, fontsize=14, fontweight='bold')
    ax1.legend(loc='upper right', fontsize=10)
    ax1.grid(True, alpha=0.3)
    
    # Bottom panel: Amino acid composition at functional sites
    if len(functional_sites) > 0:
        residues = functional_sites['Residue'].value_counts()
        
        ax2.bar(range(len(residues)), residues.values, 
               color='#E74C3C', edgecolor='black', linewidth=1.5)
        ax2.set_xticks(range(len(residues)))
        ax2.set_xticklabels(residues.index, fontsize=11, fontweight='bold')
        ax2.set_ylabel('Frequency', fontsize=11, fontweight='bold')
        ax2.set_xlabel('Amino Acid', fontsize=11, fontweight='bold')
        ax2.set_title('Conserved Residues at Functional Sites', 
                     fontsize=12, fontweight='bold')
        ax2.grid(True, alpha=0.3, axis='y')
    
    plt.tight_layout()
    plt.savefig(output_file, bbox_inches='tight', dpi=300)
    plt.close()
    
    print(f"  ✓ Saved: {output_file}")
    print(f"    Identified {len(functional_sites)} putative functional sites")
    
    # Save functional sites to file
    sites_file = output_file.replace('.png', '_sites.txt')
    functional_sites.to_csv(sites_file, sep='\t', index=False)
    print(f"  ✓ Functional sites saved: {sites_file}")

# Identify functional sites
if os.path.exists('05_domains/hmmer/OG0000000_bHLH_conservation.txt'):
    identify_functional_sites(
        '05_domains/hmmer/OG0000000_bHLH_conservation.txt',
        '05_domains/hmmer/OG0000000_bHLH_aligned.fasta',
        '05_domains/visualizations/OG0000000_functional_sites.png',
        'OG0000000 (MYOD1/MYF5) Functional Sites'
    )

if os.path.exists('05_domains/hmmer/OG0000001_bHLH_conservation.txt'):
    identify_functional_sites(
        '05_domains/hmmer/OG0000001_bHLH_conservation.txt',
        '05_domains/hmmer/OG0000001_bHLH_aligned.fasta',
        '05_domains/visualizations/OG0000001_functional_sites.png',
        'OG0000001 (MYOG) Functional Sites'
    )

print("")

# ============================================================================
# FINAL SUMMARY
# ============================================================================

print("="*70)
print("Visualization Complete!")
print("="*70)
print("")
print("Created visualizations:")
print("  1. Domain architecture diagram")
print("  2. Conservation heatmaps with species names (2)")
print("  3. Sequence logos (2)")
print("  4. Conservation comparison")
print("  5. Functional sites analysis (2)")
print("")
print("All files saved in: 05_domains/visualizations/")
print("")

# List all created files
viz_files = sorted([f for f in os.listdir('05_domains/visualizations') if f.endswith('.png')])
for f in viz_files:
    size = os.path.getsize(f'05_domains/visualizations/{f}') / (1024*1024)
    print(f"  ✓ {f} ({size:.2f} MB)")

print("")
print("Ready for final report generation!")
print("")
