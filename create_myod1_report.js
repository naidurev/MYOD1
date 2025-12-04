const fs = require('fs');
const path = require('path');
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, ImageRun,
        Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType, 
        ShadingType, TableOfContents, PageNumber, PageBreak, LevelFormat } = require('docx');

// Configuration
const BASE_PATH = process.cwd();
const OUTPUT_FILE = 'MYOD1_Conservation_Analysis_Report.docx';

const FIGURES = {
    phyloTree: '05_domains/visualizations/phylotree.png',
    domainArch: '05_domains/visualizations/domain_architecture.png',
    myod1Conservation: '05_domains/visualizations/OG0000000_conservation_final.png',
    myogConservation: '05_domains/visualizations/OG0000001_conservation_final.png',
    conservationComparison: '05_domains/visualizations/conservation_comparison.png',
    myod1Logo: '05_domains/visualizations/OG0000000_sequence_logo.png',
    myogLogo: '05_domains/visualizations/OG0000001_sequence_logo.png',
    myod1Functional: '05_domains/visualizations/OG0000000_functional_sites.png',
    myogFunctional: '05_domains/visualizations/OG0000001_functional_sites.png'
};

const tableBorder = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };

function addImage(imagePath, width, height, caption) {
    const fullPath = path.join(BASE_PATH, imagePath);
    try {
        if (fs.existsSync(fullPath)) {
            const data = fs.readFileSync(fullPath);
            const ext = path.extname(fullPath).substring(1).toLowerCase();
            return [
                new Paragraph({
                    alignment: AlignmentType.CENTER,
                    spacing: { before: 200, after: 100 },
                    children: [new ImageRun({
                        type: ext === 'jpg' ? 'jpeg' : ext,
                        data: data,
                        transformation: { width, height },
                        altText: { title: caption, description: caption, name: caption }
                    })]
                }),
                new Paragraph({
                    alignment: AlignmentType.CENTER,
                    spacing: { after: 200 },
                    children: [new TextRun({ text: caption, italics: true, size: 20, color: "666666" })]
                })
            ];
        }
    } catch (e) {
        console.log(`Warning: Could not load ${imagePath}`);
    }
    return [new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { before: 200, after: 200 },
        children: [new TextRun({ text: `[Figure: ${path.basename(imagePath)}]`, italics: true, color: "999999" })]
    })];
}

function para(text, opts = {}) {
    return new Paragraph({
        spacing: { after: 200, ...opts.spacing },
        alignment: opts.align || AlignmentType.LEFT,
        children: [new TextRun({ text, ...opts.textOpts })]
    });
}

function heading1(text) {
    return new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun(text)] });
}

function heading2(text) {
    return new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun(text)] });
}

function heading3(text) {
    return new Paragraph({ heading: HeadingLevel.HEADING_3, children: [new TextRun(text)] });
}

console.log("Generating MYOD1 Conservation Analysis Report...");
console.log("Base path:", BASE_PATH);

// Check for figures
console.log("\nChecking figures:");
Object.entries(FIGURES).forEach(([key, fpath]) => {
    const exists = fs.existsSync(path.join(BASE_PATH, fpath));
    console.log(`  ${key}: ${exists ? '✓' : '✗'} ${fpath}`);
});

const doc = new Document({
    creator: "Bioinformatics Analysis",
    title: "MYOD1 Protein Conservation Analysis",
    description: "Comprehensive evolutionary analysis across vertebrates",
    
    styles: {
        default: { document: { run: { font: "Arial", size: 24 } } },
        paragraphStyles: [
            { id: "Title", name: "Title", basedOn: "Normal",
              run: { size: 56, bold: true, font: "Arial" },
              paragraph: { spacing: { before: 240, after: 120 }, alignment: AlignmentType.CENTER } },
            { id: "Heading1", name: "Heading 1", basedOn: "Normal", quickFormat: true,
              run: { size: 32, bold: true, font: "Arial" },
              paragraph: { spacing: { before: 480, after: 240 }, outlineLevel: 0 } },
            { id: "Heading2", name: "Heading 2", basedOn: "Normal", quickFormat: true,
              run: { size: 28, bold: true, font: "Arial" },
              paragraph: { spacing: { before: 360, after: 180 }, outlineLevel: 1 } },
            { id: "Heading3", name: "Heading 3", basedOn: "Normal", quickFormat: true,
              run: { size: 26, bold: true, font: "Arial" },
              paragraph: { spacing: { before: 240, after: 120 }, outlineLevel: 2 } }
        ]
    },
    
    numbering: {
        config: [{
            reference: "bullets",
            levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
                style: { paragraph: { indent: { left: 720, hanging: 360 } } } }]
        }]
    },
    
    sections: [{
        properties: { page: { margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } } },
        
        headers: {
            default: new Header({ children: [new Paragraph({
                alignment: AlignmentType.RIGHT,
                children: [new TextRun({ text: "MYOD1 Conservation Analysis", size: 20, color: "666666" })]
            })] })
        },
        
        footers: {
            default: new Footer({ children: [new Paragraph({
                alignment: AlignmentType.CENTER,
                children: [
                    new TextRun({ text: "Page ", size: 20 }),
                    new TextRun({ children: [PageNumber.CURRENT], size: 20 }),
                    new TextRun({ text: " of ", size: 20 }),
                    new TextRun({ children: [PageNumber.TOTAL_PAGES], size: 20 })
                ]
            })] })
        },
        
        children: [
            // TITLE PAGE
            new Paragraph({ heading: HeadingLevel.TITLE,
                children: [new TextRun("Evolutionary Conservation Analysis of MYOD1 Protein Across Vertebrates")] }),
            
            para("A Comprehensive Bioinformatics Study", { 
                align: AlignmentType.CENTER, 
                spacing: { before: 240, after: 480 },
                textOpts: { size: 28, italics: true }
            }),
            
            para("Bioinformatics for Health Sciences", {
                align: AlignmentType.CENTER,
                spacing: { before: 720, after: 120 },
                textOpts: { size: 24, bold: true }
            }),
            
            para("Universitat de Barcelona", {
                align: AlignmentType.CENTER,
                spacing: { after: 120 },
                textOpts: { size: 24 }
            }),
            
            para(new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }), {
                align: AlignmentType.CENTER,
                spacing: { after: 960 },
                textOpts: { size: 24 }
            }),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // TABLE OF CONTENTS
            new TableOfContents("Table of Contents", { hyperlink: true, headingStyleRange: "1-3" }),
            new Paragraph({ children: [new PageBreak()] }),
            
            // ABSTRACT
            heading1("Abstract"),
            
            para("MYOD1 (Myogenic Differentiation 1) serves as a master transcriptional regulator controlling skeletal muscle development in vertebrates. This study presents a comprehensive bioinformatics analysis examining MYOD1 protein conservation patterns across major vertebrate lineages, spanning approximately 450 million years of evolutionary history."),
            
            para("Our analysis employed a multi-faceted computational approach combining homolog identification through BLASTP searches, ortholog classification using OrthoFinder with DIAMOND acceleration, multiple sequence alignment via MAFFT, and phylogenetic reconstruction through maximum likelihood methods implemented in IQ-TREE 2. Domain architecture analysis utilized HMMER scanning against the Pfam database, while conservation patterns were quantified through custom Python implementations."),
            
            para("The phylogenetic analysis revealed clear separation of the MRF (Myogenic Regulatory Factor) gene family into distinct functional groups, with MYOD1 and MYF5 forming a closely related clade as early determination factors, while MYOG occupies a more evolutionarily distant position consistent with its role in later-stage differentiation."),
            
            para("Quantitative conservation analysis demonstrated that the MYOD1/MYF5 orthogroup maintains 77% mean sequence conservation with 41 putative functional residues, predominantly arginine (for DNA binding) and serine (for phosphorylation). The MYOG orthogroup exhibits 72% mean conservation with 22 highly conserved positions enriched for leucine (helical structure), glycine (loop flexibility), and arginine (DNA binding). The bHLH domain demonstrates over 90% conservation across all analyzed species."),
            
            para("These findings illuminate the evolutionary constraints shaping this critical developmental regulator, demonstrating that functional specialization following gene duplication events has been maintained over vast evolutionary timescales. This work provides a foundation for understanding muscle development at a molecular level with implications for muscular diseases and regenerative medicine."),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // INTRODUCTION
            heading1("1. Introduction"),
            heading2("1.1 Background"),
            
            para("Skeletal muscle development is orchestrated by a small number of transcription factors collectively termed the Myogenic Regulatory Factors (MRFs): MYOD1, MYF5, MYOG, and MYF6. MYOD1, first identified in 1987, functions as a master regulatory gene capable of converting fibroblasts into myoblasts, establishing it as one of the first identified master regulators of cell fate determination."),
            
            para("The functional importance of MYOD1 extends beyond embryonic myogenesis to muscle regeneration in adults. Mutations affecting MYOD1 have been implicated in various muscular disorders, while aberrant expression appears in rhabdomyosarcoma. Understanding MYOD1 evolutionary conservation holds implications for both basic developmental biology and translational research in regenerative medicine and oncology."),
            
            heading2("1.2 Research Objectives"),
            para("This comprehensive bioinformatics study aimed to:"),
            
            new Paragraph({ numbering: { reference: "bullets", level: 0 },
                children: [new TextRun("Identify and characterize MYOD1 homologs across major vertebrate taxonomic groups")] }),
            new Paragraph({ numbering: { reference: "bullets", level: 0 },
                children: [new TextRun("Distinguish between orthologous and paralogous relationships within the MRF family")] }),
            new Paragraph({ numbering: { reference: "bullets", level: 0 },
                children: [new TextRun("Reconstruct phylogenetic relationships to understand evolutionary history and gene duplication timing")] }),
            new Paragraph({ numbering: { reference: "bullets", level: 0 },
                children: [new TextRun("Analyze taxonomic conservation patterns across vertebrate evolution")] }),
            new Paragraph({ numbering: { reference: "bullets", level: 0 },
                children: [new TextRun("Identify and characterize conserved functional domains, particularly the bHLH domain")] }),
            new Paragraph({ numbering: { reference: "bullets", level: 0 },
                children: [new TextRun("Quantify position-specific conservation scores to pinpoint functionally critical residues")] }),
            new Paragraph({ numbering: { reference: "bullets", level: 0 },
                children: [new TextRun("Predict putative functional sites based on conservation and domain architecture")] }),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // MATERIALS AND METHODS
            heading1("2. Materials and Methods"),
            heading2("2.1 Computational Infrastructure"),
            para("All analyses were performed on Ubuntu 22.04 LTS with multi-core processors. The pipeline was implemented using established bioinformatics tools and custom scripts with careful version control and documentation."),
            
            heading2("2.2 Sequence Acquisition"),
            para("Human MYOD1 (UniProt: P15172) served as the reference query. This well-characterized sequence from UniProtKB provided a solid foundation for comparative analysis."),
            
            heading2("2.3 Homolog Identification"),
            heading3("2.3.1 BLAST-Based Homolog Search"),
            para("BLASTP searches against the NCBI nr database targeted vertebrate lineages (Primates, Mammalia, Aves, Reptilia, Amphibia, Actinopterygii) with E-value threshold 1×10⁻⁵ and minimum 50% query coverage. The algorithm rapidly identified regions of local similarity across diverse taxonomic groups."),
            para("Script: run_phase2a_full.sh", { textOpts: { bold: true } }),
            
            heading3("2.3.2 Ortholog and Paralog Classification"),
            para("OrthoFinder v3.1.0 with DIAMOND v2.1.15 acceleration distinguished orthologous from paralogous relationships through graph-based clustering. DIAMOND achieved ~10,000× speed increase over BLASTP while maintaining sensitivity. The analysis partitioned MRF genes into OG0000000 (MYOD1/MYF5) and OG0000001 (MYOG), aligning with functional relationships."),
            para("Scripts: run_orthofinder_v3.sh, analyze_orthogroups.sh", { textOpts: { bold: true } }),
            
            heading2("2.4 Multiple Sequence Alignment"),
            para("MAFFT established positional homology using Fast Fourier Transform algorithms to identify conserved regions. The FFT-NS-2 strategy combined rapid homology detection with iterative refinement. Separate alignments for MYOD1/MYF5 and MYOG enabled focused conservation analysis."),
            para("Script: run_phase3_msa.sh", { textOpts: { bold: true } }),
            
            heading2("2.5 Phylogenetic Reconstruction"),
            heading3("2.5.1 Maximum Likelihood Tree Inference"),
            para("IQ-TREE 2 inferred phylogenetic relationships using maximum likelihood methods with automated model selection (ModelFinder) and 1000 ultrafast bootstrap replicates. This approach provides superior accuracy compared to distance-based methods for complex evolutionary patterns."),
            para("Script: run_phase4_trees.sh", { textOpts: { bold: true } }),
            
            heading3("2.5.2 Phylogenetic Tree Visualization"),
            para("Trees were uploaded to iTOL (Interactive Tree of Life) for publication-quality visualization. A circular layout accommodated numerous sequences with dual color-coding: outer ring by gene family (MYOD1-red, MYF5-blue, MYOG-green) and boxes by taxonomy (Mammalia-red, Aves-cyan, Amphibia-light green, Actinopterygii-yellow). Evolutionary events were marked with symbols: red triangles (gene duplication), orange circles (whole genome duplication), purple stars (ancient duplication)."),
            para("Scripts: create_publication_trees.sh, create_trees_final.py", { textOpts: { bold: true } }),
            
            heading2("2.6 Domain Architecture Analysis"),
            heading3("2.6.1 Domain Prediction with HMMER"),
            para("HMMER used profile Hidden Markov Models against the Pfam database to identify conserved domains. This profile-based approach proved more sensitive than pairwise methods for detecting remote homology. HMMER identified three domains: TAD (transactivation), basic region (DNA-binding), and HLH (dimerization)."),
            para("Scripts: run_phase5_part1.sh, run_phase5_part2.sh, parse_hmmer.py", { textOpts: { bold: true } }),
            
            heading3("2.6.2 Domain Extraction and Visualization"),
            para("Custom Python scripts extracted domain sequences and generated schematic diagrams using matplotlib. TAD (red), basic region (cyan), and HLH (blue) maintained consistent color scheme across all figures."),
            para("Scripts: extract_domains_fixed.py, visualize_domains_fixed.py", { textOpts: { bold: true } }),
            
            heading2("2.7 Conservation Analysis"),
            heading3("2.7.1 Position-Specific Conservation Scoring"),
            para("Shannon entropy quantified amino acid diversity at each position: H(i) = -Σ p(a) log₂ p(a). Conservation scores derived as: Conservation(i) = 1 - (H(i) / H_max), yielding scores from 0 (variable) to 1 (conserved). Positions ≥0.9 were classified as highly conserved."),
            para("Script: analyze_conservation_fixed.py", { textOpts: { bold: true } }),
            
            heading3("2.7.2 Conservation Visualization"),
            para("Multi-panel heatmaps displayed conservation scores (line plot) and amino acid identity (green-to-red heatmap). Sequence logos visualized position-specific amino acid preferences using Logomaker, with letter height proportional to information content."),
            para("Scripts: create_final_heatmaps.py, generate_final_summary.py", { textOpts: { bold: true } }),
            
            heading2("2.8 Functional Site Prediction"),
            para("Putative functional sites were predicted by integrating conservation analysis (score ≥0.9) with domain architecture (within TAD, basic, or HLH domains). Amino acid composition at these sites was quantified to reveal functional emphases: MYOD1/MYF5 enriched for arginine (DNA binding) and serine (phosphorylation), while MYOG enriched for leucine (helical structure), glycine (flexibility), and arginine."),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // RESULTS
            heading1("3. Results"),
            heading2("3.1 Phylogenetic Relationships and Evolutionary History"),
            para("The maximum likelihood phylogenetic analysis reconstructed evolutionary relationships within the MRF gene family across 450 million years of vertebrate evolution."),
            
            ...addImage(FIGURES.phyloTree, 600, 500, "Figure 1. Phylogenetic tree of MRF gene family showing MYOD1 (red), MYF5 (blue), MYOG (green), MYOD2 (dark red) with taxonomic classification and evolutionary events (triangles=gene duplication, circles=WGD, stars=ancient duplication)."),
            
            para("The phylogeny demonstrates a fundamental bifurcation separating MYOD1/MYF5 from MYOG with strong bootstrap support (>95%), reflecting an ancient gene duplication predating vertebrate divergence. MYOD1 and MYF5 form a monophyletic group as early-acting determination factors with functional redundancy. MYOG occupies a distinct position as a later-acting differentiation factor. Mammalian sequences show tight clustering (recent divergence ~66 Mya), while fish show greatest diversity reflecting earlier divergence (~420 Mya) and teleost-specific genome duplication (~350 Mya)."),
            
            heading2("3.2 Domain Architecture Conservation"),
            para("Despite 450 million years of evolution, core domain architecture remains remarkably stable. HMMER identified TAD, basic region, and HLH domains present in all MRF members."),
            
            ...addImage(FIGURES.domainArch, 600, 350, "Figure 2. Domain architecture showing TAD (red), Basic (cyan), HLH (blue) in MYOD1 (320aa), MYF5 (255aa), MYOG (224aa). Core bHLH domain maintains consistent size despite total length variation."),
            
            para("The TAD (150-200aa in MYOD1, 120-150aa in MYF5, 100-130aa in MYOG) recruits transcriptional machinery with relatively low conservation reflecting modular function through short linear motifs. The basic region (~15-20aa) mediates sequence-specific E-box recognition through electrostatic interactions, showing high conservation. The HLH domain (~40-50aa) comprises two amphipathic α-helices mediating dimerization, essential for DNA binding. The bHLH region maintains constant length (~60-65aa) and position despite total protein length variation, underscoring functional centrality."),
            
            heading2("3.3 Position-Specific Conservation Patterns"),
            heading3("3.3.1 MYOD1/MYF5 Orthogroup Conservation"),
            para("Conservation analysis revealed 41 positions with scores >0.9 (34.2% of alignment), mean conservation 77.2%, median 76.9%."),
            
            ...addImage(FIGURES.myod1Conservation, 600, 400, "Figure 3. MYOD1/MYF5 conservation showing dramatic peak at positions 70-110 (bHLH domain) with scores >0.9. Heatmap shows extensive green blocks indicating perfect conservation across species."),
            
            para("The prominent conservation peak spanning positions 70-110 corresponds to the bHLH domain with scores consistently >0.9, many achieving near-perfect conservation (>0.95). This extraordinary conservation testifies to the absolutely critical role in dimerization and DNA binding. Outside the bHLH domain, the N-terminal region shows moderate conservation (0.6-0.8) with embedded functional motifs, while the C-terminal region displays greater diversity (<0.7), suggesting flexible linker or regulatory function. Highly conserved positions show enrichment for arginine (DNA binding electrostatics), leucine (hydrophobic core), and glycine (conformational flexibility)."),
            
            heading3("3.3.2 MYOG Orthogroup Conservation"),
            para("MYOG displays similar patterns but lower overall conservation: 22 positions >0.9 (18.8%), mean 71.6%, median 70.1%."),
            
            ...addImage(FIGURES.myogConservation, 600, 400, "Figure 4. MYOG conservation shows lower overall conservation compared to MYOD1/MYF5, particularly outside bHLH domain, while bHLH itself maintains high conservation."),
            
            para("Despite lower overall conservation, the MYOG bHLH domain maintains exceptional conservation >0.9, reinforcing that this represents an evolutionary module under strong constraint regardless of functional context. The N-terminal region shows substantially greater diversity (<0.6) potentially reflecting distinct transcriptional coactivators or regulatory mechanisms for differentiation versus determination. As a late-acting factor after lineage commitment, MYOG may tolerate more functional flexibility."),
            
            heading2("3.4 Comparative Conservation Statistics"),
            
            ...addImage(FIGURES.conservationComparison, 600, 500, "Figure 5. Comparative statistics showing MYOD1/MYF5 (77% conservation, 41 highly conserved positions) vs MYOG (72% conservation, 22 highly conserved positions) through histograms, box plots, bar charts, and summary table."),
            
            para("Box plot analysis reveals MYOD1/MYF5 distribution shifted toward higher values (median 0.769 vs 0.701 for MYOG). Histogram analysis shows MYOD1/MYF5 with pronounced peak at conservation 1.0 (perfect conservation), substantially reduced in MYOG. The differential is most pronounced in high conservation category (≥0.9): MYOD1/MYF5 has 41 positions (34.2%) vs 22 (18.8%) for MYOG, representing 82% increase."),
            
            para("The higher conservation of MYOD1/MYF5 reflects their role as early determination factors where errors have severe downstream consequences. As master regulators committing cells to muscle fate, they require precise control. MYOG acts after commitment in cells already expressing muscle genes, where subtle variations are buffered by pre-existing commitment, permitting slightly relaxed constraint."),
            
            heading2("3.5 Sequence Logos and Motif Conservation"),
            para("Sequence logos visualize position-specific amino acid preferences with letter height proportional to information content."),
            
            ...addImage(FIGURES.myod1Logo, 600, 150, "Figure 6. MYOD1/MYF5 bHLH domain sequence logo showing tall arginine letters (DNA binding), regular spacing of leucine/isoleucine/valine (hydrophobic faces), and glycine/alanine enrichment (flexibility/minimal bulk)."),
            
            para("MYOD1/MYF5 patterns: Multiple arginine positions with very high information content reflect absolute requirement for DNA major groove contacts. Regular spacing of leucine/isoleucine/valine indicates maintained hydrophobic faces for helix packing. Small residues (glycine, alanine) appear where flexibility or lack of steric bulk is required."),
            
            ...addImage(FIGURES.myogLogo, 600, 150, "Figure 7. MYOG bHLH domain sequence logo showing similar but slightly lower information content at certain positions, with DNA-contacting arginines maintaining high conservation."),
            
            para("MYOG patterns: DNA-contacting arginines maintain comparable information content to MYOD1/MYF5, reinforcing that DNA-binding specificity is absolutely conserved. Some positions show slightly lower information content with two-three amino acids sharing frequency, suggesting MYOG tolerates more substitutions. Loop regions display higher diversity potentially reflecting less stringent structural constraints."),
            
            heading2("3.6 Functional Site Predictions"),
            heading3("3.6.1 MYOD1/MYF5 Functional Sites"),
            para("41 positions met functional site criteria (conservation ≥0.9 within domains): 5 in TAD, 8 in basic region, 28 in HLH."),
            
            ...addImage(FIGURES.myod1Functional, 600, 450, "Figure 8. MYOD1/MYF5 functional sites showing 41 positions (red stars) with arginine and serine dominating, reflecting DNA binding and phosphorylation roles."),
            
            para("Arginine and serine each appear at 5 positions (most frequent). Arginine's enrichment corresponds to DNA binding—the positively charged guanidinium forms electrostatic interactions with DNA phosphate backbone and hydrogen bonds with bases. Serine's enrichment reflects post-translational regulation through phosphorylation by protein kinases, creating negative charge, new interaction surfaces, or conformational changes regulating DNA-binding activity, stability, and coactivator interactions. Additional amino acids include leucine (4), proline (4), isoleucine (3), glutamic acid (3)."),
            
            heading3("3.6.2 MYOG Functional Sites"),
            para("22 predicted sites: 3 in TAD, 5 in basic region, 14 in HLH."),
            
            ...addImage(FIGURES.myogFunctional, 600, 450, "Figure 9. MYOG functional sites showing 22 positions with leucine most frequent, followed by glycine and arginine, reflecting helix structure, loop flexibility, and DNA binding."),
            
            para("Leucine emerges most frequent (5 positions), reflecting emphasis on helical structure. Hydrophobic leucine side chains pack into HLH domain interior, forming the core driving helix association. Glycine and arginine each at 3 positions. Glycine provides conformational flexibility particularly in loops, suggesting precise loop geometry may be more critical in MYOG. Arginine's presence reinforces that DNA-binding requirements remain conserved across paralogs."),
            
            para("Comparison reveals conserved themes (arginine for DNA binding) but distinct emphases: serine for MYOD1/MYF5 (phosphorylation regulation) vs leucine for MYOG (helical structure). These differences reflect distinct regulatory requirements and interaction partners of determination vs differentiation factors."),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // DISCUSSION
            heading1("4. Discussion"),
            heading2("4.1 Evolutionary Insights"),
            para("The clear phylogenetic separation between MYOD1/MYF5 and MYOG, supported by strong bootstrap values, indicates the fundamental MRF split predates vertebrate radiation ≥450 million years ago. Subsequent retention despite general gene loss tendency suggests each paralog acquired distinct, essential functions. The phylogenetic positioning matches functional specialization: MYOD1/MYF5 share earliest myogenesis step (specification), maintaining partially overlapping mechanisms and genetic redundancy. MYOG's distinct position corresponds to unique terminal differentiation role, enabling accumulation of regulatory changes for later developmental stage function."),
            
            heading2("4.2 Domain Architecture as Evolutionary Module"),
            para("The striking bHLH domain conservation exemplifies protein domains as evolutionary modules—semi-autonomous units maintaining core functions while enabling innovation through recombination or non-domain modification. The variable TAD regions likely reflect lineage-specific acquisition of regulatory sequences for protein-protein interactions, post-translational modification sites, or nuclear localization signals. This modularity allows tuning transcriptional specificity (TAD variation) while preserving DNA-binding specificity (bHLH conservation)."),
            
            heading2("4.3 Evolutionary Constraints and Functional Importance"),
            para("The 5.6 percentage point conservation difference (77.2% vs 71.6%) and two-fold difference in highly conserved positions (41 vs 22) reflect differential selective pressure, not general mutational processes. Contributing factors: (1) MYOD1/MYF5 operate earlier where errors have more profound consequences, (2) function in more stringent regulatory context requiring coordination with multiple signaling pathways, (3) partial redundancy requires compatible structures for heterodimerization. MYOG operates after commitment where subtle variations may be buffered."),
            
            heading2("4.4 Functional Site Predictions"),
            para("Distinct amino acid profiles provide testable mechanistic hypotheses. MYOD1/MYF5 serine enrichment suggests phosphorylation regulation is particularly important, with experimental documentation of multiple kinase pathways (p38 MAPK, ERK) modulating activity. Conservation implies these phosphorylation sites represent ancient regulatory mechanisms. MYOG's leucine/glycine enrichment suggests precise structural and conformational control is particularly important, potentially reflecting need for distinct coactivator interactions or subtle DNA sequence recognition differences."),
            
            heading2("4.5 Implications for Human Disease"),
            para("Highly conserved positions provide a framework for interpreting human variants. Variants affecting positions with conservation ~1.0 (perfectly conserved across vertebrates) are extremely likely deleterious, strong candidates for causing muscle disorders. Variants at lower conservation positions, particularly non-domain regions, may represent benign polymorphisms. Rhabdomyosarcoma often shows aberrant MYOD1 expression—exceptional DNA-binding domain conservation suggests mutations here would be particularly detrimental, potentially redirecting the protein to aberrant targets and contributing to oncogenesis."),
            
            heading2("4.6 Study Limitations"),
            para("Limitations include: (1) focus on coding sequences, not regulatory regions controlling expression, (2) computational predictions rather than experimental validation, (3) vertebrate-focused sampling missing deeper evolutionary origins, (4) lack of three-dimensional structure integration which could reveal structural conservation through compensatory substitutions."),
            
            heading2("4.7 Future Directions"),
            para("Future investigations: (1) site-directed mutagenesis testing conserved residue importance, (2) regulatory region comparative analysis identifying conserved enhancers, (3) epigenomic data integration across species, (4) phosphoproteomics cataloging all MYOD1 modifications and kinase pathway identification. Understanding phosphorylation networks could reveal therapeutic targets for manipulating muscle formation in regenerative medicine or intervening in rhabdomyosarcoma."),
            
            heading2("4.8 Conclusions"),
            para("This comprehensive analysis revealed remarkable MYOD1 conservation across 450 million years, with the bHLH domain showing >90% conservation testifying to absolute functional importance for DNA binding and dimerization. Differential conservation between MYOD1/MYF5 (determination) and MYOG (differentiation) illuminates how evolutionary pressure varies by functional context and developmental timing. The identification of 41 MYOD1/MYF5 and 22 MYOG putative functional sites with distinct amino acid profiles provides a framework for future experimental investigation. This work demonstrates the power of comparative evolutionary analysis for illuminating protein function, providing insights that advance fundamental understanding while offering practical guidance for interpreting genetic variation and designing therapeutic interventions."),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // REFERENCES
            heading1("5. References"),
            para("Altschul SF, Gish W, Miller W, Myers EW, Lipman DJ. (1990). Basic local alignment search tool. J Mol Biol, 215(3), 403-410.", { spacing: { after: 120 } }),
            para("Buchfink B, Reuter K, Drost HG. (2021). Sensitive protein alignments at tree-of-life scale using DIAMOND. Nat Methods, 18(4), 366-368.", { spacing: { after: 120 } }),
            para("Davis RL, Weintraub H, Lassar AB. (1987). Expression of a single transfected cDNA converts fibroblasts to myoblasts. Cell, 51(6), 987-1000.", { spacing: { after: 120 } }),
            para("Eddy SR. (2011). Accelerated profile HMM searches. PLoS Comput Biol, 7(10), e1002195.", { spacing: { after: 120 } }),
            para("Emms DM, Kelly S. (2019). OrthoFinder: phylogenetic orthology inference for comparative genomics. Genome Biol, 20(1), 238.", { spacing: { after: 120 } }),
            para("Katoh K, Standley DM. (2013). MAFFT multiple sequence alignment software version 7. Mol Biol Evol, 30(4), 772-780.", { spacing: { after: 120 } }),
            para("Letunic I, Bork P. (2021). Interactive Tree Of Life (iTOL) v5. Nucleic Acids Res, 49(W1), W293-W296.", { spacing: { after: 120 } }),
            para("Minh BQ, et al. (2020). IQ-TREE 2: New models and efficient methods for phylogenetic inference. Mol Biol Evol, 37(5), 1530-1534.", { spacing: { after: 120 } }),
            para("Mistry J, et al. (2021). Pfam: The protein families database in 2021. Nucleic Acids Res, 49(D1), D412-D419.", { spacing: { after: 120 } }),
            para("Rudnicki MA, et al. (1993). MyoD or Myf-5 is required for skeletal muscle formation. Cell, 75(7), 1351-1359.", { spacing: { after: 120 } }),
            para("Weintraub H, et al. (1991). The myoD gene family: nodal point during specification. Science, 251(4995), 761-766.", { spacing: { after: 120 } }),
            
            para("--- End of Report ---", { 
                align: AlignmentType.CENTER,
                spacing: { before: 480 },
                textOpts: { italics: true, size: 20, color: "666666" }
            })
        ]
    }]
});

console.log("\nGenerating document...");

Packer.toBuffer(doc).then(buffer => {
    fs.writeFileSync(OUTPUT_FILE, buffer);
    console.log(`✓ Report generated: ${OUTPUT_FILE}`);
    console.log(`\nFile size: ${(buffer.length / 1024 / 1024).toFixed(2)} MB`);
    console.log("\nYou can now:");
    console.log(`  1. Open the file: xdg-open "${OUTPUT_FILE}"`);
    console.log(`  2. Copy to Windows: cp "${OUTPUT_FILE}" /mnt/c/Users/YourUsername/Downloads/`);
}).catch(err => {
    console.error("Error generating document:", err);
    process.exit(1);
});
SCRIPT_EOF

echo "✅ Script created successfully!"
