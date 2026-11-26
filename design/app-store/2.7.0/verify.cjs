const { createHash } = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');
const sharp = require('sharp');

const archive = path.join(__dirname, 'exports');
const rendered = path.resolve(__dirname, '../../../build/app-store/2.7.0');

async function sha256(file) {
  return createHash('sha256').update(await fs.readFile(file)).digest('hex');
}

async function verify(name, expectedHash, dimensions) {
  const original = path.join(archive, name);
  const result = path.join(rendered, name);
  if (await sha256(original) !== expectedHash) {
    throw new Error('Archived upload changed: ' + name);
  }
  const [reference, actual] = await Promise.all([original, result].map(file => sharp(file).metadata()));
  for (const meta of [reference, actual]) {
    if (meta.format !== 'png' || meta.width !== dimensions[0] || meta.height !== dimensions[1] || meta.channels !== 3 ||
        meta.space !== 'srgb' || meta.hasAlpha || !meta.icc) {
      throw new Error('Unexpected PNG dimensions, channels or color profile: ' + name);
    }
  }
  if (!reference.icc.equals(actual.icc)) throw new Error('ICC profile differs: ' + name);
  if (await sha256(result) === expectedHash) {
    console.log(name + ': identical SHA-256');
    return;
  }

  const [a, b] = await Promise.all([original, result].map(file => sharp(file).raw().toBuffer()));
  let maxDifference = 0;
  for (let i = 0; i < a.length; i++) {
    const difference = Math.abs(a[i] - b[i]);
    if (difference > 1) {
      const pixel = Math.floor(i / 3);
      throw new Error(`${name}: channel difference ${difference} at (${pixel % actual.width}, ${Math.floor(pixel / actual.width)})`);
    }
    maxDifference = Math.max(maxDifference, difference);
  }
  console.log(`${name}: archived SHA-256 verified, largest rendered channel difference ${maxDifference}/255`);
}

async function main() {
  const checksums = await fs.readFile(path.join(archive, 'SHA256SUMS'), 'utf8');
  const hashes = new Map(checksums.trim().split('\n').map(line => {
    const [hash, name] = line.split('  ');
    return [name, hash];
  }));
  const receipt = JSON.parse(await fs.readFile(path.join(__dirname, 'verification.json'), 'utf8'));
  if (hashes.size !== 3 || Object.keys(receipt.assets).length !== 3) {
    throw new Error('Expected the header and both localized search images');
  }
  for (const [name, asset] of Object.entries(receipt.assets)) {
    await verify(name, hashes.get(name), asset.dimensions);
  }
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
