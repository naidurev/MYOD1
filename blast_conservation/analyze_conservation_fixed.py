#!/usr/bin/env python3

from Bio import AlignIO
from collections import Counter
import numpy as np
import os

def calculate_conservation(alignment_file, output_file):
    """Calculate per-position conservation scores"""
    
    if not os.path.exists(alignment_file):
        print(f"  ⚠ File not found: {alignment_file}")
        return
    
    try:
        alignment = AlignIO.read(alignment_file, "fasta")
    except:
        print(f"  ⚠ Could not read {alignment_file}")
        return
    
    n_seqs = len(alignment)
    aln_len = alignment.get_alignment_length()
    
    conservation = []
    
    for pos in range(aln_len):
        column = alignment[:, pos]
        
        # Skip gap-only columns
        non_gap = [aa for aa in column if aa != '-']
        if len(non_gap) == 0:
            conservation.append(0)
            continue
        
        # Calculate Shannon entropy (lower = more conserved)
        counts = Counter(non_gap)
        total = len(non_gap)
        
        entropy = 0
        for count in counts.values():
            p = count / total
            if p > 0:
                entropy -= p * np.log2(p)
        
        # Normalize to 0-1 (1 = perfectly conserved)
        max_entropy = np.log2(min(20, len(non_gap)))
        if max_entropy > 0:
            conservation_score = 1 - (entropy / max_entropy)
        else:
            conservation_score = 1
        
        conservation.append(conservation_score)
    
    # Save conservation scores
    with open(output_file, 'w') as f:
        f.write("Position\tConservation_Score\tResidue\n")
        for pos, score in enumerate(conservation, 1):
            column = alignment[:, pos-1]
            non_gap = [aa for aa in column if aa != '-']
            if non_gap:
                consensus = Counter(non_gap).most_common(1)[0][0]
            else:
                consensus = '-'
            
            f.write(f"{pos}\t{score:.3f}\t{consensus}\n")
    
    print(f"  ✓ Analyzed {alignment_file}")
    print(f"    Sequences: {n_seqs}, Length: {aln_len}")
    
    highly_conserved = sum(1 for s in conservation if s > 0.9)
    moderate = sum(1 for s in conservation if 0.7 <= s <= 0.9)
    
    print(f"    Highly conserved (>0.9): {highly_conserved} positions")
    print(f"    Moderately conserved (0.7-0.9): {moderate} positions")
    print("")

print("\n" + "="*70)
print("Conservation Analysis")
print("="*70)
print("")

if os.path.exists('05_domains/hmmer/OG0000000_bHLH_aligned.fasta'):
    print("OG0000000 bHLH domains:")
    calculate_conservation(
        '05_domains/hmmer/OG0000000_bHLH_aligned.fasta',
        '05_domains/hmmer/OG0000000_bHLH_conservation.txt'
    )

if os.path.exists('05_domains/hmmer/OG0000001_bHLH_aligned.fasta'):
    print("OG0000001 bHLH domains:")
    calculate_conservation(
        '05_domains/hmmer/OG0000001_bHLH_aligned.fasta',
        '05_domains/hmmer/OG0000001_bHLH_conservation.txt'
    )

print("✓ Conservation analysis complete")
print("")

