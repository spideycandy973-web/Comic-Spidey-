// Run on GitHub's Ubuntu runner, which provides Google Chrome.
const { chromium } = require('playwright-core');
const assert = require('node:assert/strict');
(async () => {
  const browser = await chromium.launch({executablePath:'/usr/bin/google-chrome', headless:true, args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
  const page = await browser.newPage({viewport:{width:1280,height:720}});
  const errors=[]; page.on('pageerror', e=>errors.push(e.message));
  try {
    await page.goto('http://127.0.0.1:8000', {waitUntil:'load'});
    await page.waitForTimeout(1000);
    assert.equal(await page.locator('#error').isVisible(), false, 'WebGL started');
    await page.click('#play');
    assert.equal(await page.locator('#bossName').innerText(), 'VOLT');
    await page.click('#camera'); assert.match(await page.locator('#camera').innerText(), /1ST/);
    await page.click('#camera'); assert.match(await page.locator('#camera').innerText(), /3RD/);
    await page.keyboard.down('w');
    let hit=false;
    for(let i=0;i<18;i++){
      await page.keyboard.press('f'); await page.waitForTimeout(250);
      const width=await page.locator('#bossBar').evaluate(el=>parseFloat(el.style.width));
      if(width<100){hit=true; break;}
    }
    await page.keyboard.up('w');
    assert.ok(hit,'player can approach and damage the villain');
    await page.click('#pause'); assert.equal(await page.locator('#pausePanel').isVisible(),true);
    await page.click('#resume'); assert.equal(await page.locator('#dialog').isVisible(),false);
    assert.deepEqual(errors,[]);
    console.log('Browser smoke test passed: WebGL, both cameras, movement, villain damage, pause/resume.');
  } finally {await browser.close();}
})().catch(err=>{console.error(err);process.exit(1);});
