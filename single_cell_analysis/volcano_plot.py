import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import sys

# Resolve the directory
try:
    SCRIPT_DIR = Path(__file__).resolve().parent
except NameError:
    SCRIPT_DIR = Path.cwd()

print(SCRIPT_DIR)

# Parameters
alpha = 0.05          # FDR threshold
log2fc_min = 0.5      # effect-size guard (log2FC threshold)
group_a = "Other"     # reference
group_b = "MYOD1+"    # case (MYOD1-positive cells)
csv_path = SCRIPT_DIR / Path("myod1_markers_wt.csv")
out_path = SCRIPT_DIR / f"volcano_{group_b}_vs_{group_a}_WT.png"
out_path_svg = SCRIPT_DIR / f"volcano_{group_b}_vs_{group_a}_WT.svg"

# Load DE results
df = pd.read_csv(csv_path)

# # Check required columns
# required = {"gene", "avg_log2FC", "p_val", "p_val_adj"}
# missing = required - set(df.columns)
# if missing:
#     raise ValueError(f"Input must contain columns: {', '.join(sorted(missing))}")

plot_df = df.copy()
plot_df = plot_df[plot_df['gene'] != 'MYOD1']

print(plot_df.head())


# Prepare plotting columns
eps = np.finfo(float).tiny  # avoid -log10(0)
plot_df["neglog10_p"] = -np.log10(np.maximum(plot_df["p_val_adj"].values, eps))  # raw p on y
plot_df["log2FC"] = plot_df["avg_log2FC"]


# Masks: significance (FDR) + side
sig = (plot_df["p_val_adj"] < alpha) & (plot_df["log2FC"].abs() >= log2fc_min)
left_sig  = sig & (plot_df["log2FC"] <= -log2fc_min)   # under-expressed in MYOD1+
right_sig = sig & (plot_df["log2FC"] >=  log2fc_min)   # over-expressed in MYOD1+
ns_mask   = ~(left_sig | right_sig)



n_left  = int(left_sig.sum())
n_right = int(right_sig.sum())
n_ns    = int(ns_mask.sum())

# Colors (more saturated)
COL_NS    = "#6f6f6f"   # grey
COL_LEFT  = "#2b8cbe"   # blue   (under)
COL_RIGHT = "#e45757"   # red    (over)
ALPHA_NS  = 0.6
ALPHA_SIG = 0.9
SIZE_NS   = 12
SIZE_SIG  = 14

# Plot
fig, ax = plt.subplots(figsize=(8, 6))

# Non-significant (grey)
ax.scatter(plot_df.loc[ns_mask, "log2FC"],
           plot_df.loc[ns_mask, "neglog10_p"],
           c=COL_NS, alpha=ALPHA_NS, s=SIZE_NS, edgecolors="none",
           label=f"Not significant (n={n_ns})")

# Significant left (Under-expressed in MYOD1+)
ax.scatter(plot_df.loc[left_sig, "log2FC"],
           plot_df.loc[left_sig, "neglog10_p"],
           c=COL_LEFT, alpha=ALPHA_SIG, s=SIZE_SIG, edgecolors="none",
           label=f"Under-expressed in {group_b} (n={n_left})")

# Significant right (Over-expressed in MYOD1+)
ax.scatter(plot_df.loc[right_sig, "log2FC"],
           plot_df.loc[right_sig, "neglog10_p"],
           c=COL_RIGHT, alpha=ALPHA_SIG, s=SIZE_SIG, edgecolors="none",
           label=f"Over-expressed in {group_b} (n={n_right})")

# Threshold guide lines (no legend entry for p-line)
guide_color = "black"
p_y = -np.log10(alpha)
ax.axhline(p_y, linestyle="--", linewidth=0.8, color=guide_color)  # no label
ax.axvline(log2fc_min,  linestyle="--", linewidth=0.8, color=guide_color)
ax.axvline(-log2fc_min, linestyle="--", linewidth=0.8, color=guide_color)

# Place "p = α" text just above the horizontal line near the right
x_min, x_max = ax.get_xlim()
y_min, y_max = ax.get_ylim()
y_offset = 0.02 * (y_max - y_min)
ax.text(x_max, p_y + y_offset, f"p = {alpha}",
        ha="right", va="bottom", fontsize=10, color=guide_color, clip_on=False)

# Labels
ax.set_xlabel(f"log2 Fold Change")
ax.set_ylabel("-log10 Adjusted P-value")
ax.set_title(f"Marker Genes in MYOD1+ Cells: Wild Type")

# Compact legend (only the three point groups)
leg = ax.legend(frameon=True, loc="upper left", markerscale=1.0)
for lh in leg.legend_handles:
    lh.set_alpha(1.0)

plt.tight_layout()
fig.savefig(out_path, dpi=600)
fig.savefig(out_path_svg, dpi=600)

print(f"Volcano plot saved to:\n  {out_path}\n  {out_path_svg}")
print(f"\nSummary:")
print(f"  Total genes: {len(plot_df)}")
print(f"  Not significant: {n_ns}")
print(f"  Under-expressed in {group_b}: {n_left}")
print(f"  Over-expressed in {group_b}: {n_right}")