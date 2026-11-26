const fs = require('node:fs/promises');
const path = require('node:path');
const { chromium } = require('playwright');
const sharp = require('sharp');

const source = path.join(__dirname, 'source');
const output = path.resolve(__dirname, '../../../build/app-store/2.7.0');
const languages = [
  { tag: 'en-US', lang: 'en', first: 'Your playlist.', second: 'Live TV.' },
  { tag: 'zh-Hans', lang: 'zh', first: '导入播放列表', second: '看直播' },
];

function writePng(image, filename) {
  return image.removeAlpha().toColourspace('srgb').withIccProfile('srgb')
    .png({ compressionLevel: 9 }).toFile(path.join(output, filename));
}

function dataUrl(png) {
  return 'data:image/png;base64,' + png.toString('base64');
}

async function renderSearch(browser, template, scene, language, safeArea) {
  const page = await browser.newPage({ viewport: { width: 960, height: 640 }, deviceScaleFactor: 4 });
  try {
    const controls = await fs.readFile(path.join(source, 'controls-' + language.lang + '.png'));
    const fields = { ...language, scene, controls: dataUrl(controls) };
    const markup = template.replace(/{{(\w+)}}/g, (_, key) =>
      fields[key].replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('"', '&quot;'));
    await page.setContent(markup, { waitUntil: 'load' });
    const boxes = await page.evaluate(async () => {
      await Promise.all([...document.images].map(image => image.decode()));
      await document.fonts.ready;

      return Object.fromEntries(['first', 'second', 'controls'].map(name => {
        const box = document.querySelector('.' + name).getBoundingClientRect();
        const pixels = [box.left, box.top, box.right, box.bottom]
          .map(value => Math.round(value * window.devicePixelRatio));
        return [name, pixels];
      }));
    });

    const [left, top, right, bottom] = safeArea;
    for (const [name, box] of Object.entries(boxes)) {
      if (box[0] < left || box[1] < top || box[2] > right || box[3] > bottom) {
        throw new Error(`${language.tag} ${name} exceeds the search art safe area: ${box}`);
      }
    }
    const pixels = await page.screenshot({ type: 'png', animations: 'disabled' });
    await writePng(sharp(pixels), 'XPlayer-Search-' + language.tag + '.png');
  } finally {
    await page.close();
  }
}

async function main() {
  await fs.mkdir(output, { recursive: true });
  const header = sharp(path.join(source, 'header-art.png'))
    .extract({ left: 135, top: 51, width: 1645, height: 705 })
    .resize(3840, 1646, { fit: 'fill', kernel: 'lanczos3' });
  await writePng(header, 'XPlayer-Header.png');

  const scene = await sharp(path.join(source, 'search-art.png'))
    .extract({ left: 306, top: 92, width: 1230, height: 820 })
    .resize(3840, 2560).png().toBuffer();
  const template = await fs.readFile(path.join(source, 'search.html'), 'utf8');
  const layout = JSON.parse(await fs.readFile(path.join(source, 'layout.json'), 'utf8'));
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  try {
    const background = dataUrl(scene);
    for (const language of languages) {
      await renderSearch(browser, template, background, language, layout.search.safeArea);
    }
  } finally {
    await browser.close();
  }
  console.log('Wrote three PNGs to ' + output);
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
