const fs = require('fs');

// Simple markdown to HTML converter for basic elements
function simpleMarkdownToHtml(markdown) {
    let html = markdown;
    
    // Convert headers
    html = html.replace(/^### (.*$)/gim, '<h3>$1</h3>');
    html = html.replace(/^## (.*$)/gim, '<h2>$1</h2>');
    html = html.replace(/^# (.*$)/gim, '<h1>$1</h1>');
    
    // Convert bold and italic
    html = html.replace(/\*\*\*(.*)\*\*\*/gim, '<strong><em>$1</em></strong>');
    html = html.replace(/\*\*(.*)\*\*/gim, '<strong>$1</strong>');
    html = html.replace(/\*(.*)\*/gim, '<em>$1</em>');
    
    // Convert links
    html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/gim, '<a href="$2">$1</a>');
    
    // Convert code blocks
    html = html.replace(/```(\w+)?\n([\s\S]*?)```/gim, '<pre><code class="language-$1">$2</code></pre>');
    html = html.replace(/`([^`]+)`/gim, '<code>$1</code>');
    
    // Convert lists
    html = html.replace(/^\* (.+)$/gim, '<li>$1</li>');
    html = html.replace(/^- (.+)$/gim, '<li>$1</li>');
    html = html.replace(/^\d+\. (.+)$/gim, '<li>$1</li>');
    
    // Wrap consecutive list items
    html = html.replace(/(<li>.*<\/li>\n)+/gim, function(match) {
        return '<ul>\n' + match + '</ul>\n';
    });
    
    // Convert horizontal rules
    html = html.replace(/^---$/gim, '<hr>');
    
    // Convert paragraphs
    html = html.replace(/\n\n/gim, '</p><p>');
    html = '<p>' + html + '</p>';
    
    // Clean up
    html = html.replace(/<p><h/gim, '<h');
    html = html.replace(/<\/h(\d)><\/p>/gim, '</h$1>');
    html = html.replace(/<p><ul>/gim, '<ul>');
    html = html.replace(/<\/ul><\/p>/gim, '</ul>');
    html = html.replace(/<p><pre>/gim, '<pre>');
    html = html.replace(/<\/pre><\/p>/gim, '</pre>');
    html = html.replace(/<p><hr><\/p>/gim, '<hr>');
    html = html.replace(/<p><\/p>/gim, '');
    
    return html;
}

// Read the markdown file
const markdownContent = fs.readFileSync('rapport-projet-fin-annee.md', 'utf8');

// Convert to HTML
const htmlContent = simpleMarkdownToHtml(markdownContent);

// Create full HTML document
const fullHtml = `<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Projet de Fin d'Année - AWS S3 Manager</title>
    <style>
        @page {
            size: A4;
            margin: 2cm;
        }
        
        * {
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', 'Arial', sans-serif;
            line-height: 1.8;
            color: #2c3e50;
            max-width: 210mm;
            margin: 0 auto;
            padding: 20px;
            background-color: #fff;
        }
        
        h1 {
            color: #1a237e;
            font-size: 28px;
            border-bottom: 3px solid #3f51b5;
            padding-bottom: 15px;
            margin: 40px 0 30px 0;
            page-break-before: always;
        }
        
        h1:first-of-type {
            page-break-before: avoid;
            margin-top: 0;
        }
        
        h2 {
            color: #283593;
            font-size: 22px;
            margin: 30px 0 20px 0;
            border-bottom: 2px solid #e8eaf6;
            padding-bottom: 10px;
        }
        
        h3 {
            color: #3949ab;
            font-size: 18px;
            margin: 25px 0 15px 0;
        }
        
        h4 {
            color: #5c6bc0;
            font-size: 16px;
            margin: 20px 0 10px 0;
        }
        
        p {
            margin: 12px 0;
            text-align: justify;
        }
        
        code {
            background-color: #f5f5f5;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 0.9em;
            color: #d32f2f;
        }
        
        pre {
            background-color: #263238;
            color: #aed581;
            border-radius: 8px;
            padding: 20px;
            overflow-x: auto;
            font-size: 14px;
            line-height: 1.5;
            margin: 20px 0;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        pre code {
            background-color: transparent;
            color: inherit;
            padding: 0;
        }
        
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 20px 0;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        th, td {
            border: 1px solid #e0e0e0;
            padding: 12px;
            text-align: left;
        }
        
        th {
            background-color: #3f51b5;
            color: white;
            font-weight: 600;
        }
        
        tr:nth-child(even) {
            background-color: #f5f5f5;
        }
        
        blockquote {
            border-left: 4px solid #3f51b5;
            margin: 20px 0;
            padding: 10px 20px;
            background-color: #e8eaf6;
            font-style: italic;
        }
        
        ul, ol {
            margin: 15px 0;
            padding-left: 30px;
        }
        
        li {
            margin: 8px 0;
        }
        
        hr {
            border: none;
            border-top: 2px solid #e0e0e0;
            margin: 40px 0;
        }
        
        a {
            color: #3f51b5;
            text-decoration: none;
        }
        
        a:hover {
            text-decoration: underline;
        }
        
        .highlight {
            background-color: #fff9c4;
            padding: 15px;
            border-left: 4px solid #fbc02d;
            margin: 20px 0;
            border-radius: 4px;
        }
        
        .page-break {
            page-break-after: always;
        }
        
        .cover-page {
            text-align: center;
            padding: 100px 20px;
            page-break-after: always;
        }
        
        .cover-page h1 {
            font-size: 36px;
            border: none;
            margin-bottom: 50px;
            color: #1a237e;
        }
        
        .cover-page p {
            font-size: 18px;
            margin: 10px 0;
            text-align: center;
        }
        
        @media print {
            body {
                font-size: 11pt;
                padding: 0;
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
                font-size: 9pt;
            }
            
            table {
                page-break-inside: avoid;
            }
            
            .page-break {
                page-break-after: always;
            }
        }
    </style>
</head>
<body>
    ${htmlContent}
    
    <script>
        // Add print instructions
        if (window.location.protocol === 'file:') {
            const printNote = document.createElement('div');
            printNote.style.cssText = 'position: fixed; top: 10px; right: 10px; background: #3f51b5; color: white; padding: 10px 20px; border-radius: 5px; font-size: 14px; z-index: 1000; cursor: pointer;';
            printNote.innerHTML = 'Cliquez ici ou Ctrl+P pour imprimer en PDF';
            printNote.onclick = () => window.print();
            document.body.appendChild(printNote);
        }
    </script>
</body>
</html>`;

// Save HTML file
fs.writeFileSync('rapport-projet-fin-annee.html', fullHtml);

console.log('HTML report generated successfully: rapport-projet-fin-annee.html');
console.log('');
console.log('To convert to PDF:');
console.log('1. Open rapport-projet-fin-annee.html in your web browser');
console.log('2. Press Ctrl+P (or Cmd+P on Mac) to open print dialog');
console.log('3. Select "Save as PDF" as the destination');
console.log('4. Click "Save" and choose where to save the PDF file');
console.log('');
console.log('The HTML file includes print-optimized CSS for proper PDF formatting.');