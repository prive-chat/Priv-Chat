import Jimp from 'jimp';
import fs from 'fs';
import path from 'path';

async function processLogo() {
  const inputPath = 'public/icon.png';
  
  if (!fs.existsSync(inputPath)) {
    console.warn(`Master logo not found at ${inputPath}. Skipping asset generation.`);
    return;
  }

  // --- AUTO-REPAIR PNG (IEND CHUNK) ---
  // Some uploaded PNGs have extra trailing data that crashes standard parsers
  try {
    const buf = fs.readFileSync(inputPath);
    if (buf.length > 8) {
      const iend = buf.lastIndexOf(Buffer.from([0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82]));
      if (iend !== -1 && iend + 8 < buf.length) {
        console.log('Detected trailing data in PNG. Repairing...');
        fs.writeFileSync(inputPath, buf.slice(0, iend + 8));
      }
    }
  } catch (e) {
    console.warn('Failed to repair PNG header, attempt load anyway.');
  }
  // ------------------------------------

  console.log('Processing master logo...');
  let image;
  try {
    image = await Jimp.read(inputPath);
  } catch (err) {
    console.error(`Jimp could not read the image: ${err.message}`);
    console.warn('Proceeding without new asset generation.');
    return;
  }

  const { width, height } = image.bitmap;

  // 1. Clean background (Checkerboard removal)
  // Sample corners for bg colors
  const bgColors = new Set();
  const samplePoints = [[0, 0], [width - 1, 0], [0, height - 1], [width - 1, height - 1]];
  for (const [px, py] of samplePoints) {
    bgColors.add(image.getPixelColor(px, py));
  }

  const bgRGBA = Array.from(bgColors).map(c => Jimp.intToRGBA(c));
  let cleanedCount = 0;

  image.scan(0, 0, width, height, function(x, y, idx) {
    const r = this.bitmap.data[idx + 0];
    const g = this.bitmap.data[idx + 1];
    const b = this.bitmap.data[idx + 2];
    
    for (const bg of bgRGBA) {
      const diff = Math.abs(r - bg.r) + Math.abs(g - bg.g) + Math.abs(b - bg.b);
      if (diff < 35) { // Tolerance for edge artifacts
        this.bitmap.data[idx + 3] = 0;
        cleanedCount++;
        break;
      }
    }
  });

  console.log(`Background cleaning: ${cleanedCount} pixels transparency achieved.`);

  // 2. Generate assets
  const assets = [
    { name: 'apple-touch-icon.png', size: 180 },
    { name: 'icon-192.png', size: 192 },
    { name: 'icon-512.png', size: 512 },
    { name: 'favicon-32.png', size: 32 },
    { name: 'favicon-16.png', size: 16 }
  ];

  for (const asset of assets) {
    console.log(`Generating ${asset.name}...`);
    const resized = image.clone().resize(asset.size, asset.size);
    await resized.writeAsync(path.join('public', asset.name));
  }

  // Update original icon.png with cleaned version if it was processed
  if (cleanedCount > 0) {
    await image.writeAsync(inputPath);
    console.log('Master icon.png updated with transparency.');
  }

  console.log('Branding assets ready for deployment.');
}

processLogo().catch(err => {
  console.error('Asset generation failed:', err);
  process.exit(1);
});
