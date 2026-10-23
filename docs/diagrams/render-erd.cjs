// Local artifact rendering only. Paths are supplied by the operator, not app dependencies.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const [playwrightPath, mermaidBundle, edgePath] = process.argv.slice(2);
if (!playwrightPath || !mermaidBundle || !edgePath) throw new Error('Supply Playwright module, Mermaid browser bundle, and browser executable paths.');
const { chromium } = require(path.resolve(playwrightPath));
const folder = __dirname;
const base = path.join(folder, 'ERD-full-attributes');
(async () => {
  const browser = await chromium.launch({ executablePath: path.resolve(edgePath), headless: true });
  try {
    const page = await browser.newPage({ viewport: { width: 1800, height: 1200 }, deviceScaleFactor: 1.5 });
    await page.setContent('<!doctype html><html><head><meta charset="utf-8"></head><body style="margin:0;background:white"></body></html>');
    await page.addScriptTag({ content: fs.readFileSync(mermaidBundle, 'utf8') });
    const result = await page.evaluate(async ({ code, config }) => {
      mermaid.initialize({ ...config, startOnLoad: false, securityLevel: 'strict' });
      const { svg } = await mermaid.render('erdFullAttributes', code);
      return svg;
    }, { code: fs.readFileSync(base + '.mmd', 'utf8'), config: JSON.parse(fs.readFileSync(path.join(folder, 'erd-render-config.json'), 'utf8')) });
    fs.writeFileSync(base + '.svg', result);
    await page.setContent('<!doctype html><html><head><meta charset="utf-8"></head><body style="margin:0;background:white">' + result + '</body></html>');
    const svg = page.locator('svg');
    const stats = await svg.evaluate(el => {
      const v = el.viewBox.baseVal;
      el.style.maxWidth = 'none';
      el.style.width = Math.ceil(v.width) + 'px';
      el.style.height = Math.ceil(v.height) + 'px';
      return { width: Math.ceil(v.width), height: Math.ceil(v.height), tables: el.querySelectorAll('.nodes .node').length, relations: el.querySelectorAll('.edgePaths path').length };
    });
    assert.equal(stats.tables, 12);
    assert.equal(stats.relations, 19);
    // Native Mermaid parses all attribute lines; verify each of 12 physical table labels.
    const source = fs.readFileSync(base + '.mmd', 'utf8');
    const tables = [...source.matchAll(/^    "?(\w+)"? \{$/gm)].map(m => m[1]);
    const renderedText = await svg.textContent();
    assert.equal(tables.length, 12);
    for (const name of tables) assert(renderedText.includes(name), name);
    const attrs = [...source.matchAll(/^        \S+ (\w+)/gm)].map(m => m[1]);
    assert.equal(attrs.length, 99);
    for (const attr of attrs) assert(renderedText.includes(attr), attr);
    await page.setViewportSize({ width: stats.width, height: stats.height });
    await svg.screenshot({ path: base + '.png' });
    await page.pdf({ path: base + '.pdf', width: stats.width + 'px', height: stats.height + 'px', margin: { top: 0, right: 0, bottom: 0, left: 0 }, printBackground: true });
    const receiptPath = path.resolve(folder, '../evidence/erd-full-attributes.json');
    const receipt = JSON.parse(fs.readFileSync(receiptPath, 'utf8'));
    receipt.render = 'PASS_NATIVE_MERMAID';
    receipt.renderDimensions = stats;
    receipt.files = Object.fromEntries(['md','mmd','svg','png','pdf'].map(ext => [path.basename(base)+'.'+ext,crypto.createHash('sha256').update(fs.readFileSync(base+'.'+ext)).digest('hex').toUpperCase()]));
    fs.writeFileSync(receiptPath, JSON.stringify(receipt, null, 2)+'\n');
    console.log(JSON.stringify({ pass: true, ...stats, attributes: attrs.length, format: 'native Mermaid ERD' }));
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
