#!/usr/bin/env python3

import sys
from collections import defaultdict

def parse_hmmer_domtblout(domtbl_file):
    """Parse HMMER domtblout format"""
    
    domains = defaultdict(list)
    
    with open(domtbl_file, 'r') as f:
        for line in f:
            if line.startswith('#'):
                continue
            
            parts = line.split()
            if len(parts) < 23:
                continue
            
            target_name = parts[0]  # Pfam domain
            query_name = parts[3]   # Sequence ID
            evalue = float(parts[6])
            score = float(parts[7])
            
            # Domain coordinates
            ali_from = int(parts[17])
            ali_to = int(parts[18])
            
            # Description (rest of line)
            desc = ' '.join(parts[22:])
            
            domains[query_name].append({
                'domain': target_name,
                'evalue': evalue,
                'score': score,
                'start': ali_from,
                'end': ali_to,
                'description': desc
            })
    
    return domains

def print_domain_summary(domains, orthogroup):
    """Print summary of domains found"""
    
    print(f"\n{'='*70}")
    print(f"Domain Summary for {orthogroup}")
    print('='*70)
    print("")
    
    # Count unique domains
    all_domains = set()
    for seq_domains in domains.values():
        for d in seq_domains:
            all_domains.add(d['domain'])
    
    print(f"Total sequences with domains: {len(domains)}")
    print(f"Unique domain types found: {len(all_domains)}")
    print("")
    
    # Domain frequency
    domain_counts = defaultdict(int)
    for seq_domains in domains.values():
        for d in seq_domains:
            domain_counts[d['domain']] += 1
    
    print("Most common domains:")
    for domain, count in sorted(domain_counts.items(), key=lambda x: -x[1])[:10]:
        print(f"  {domain}: {count} sequences")
    
    print("")

# Parse both orthogroups
print("\nParsing HMMER results...")

og0_domains = parse_hmmer_domtblout('05_domains/hmmer/OG0000000_domains.txt')
print_domain_summary(og0_domains, "OG0000000 (MYOD1/MYF5)")

og1_domains = parse_hmmer_domtblout('05_domains/hmmer/OG0000001_domains.txt')
print_domain_summary(og1_domains, "OG0000001 (MYOG)")

# Save parsed results
import json

with open('05_domains/hmmer/OG0000000_parsed.json', 'w') as f:
    json.dump(og0_domains, f, indent=2)

with open('05_domains/hmmer/OG0000001_parsed.json', 'w') as f:
    json.dump(og1_domains, f, indent=2)

print("\n✓ Parsed domain data saved to JSON files")
print("")

