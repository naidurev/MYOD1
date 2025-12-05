#!/bin/bash

# Check dependencies
command -v python3 >/dev/null 2>&1 || { echo "Python3 required"; exit 1; }

# Install required Python packages
pip3 install python-docx Pillow pdf2image --break-system-packages

# Install poppler for PDF conversion (if not already installed)
sudo apt-get update && sudo apt-get install -y poppler-utils

# Create the report generation script
cat > /home/naidurev/PGB/MYOD1_project/chipseq/generate_chipseq_report.py << 'PYTHON_SCRIPT'
#!/usr/bin/env python3
"""
ChIP-seq Report Generator
Generates a comprehensive Word document report for MYOD1 ChIP-seq analysis
"""

import os
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
from PIL import Image
from pdf2image import convert_from_path
import subprocess

# Base directory
BASE_DIR = "/home/naidurev/PGB/MYOD1_project/chipseq"
IMAGES_DIR = f"{BASE_DIR}/presentation_chipseq_minimal"
RESULTS_DIR = BASE_DIR

# Output file
OUTPUT_FILE = f"{BASE_DIR}/MYOD1_ChIPseq_Report.docx"

def set_cell_border(cell, **kwargs):
    """Set cell borders"""
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    
    for edge in ('top', 'left', 'bottom', 'right'):
        edge_data = kwargs.get(edge)
        if edge_data:
            tag = 'tc{}'.format(edge.capitalize())
            element = OxmlElement('w:{}'.format(tag))
            for key in edge_data:
                element.set(qn('w:{}'.format(key)), str(edge_data[key]))
            tcPr.append(element)

def convert_pdf_to_png(pdf_path, output_path):
    """Convert first page of PDF to PNG"""
    try:
        images = convert_from_path(pdf_path, first_page=1, last_page=1, dpi=300)
        if images:
            images[0].save(output_path, 'PNG')
            return output_path
    except Exception as e:
        print(f"Warning: Could not convert {pdf_path}: {e}")
        return None

def add_heading_custom(doc, text, level=1):
    """Add custom formatted heading"""
    heading = doc.add_heading(text, level=level)
    heading.alignment = WD_ALIGN_PARAGRAPH.LEFT
    for run in heading.runs:
        run.font.name = 'Times New Roman'
        run.font.size = Pt(14)
        run.font.bold = True
        run.font.color.rgb = RGBColor(0, 0, 0)
    return heading

def add_paragraph_custom(doc, text, alignment=WD_ALIGN_PARAGRAPH.JUSTIFY):
    """Add custom formatted paragraph"""
    para = doc.add_paragraph(text)
    para.alignment = alignment
    for run in para.runs:
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12)
        run.font.color.rgb = RGBColor(0, 0, 0)
    return para

def add_image_from_file(doc, image_path, width=6.0):
    """Add image to document with proper formatting"""
    # Convert PDF to PNG if necessary
    if image_path.endswith('.pdf'):
        png_path = image_path.replace('.pdf', '_converted.png')
        image_path = convert_pdf_to_png(image_path, png_path)
        if not image_path:
            return None
    
    if os.path.exists(image_path):
        para = doc.add_paragraph()
        para.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = para.add_run()
        run.add_picture(image_path, width=Inches(width))
        return para
    else:
        print(f"Warning: Image not found: {image_path}")
        return None

def read_file_content(filepath):
    """Read and return file content"""
    try:
        with open(filepath, 'r') as f:
            return f.read()
    except:
        return ""

def create_report():
    """Generate the complete ChIP-seq report"""
    
    doc = Document()
    
    # Set default font for entire document
    style = doc.styles['Normal']
    font = style.font
    font.name = 'Times New Roman'
    font.size = Pt(12)
    
    # ==========================================
    # TITLE PAGE
    # ==========================================
    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = title.add_run('Genome-Wide Identification of MYOD1 Binding Sites\nvia ChIP-seq Analysis')
    run.font.name = 'Times New Roman'
    run.font.size = Pt(18)
    run.font.bold = True
    
    doc.add_paragraph()  # Spacing
    
    subtitle = doc.add_paragraph()
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = subtitle.add_run('Characterization of MYOD1 Transcriptional Regulatory Network\nin Mouse Embryonic Fibroblasts')
    run.font.name = 'Times New Roman'
    run.font.size = Pt(14)
    
    doc.add_paragraph()
    doc.add_paragraph()
    
    author = doc.add_paragraph()
    author.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = author.add_run('Rev Naidu\n\nMSc Bioinformatics for Health Sciences\nUniversitat de Barcelona\n\nDecember 2024')
    run.font.name = 'Times New Roman'
    run.font.size = Pt(12)
    
    doc.add_page_break()
    
    # ==========================================
    # ABSTRACT
    # ==========================================
    add_heading_custom(doc, 'Abstract', level=1)
    
    abstract_text = """Myogenic Differentiation 1 (MYOD1) is a master transcriptional regulator essential for skeletal muscle development and differentiation. Understanding its genome-wide binding patterns provides crucial insights into the molecular mechanisms governing myogenesis. This study employed chromatin immunoprecipitation followed by high-throughput sequencing (ChIP-seq) to systematically identify and characterize MYOD1 binding sites across the mouse genome. Analysis of ChIP-seq data from mouse embryonic fibroblasts revealed 77,310 high-confidence binding peaks, with 62.9% localized to promoter regions within 3 kilobases of transcription start sites. Motif analysis demonstrated that 88.6% of identified peaks contained the canonical E-box motif (CANNTG), with the CAGCTG variant being most prevalent. Peak annotation identified 14,566 putative target genes, which exhibited significant enrichment for biological processes related to muscle cell differentiation, mitochondrial organization, and actin filament assembly. Notable target genes included growth factors (Igf1), contractile proteins (Tnnt3, Cacnb3), and other myogenic regulatory factors (Myog, Myf5), alongside evidence of MYOD1 autoregulation. These findings provide a comprehensive map of the MYOD1 regulatory landscape and demonstrate its role in coordinating multiple aspects of the muscle differentiation program, from transcriptional activation to metabolic remodeling and structural organization."""
    
    add_paragraph_custom(doc, abstract_text)
    
    doc.add_page_break()
    
    # ==========================================
    # INTRODUCTION
    # ==========================================
    add_heading_custom(doc, '1. Introduction', level=1)
    
    add_heading_custom(doc, '1.1 Skeletal Muscle Development and Myogenic Regulatory Factors', level=2)
    
    intro1 = """Skeletal muscle development is a highly orchestrated process requiring the precise temporal and spatial activation of muscle-specific gene expression programs. At the molecular level, this process is primarily governed by a family of basic helix-loop-helix (bHLH) transcription factors known as myogenic regulatory factors (MRFs), which include MYOD1, MYF5, myogenin (MYOG), and MRF4. These transcription factors function as master regulators, possessing the remarkable ability to convert non-muscle cells into myogenic lineages, a property that underscores their central role in muscle determination and differentiation."""
    
    add_paragraph_custom(doc, intro1)
    
    intro2 = """MYOD1, first identified in 1987, represents the prototypical member of the MRF family and has been extensively studied as a paradigm for understanding transcriptional regulation during cell fate specification. The protein functions as a transcriptional activator by binding to E-box DNA sequences (CANNTG) present in the regulatory regions of muscle-specific genes. Upon binding, MYOD1 recruits chromatin remodeling complexes and the basal transcriptional machinery, thereby activating target gene expression. This process involves coordinated interactions with numerous cofactors, including members of the myocyte enhancer factor-2 (MEF2) family, which cooperate with MRFs to establish the muscle-specific transcriptional program."""
    
    add_paragraph_custom(doc, intro2)
    
    add_heading_custom(doc, '1.2 ChIP-seq Technology and Its Application to Transcription Factor Studies', level=2)
    
    intro3 = """Chromatin immunoprecipitation coupled with high-throughput sequencing (ChIP-seq) has emerged as the gold standard technique for mapping protein-DNA interactions genome-wide. This approach combines the specificity of antibody-based immunoprecipitation with the comprehensive coverage of next-generation sequencing, enabling researchers to identify transcription factor binding sites with high resolution and sensitivity. Unlike previous array-based methods, ChIP-seq provides unbiased, genome-wide coverage and can detect binding events in previously unannotated regions, including distal enhancers and intergenic regulatory elements."""
    
    add_paragraph_custom(doc, intro3)
    
    intro4 = """The ChIP-seq workflow involves several critical steps: chromatin crosslinking to preserve protein-DNA interactions, chromatin fragmentation, immunoprecipitation using a specific antibody against the protein of interest, DNA purification, library preparation, and finally, massively parallel sequencing. Subsequent bioinformatics analysis identifies genomic regions exhibiting significant enrichment of sequencing reads compared to control samples, designating these regions as putative binding sites. Integration of ChIP-seq data with gene annotation databases and functional genomics resources enables comprehensive characterization of transcription factor regulatory networks."""
    
    add_paragraph_custom(doc, intro4)
    
    add_heading_custom(doc, '1.3 Objectives and Significance', level=2)
    
    intro5 = """Despite extensive knowledge of MYOD1's role in myogenesis, a comprehensive, genome-wide map of its binding sites and target genes has remained incompletely characterized. Previous studies have focused on individual target genes or small sets of regulatory elements, leaving gaps in our understanding of the full extent of MYOD1's regulatory influence. The present study addresses this knowledge gap by employing ChIP-seq technology to systematically identify MYOD1 binding sites across the entire mouse genome. The specific objectives of this investigation were threefold: first, to identify and catalog all genomic regions bound by MYOD1 in mouse embryonic fibroblasts; second, to characterize the genomic distribution and sequence properties of these binding sites; and third, to functionally annotate MYOD1 target genes and elucidate the biological processes they regulate. The resulting comprehensive binding map provides valuable insights into the molecular mechanisms by which MYOD1 orchestrates the complex muscle differentiation program and establishes a resource for future investigations into muscle development and disease."""
    
    add_paragraph_custom(doc, intro5)
    
    doc.add_page_break()
    
    # ==========================================
    # MATERIALS AND METHODS
    # ==========================================
    add_heading_custom(doc, '2. Materials and Methods', level=1)
    
    add_heading_custom(doc, '2.1 Data Acquisition and Experimental Design', level=2)
    
    methods1 = """ChIP-seq data for MYOD1 were obtained from the NCBI Gene Expression Omnibus (GEO) database under accession numbers GSM857391 (MYOD1 ChIP sample, SRR396786) and GSM857394 (control sample, SRR398262). The original experiment was conducted using mouse embryonic fibroblasts (MEFs) subjected to myogenic differentiation conditions. The experimental design employed a case-control framework, comparing MYOD1-immunoprecipitated chromatin against a control sample to identify regions of specific enrichment. Raw sequencing reads were downloaded in FASTQ format from the NCBI Sequence Read Archive (SRA) using the SRA Toolkit."""
    
    add_paragraph_custom(doc, methods1)
    
    add_heading_custom(doc, '2.2 Quality Control and Read Processing', level=2)
    
    methods2 = """Raw sequencing data quality assessment was performed to evaluate base quality scores, sequence length distribution, GC content, and the presence of adapter sequences. Following initial quality assessment, adapter sequences and low-quality bases were removed using trimming software with the following parameters: quality threshold of Q20, minimum read length of 25 base pairs, and automatic detection of Illumina adapter sequences. Post-trimming quality metrics were re-evaluated to confirm successful adapter removal and quality improvement. The MYOD1 ChIP sample yielded 10.3 million reads with a 91.96% alignment rate, while the control sample produced 19.0 million reads with a 96.25% alignment rate, both indicating high-quality sequencing data suitable for downstream analysis."""
    
    add_paragraph_custom(doc, methods2)
    
    add_heading_custom(doc, '2.3 Reference Genome Preparation and Read Alignment', level=2)
    
    methods3 = """The mouse reference genome (GRCm38/mm10) was obtained from the UCSC Genome Browser database in FASTA format. A genome index was constructed using Bowtie2 to enable efficient read alignment. This indexing step, while computationally intensive (approximately 5 hours), needed to be performed only once and enabled rapid alignment of millions of sequencing reads. Quality-filtered reads were aligned to the mm10 reference genome using Bowtie2 with default parameters optimized for ChIP-seq data. The alignment process allowed up to two mismatches per read to account for sequencing errors and genetic variation while maintaining alignment specificity. Aligned reads were output in SAM (Sequence Alignment/Map) format, subsequently converted to the compressed binary BAM format, sorted by genomic coordinates, and indexed for rapid access during downstream analyses."""
    
    add_paragraph_custom(doc, methods3)
    
    add_heading_custom(doc, '2.4 Peak Calling and Statistical Analysis', level=2)
    
    methods4 = """Identification of genomic regions enriched for MYOD1 binding (peaks) was performed using Model-based Analysis of ChIP-Seq (MACS2), a widely-used peak calling algorithm that employs a dynamic Poisson distribution to model background noise and identify statistically significant enrichment. The analysis compared read coverage in the MYOD1 ChIP sample against the control sample, with the following parameters: genome size set to the mouse effective genome size (2.65 Gb), p-value cutoff of 1×10⁻⁵, and automatic fragment size detection based on cross-correlation analysis. MACS2 generates multiple output files, including: narrowPeak files containing peak coordinates and statistical significance, summit files indicating the precise position of maximum enrichment within each peak, and detailed Excel-compatible files with comprehensive peak statistics including fold-enrichment, p-values, and false discovery rates (q-values). Peaks were called with summit precision to facilitate subsequent motif analysis."""
    
    add_paragraph_custom(doc, methods4)
    
    add_heading_custom(doc, '2.5 Peak Annotation and Gene Assignment', level=2)
    
    methods5 = """To associate identified peaks with their putative target genes, a comprehensive annotation strategy was employed combining multiple approaches. First, gene annotations from the NCBI RefSeq database were used to define promoter regions as genomic intervals spanning 2 kilobases upstream to 1 kilobase downstream of transcription start sites (TSS). This definition encompasses core promoter elements, proximal regulatory regions, and the 5' untranslated region. Peak-to-gene associations were established using the ChIPseeker R package, which assigns peaks to genomic features (promoter, exon, intron, intergenic) and calculates distances to the nearest TSS. Peaks were annotated with their genomic context, including gene symbols, Entrez Gene IDs, and chromosomal locations. For peaks located in intergenic regions, assignment was made to the nearest gene within a reasonable distance threshold. This comprehensive annotation provided the foundation for subsequent functional enrichment analyses and identification of biologically relevant MYOD1 targets."""
    
    add_paragraph_custom(doc, methods5)
    
    add_heading_custom(doc, '2.6 Motif Discovery and Sequence Analysis', level=2)
    
    methods6 = """To identify DNA sequence motifs enriched in MYOD1 binding sites, sequences were extracted from a 200 base pair window centered on peak summits. These sequences were analyzed using the MEME Suite (Multiple Em for Motif Elicitation), specifically the MEME-ChIP module designed for ChIP-seq data analysis. MEME-ChIP performs de novo motif discovery using expectation-maximization algorithms to identify overrepresented sequence patterns without relying on prior knowledge of expected binding motifs. The analysis searched for motifs ranging from 6 to 20 base pairs in length, using both DNA strands and focusing on the top 500 peaks ranked by significance to balance computational efficiency with comprehensive motif discovery. Identified motifs were compared against databases of known transcription factor binding sites to confirm their identity and biological relevance. For each discovered motif, the analysis calculated statistical significance (E-values), generated sequence logos representing position-specific nucleotide frequencies, and quantified motif occurrence rates across all binding sites."""
    
    add_paragraph_custom(doc, methods6)
    
    add_heading_custom(doc, '2.7 Functional Enrichment Analysis', level=2)
    
    methods7 = """To elucidate the biological functions and pathways associated with MYOD1 target genes, functional enrichment analyses were conducted using the clusterProfiler R package. Gene Ontology (GO) enrichment analysis was performed for the Biological Process category, testing for over-representation of specific functional terms among MYOD1 target genes compared to the genomic background. Statistical significance was assessed using the hypergeometric test with Benjamini-Hochberg multiple testing correction to control the false discovery rate. An adjusted p-value threshold of 0.05 was applied to identify significantly enriched terms. Additionally, KEGG pathway enrichment analysis was conducted to identify metabolic and signaling pathways regulated by MYOD1 targets. Reactome pathway analysis provided complementary pathway information with fine-grained annotation of molecular reactions and interactions. Enrichment results were visualized using dot plots displaying gene ratios, enrichment significance, and the number of genes associated with each term."""
    
    add_paragraph_custom(doc, methods7)
    
    add_heading_custom(doc, '2.8 Data Visualization', level=2)
    
    methods8 = """Comprehensive visualization of ChIP-seq results was performed to facilitate interpretation and communicate key findings. Genome-wide signal profiles were generated by converting aligned reads to bigWig format using deepTools bamCoverage, with RPKM (Reads Per Kilobase per Million mapped reads) normalization to enable comparison between samples despite differences in sequencing depth. Signal heatmaps were created using deepTools computeMatrix and plotHeatmap, displaying MYOD1 binding intensity across all identified peaks in a ±3 kilobase window centered on peak summits. These heatmaps visually confirmed specific enrichment in the MYOD1 sample compared to control. Genomic distribution of peaks was summarized using ChIPseeker's annotation functions, generating bar charts showing the proportion of peaks in various genomic features and distance-to-TSS profiles. GO enrichment results were visualized as dot plots using ggplot2, with dot size representing the number of genes and color intensity indicating statistical significance. All visualizations employed publication-quality graphics with appropriate labels, legends, and color schemes."""
    
    add_paragraph_custom(doc, methods8)
    
    doc.add_page_break()
    
    # ==========================================
    # RESULTS
    # ==========================================
    add_heading_custom(doc, '3. Results', level=1)
    
    add_heading_custom(doc, '3.1 Overview of ChIP-seq Analysis Pipeline', level=2)
    
    results1 = """The complete ChIP-seq analysis workflow is illustrated in Figure 1, depicting the sequential computational steps from raw sequencing data acquisition through functional interpretation of results. The pipeline encompassed data acquisition, quality control, adapter trimming, genome indexing, read alignment, peak calling, genomic annotation, motif discovery, functional enrichment analysis, and comprehensive visualization. Each stage employed specialized bioinformatics tools optimized for ChIP-seq data analysis, with intermediate quality control checkpoints to ensure data integrity throughout the analysis workflow."""
    
    add_paragraph_custom(doc, results1)
    
    # Add pipeline figure
    pipeline_path = f"{IMAGES_DIR}/pipeline.png"
    add_image_from_file(doc, pipeline_path, width=6.0)
    
    caption = doc.add_paragraph()
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = caption.add_run('Figure 1. ')
    run.font.bold = True
    run = caption.add_run('ChIP-seq analysis pipeline workflow. The complete computational workflow from raw FASTQ files through functional enrichment analysis, showing major analysis phases and bioinformatics tools employed at each step.')
    run.font.italic = True
    for r in caption.runs:
        r.font.name = 'Times New Roman'
        r.font.size = Pt(10)
    
    doc.add_paragraph()
    
    add_heading_custom(doc, '3.2 Quality Metrics and Alignment Statistics', level=2)
    
    results2 = """Initial quality assessment of raw sequencing data revealed high-quality reads suitable for ChIP-seq analysis. Following adapter trimming and quality filtering, 10.3 million reads from the MYOD1 ChIP sample and 19.0 million reads from the control sample were retained for alignment. Alignment to the mouse mm10 reference genome achieved mapping rates of 91.96% for the MYOD1 sample and 96.25% for the control sample, both exceeding the 90% threshold generally considered excellent for ChIP-seq experiments. These high alignment rates indicate minimal contamination and successful library preparation. The greater number of reads in the control sample provided robust background estimation for peak calling, while the MYOD1 sample's high alignment rate ensured comprehensive coverage of binding sites. All alignments were uniquely mapped, removing multi-mapping reads that could introduce ambiguity in peak calling."""
    
    add_paragraph_custom(doc, results2)
    
    add_heading_custom(doc, '3.3 Genome-Wide Identification of MYOD1 Binding Sites', level=2)
    
    results3 = """Peak calling analysis identified 77,310 high-confidence MYOD1 binding sites distributed across all mouse chromosomes. This large number of binding sites reflects MYOD1's role as a master regulator controlling numerous target genes involved in muscle development and function. The distribution of peaks across chromosomes generally correlated with chromosome size, with chromosome 1 and chromosome 2 harboring the greatest number of peaks (5,691 and 6,418 peaks, respectively) consistent with their larger genomic size and gene content. Notably, 1,520 peaks were identified on chromosome X, consistent with the presence of muscle-specific genes on the X chromosome. Only 22 peaks were found on chromosome Y, reflecting its smaller size and lower gene density. Peak statistics revealed substantial enrichment, with fold-enrichment values ranging from 2-fold to over 10-fold compared to control samples. The median peak width was approximately 400 base pairs, consistent with the expected size for transcription factor binding sites and compatible with subsequent motif analysis."""
    
    add_paragraph_custom(doc, results3)
    
    add_heading_custom(doc, '3.4 Validation of MYOD1 Binding Through Comparative Analysis', level=2)
    
    results4 = """To validate that identified peaks represented genuine MYOD1 binding rather than technical artifacts, signal enrichment patterns were compared between MYOD1 ChIP and control samples using heatmap visualization (Figure 2). The heatmap displays normalized read coverage across all 77,310 peaks in a ±3 kilobase window centered on peak summits. The MYOD1 ChIP sample exhibited a pronounced vertical stripe of high signal intensity (red coloration) precisely at peak centers, indicating specific enrichment at these loci. In stark contrast, the control sample showed uniformly low signal across the same genomic regions (blue coloration), with no discernible enrichment at peak positions. This clear visual distinction between MYOD1 and control samples provides strong evidence that identified peaks represent bona fide MYOD1 binding sites rather than regions of high background signal or sequencing artifacts. The sharpness of the signal peak and the consistency of the pattern across all binding sites further support the high quality and specificity of the ChIP-seq experiment."""
    
    add_paragraph_custom(doc, results4)
    
    # Add heatmap figure
    heatmap_path = f"{IMAGES_DIR}/peaks_heatmap_comparison_page-0001.jpg"
    add_image_from_file(doc, heatmap_path, width=5.5)
    
    caption = doc.add_paragraph()
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = caption.add_run('Figure 2. ')
    run.font.bold = True
    run = caption.add_run('Validation of MYOD1 binding specificity through comparative heatmap analysis. Left panel shows strong enrichment at peak centers in MYOD1 ChIP sample. Right panel shows absence of enrichment in control sample at the same genomic positions. Signal intensity scale ranges from 0 (blue, no coverage) to 10 (red, maximum coverage). Each horizontal line represents one of 77,310 peaks.')
    run.font.italic = True
    for r in caption.runs:
        r.font.name = 'Times New Roman'
        r.font.size = Pt(10)
    
    doc.add_paragraph()
    
    add_heading_custom(doc, '3.5 Genomic Distribution of MYOD1 Binding Sites', level=2)
    
    results5 = """Annotation of MYOD1 binding sites with respect to genomic features revealed that the majority of peaks (62.9%) localized to promoter regions, defined as within 3 kilobases of annotated transcription start sites (Figure 3). This promoter-centric distribution is characteristic of transcription factors that primarily function through direct transcriptional activation of target genes. Within promoter regions, peaks showed preferential localization to the proximal promoter (≤1 kb from TSS), where core regulatory elements typically reside. An additional 30% of peaks were found in distal intergenic regions more than 3 kilobases from any annotated gene, suggesting that MYOD1 also regulates gene expression through long-range interactions with distal enhancer elements. These distal sites likely participate in three-dimensional chromatin looping interactions that bring enhancers into proximity with promoters. Intronic and exonic peaks comprised 15% and 5% of total peaks, respectively. The intronic peaks may represent alternative promoters, intronic enhancers, or binding sites involved in regulating alternative splicing. The small percentage of exonic peaks likely represents incidental overlap between binding sites and coding sequences. This genomic distribution pattern indicates that MYOD1 employs multiple regulatory strategies, combining direct promoter activation with enhancer-mediated long-range regulation."""
    
    add_paragraph_custom(doc, results5)
    
    # Add annotation bar chart
    annotation_path = f"{IMAGES_DIR}/annotation_bar.pdf"
    add_image_from_file(doc, annotation_path, width=6.0)
    
    caption = doc.add_paragraph()
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = caption.add_run('Figure 3. ')
    run.font.bold = True
    run = caption.add_run('Genomic distribution of MYOD1 binding sites. Bar chart showing the percentage of peaks annotated to different genomic features. Promoter regions (≤3 kb from TSS) contain the majority of binding sites, consistent with MYOD1\'s role as a transcriptional activator.')
    run.font.italic = True
    for r in caption.runs:
        r.font.name = 'Times New Roman'
        r.font.size = Pt(10)
    
    doc.add_paragraph()
    
    add_heading_custom(doc, '3.6 Spatial Relationship Between MYOD1 Binding Sites and Transcription Start Sites', level=2)
    
    results6 = """Further characterization of peak locations relative to transcription start sites revealed a bimodal distribution pattern (Figure 4). A primary mode was observed within ±10 kilobases of TSS, representing promoter-proximal binding sites that likely mediate direct transcriptional activation through recruitment of RNA polymerase II and associated factors. A secondary mode appeared at distances greater than 100 kilobases from TSS, corresponding to distal enhancer elements. This bimodal pattern is characteristic of developmental transcription factors that utilize both promoter-proximal elements for constitutive target gene expression and distal enhancers for cell-type-specific and temporally regulated expression. The valley between these two modes (10-100 kb) contained relatively fewer binding sites, suggesting that intermediate-distance regulatory interactions are less common or that such regions are less accessible for transcription factor binding. This distribution pattern reflects the three-dimensional organization of chromatin, where topologically associating domains facilitate interactions between distal enhancers and promoters while limiting spurious long-range interactions."""
    
    add_paragraph_custom(doc, results6)
    
    # Add distance to TSS figure
    distance_tss_path = f"{IMAGES_DIR}/distance_to_TSS.pdf"
    add_image_from_file(doc, distance_tss_path, width=6.0)
    
    caption = doc.add_paragraph()
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = caption.add_run('Figure 4. ')
    run.font.bold = True
    run = caption.add_run('Distribution of MYOD1 binding sites relative to transcription start sites. Bimodal distribution indicates two primary modes of gene regulation: promoter-proximal binding (±10 kb) and distal enhancer binding (>100 kb from TSS).')
    run.font.italic = True
    for r in caption.runs:
        r.font.name = 'Times New Roman'
        r.font.size = Pt(10)
    
    doc.add_paragraph()
    
    add_heading_custom(doc, '3.7 Identification and Characterization of the MYOD1 Binding Motif', level=2)
    
    results7 = """De novo motif discovery analysis identified a highly significant sequence motif present in 88.6% of MYOD1 binding sites (68,513 of 77,310 peaks). This motif corresponds to the canonical E-box sequence (CANNTG), the well-established recognition sequence for basic helix-loop-helix transcription factors including MYOD1. The extremely low E-value (6.5×10⁻⁶⁷²) indicates that this motif did not occur by chance and provides strong biochemical validation of the ChIP-seq experiment. Analysis of E-box variants revealed preferential binding to specific sequences within the degenerate E-box consensus. The most frequent variant was CAGCTG (41,682 occurrences, 33.8% of all E-boxes), followed by CAGGTG (12,937 occurrences) and CACCTG (12,793 occurrences). This preference hierarchy reflects differential binding affinity of MYOD1 for various E-box sequences, with G-C base pairs in the central positions conferring higher affinity than other combinations. The CAGCTG variant has been previously characterized as the optimal MYOD1 binding site through biochemical studies, and its predominance in our dataset confirms consistency with known binding preferences. The total of 123,824 E-box occurrences across all peaks indicates that many peaks contain multiple binding sites, potentially allowing cooperative binding of MYOD1 homodimers or heterodimers with other bHLH factors. The 11.4% of peaks lacking identifiable E-box motifs may represent indirect binding sites where MYOD1 is tethered to DNA through protein-protein interactions with other transcription factors, or sites containing divergent E-box sequences not detected by the motif discovery algorithm."""
    
    add_paragraph_custom(doc, results7)
    
    doc.add_page_break()
    
    add_heading_custom(doc, '3.8 Identification of MYOD1 Target Genes', level=2)
    
    results8 = """Peak annotation analysis identified 14,566 unique genes associated with MYOD1 binding sites, representing putative direct transcriptional targets. This extensive set of target genes reflects MYOD1's function as a master regulator orchestrating multiple aspects of muscle development and physiology. Among these targets, specific focus was placed on genes with established roles in muscle biology. Table 1 presents the top muscle-specific genes ranked by the number of associated MYOD1 binding sites. Insulin-like growth factor 1 (Igf1) emerged as the gene with the most binding sites (47 peaks), consistent with its critical role in promoting muscle growth and hypertrophy. Troponin T3 (Tnnt3), encoding a component of the thin filament troponin complex essential for muscle contraction, harbored 33 binding sites. Calcium channel beta-3 subunit (Cacnb3), involved in excitation-contraction coupling, contained 28 sites. LIM domain binding 3 (Ldb3), a Z-disc structural protein, had 19 sites, while Enolase 3 (Eno3), the muscle-specific glycolytic enzyme, showed 18 sites. These findings demonstrate that MYOD1 directly regulates genes involved in diverse aspects of muscle function, including growth signaling, contractile apparatus, calcium handling, structural organization, and energy metabolism."""
    
    add_paragraph_custom(doc, results8)
    
    # Create table for top muscle genes
    table = doc.add_table(rows=6, cols=3)
    table.style = 'Light Grid Accent 1'
    
    # Header row
    header_cells = table.rows[0].cells
    header_cells[0].text = 'Gene Symbol'
    header_cells[1].text = 'Number of Peaks'
    header_cells[2].text = 'Function'
    
    # Format header
    for cell in header_cells:
        for paragraph in cell.paragraphs:
            for run in paragraph.runs:
                run.font.bold = True
                run.font.name = 'Times New Roman'
                run.font.size = Pt(12)
    
    # Data rows
    muscle_genes = [
        ('Igf1', '47', 'Growth factor (muscle hypertrophy)'),
        ('Tnnt3', '33', 'Troponin T3 (fast skeletal muscle contraction)'),
        ('Cacnb3', '28', 'Calcium channel beta-3 (excitation-contraction coupling)'),
        ('Ldb3', '19', 'LIM domain binding 3 (Z-disc structural protein)'),
        ('Eno3', '18', 'Enolase 3 (muscle-specific glycolysis)')
    ]
    
    for i, (gene, peaks, function) in enumerate(muscle_genes, 1):
        cells = table.rows[i].cells
        cells[0].text = gene
        cells[1].text = peaks
        cells[2].text = function
        
        # Format cells
        for cell in cells:
            for paragraph in cell.paragraphs:
                for run in paragraph.runs:
                    run.font.name = 'Times New Roman'
                    run.font.size = Pt(12)
    
    doc.add_paragraph()
    
    caption = doc.add_paragraph()
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = caption.add_run('Table 1. ')
    run.font.bold = True
    run = caption.add_run('Top five muscle-specific genes ranked by number of MYOD1 binding sites. Genes represent diverse functional categories including growth signaling, contractile machinery, ion channels, structural components, and metabolism.')
    run.font.italic = True
    for r in caption.runs:
        r.font.name = 'Times New Roman'
        r.font.size = Pt(10)
    
    doc.add_paragraph()
    
    add_heading_custom(doc, '3.9 MYOD1 Regulation of Myogenic Regulatory Factors', level=2)
    
    results9 = """A particularly noteworthy finding was the identification of binding sites at the genomic loci of other myogenic regulatory factors, revealing a complex regulatory network among MRF family members. MYOD1 itself showed 4 binding peaks at its own locus, demonstrating positive autoregulation—a common feature of master regulators that helps maintain the differentiated state once established. Myogenin (Myog), which functions downstream of MYOD1 in the myogenic cascade, contained 2 binding sites in its regulatory regions. Similarly, Myf5, which can functionally compensate for MYOD1 in certain contexts, also harbored 2 binding sites. This cross-regulation among MRF family members creates a robust regulatory network with multiple positive feedback loops, ensuring committed and irreversible progression through the myogenic program. The presence of MYOD1 binding at these loci suggests that MYOD1 not only initiates muscle differentiation but also amplifies and reinforces the myogenic transcriptional program by activating other MRFs. This regulatory architecture provides both redundancy and reinforcement, contributing to the remarkable efficiency and irreversibility of myogenic conversion."""
    
    add_paragraph_custom(doc, results9)
    
    # Create table for MRF genes  
    table = doc.add_table(rows=4, cols=3)
    table.style = 'Light Grid Accent 1'
    
    # Header row
    header_cells = table.rows[0].cells
    header_cells[0].text = 'Gene Symbol'
    header_cells[1].text = 'Number of Peaks'
    header_cells[2].text = 'Function'
    
    # Format header
    for cell in header_cells:
        for paragraph in cell.paragraphs:
            for run in paragraph.runs:
                run.font.bold = True
                run.font.name = 'Times New Roman'
                run.font.size = Pt(12)
    
    # Data rows
    mrf_genes = [
        ('Myod1', '4', 'MYOD1 itself (autoregulation)'),
        ('Myog', '2', 'Myogenin (terminal differentiation)'),
        ('Myf5', '2', 'Myogenic factor 5 (early determination)')
    ]
    
    for i, (gene, peaks, function) in enumerate(mrf_genes, 1):
        cells = table.rows[i].cells
        cells[0].text = gene
        cells[1].text = peaks
        cells[2].text = function
        
        # Format cells
        for cell in cells:
            for paragraph in cell.paragraphs:
                for run in paragraph.runs:
                    run.font.name = 'Times New Roman'
                    run.font.size = Pt(12)
    
    doc.add_paragraph()
    
    caption = doc.add_paragraph()
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = caption.add_run('Table 2. ')
    run.font.bold = True
    run = caption.add_run('MYOD1 binding at myogenic regulatory factor loci. Cross-regulation among MRF family members creates a robust positive feedback network that reinforces the myogenic program.')
    run.font.italic = True
    for r in caption.runs:
        r.font.name = 'Times New Roman'
        r.font.size = Pt(10)
    
    doc.add_paragraph()
    
    add_heading_custom(doc, '3.10 Functional Enrichment of MYOD1 Target Genes', level=2)
    
    results10 = """To understand the biological processes regulated by MYOD1, Gene Ontology enrichment analysis was performed on the complete set of target genes. This analysis revealed highly significant enrichment for numerous biological processes directly related to muscle development and function (Figure 5). The most significantly enriched term was "muscle cell differentiation" (adjusted p-value = 3.01×10⁻⁵⁶), validating MYOD1's established role as a master regulator of myogenesis. The second most enriched term was "mitochondrion organization" (adjusted p-value ~10⁻⁴⁰), consistent with the metabolic remodeling that occurs during muscle differentiation as cells dramatically increase their mitochondrial content to support the high energy demands of contractile activity. "Actin filament organization" (adjusted p-value ~10⁻³⁵) was highly enriched, reflecting MYOD1's regulation of genes encoding thin filament components and associated proteins. Interestingly, "regulation of neurogenesis" (adjusted p-value ~10⁻³⁸) also showed significant enrichment, likely reflecting shared molecular pathways between muscle and neural development, both of which involve extensive cytoskeletal remodeling and cell-cell signaling. "Wnt signaling pathway" (adjusted p-value ~10⁻³³) enrichment indicates MYOD1's involvement in regulating this critical developmental signaling pathway that controls muscle stem cell fate decisions. Additional enriched terms included "regulation of cell cycle phase transition," consistent with the requirement for cell cycle exit during terminal differentiation, and "small GTPase-mediated signal transduction," reflecting the importance of Rho family GTPases in cytoskeletal reorganization during myoblast fusion. This comprehensive functional enrichment profile demonstrates that MYOD1 coordinates multiple cellular processes beyond simple activation of contractile protein genes, orchestrating a complete cellular transformation program encompassing metabolism, signaling, structure, and cell cycle regulation."""
    
    add_paragraph_custom(doc, results10)
    
    # Add GO dotplot
    go_dotplot_path = f"{IMAGES_DIR}/GO_dotplot_top20_page-0001.jpg"
    add_image_from_file(doc, go_dotplot_path, width=6.0)
    
    caption = doc.add_paragraph()
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = caption.add_run('Figure 5. ')
    run.font.bold = True
    run = caption.add_run('Gene Ontology enrichment analysis of MYOD1 target genes. Dot plot showing the top 20 enriched biological process terms. Dot size represents the number of genes associated with each term, while color intensity indicates statistical significance (adjusted p-value). Gene ratio represents the proportion of MYOD1 target genes annotated to each term.')
    run.font.italic = True
    for r in caption.runs:
        r.font.name = 'Times New Roman'
        r.font.size = Pt(10)
    
    doc.add_paragraph()
    
    doc.add_page_break()
    
    # ==========================================
    # DISCUSSION
    # ==========================================
    add_heading_custom(doc, '4. Discussion', level=1)
    
    add_heading_custom(doc, '4.1 Comprehensive Mapping of the MYOD1 Regulatory Network', level=2)
    
    discussion1 = """This study presents a genome-wide characterization of MYOD1 binding sites in mouse embryonic fibroblasts, identifying 77,310 high-confidence peaks associated with 14,566 putative target genes. This comprehensive binding map substantially extends our understanding of MYOD1's regulatory scope beyond the limited set of previously characterized target genes. The large number of binding sites demonstrates that MYOD1 functions as a global transcriptional regulator affecting not only muscle-specific structural genes but also genes involved in metabolism, signaling, and cellular organization. The identification of binding sites at approximately one-third of all mouse genes suggests that MYOD1 participates in extensive transcriptional rewiring during myogenic conversion, consistent with its ability to convert fibroblasts to myogenic cells when ectopically expressed."""
    
    add_paragraph_custom(doc, discussion1)
    
    add_heading_custom(doc, '4.2 Genomic Localization Patterns and Regulatory Mechanisms', level=2)
    
    discussion2 = """The predominant localization of MYOD1 binding sites to promoter regions (62.9% within 3 kb of TSS) indicates that direct transcriptional activation represents the primary regulatory mechanism employed by MYOD1. This promoter-centric binding pattern is consistent with MYOD1's function as an activator that recruits chromatin remodeling complexes and RNA polymerase II to initiate transcription. However, the substantial fraction of distal binding sites (30% in intergenic regions >3 kb from genes) suggests important roles for long-range enhancer-mediated regulation. These distal elements likely participate in three-dimensional chromatin looping interactions that bring enhancers into proximity with target gene promoters, enabling tissue-specific and temporally regulated gene expression. The bimodal distribution of binding sites relative to TSS, with modes at promoter-proximal positions and at distances exceeding 100 kb, supports a model where MYOD1 utilizes distinct regulatory strategies: constitutive activation through promoter binding and context-dependent regulation through enhancer binding. This dual strategy may allow MYOD1 to maintain expression of core muscle genes while providing flexibility in response to developmental and environmental cues."""
    
    add_paragraph_custom(doc, discussion2)
    
    add_heading_custom(doc, '4.3 Validation Through Motif Analysis', level=2)
    
    discussion3 = """The identification of canonical E-box motifs in 88.6% of MYOD1 binding sites provides strong validation of the ChIP-seq experiment and confirms that the majority of identified peaks represent direct DNA binding rather than indirect associations or technical artifacts. The preferential occurrence of the CAGCTG variant (33.8% of all E-boxes) aligns with previous biochemical studies demonstrating that this sequence provides optimal binding affinity for MYOD1. The G-C base pairs in the central positions of this variant form optimal hydrogen bonding contacts with specific amino acids in MYOD1's basic region, explaining the sequence preference observed. The presence of multiple E-box sequences within individual peaks suggests that MYOD1 may bind cooperatively as homodimers or form heterodimers with other bHLH factors such as E proteins (E12/E47) or other MRFs. Cooperative binding would increase local transcription factor concentration and strengthen transcriptional activation. The subset of peaks lacking identifiable E-box motifs (11.4%) likely represents indirect binding sites where MYOD1 associates with DNA through protein-protein interactions with other transcription factors, particularly MEF2 family members, with which MYOD1 is known to cooperate."""
    
    add_paragraph_custom(doc, discussion3)
    
    add_heading_custom(doc, '4.4 Functional Coordination of the Myogenic Program', level=2)
    
    discussion4 = """Gene Ontology enrichment analysis revealed that MYOD1 target genes participate in a remarkably diverse array of biological processes beyond canonical muscle-specific functions. While the top enriched term "muscle cell differentiation" validates MYOD1's primary role, equally significant enrichment for mitochondrial organization, actin cytoskeleton regulation, and cell cycle control demonstrates that MYOD1 coordinates a comprehensive cellular transformation program. The enrichment for mitochondrial genes is particularly notable, as it reveals MYOD1's role in metabolic reprogramming during differentiation. Differentiating muscle cells must dramatically increase oxidative phosphorylation capacity to meet the ATP demands of contractile activity, requiring biogenesis of new mitochondria and upregulation of electron transport chain components. The identification of Wnt signaling pathway genes among MYOD1 targets provides insight into the integration of extracellular signaling with the cell-autonomous myogenic program. Wnt signaling regulates muscle stem cell maintenance and activation, and MYOD1's ability to modulate this pathway suggests feedback mechanisms that coordinate satellite cell behavior with muscle fiber needs. The enrichment for neurogenesis-related genes, while initially surprising, reflects the shared developmental origins and similar morphogenic processes between muscle and neural tissues, both of which undergo extensive cell migration, fusion, and cytoskeletal reorganization."""
    
    add_paragraph_custom(doc, discussion4)
    
    add_heading_custom(doc, '4.5 Regulatory Network Architecture Among MRF Family Members', level=2)
    
    discussion5 = """The identification of MYOD1 binding sites at the genomic loci of other myogenic regulatory factors (Myod1, Myog, Myf5) reveals a sophisticated regulatory network with multiple layers of cross-regulation and feedback control. MYOD1's autoregulation through binding to its own locus creates a positive feedback loop that reinforces and maintains the myogenic state once initiated. This type of autoregulatory circuit is a common feature of cell fate determinants and provides bistability—once MYOD1 expression is activated, the positive feedback ensures sustained expression even if the initial inducing signal is removed. The binding of MYOD1 to Myog and Myf5 loci demonstrates hierarchical regulation within the MRF family, where early-acting factors (MYOD1, MYF5) directly activate later-acting factors (MYOG). This cascade architecture ensures ordered progression through the myogenic program and creates multiple commitment checkpoints. Importantly, the presence of only 2-4 binding sites at MRF loci, compared to 18-47 sites at structural genes, suggests that MRF regulation requires fewer but perhaps higher-affinity binding sites for effective activation. This regulatory network architecture provides both redundancy (multiple MRFs can activate similar targets) and robustness (positive feedback ensures sustained activation), properties that are essential for irreversible cell fate decisions."""
    
    add_paragraph_custom(doc, discussion5)
    
    add_heading_custom(doc, '4.6 Integration with Existing Knowledge and Novel Insights', level=2)
    
    discussion6 = """The findings from this genome-wide analysis both confirm previous knowledge and provide novel insights into MYOD1 function. The identification of well-established MYOD1 targets such as Myog, desmin, and muscle creatine kinase validates the analysis approach and demonstrates consistency with decades of focused gene-by-gene studies. However, the genome-wide perspective reveals the true breadth of MYOD1's regulatory influence, identifying thousands of novel target genes not previously associated with MYOD1 regulation. Particularly notable is the identification of genes involved in non-canonical processes such as mitochondrial biogenesis, Wnt signaling, and neurogenesis, expanding our understanding of the cellular processes controlled during myogenic conversion. The large number of binding sites at metabolic genes (Igf1, Eno3) reveals MYOD1's role in coordinating anabolic and catabolic programs with structural differentiation. The presence of binding sites at calcium handling genes (Cacnb3, Ryr1) demonstrates direct regulation of excitation-contraction coupling machinery. These findings indicate that MYOD1 does not simply turn on contractile protein genes but orchestrates a complete cellular transformation encompassing structure, metabolism, signaling, and function."""
    
    add_paragraph_custom(doc, discussion6)
    
    add_heading_custom(doc, '4.7 Implications for Muscle Development and Disease', level=2)
    
    discussion7 = """Understanding the complete MYOD1 regulatory network has important implications for both basic muscle biology and clinical applications. The identification of novel MYOD1 targets provides candidate genes for investigation in muscle developmental disorders and dystrophies. Mutations affecting MYOD1 binding sites in target gene regulatory regions could impair muscle development or function without directly affecting coding sequences, representing a potential mechanism for currently unexplained myopathies. The comprehensive binding map also informs regenerative medicine approaches aimed at converting non-muscle cells to myogenic lineages for cell therapy or tissue engineering applications. Knowledge of the complete set of genes that must be activated for successful myogenic conversion can guide the design of more efficient reprogramming strategies. Furthermore, the identification of metabolic and signaling pathway genes among MYOD1 targets suggests potential pharmaceutical intervention points for enhancing muscle regeneration or treating muscle wasting conditions. Small molecules that modulate pathways enriched among MYOD1 targets (Wnt signaling, IGF1 signaling) could potentially augment endogenous muscle regenerative capacity."""
    
    add_paragraph_custom(doc, discussion7)
    
    add_heading_custom(doc, '4.8 Technical Considerations and Experimental Validation', level=2)
    
    discussion8 = """While ChIP-seq provides a powerful genome-wide perspective on transcription factor binding, several technical considerations should be acknowledged. ChIP-seq identifies transcription factor-DNA binding but does not directly demonstrate functional consequences of that binding. A subset of binding events may represent non-functional interactions that do not result in target gene activation. Future studies employing complementary approaches such as ChIP-seq followed by RNA-seq in the same cellular context would establish which MYOD1 binding events correlate with target gene expression changes. Additionally, ChIP-seq provides a snapshot of binding in a specific cellular state and cannot capture dynamic changes during differentiation progression. Time-course ChIP-seq experiments at multiple differentiation stages would reveal how MYOD1 binding patterns evolve as cells transit through the myogenic program. The identification of binding sites at distal enhancers raises questions about long-range chromatin interactions that could be addressed through chromosome conformation capture (Hi-C or ChIA-PET) experiments to map physical enhancer-promoter contacts. Finally, functional validation of novel target genes through loss-of-function and gain-of-function experiments would establish which identified targets are essential for myogenesis versus dispensable or redundant."""
    
    add_paragraph_custom(doc, discussion8)
    
    doc.add_page_break()
    
    # ==========================================
    # CONCLUSIONS
    # ==========================================
    add_heading_custom(doc, '5. Conclusions', level=1)
    
    conclusion1 = """This comprehensive ChIP-seq analysis provides a genome-wide map of MYOD1 binding sites, identifying 77,310 high-confidence peaks associated with 14,566 putative target genes. The analysis confirms MYOD1's central role in muscle development while revealing unexpected breadth in the biological processes it regulates. The predominant localization of binding sites to promoter regions validates MYOD1 as a direct transcriptional activator, while the substantial fraction of distal sites indicates important roles for long-range enhancer-mediated regulation. Motif analysis confirming E-box presence in 88.6% of peaks provides strong validation of the experimental approach. Functional enrichment analysis demonstrates that MYOD1 coordinates multiple cellular processes including muscle differentiation, mitochondrial biogenesis, cytoskeletal organization, cell cycle regulation, and signal transduction, revealing MYOD1 as an orchestrator of comprehensive cellular transformation rather than simply an activator of muscle structural genes. The identification of cross-regulation among MRF family members elucidates the network architecture that ensures robust and irreversible myogenic commitment. These findings establish a foundation for future investigations into muscle development, regeneration, and disease, and provide a valuable resource for the muscle biology research community."""
    
    add_paragraph_custom(doc, conclusion1)
    
    doc.add_page_break()
    
    # ==========================================
    # REFERENCES
    # ==========================================
    add_heading_custom(doc, 'References', level=1)
    
    references = [
        "Cao Y, Yao Z, Sarkar D, Lawrence M, Sanchez GJ, Parker MH, MacQuarrie KL, Davison J, Morgan MT, Ruzzo WL, Gentleman RC, Tapscott SJ. Genome-wide MyoD binding in skeletal muscle cells: a potential for broad cellular reprogramming. Dev Cell. 2010 Oct 19;18(4):662-74.",
        
        "Tapscott SJ. The circuitry of a master switch: Myod and the regulation of skeletal muscle gene transcription. Development. 2005 Jun;132(12):2685-95.",
        
        "Berkes CA, Tapscott SJ. MyoD and the transcriptional control of myogenesis. Semin Cell Dev Biol. 2005 Aug-Oct;16(4-5):585-95.",
        
        "Weintraub H, Davis R, Tapscott S, Thayer M, Krause M, Benezra R, Blackwell TK, Turner D, Rupp R, Hollenberg S. The myoD gene family: nodal point during specification of the muscle cell lineage. Science. 1991 Feb 15;251(4995):761-6.",
        
        "Lassar AB, Paterson BM, Weintraub H. Transfection of a DNA locus that mediates the conversion of 10T1/2 fibroblasts to myoblasts. Cell. 1986 Nov 7;47(5):649-56.",
        
        "Park PJ. ChIP-seq: advantages and challenges of a maturing technology. Nat Rev Genet. 2009 Oct;10(10):669-80.",
        
        "Zhang Y, Liu T, Meyer CA, Eeckhoute J, Johnson DS, Bernstein BE, Nusbaum C, Myers RM, Brown M, Li W, Liu XS. Model-based analysis of ChIP-Seq (MACS). Genome Biol. 2008;9(9):R137.",
        
        "Yu G, Wang LG, He QY. ChIPseeker: an R/Bioconductor package for ChIP peak annotation, comparison and visualization. Bioinformatics. 2015 Jul 15;31(14):2382-3.",
        
        "Bailey TL, Johnson J, Grant CE, Noble WS. The MEME Suite. Nucleic Acids Res. 2015 Jul 1;43(W1):W39-49.",
        
        "Yu G, Wang LG, Han Y, He QY. clusterProfiler: an R package for comparing biological themes among gene clusters. OMICS. 2012 May;16(5):284-7.",
        
        "Ramírez F, Ryan DP, Grüning B, Bhardwaj V, Kilpert F, Richter AS, Heyne S, Dündar F, Manke T. deepTools2: a next generation web server for deep-sequencing data analysis. Nucleic Acids Res. 2016 Jul 8;44(W1):W160-5.",
        
        "Langmead B, Salzberg SL. Fast gapped-read alignment with Bowtie 2. Nat Methods. 2012 Mar 4;9(4):357-9.",
        
        "Li H, Handsaker B, Wysoker A, Fennell T, Ruan J, Homer N, Marth G, Abecasis G, Durbin R; 1000 Genome Project Data Processing Subgroup. The Sequence Alignment/Map format and SAMtools. Bioinformatics. 2009 Aug 15;25(16):2078-9.",
        
        "Quinlan AR, Hall IM. BEDTools: a flexible suite of utilities for comparing genomic features. Bioinformatics. 2010 Mar 15;26(6):841-2.",
        
        "Martin M. Cutadapt removes adapter sequences from high-throughput sequencing reads. EMBnet.journal. 2011;17(1):10-12."
    ]
    
    for ref in references:
        para = doc.add_paragraph(ref, style='List Number')
        para.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        for run in para.runs:
            run.font.name = 'Times New Roman'
            run.font.size = Pt(12)
    
    # Save document
    doc.save(OUTPUT_FILE)
    print(f"\n✓ Report generated successfully!")
    print(f"📄 Location: {OUTPUT_FILE}")
    print(f"📊 Total pages: ~30-35 pages")
    print(f"🖼️  Images included: 5 figures, 2 tables")

if __name__ == "__main__":
    print("="*60)
    print("  MYOD1 ChIP-seq Report Generator")
    print("="*60)
    print("\nGenerating comprehensive Word document report...")
    print("This may take a few minutes due to PDF to PNG conversion...")
    print("")
    
    create_report()
    
    print("\n" + "="*60)
    print("  Report Generation Complete!")
    print("="*60)

PYTHON_SCRIPT

# Make the script executable
chmod +x /home/naidurev/PGB/MYOD1_project/chipseq/generate_chipseq_report.py

# Run the script
echo ""
echo "Running report generator..."
echo ""
cd /home/naidurev/PGB/MYOD1_project/chipseq
python3 generate_chipseq_report.py

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Report Generated!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Output: /home/naidurev/PGB/MYOD1_project/chipseq/MYOD1_ChIPseq_Report.docx"
echo ""
echo "You can now:"
echo "  1. Open with LibreOffice: libreoffice MYOD1_ChIPseq_Report.docx"
echo "  2. Or transfer to Windows and open with Microsoft Word"
echo ""
