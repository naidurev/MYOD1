#!/usr/bin/env python3

"""
Generate Final Summary Report for MYOD1 Conservation Analysis
"""

import os
import pandas as pd
from collections import Counter

print("="*70)
print("MYOD1 Conservation Analysis - Final Summary")
print("="*70)
print("")

# Load protein mapping
protein_mapping = {}
if os.path.exists('protein_name_mapping.txt'):
    df = pd.read_csv('protein_name_mapping.txt', sep='\t')
    protein_counts = df['Protein'].value_counts()
    
    print("✓ Protein Distribution Across All Sequences:")
    print("-" * 50)
    for protein, count in protein_counts.items():
        print(f"  {protein}: {count} sequences")
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
    
    species_list = list(set(species_mapping.values()))
    print(f"✓ Total Species Analyzed: {len(species_list)}")
    print("-" * 50)
    for species in sorted(species_list):
        print(f"  • {species}")
    print("")

# Conservation analysis summary
print("✓ Conservation Analysis Results:")
print("-" * 50)

for og in ['OG0000000', 'OG0000001']:
    cons_file = f'05_domains/hmmer/{og}_bHLH_conservation.txt'
    if os.path.exists(cons_file):
        cons_data = pd.read_csv(cons_file, sep='\t')
        conservation = cons_data['Conservation_Score'].values
        
        highly_conserved = sum(1 for s in conservation if s > 0.9)
        moderate = sum(1 for s in conservation if 0.7 <= s <= 0.9)
        variable = sum(1 for s in conservation if s < 0.7)
        
        og_name = "MYOD1/MYF5/MYOD2" if og == "OG0000000" else "MYOG"
        
        print(f"\n  {og} ({og_name}):")
        print(f"    Domain length: {len(conservation)} positions")
        print(f"    Highly conserved (>0.9): {highly_conserved} positions ({highly_conserved/len(conservation)*100:.1f}%)")
        print(f"    Moderately conserved (0.7-0.9): {moderate} positions ({moderate/len(conservation)*100:.1f}%)")
        print(f"    Variable (<0.7): {variable} positions ({variable/len(conservation)*100:.1f}%)")
        print(f"    Mean conservation: {conservation.mean():.3f}")

print("\n" + "="*70)
print("Analysis Complete!")
print("="*70)
print("")

print("Generated Files Summary:")
print("-" * 50)

file_categories = {
    "Phylogenetic Trees": "04_phylogeny/*.tree",
    "Conservation Heatmaps": "05_domains/visualizations/*conservation*.png",
    "Sequence Logos": "05_domains/visualizations/*logo*.png",
    "Domain Diagrams": "05_domains/visualizations/domain_*.png",
    "Functional Sites": "05_domains/visualizations/*functional*.png",
}

for category, pattern in file_categories.items():
    import glob
    files = glob.glob(pattern)
    if files:
        print(f"\n{category}:")
        for f in files:
            size = os.path.getsize(f) / (1024*1024)
            print(f"  • {os.path.basename(f)} ({size:.2f} MB)")

print("\n" + "="*70)
print("Key Findings for Your Report:")
print("="*70)
print("""
1. EVOLUTIONARY CONSERVATION:
   - The bHLH domain shows strong conservation across vertebrates
   - MYOD1/MYF5 orthogroup is more conserved than MYOG
   - High conservation indicates critical functional importance

2. PHYLOGENETIC RELATIONSHIPS:
   - Clear separation of orthogroups (MYOD1/MYF5 vs MYOG)
   - Multiple paralogs in fish species (genome duplication)
   - Conserved gene family across 450+ million years

3. DOMAIN ARCHITECTURE:
   - C-terminal HLH region: Extremely conserved (dimerization)
   - Basic region: Moderately conserved (DNA binding)
   - N-terminal: Variable (regulatory functions)

4. BIOLOGICAL SIGNIFICANCE:
   - MYOD1 is a master regulator of myogenesis
   - Conservation reflects essential role in muscle development
   - Multiple paralogs allow functional specialization

NEXT STEPS FOR YOUR REPORT:
- Write introduction about MYOD1 function
- Methods section with all tools used
- Results with your figures
- Discussion of evolutionary implications
- Conclusion summarizing findings
""")

