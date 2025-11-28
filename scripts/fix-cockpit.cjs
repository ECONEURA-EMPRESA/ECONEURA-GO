const fs = require('fs');
const path = 'packages/frontend/src/EconeuraCockpit.tsx';
const lines = fs.readFileSync(path, 'utf8').split('\n');

// Remove lines 612 to 848 (1-based)
// 0-based: 611 to 847
const start = 611;
const end = 847;

// Verify content before deleting to be super safe
const startLine = lines[start];
const endLine = lines[end];

console.log('Start line content:', startLine);
console.log('End line content:', endLine);

if (startLine.trim() === '// Funciones de chat movidas a useNeuraChat' && endLine.trim() === '}') {
    lines.splice(start, end - start + 1);
    fs.writeFileSync(path, lines.join('\n'));
    console.log('Successfully removed lines.');
} else {
    console.error('Safety check failed. Lines do not match expected content.');
    console.error('Expected start: // Funciones de chat movidas a useNeuraChat');
    console.error('Expected end: }');
}
