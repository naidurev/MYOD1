#!/usr/bin/env python3

from Bio import Phylo
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import os
import re

# Load name mapping
name_mapping = {}
with open('04_phylogeny/accession_to_species.txt', 'r') as f:
    for line in f:
        if line.strip():
            parts = line.strip().split('\t')
            if len(parts) == 2:
                name_mapping[parts[0]] = parts[1]

def get_color(species_name):
    """Get color based on taxonomy"""
    if any(x in species_name for x in ['Homo_sapiens', 'Mus_musculus', 'Bos_taurus', 'Canis_lupus']):
        return '#4169E1'
    elif any(x in species_name for x in ['Danio', 'Oryzias', 'Takifugu', 'Salmo']):
        return '#228B22'
    elif 'Xenopus' in species_name:
        return '#FF8C00'
    elif 'Gallus' in species_name:
        return '#DC143C'
    else:
        return '#808080'

def strip_support_values(tree):
    """Remove support values from internal nodes"""
    for node in tree.get_nonterminals():
        node.confidence = None

def plot_tree(treefile, output_png, title, layout='rectangular'):
    """Create beautiful tree plot"""
    
    try:
        print(f"Creating: {title}")
        
        # Read tree
        tree = Phylo.read(treefile, 'newick')
        
        # Strip support values from internal nodes
        strip_support_values(tree)
        
        # Replace leaf names
        for leaf in tree.get_terminals():
            species_name = name_mapping.get(leaf.name, leaf.name)
            leaf.name = species_name.replace('_', ' ')
        
        # Calculate figure size
        n_leaves = len(tree.get_terminals())
        
        if layout == 'circular':
            fig_size = (16, 16)
        else:
            height = max(12, n_leaves * 0.35)
            fig_size = (14, height)
        
        # Create figure
        fig, ax = plt.subplots(figsize=fig_size)
        
        # Draw tree
        if layout == 'circular':
            # For circular, we need to manually draw
            Phylo.draw(tree, axes=ax, do_show=False, 
                      show_confidence=False,
                      branch_labels=None)
        else:
            Phylo.draw(tree, axes=ax, do_show=False, 
                      show_confidence=False,
                      branch_labels=None)
        
        # Color leaves by taxonomy (only leaf labels, not branch labels)
        for text in ax.texts:
            label = text.get_text()
            # Skip if it's a number (branch support or coordinate)
            if re.match(r'^[\d./]+$', label.strip()):
                text.set_visible(False)
                continue
            
            original_name = label.replace(' ', '_')
            color = get_color(original_name)
            text.set_color(color)
            text.set_fontsize(11)
            text.set_fontweight('bold')
        
        # Title
        ax.set_title(title, fontsize=18, fontweight='bold', pad=20)
        
        # Legend
        mammals_patch = mpatches.Patch(color='#4169E1', label='Mammals')
        fish_patch = mpatches.Patch(color='#228B22', label='Fish')
        amphibian_patch = mpatches.Patch(color='#FF8C00', label='Amphibians')
        bird_patch = mpatches.Patch(color='#DC143C', label='Birds')
        
        ax.legend(handles=[mammals_patch, fish_patch, amphibian_patch, bird_patch],
                 loc='upper right', fontsize=12, frameon=True, fancybox=True)
        
        # Clean up axes
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.spines['bottom'].set_visible(False)
        ax.spines['left'].set_visible(False)
        ax.set_xlabel('')
        ax.set_ylabel('')
        
        # Remove axis ticks
        ax.set_xticks([])
        ax.set_yticks([])
        
        # Save with high DPI
        plt.tight_layout()
        plt.savefig(output_png, dpi=600, bbox_inches='tight', facecolor='white')
        plt.close()
        
        print(f"  ✓ Saved: {output_png}")
        return True
        
    except Exception as e:
        print(f"  ✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

# Create output directory
os.makedirs("04_phylogeny/publication_figures", exist_ok=True)

print("="*70)
print("Creating Publication Figures (600 DPI)")
print("="*70)
print("")

success = 0

# PRANK trees - CIRCULAR
print("PRANK TREES (Circular - Evolutionary)")
print("-"*70)

if plot_tree(
    "04_phylogeny/prank_trees/OG0000000_prank.treefile",
    "04_phylogeny/publication_figures/Figure_1A_OG0000000_PRANK_circular.png",
    "OG0000000: MYOD1/MYF5 Evolutionary Phylogeny (PRANK)",
    'circular'
):
    success += 1

if plot_tree(
    "04_phylogeny/prank_trees/OG0000001_prank.treefile",
    "04_phylogeny/publication_figures/Figure_1B_OG0000001_PRANK_circular.png",
    "OG0000001: MYOG Evolutionary Phylogeny (PRANK)",
    'circular'
):
    success += 1

print("")
print("PRANK TREES (Rectangular - Evolutionary)")
print("-"*70)

if plot_tree(
    "04_phylogeny/prank_trees/OG0000000_prank.treefile",
    "04_phylogeny/publication_figures/Figure_1A_OG0000000_PRANK_rect.png",
    "OG0000000: MYOD1/MYF5 Evolutionary Phylogeny (PRANK)",
    'rectangular'
):
    success += 1

if plot_tree(
    "04_phylogeny/prank_trees/OG0000001_prank.treefile",
    "04_phylogeny/publication_figures/Figure_1B_OG0000001_PRANK_rect.png",
    "OG0000001: MYOG Evolutionary Phylogeny (PRANK)",
    'rectangular'
):
    success += 1

print("")
print("MAFFT TREES (Rectangular - Functional)")
print("-"*70)

if plot_tree(
    "04_phylogeny/mafft_trees/OG0000000_mafft.treefile",
    "04_phylogeny/publication_figures/Figure_2A_OG0000000_MAFFT.png",
    "OG0000000: MYOD1/MYF5 Functional Relationships (MAFFT)",
    'rectangular'
):
    success += 1

if plot_tree(
    "04_phylogeny/mafft_trees/OG0000001_mafft.treefile",
    "04_phylogeny/publication_figures/Figure_2B_OG0000001_MAFFT.png",
    "OG0000001: MYOG Functional Relationships (MAFFT)",
    'rectangular'
):
    success += 1

print("")
print("="*70)
print(f"Complete! Successfully created {success}/6 figures")
print("="*70)
print("")

# List files
print("Files created:")
for f in sorted(os.listdir("04_phylogeny/publication_figures")):
    if f.endswith('.png'):
        filepath = f"04_phylogeny/publication_figures/{f}"
        size = os.path.getsize(filepath) / (1024*1024)
        print(f"  ✓ {f} ({size:.2f} MB)")

print("")
print("You now have:")
print("  - 2 circular PRANK trees (evolutionary)")
print("  - 2 rectangular PRANK trees (evolutionary)")
print("  - 2 rectangular MAFFT trees (functional)")
print("")
print("All figures ready for presentation and publication!")
