const fs = require('fs');
const path = require('path');
const s2v = require('svg2vectordrawable');

const svgDir = path.join(__dirname, 'assets', 'symbols', 'fill', 'svg-static');
const drawableDir = path.join(__dirname, 'android', 'app', 'src', 'main', 'res', 'drawable');

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
    const xmlFile = path.join(drawableDir, `ic_${symbol.replace(/-/g, '_')}.xml`);

    if (fs.existsSync(svgFile)) {
      const svgCode = fs.readFileSync(svgFile, 'utf8');
      try {
        const xmlCode = await s2v(svgCode);
        fs.writeFileSync(xmlFile, xmlCode);
        console.log(`Converted ${symbol}.svg to ic_${symbol.replace(/-/g, '_')}.xml`);
      } catch (err) {
        console.error(`Failed to convert ${symbol}.svg: ${err}`);
      }
    } else {
      console.warn(`File not found: ${svgFile}`);
    }
  }
}

convertSvgs();
