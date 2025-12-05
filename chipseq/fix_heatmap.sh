#!/bin/bash

###############################################################################
# Fix and Convert Peak Heatmap to PNG
###############################################################################

cd ~/PGB/MYOD1_project/chipseq

echo "=========================================="
echo "Converting Peak Heatmap to PNG"
echo "=========================================="
echo ""
echo "Working directory: $(pwd)"
echo ""

# Check if ImageMagick is installed (for PDF → PNG conversion)
if ! command -v convert &> /dev/null; then
    echo "Installing ImageMagick for PDF conversion..."
    sudo apt-get update
    sudo apt-get install -y imagemagick
fi

echo "Step 1: Converting existing PDF to PNG..."

# Convert PDF to PNG with high resolution
convert -density 300 \
    09_chipseeker/peak_heatmap.pdf \
    09_chipseeker/peak_heatmap.png 2>/dev/null

if [ -f "09_chipseeker/peak_heatmap.png" ]; then
    echo "  ✓ PDF converted to PNG"
    echo "  Location: 09_chipseeker/peak_heatmap.png"
else
    echo "  ⚠ PDF conversion failed or PDF is blank"
    echo ""
    echo "Step 2: Regenerating heatmap from scratch..."
    
    # Regenerate the heatmap using R
    Rscript -e "
    library(ChIPseeker)
    library(TxDb.Mmusculus.UCSC.mm10.knownGene)
    
    # Load data
    txdb <- TxDb.Mmusculus.UCSC.mm10.knownGene
    peaks <- readPeakFile('06_peaks/MYOD1_peaks_peaks.narrowPeak')
    
    # Generate heatmap
    promoter <- getPromoters(TxDb=txdb, upstream=3000, downstream=3000)
    tagMatrix <- getTagMatrix(peaks, windows=promoter)
    
    # Save as PNG directly
    png('09_chipseeker/peak_heatmap.png', 
        width=2400, height=3000, res=300)
    tagHeatmap(tagMatrix)
    dev.off()
    
    cat('✓ Heatmap regenerated as PNG\n')
    "
fi

echo ""
echo "Step 3: Creating alternative average profile plot..."

# Create an average profile plot (often more informative anyway)
Rscript -e "
library(ChIPseeker)
library(TxDb.Mmusculus.UCSC.mm10.knownGene)

txdb <- TxDb.Mmusculus.UCSC.mm10.knownGene
peaks <- readPeakFile('06_peaks/MYOD1_peaks_peaks.narrowPeak')

promoter <- getPromoters(TxDb=txdb, upstream=3000, downstream=3000)
tagMatrix <- getTagMatrix(peaks, windows=promoter)

# Save average profile as PNG
png('09_chipseeker/peak_average_profile.png',
    width=3000, height=2400, res=300)
plotAvgProf(tagMatrix, xlim=c(-3000, 3000),
            xlab='Genomic Region (5\' -> 3\')',
            ylab='Read Count Frequency',
            main='MYOD1 Peak Enrichment Around TSS')
dev.off()

cat('✓ Average profile plot created\n')
"

echo ""
echo "=========================================="
echo "Complete!"
echo "=========================================="
echo ""
echo "Generated files:"
ls -lh 09_chipseeker/peak*.png 2>/dev/null || echo "  No PNG files found"
echo ""
echo "View in Windows:"
echo "  Navigate to: \\\\wsl.localhost\\Ubuntu\\home\\naidurev\\PGB\\MYOD1_project\\chipseq\\09_chipseeker\\"
echo "  Open: peak_heatmap.png"
echo "  Or: peak_average_profile.png"
echo ""
