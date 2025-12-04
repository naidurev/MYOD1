#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, ImageRun,
        Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType, 
        ShadingType, TableOfContents, PageNumber, PageBreak, LevelFormat } = require('docx');

// ========== CONFIGURATION ==========
const BASE_PATH = '/home/naidurev/PGB/MYOD1_project/blast_conservation';
const OUTPUT_PATH = path.join(BASE_PATH, 'MYOD1_Conservation_Analysis_Report.docx');

const FIGURES = {
    phyloTree: path.join(BASE_PATH, '05_domains/visualizations/phylotree.png'),
    domainArch: path.join(BASE_PATH, '05_domains/visualizations/domain_architecture.png'),
    myod1Conservation: path.join(BASE_PATH, '05_domains/visualizations/OG0000000_conservation_final.png'),
    myogConservation: path.join(BASE_PATH, '05_domains/visualizations/OG0000001_conservation_final.png'),
    conservationComparison: path.join(BASE_PATH, '05_domains/visualizations/conservation_comparison.png'),
    myod1Logo: path.join(BASE_PATH, '05_domains/visualizations/OG0000000_sequence_logo.png'),
    myogLogo: path.join(BASE_PATH, '05_domains/visualizations/OG0000001_sequence_logo.png'),
    myod1Functional: path.join(BASE_PATH, '05_domains/visualizations/OG0000000_functional_sites.png'),
    myogFunctional: path.join(BASE_PATH, '05_domains/visualizations/OG0000001_functional_sites.png')
};

const tableBorder = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };

//