const fs = require('fs');

// Create a simpler HTML version optimized for PDF conversion
function createPrintOptimizedHTML() {
    const markdownContent = fs.readFileSync('rapport-projet-fin-annee.md', 'utf8');
    
    // Simple but effective markdown to HTML conversion
    let html = markdownContent;
    
    // Convert headers with proper hierarchy
    html = html.replace(/^### (.*$)/gim, '<h3>$1</h3>');
    html = html.replace(/^## (.*$)/gim, '<h2>$1</h2>');
    html = html.replace(/^# (.*$)/gim, '<h1>$1</h1>');
    
    // Convert formatting
    html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
    html = html.replace(/\*(.*?)\*/g, '<em>$1</em>');
    
    // Convert code blocks
    html = html.replace(/```[\s\S]*?```/g, function(match) {
        const code = match.replace(/```\w*\n?/, '').replace(/```$/, '');
        return `<pre class="code-block">${code}</pre>`;
    });
    
    html = html.replace(/`([^`]+)`/g, '<code>$1</code>');
    
    // Convert lists
    html = html.replace(/^[\*\-] (.+)$/gim, '<li>$1</li>');
    html = html.replace(/^\d+\. (.+)$/gim, '<li>$1</li>');
    
    // Wrap list items
    html = html.replace(/((<li>.*?<\/li>\s*)+)/gs, '<ul>$1</ul>');
    
    // Convert line breaks to paragraphs
    html = html.split('\n\n').map(paragraph => {
        if (paragraph.trim() && 
            !paragraph.includes('<h') && 
            !paragraph.includes('<ul') && 
            !paragraph.includes('<pre') && 
            !paragraph.includes('<li>')) {
            return `<p>${paragraph.trim()}</p>`;
        }
        return paragraph;
    }).join('\n');
    
    return html;
}

const htmlContent = createPrintOptimizedHTML();

const optimizedHTML = `<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Rapport de Projet - AWS S3 Manager</title>
    <style>
        @page {
            size: A4;
            margin: 20mm;
        }
        
        body {
            font-family: Arial, sans-serif;
            font-size: 12pt;
            line-height: 1.6;
            color: #000;
            margin: 0;
            padding: 0;
        }
        
        h1 {
            font-size: 18pt;
            color: #1a237e;
            margin: 30pt 0 15pt 0;
            page-break-before: always;
            border-bottom: 2pt solid #1a237e;
            padding-bottom: 5pt;
        }
        
        h1:first-of-type {
            page-break-before: avoid;
        }
        
        h2 {
            font-size: 16pt;
            color: #283593;
            margin: 25pt 0 12pt 0;
            border-bottom: 1pt solid #283593;
            padding-bottom: 3pt;
        }
        
        h3 {
            font-size: 14pt;
            color: #3949ab;
            margin: 20pt 0 10pt 0;
        }
        
        p {
            margin: 8pt 0;
            text-align: justify;
        }
        
        ul {
            margin: 8pt 0;
            padding-left: 20pt;
        }
        
        li {
            margin: 4pt 0;
        }
        
        code {
            font-family: Consolas, monospace;
            background-color: #f5f5f5;
            padding: 2pt 4pt;
            font-size: 10pt;
        }
        
        .code-block {
            font-family: Consolas, monospace;
            background-color: #f8f8f8;
            border: 1pt solid #ddd;
            padding: 10pt;
            margin: 10pt 0;
            font-size: 9pt;
            line-height: 1.4;
            page-break-inside: avoid;
            white-space: pre-wrap;
            word-wrap: break-word;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 10pt 0;
            page-break-inside: avoid;
        }
        
        th, td {
            border: 1pt solid #000;
            padding: 6pt;
            text-align: left;
        }
        
        th {
            background-color: #f0f0f0;
            font-weight: bold;
        }
        
        strong {
            font-weight: bold;
        }
        
        em {
            font-style: italic;
        }
        
        @media print {
            body {
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
        }
    </style>
</head>
<body>
    ${htmlContent}
</body>
</html>`;

fs.writeFileSync('rapport-simple.html', optimizedHTML);

console.log('✓ Simplified HTML report created: rapport-simple.html');
console.log('');
console.log('📄 Alternative PDF creation methods:');
console.log('');
console.log('Method 1 - Browser Print (Recommended):');
console.log('  1. Open rapport-simple.html in Chrome or Edge');
console.log('  2. Press Ctrl+P');
console.log('  3. Choose "Save as PDF"');
console.log('  4. Make sure "More settings" → "Graphics" is checked');
console.log('  5. Save the file');
console.log('');
console.log('Method 2 - Online Converter:');
console.log('  1. Go to https://html-pdf-converter.com/');
console.log('  2. Upload rapport-simple.html');
console.log('  3. Download the generated PDF');
console.log('');
console.log('Method 3 - Microsoft Word:');
console.log('  1. Open rapport-simple.html in Microsoft Word');
console.log('  2. File → Save As → PDF');
console.log('');
console.log('Method 4 - LibreOffice:');
console.log('  1. Open LibreOffice Writer');
console.log('  2. File → Open → Select rapport-simple.html');
console.log('  3. File → Export as PDF');