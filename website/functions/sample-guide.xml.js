// A rolling XMLTV fixture for the optional App Review playlist. All titles and
// times are demonstration data, independent of the on-demand sample streams.
export function onRequestGet() {
  const hour = 3_600_000;
  const start = Math.floor(Date.now() / hour) * hour;
  const channels = [
    ['sample.bunny', 'Big Buck Bunny', ['Bunny — Opening', 'Bunny — Animation Showcase']],
    ['sample.steel', 'Tears of Steel', ['Steel — Studio Session', 'Steel — Visual Effects']],
  ];
  const xmlTime = ms => new Date(ms).toISOString().slice(0, 19).replace(/[-:T]/g, '') + ' +0000';
  const elements = ['<?xml version="1.0" encoding="UTF-8"?>', '<tv generator-info-name="XPlayer sample guide">'];
  for (const [id, name] of channels) elements.push(`<channel id="${id}"><display-name>${name}</display-name></channel>`);
  for (let slot = 0; slot < 48; slot++) {
    for (const [id, , titles] of channels) {
      elements.push(`<programme channel="${id}" start="${xmlTime(start + slot * hour)}" stop="${xmlTime(start + (slot + 1) * hour)}"><title>${titles[slot % titles.length]}</title></programme>`);
    }
  }
  elements.push('</tv>');
  return new Response(elements.join('\n'), {headers: {'Content-Type': 'application/xml; charset=utf-8', 'Cache-Control': 'public, max-age=900'}});
}
