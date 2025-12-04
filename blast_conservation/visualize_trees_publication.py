#!/usr/bin/env python3

"""
Publication-Quality Phylogenetic Tree Visualization
- PRANK trees: Circular phylograms (evolutionary focus)
- MAFFT trees: Rectangular cladograms (functional focus)
- 600 DPI resolution
- Species names instead of accession IDs
"""

from ete3 import Tree, TreeStyle, NodeStyle, TextFace, faces
import sys
import os

# Load accession to species mapping
def load_name_mapping(mapping_file):
    """Load accession ID to species name mapping"""
    mapping = {}
    with open(mapping_file, 'r') as f:
        for line in f:
            if line.strip():
                parts = line.strip().split('\t')
                if len(parts) == 2:
                    mapping[parts[0]] = parts[1]
    return mapping

# Load mapping
name_mapping = load_name_mapping('04_phylogeny/accession_to_species.txt')

def get_species_info(accession):
    """Get species name and taxonomic group from accession"""
    species_name = name_mapping.get(accession, accession)
    
    # Determine taxonomic group and color
    if 'Homo_sapiens' in species_name or 'Mus_musculus' in species_name or \
       'Bos_taurus' in species_name or 'Canis_lupus' in species_name:
        taxon_color = '#4169E1'  # Royal Blue - Mammals
        taxon_group = 'Mammal'
    elif 'Danio' in species_name or 'Oryzias' in species_name or \
         'Takifugu' in species_name or 'Salmo' in species_name:
        taxon_color = '#228B22'  # Forest Green - Fish
        taxon_group = 'Fish'
    elif 'Xenopus' in species_name:
        taxon_color = '#FF8C00'  # Dark Orange - Amphibians
        taxon_group = 'Amphibian'
    elif 'Gallus' in species_name:
        taxon_color = '#DC143C'  # Crimson - Birds
        taxon_group = 'Bird'
    else:
        taxon_color = '#808080'  # Gray - Other
        taxon_group = 'Other'
    
    # Determine gene type
    if 'MYOD1' in species_name:
        gene_type = 'MYOD1'
        gene_color = '#1E90FF'  # Dodger Blue
    elif 'MYF5' in species_name:
        gene_type = 'MYF5'
        gene_color = '#32CD32'  # Lime Green
    elif 'MYOG' in species_name:
        gene_type = 'MYOG'
        gene_color = '#9370DB'  # Medium Purple
    else:
        gene_type = 'Unknown'
        gene_color = '#808080'
    
    return species_name, taxon_color, taxon_group, gene_type, gene_color

def create_prank_circular_tree(treefile, output_png, title, orthogroup):
    """
    Create beautiful circular phylogram for PRANK trees
    Emphasizes evolutionary relationships and branch lengths
    """
    
    try:
        print(f"Creating PRANK circular tree: {title}")
        
        # Load tree
        tree = Tree(treefile, format=0)
        
        # Replace accession IDs with species names
        for leaf in tree.get_leaves():
            species_name, _, _, _, _ = get_species_info(leaf.name)
            leaf.name = species_name.replace('_', ' ')
        
        # Tree style
        ts = TreeStyle()
        ts.mode = "c"  # Circular
        ts.arc_start = -180
        ts.arc_span = 360
        
        # Title
        title_face = TextFace(title, fsize=24, bold=True, fgcolor='#2C3E50')
        ts.title.add_face(title_face, column=0)
        
        # Show scale
        ts.show_scale = True
        ts.scale = 50
        ts.scale_length = 0.1
        
        # Branch and leaf labels
        ts.show_leaf_name = False  # We'll add custom labels
        ts.show_branch_length = False
        ts.show_branch_support = True
        
        # Legend
        ts.legend.add_face(TextFace("  ", fsize=10), column=0)
        ts.legend.add_face(TextFace("Bootstrap Support:", fsize=14, bold=True), column=0)
        ts.legend.add_face(TextFace("  ● ≥95% (Strong)", fsize=12, fgcolor="darkgreen"), column=0)
        ts.legend.add_face(TextFace("  ● 80-94% (Moderate)", fsize=12, fgcolor="orange"), column=0)
        ts.legend.add_face(TextFace("  ● <80% (Weak)", fsize=12, fgcolor="red"), column=0)
        ts.legend.add_face(TextFace("  ", fsize=10), column=0)
        ts.legend.add_face(TextFace("Taxonomic Groups:", fsize=14, bold=True), column=0)
        ts.legend.add_face(TextFace("  ● Mammals", fsize=12, fgcolor="#4169E1"), column=0)
        ts.legend.add_face(TextFace("  ● Fish", fsize=12, fgcolor="#228B22"), column=0)
        ts.legend.add_face(TextFace("  ● Amphibians", fsize=12, fgcolor="#FF8C00"), column=0)
        ts.legend.add_face(TextFace("  ● Birds", fsize=12, fgcolor="#DC143C"), column=0)
        ts.legend_position = 4
        
        # Style nodes
        for node in tree.traverse():
            nstyle = NodeStyle()
            nstyle["hz_line_width"] = 3
            nstyle["vt_line_width"] = 3
            
            if node.is_leaf():
                # Get species info
                original_name = node.name.replace(' ', '_')
                _, taxon_color, _, _, _ = get_species_info(original_name)
                
                # Leaf node style
                nstyle["size"] = 12
                nstyle["shape"] = "circle"
                nstyle["fgcolor"] = taxon_color
                
                # Add species name
                name_face = TextFace(node.name, fsize=11, fgcolor=taxon_color, bold=True)
                node.add_face(name_face, column=0, position="branch-right")
                
            else:
                # Internal node
                nstyle["size"] = 8
                nstyle["shape"] = "circle"
                
                # Color by bootstrap support
                support = float(node.support) if node.support else 0
                
                if support >= 95:
                    nstyle["fgcolor"] = "darkgreen"
                    support_face = TextFace(f"{support:.0f}", fsize=10, fgcolor="darkgreen", bold=True)
                elif support >= 80:
                    nstyle["fgcolor"] = "orange"
                    support_face = TextFace(f"{support:.0f}", fsize=10, fgcolor="orange", bold=True)
                else:
                    nstyle["fgcolor"] = "red"
                    support_face = TextFace(f"{support:.0f}", fsize=9, fgcolor="red")
                
                if support > 0:
                    node.add_face(support_face, column=0, position="branch-top")
            
            node.set_style(nstyle)
        
        # Render at 600 DPI
        tree.render(output_png, tree_style=ts, w=2400, h=2400, dpi=600)
        print(f"  ✓ Saved: {output_png}")
        
    except Exception as e:
        print(f"  ✗ Error: {e}")
        import traceback
        traceback.print_exc()

def create_mafft_rectangular_tree(treefile, output_png, title, orthogroup):
    """
    Create clean rectangular cladogram for MAFFT trees
    Emphasizes functional groupings and taxonomy
    """
    
    try:
        print(f"Creating MAFFT rectangular tree: {title}")
        
        # Load tree
        tree = Tree(treefile, format=0)
        
        # Replace accession IDs with species names
        for leaf in tree.get_leaves():
            species_name, _, _, _, _ = get_species_info(leaf.name)
            leaf.name = species_name.replace('_', ' ')
        
        # Tree style
        ts = TreeStyle()
        ts.mode = "r"  # Rectangular
        
        # Title
        title_face = TextFace(title, fsize=24, bold=True, fgcolor='#2C3E50')
        ts.title.add_face(title_face, column=0)
        
        # Cladogram mode (equal branch lengths for clarity)
        ts.force_topology = False
        ts.show_leaf_name = False
        ts.show_branch_length = False
        ts.show_branch_support = True
        
        # Orientation
        ts.rotation = 0
        ts.branch_vertical_margin = 15  # Spacing between branches
        
        # Legend
        ts.legend.add_face(TextFace("  ", fsize=10), column=0)
        ts.legend.add_face(TextFace("Taxonomic Groups:", fsize=14, bold=True), column=0)
        ts.legend.add_face(TextFace("  ● Mammals", fsize=12, fgcolor="#4169E1"), column=0)
        ts.legend.add_face(TextFace("  ● Fish", fsize=12, fgcolor="#228B22"), column=0)
        ts.legend.add_face(TextFace("  ● Amphibians", fsize=12, fgcolor="#FF8C00"), column=0)
        ts.legend.add_face(TextFace("  ● Birds", fsize=12, fgcolor="#DC143C"), column=0)
        ts.legend.add_face(TextFace("  ", fsize=10), column=0)
        ts.legend.add_face(TextFace("Bootstrap: >70% shown", fsize=12), column=0)
        ts.legend_position = 3
        
        # Style nodes
        for node in tree.traverse():
            nstyle = NodeStyle()
            nstyle["hz_line_width"] = 3
            nstyle["vt_line_width"] = 3
            
            if node.is_leaf():
                # Get species info
                original_name = node.name.replace(' ', '_')
                _, taxon_color, _, _, _ = get_species_info(original_name)
                
                # Leaf style
                nstyle["size"] = 0  # Hide node circle
                
                # Add colored species name
                name_face = TextFace(f"  {node.name}", fsize=12, fgcolor=taxon_color, bold=True)
                node.add_face(name_face, column=0, position="branch-right")
                
            else:
                # Internal node
                support = float(node.support) if node.support else 0
                
                # Only show support if >70%
                if support >= 70:
                    nstyle["size"] = 7
                    nstyle["shape"] = "circle"
                    
                    if support >= 95:
                        nstyle["fgcolor"] = "darkgreen"
                        support_face = TextFace(f" {support:.0f}", fsize=10, fgcolor="darkgreen", bold=True)
                    elif support >= 80:
                        nstyle["fgcolor"] = "orange"
                        support_face = TextFace(f" {support:.0f}", fsize=10, fgcolor="orange", bold=True)
                    else:
                        nstyle["fgcolor"] = "#DAA520"
                        support_face = TextFace(f" {support:.0f}", fsize=9, fgcolor="#DAA520")
                    
                    node.add_face(support_face, column=0, position="branch-top")
                else:
                    nstyle["size"] = 0  # Hide low support nodes
            
            node.set_style(nstyle)
        
        # Calculate height based on number of leaves
        n_leaves = len(tree.get_leaves())
        height = max(1800, n_leaves * 50)
        
        # Render at 600 DPI
        tree.render(output_png, tree_style=ts, w=3000, h=height, dpi=600)
        print(f"  ✓ Saved: {output_png}")
        
    except Exception as e:
        print(f"  ✗ Error: {e}")
        import traceback
        traceback.print_exc()

# Create output directory
os.makedirs("04_phylogeny/publication_figures", exist_ok=True)

print("="*70)
print("Creating Publication-Quality Figures (600 DPI)")
print("="*70)
print("")

# PRANK Trees - Circular (Evolutionary focus)
print("PRANK TREES (Circular Phylograms)")
print("-"*70)

create_prank_circular_tree(
    "04_phylogeny/prank_trees/OG0000000_prank.treefile",
    "04_phylogeny/publication_figures/Figure_1A_OG0000000_PRANK.png",
    "OG0000000: MYOD1/MYF5 Evolutionary Phylogeny",
    "OG0000000"
)

create_prank_circular_tree(
    "04_phylogeny/prank_trees/OG0000001_prank.treefile",
    "04_phylogeny/publication_figures/Figure_1B_OG0000001_PRANK.png",
    "OG0000001: MYOG Evolutionary Phylogeny",
    "OG0000001"
)

print("")
print("MAFFT TREES (Rectangular Cladograms)")
print("-"*70)

create_mafft_rectangular_tree(
    "04_phylogeny/mafft_trees/OG0000000_mafft.treefile",
    "04_phylogeny/publication_figures/Figure_2A_OG0000000_MAFFT.png",
    "OG0000000: MYOD1/MYF5 Functional Relationships",
    "OG0000000"
)

create_mafft_rectangular_tree(
    "04_phylogeny/mafft_trees/OG0000001_mafft.treefile",
    "04_phylogeny/publication_figures/Figure_2B_OG0000001_MAFFT.png",
    "OG0000001: MYOG Functional Relationships",
    "OG0000001"
)

print("")
print("="*70)
print("Publication Figures Complete!")
print("="*70)
print("")
print("Output directory: 04_phylogeny/publication_figures/")
print("")
print("Files created:")
print("  Figure 1: PRANK Evolutionary Trees (Circular, 600 DPI)")
print("    - Figure_1A_OG0000000_PRANK.png")
print("    - Figure_1B_OG0000001_PRANK.png")
print("")
print("  Figure 2: MAFFT Functional Trees (Rectangular, 600 DPI)")
print("    - Figure_2A_OG0000000_MAFFT.png")
print("    - Figure_2B_OG0000001_MAFFT.png")
print("")
print("All figures ready for publication/presentation!")
print("")

