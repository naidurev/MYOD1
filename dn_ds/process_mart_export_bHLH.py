import re

# Read bHLH Ensembl codes
with open('bHLH_ensembl_codes.txt', 'r') as file:
    lines = file.readlines()
    bHLH_ensembl_codes = []
    for line in lines:
        match = re.search(r'ENSG\d+', line)
        if match:
            bHLH_ensembl_codes.append(match.group())

print(len(bHLH_ensembl_codes))

filtered_lines = []

# Process mart export file
with open('mart_export_mouse.txt', 'r') as mart_file:
    for line in mart_file:
        parts = line.strip().split('\t')
        if len(parts) < 4:
            continue  # skip malformed lines

        code = parts[0]
        if code in bHLH_ensembl_codes:
            try:
                dn = float(parts[2])
                ds = float(parts[3])

                # Replace zeros with 0.00001
                if dn == 0.0:
                    dn = 0.00001
                if ds == 0.0:
                    ds = 0.00001

                ratio = dn / ds
                filtered_lines.append((code, ratio))

            except ValueError:
                continue  # skip lines with invalid numbers

# Save output
seen = set()  # store (code, ratio) pairs we've already written

with open('bHLH_dn_ds_values_mouse.txt', 'w') as out:
    for code, ratio in filtered_lines:
        pair = (code, round(ratio, 5))  # round to match the output format
        if pair not in seen:
            out.write(f"{code}\t{ratio:.5f}\n")
            seen.add(pair)

print(f"Number of matches found: {len(seen)}")

print("Results saved to bHLH_dn_ds_values_.txt")

