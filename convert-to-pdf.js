const fs = require('fs');
const path = require('path');
const { marked } = require('marked');
const puppeteer = require('puppeteer');

// Read the markdown file
const markdownContent = fs.readFileSync('rapport-projet-fin-annee.md', 'utf8');

// Convert markdown to HTML
const htmlContent = marked(markdownContent);

// Create full HTML document with styling
const fullHtml = `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Projet de Fin d'Année</title>
    <style>
        @page {
            size: A4;
            margin: 2cm;
        }
        
        body {
            font-family: 'Arial', sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 21cm;
            margin: 0 auto;
            padding: 20px;
        }
        
        h1 {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
            margin-top: 2em;
            page-break-before: always;
        }
        
        h1:first-of-type {
            page-break-before: avoid;
        }
        
        h2 {
            color: #34495e;
            margin-top: 1.5em;
            border-bottom: 1px solid #ecf0f1;
            padding-bottom: 5px;
        }
        
        h3 {
            color: #7f8c8d;
            margin-top: 1.2em;
        }
        
        code {
            background-color: #f4f4f4;
            padding: 2px 4px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
        }
        
        pre {
            background-color: #f8f8f8;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            overflow-x: auto;
            font-size: 0.85em;
            line-height: 1.4;
        }
        
        pre code {
            background-color: transparent;
            padding: 0;
        }
        
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 1em 0;
        }
        
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        
        blockquote {
            border-left: 4px solid #3498db;
            margin: 1em 0;
            padding-left: 1em;
            color: #666;
        }
        
        img {
            max-width: 100%;
            height: auto;
        }
        
        ul, ol {
            margin: 1em 0;
            padding-left: 2em;
        }
        
        li {
            margin: 0.5em 0;
        }
        
        hr {
            border: none;
            border-top: 2px solid #ecf0f1;
            margin: 2em 0;
        }
        
        .page-break {
            page-break-after: always;
        }
        
        #table-of-contents {
            background-color: #f9f9f9;
            border: 1px solid #ddd;
            padding: 20px;
            margin: 2em 0;
            border-radius: 5px;
        }
        
        #table-of-contents h2 {
            margin-top: 0;
        }
        
        #table-of-contents ul {
            list-style-type: none;
            padding-left: 0;
        }
        
        #table-of-contents ul ul {
            padding-left: 20px;
        }
        
        #table-of-contents a {
            text-decoration: none;
            color: #3498db;
        }
        
        #table-of-contents a:hover {
            text-decoration: underline;
        }
        
        .highlight {
            background-color: #fff3cd;
            padding: 10px;
            border-left: 4px solid #ffc107;
            margin: 1em 0;
        }
        
        @media print {
            body {
                font-size: 11pt;
            }
            
            h1 {
                font-size: 20pt;
            }
            
            h2 {
                font-size: 16pt;
            }
            
            h3 {
                font-size: 14pt;
            }
            
            pre {
                page-break-inside: avoid;
            }
            
            table {
                page-break-inside: avoid;
            }
        }
    </style>
</head>
<body>
    ${htmlContent}
</body>
</html>
`;

// Save HTML file
fs.writeFileSync('rapport-projet-fin-annee.html', fullHtml);

// Convert HTML to PDF using Puppeteer
async function convertToPDF() {
    try {
        console.log('Starting PDF conversion...');
        
        const browser = await puppeteer.launch({
            headless: 'new',
            args: ['--no-sandbox', '--disable-setuid-sandbox']
        });
        
        const page = await browser.newPage();
        
        // Load the HTML content
        await page.setContent(fullHtml, { waitUntil: 'networkidle0' });
        
        // Generate PDF
        await page.pdf({
            path: 'rapport-projet-fin-annee.pdf',
            format: 'A4',
            printBackground: true,
            margin: {
                top: '2cm',
                right: '2cm',
                bottom: '2cm',
                left: '2cm'
            }
        });
        
        await browser.close();
        
        console.log('PDF generated successfully: rapport-projet-fin-annee.pdf');
        
        // Clean up HTML file
        fs.unlinkSync('rapport-projet-fin-annee.html');
        
    } catch (error) {
        console.error('Error generating PDF:', error);
        
        // Fallback: If puppeteer fails, keep the HTML file
        console.log('HTML file saved as: rapport-projet-fin-annee.html');
        console.log('You can open this file in a browser and print to PDF manually.');
    }
}

// Check if puppeteer is available
try {
    require.resolve('puppeteer');
    convertToPDF();
} catch (e) {
    console.log('Puppeteer not found. Installing dependencies...');
    console.log('Please run: npm install marked puppeteer');
    console.log('Then run: node convert-to-pdf.js');
    
    // Save package.json for the conversion script
    const packageJson = {
        "name": "pdf-converter",
        "version": "1.0.0",
        "description": "Convert markdown report to PDF",
        "main": "convert-to-pdf.js",
        "scripts": {
            "convert": "node convert-to-pdf.js"
        },
        "dependencies": {
            "marked": "^4.3.0",
            "puppeteer": "^21.0.0"
        }
    };
    
    fs.writeFileSync('pdf-converter-package.json', JSON.stringify(packageJson, null, 2));
    console.log('\nPackage.json saved as: pdf-converter-package.json');
    console.log('Run: npm install --prefix . --package-lock-only=false marked puppeteer');
}