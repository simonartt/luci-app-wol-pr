const path = require('path');
const pnpm = 'C:/Users/Administrator/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/.pnpm';
const pwCore = path.join(pnpm, 'playwright-core@1.60.0/node_modules/playwright-core');
const pw = path.join(pnpm, 'playwright@1.60.0/node_modules/playwright');
const oldNP = process.env.NODE_PATH || '';
process.env.NODE_PATH = pwCore + ';' + pw + ';' + oldNP;
delete require.cache;
const Module = require('module');
Module._initPaths();
const { chromium } = require(pw);
(async () => {
  try {
    const b = await chromium.launch({ headless: true, executablePath: null });
    const p = await b.newPage({ viewport: { width: 1440, height: 1000 } });
    await p.goto('file:///D:/traecx/openwrt2/wol/luci-app-wol-pro/luasrc/view/wol-pro/prototype-index.html');
    await p.waitForTimeout(1500);
    await p.screenshot({ path: 'D:/traecx/openwrt2/wol/prototype-v2.png', fullPage: true });
    await b.close();
    console.log('Screenshot saved successfully');
  } catch(e) {
    console.error('Error:', e.message);
    // Try with an alternative approach
    try {
      const b2 = await chromium.launch({ headless: true });
      const p2 = await b2.newPage({ viewport: { width: 1440, height: 1000 } });
      await p2.goto('file:///D:/traecx/openwrt2/wol/luci-app-wol-pro/luasrc/view/wol-pro/prototype-index.html');
      await p2.waitForTimeout(1500);
      await p2.screenshot({ path: 'D:/traecx/openwrt2/wol/prototype-v2.png', fullPage: true });
      await b2.close();
      console.log('Screenshot saved (second attempt)');
    } catch(e2) {
      console.error('Final error:', e2.message);
    }
  }
})();
