#!/usr/bin/env python3

from Bio import SeqIO
import json
import os

def load_sequences(fasta_file):
    """Load sequences from FASTA"""
    seqs = {}
    for record in SeqIO.parse(fasta_file, "fasta"):
        seqs[record.id] = str(record.seq)
    return seqs

def extract_domain_sequences(seq_file, domain_file, output_file):
    """Extract domain sequences based on HMMER coordinates"""
    
    # Load sequences
    sequences = load_sequences(seq_file)
    
    # Load domain coordinates
    with open(domain_file, 'r') as f:
        domains = json.load(f)
    
    # Look for HLH or Basic domains (these are the bHLH components)
    domain_seqs = []
    
    for seq_id, seq in sequences.items():
        if seq_id in domains:
            for domain in domains[seq_id]:
                # Match HLH or Basic domains
                if 'HLH' in domain['domain'] or 'Basic' in domain['domain']:
                    
                    start = domain['start'] - 1  # 0-indexed
                    end = domain['end']
                    
                    domain_seq = seq[start:end]
                    
                    domain_seqs.append({
                        'id': seq_id,
                        'domain': domain['domain'],
                        'start': domain['start'],
                        'end': domain['end'],
                        'sequence': domain_seq,
                        'evalue': domain['evalue']
                    })
    
    # Write to FASTA
    if domain_seqs:
        with open(output_file, 'w') as f:
            for entry in domain_seqs:
                f.write(f">{entry['id']}_{entry['domain']}_{entry['start']}-{entry['end']}\n")
                f.write(f"{entry['sequence']}\n")
        
        print(f"  ✓ Extracted {len(domain_seqs)} domain sequences")
    else:
        print(f"  ⚠ No domains found")
    
    return domain_seqs

print("\n" + "="*70)
print("Extracting Domain Sequences")
print("="*70)
print("")

print("OG0000000 (MYOD1/MYF5):")
og0_domains = extract_domain_sequences(
    '03_alignments/OG0000000_sequences.fasta',
    '05_domains/hmmer/OG0000000_parsed.json',
    '05_domains/hmmer/OG0000000_bHLH_domains.fasta'
)

print("")
print("OG0000001 (MYOG):")
og1_domains = extract_domain_sequences(
    '03_alignments/OG0000001_sequences.fasta',
    '05_domains/hmmer/OG0000001_parsed.json',
    '05_domains/hmmer/OG0000001_bHLH_domains.fasta'
)

print("")
print("✓ Domain extraction complete")
print("")

