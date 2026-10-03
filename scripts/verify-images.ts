import fs from 'node:fs';
import path from 'node:path';

// Define the expected 58 image IDs based on the brand lock registry
const expectedIds = [
  'A01', 'A02', 'A03', 'A04', 'A05', 'A06',
  'B01', 'B02', 'B03', 'B04', 'B05', 'B06',
  'C01', 'C02', 'C03', 'C04',
  'D01', 'D02', 'D03', 'D04', 'D05',
  'E01', 'E02', 'E03',
  'F01', 'F02', 'F03',
  'G01', 'G02',
  'H01', 'H02', 'H03',
  'I01', 'I02', 'I03',
  'J01', 'J02', 'J03', 'J04', 'J05', 'J06', 'J07', 'J08',
  'K01', 'K02', 'K03',
  'L01', 'L02', 'L03',
  'M01', 'M02', 'M03',
  'N01', 'N02', 'N03', 'N04', 'N05', 'N06'
];

const originalsDir = path.join(process.cwd(), 'apps/web/public/images/originals');

function verifyImages() {
  console.log('Verifying image registry...');
  
  if (!fs.existsSync(originalsDir)) {
    console.error(`Originals directory not found: ${originalsDir}`);
    fs.mkdirSync(originalsDir, { recursive: true });
    // Don't exit yet, let it print the missing table
  }

  const files = fs.existsSync(originalsDir) ? fs.readdirSync(originalsDir) : [];
  
  const foundIds = new Set<string>();
  const duplicates = new Set<string>();
  
  for (const file of files) {
    const match = file.match(/^31deg_([A-Z]\d{2})_.*\.(png|jpg|jpeg|webp|avif)$/);
    if (match) {
      const id = match[1];
      if (foundIds.has(id)) {
        duplicates.add(id);
      } else {
        foundIds.add(id);
      }
    }
  }

  console.log('\n--- IMAGE REGISTRY REPORT ---');
  console.log('ID\t| STATUS');
  console.log('------------------------');
  
  let allFound = true;
  for (const id of expectedIds) {
    if (foundIds.has(id)) {
      if (duplicates.has(id)) {
        console.log(`${id}\t| DUPLICATE (FAIL)`);
        allFound = false;
      } else {
        console.log(`${id}\t| FOUND`);
      }
    } else {
      console.log(`${id}\t| MISSING (FAIL)`);
      allFound = false;
    }
  }

  console.log('------------------------');
  const foundCount = foundIds.size;
  const expectedCount = expectedIds.length;
  console.log(`Summary: ${foundCount}/${expectedCount} IDs found.`);
  
  if (!allFound) {
    console.error('\nERROR: Image registry verification failed. Missing or duplicate IDs found.');
    process.exit(1);
  } else {
    console.log('\nSUCCESS: Image registry verified (58/58).');
  }
}

verifyImages();
