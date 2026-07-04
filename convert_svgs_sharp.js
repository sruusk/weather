const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const svgDir = path.join(__dirname, 'assets', 'symbols', 'fill', 'svg-static');
const drawableDir = path.join(__dirname, 'android', 'app', 'src', 'main', 'res', 'drawable-xxhdpi');

const symbols = [
  'clear-day',
  'partly-cloudy-day',
  'cloudy',
  'overcast',
  'fog',
  'drizzle',
  'sleet',
  'rain',
  'overcast-rain',
  'extreme-rain',
  'snow',
  'overcast-snow',
  'extreme-snow',
  'thunderstorms',
  'thunderstorms-extreme',
  'partly-cloudy-day-rain',
  'partly-cloudy-day-snow',
  'not-available'
];

async function convertSvgs() {
  if (!fs.existsSync(drawableDir)) {
    fs.mkdirSync(drawableDir, { recursive: true });
  }

  for (const symbol of symbols) {
    const svgFile = path.join(svgDir, `${symbol}.svg`);
    const pngFile = path.join(drawableDir, `ic_${symbol.replace(/-/g, '_')}.png`);

    if (fs.existsSync(svgFile)) {
      try {
        await sharp(svgFile)
          .resize(192, 192) // Good resolution for xxhdpi
          .png()
          .toFile(pngFile);
        console.log(`Converted ${symbol}.svg to ic_${symbol.replace(/-/g, '_')}.png`);
      } catch (err) {
        console.error(`Failed to convert ${symbol}.svg: ${err}`);
      }
    } else {
      console.warn(`File not found: ${svgFile}`);
    }
  }
}

convertSvgs();
