const fs = require('fs');

// Create a Word-compatible RTF document
function createRTFDocument() {
    const markdownContent = fs.readFileSync('rapport-projet-fin-annee.md', 'utf8');
    
    // Convert markdown to RTF format
    let rtf = markdownContent;
    
    // Clean up markdown syntax for RTF
    rtf = rtf.replace(/^### (.*$)/gim, '\\par\\b\\fs24 $1\\b0\\fs22\\par');
    rtf = rtf.replace(/^## (.*$)/gim, '\\par\\b\\fs28 $1\\b0\\fs22\\par');
    rtf = rtf.replace(/^# (.*$)/gim, '\\page\\par\\b\\fs32 $1\\b0\\fs22\\par');
    
    // Convert formatting
    rtf = rtf.replace(/\*\*(.*?)\*\*/g, '\\b $1\\b0');
    rtf = rtf.replace(/\*(.*?)\*/g, '\\i $1\\i0');
    rtf = rtf.replace(/`([^`]+)`/g, '\\f1 $1\\f0');
    
    // Convert code blocks
    rtf = rtf.replace(/```[\s\S]*?```/g, function(match) {
        const code = match.replace(/```\w*\n?/, '').replace(/```$/, '');
        return `\\par\\f1\\fs20 ${code}\\f0\\fs22\\par`;
    });
    
    // Convert line breaks
    rtf = rtf.replace(/\n\n/g, '\\par\\par');
    rtf = rtf.replace(/\n/g, '\\par');
    
    // RTF header and footer
    const rtfDocument = `{\\rtf1\\ansi\\deff0
{\\fonttbl{\\f0 Times New Roman;}{\\f1 Courier New;}}
{\\colortbl;\\red0\\green0\\blue0;\\red26\\green35\\blue126;}
\\paperw11906\\paperh16838\\margl1440\\margr1440\\margt1440\\margb1440
\\fs22
${rtf}
}`;

    return rtfDocument;
}

// Create RTF file
const rtfContent = createRTFDocument();
fs.writeFileSync('rapport-projet-fin-annee.rtf', rtfContent);

// Also create a plain text version
const markdownContent = fs.readFileSync('rapport-projet-fin-annee.md', 'utf8');
const txtContent = markdownContent
    .replace(/^#{1,6}\s*/gm, '')  // Remove markdown headers
    .replace(/\*\*(.*?)\*\*/g, '$1')  // Remove bold
    .replace(/\*(.*?)\*/g, '$1')      // Remove italic
    .replace(/`([^`]+)`/g, '$1')      // Remove inline code
    .replace(/```[\s\S]*?```/g, function(match) {
        return match.replace(/```\w*\n?/, '').replace(/```$/, '');
    });

fs.writeFileSync('rapport-projet-fin-annee.txt', txtContent);

console.log('✅ Multiple format files created:');
console.log('');
console.log('📁 Files in your project folder:');
console.log('  • rapport-projet-fin-annee.md   (Original Markdown)');
console.log('  • rapport-projet-fin-annee.html (Full HTML version)');
console.log('  • rapport-simple.html           (Simplified HTML for PDF)');
console.log('  • rapport-projet-fin-annee.rtf  (Word-compatible RTF)');
console.log('  • rapport-projet-fin-annee.txt  (Plain text)');
console.log('');
console.log('🔧 PDF Creation Options:');
console.log('');
console.log('Option 1 - Use rapport-simple.html:');
console.log('  → Open in Chrome/Edge → Ctrl+P → Save as PDF');
console.log('');
console.log('Option 2 - Use rapport-projet-fin-annee.rtf:');
console.log('  → Open in Microsoft Word → File → Save As → PDF');
console.log('');
console.log('Option 3 - Online converter:');
console.log('  → Upload rapport-simple.html to any HTML-to-PDF converter');
console.log('');
console.log('Option 4 - LibreOffice:');
console.log('  → Open .rtf file → File → Export as PDF');
console.log('');
console.log('💡 If PDF generation still fails, the .rtf file can be opened');
console.log('   in any word processor and saved as PDF from there.');