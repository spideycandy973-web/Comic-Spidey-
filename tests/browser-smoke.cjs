// Run on GitHub's Ubuntu runner, which provides Google Chrome.
const { chromium } = require('playwright-core');
const assert = require('node:assert/strict');
(async () => {
  const browser = await chromium.launch({executablePath:'/usr/bin/google-chrome', headless:true, args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
  const page = await browser.newPage({viewport:{width:640,height:360}});
  const errors=[]; page.on('pageerror', e=>errors.push(e.message));
  try {
    await page.goto('http://127.0.0.1:8000', {waitUntil:'load'});
    await page.waitForTimeout(1000);
    assert.equal(await page.locator('#error').isVisible(), false, 'WebGL started');
    await page.waitForFunction(()=>document.body.dataset.heroModel && document.body.dataset.docModel && document.body.dataset.citizenModel, null, {timeout:30000});
    assert.equal(await page.locator('body').getAttribute('data-hero-model'),'loaded','rigged Spider-Man model loaded');
    assert.equal(await page.locator('body').getAttribute('data-doc-model'),'loaded','Doctor Octopus model loaded');
    assert.equal(await page.locator('body').getAttribute('data-citizen-model'),'loaded','rigged citizen models loaded');
    await page.click('#play');
    assert.match(await page.locator('#objective').innerText(), /Investigate the plaza/);
    assert.equal(await page.locator('#districtName').innerText(),'DOWNTOWN');
    assert.equal(await page.locator('#minimap').isVisible(),true);
    assert.ok(parseInt(await page.locator('body').getAttribute('data-loaded-chunks'),10)<=9);
    assert.equal(await page.locator('#bossHud').isVisible(), false);
    await page.click('#camera'); assert.match(await page.locator('#camera').innerText(), /1ST/);
    await page.click('#camera'); assert.match(await page.locator('#camera').innerText(), /TOP/);
    await page.click('#camera'); assert.match(await page.locator('#camera').innerText(), /3RD/);
    await page.keyboard.down('w');
    let hit=false;
    for(let i=0;i<140;i++){
      await page.keyboard.press('f'); await page.waitForTimeout(250);
      const width=await page.locator('#bossBar').evaluate(el=>parseFloat(el.style.width));
      if(width<100){hit=true; break;}
    }
    await page.keyboard.up('w');
    assert.ok(hit,`player can reach the story objective and damage the villain (objective: ${await page.locator('#objective').innerText()}, health: ${await page.locator('#playerHealth').innerText()}, notice: ${await page.locator('#notice').innerText()})`);
    assert.equal(await page.locator('#bossName').innerText(), 'VOLT');
    await page.keyboard.press('g'); await page.waitForFunction(()=>Number(document.querySelector('#webStatus').dataset.energy)<100,null,{timeout:20000});
    assert.match(await page.locator('#notice').innerText(),/WEB HIT/);
    await page.keyboard.press('q'); assert.match(await page.locator('#notice').innerText(),/DODGE/);
    assert.equal(await page.evaluate(()=>JSON.parse(localStorage.getItem('comic-story-v1')).stage),1);
    await page.click('#pause'); assert.equal(await page.locator('#pausePanel').isVisible(),true);
    await page.click('#toMenu'); assert.equal(await page.locator('#continueStory').isVisible(),true);
    await page.click('#continueStory'); assert.equal(await page.locator('#bossHud').isVisible(),true);
    await page.click('#pause'); await page.click('#resume'); assert.equal(await page.locator('#dialog').isVisible(),false);
    // Fresh free-roam session: interaction with a moving civilian and an actual assisted takeoff.
    await page.reload(); await page.click('#settingsOpen'); await page.selectOption('#lighting','cycle');
    await page.selectOption('#weather','rain'); await page.selectOption('#quality','low'); await page.selectOption('#touchSize','small');
    await page.check('#swapControls'); await page.uncheck('#sound');
    assert.equal(await page.locator('body').getAttribute('data-raining'),'true');
    assert.equal(await page.locator('body').getAttribute('data-quality'),'low');
    assert.equal(await page.locator('#gameView canvas').evaluate(el=>el.width),480);
    assert.equal(await page.locator('.hud-bottom').evaluate(el=>el.classList.contains('swapped')),true);
    await page.click('#settingsDone'); await page.reload(); await page.click('#settingsOpen');
    assert.equal(await page.locator('#weather').inputValue(),'rain'); assert.equal(await page.locator('#quality').inputValue(),'low');
    assert.equal(await page.locator('#swapControls').isChecked(),true); assert.equal(await page.locator('#sound').isChecked(),false);
    await page.selectOption('#weather','clear'); await page.selectOption('#quality','high'); await page.selectOption('#touchSize','normal'); await page.uncheck('#swapControls'); await page.click('#settingsDone');
    await page.click('#freeRoam');
    assert.equal(await page.locator('body').getAttribute('data-lighting'),'cycle');
    const sky=await page.locator('body').getAttribute('data-sky-color');
    await page.waitForFunction(initial=>document.body.dataset.skyColor!==initial,sky,{timeout:30000});
    assert.equal(await page.locator('#bossHud').isVisible(), false);
    await page.waitForFunction(()=>document.body.dataset.crimePhase==='active',null,{timeout:90000});
    assert.match(await page.locator('#objective').innerText(),/street crime/);
    await page.keyboard.down('s'); await page.keyboard.down('d');
    let nearby=false;
    for(let i=0;i<100;i++) { await page.waitForTimeout(100); if(await page.locator('#talk').getAttribute('data-nearby')==='true'){nearby=true;break;} }
    await page.keyboard.up('s'); await page.keyboard.up('d');
    assert.ok(nearby,'can approach a moving civilian');
    await page.keyboard.press('e'); assert.match(await page.locator('#notice').innerText(),/CIVILIAN:/);
    await page.reload(); await page.click('#freeRoam');
    await page.keyboard.down('Shift'); await page.waitForTimeout(700);
    assert.match(await page.locator('#webStatus').innerText(), /WEB ATTACHED/);
    assert.equal(await page.locator('body').getAttribute('data-hero-action'),'swing','rig animation switched to swing');
    assert.equal(await page.locator('body').getAttribute('data-web-origin'),'rigged-hand','web starts from the rigged hand');
    assert.ok(parseFloat(await page.locator('#webStatus').getAttribute('data-altitude'))>.5,'assisted swing leaves the ground');
    await page.keyboard.up('Shift');
    await page.waitForFunction(()=>document.querySelector('#webStatus').textContent.includes('WEB READY'),null,{timeout:20000});
    assert.match(await page.locator('#webStatus').innerText(),/WEB READY/);
    await page.evaluate(()=>localStorage.setItem('comic-story-v1',JSON.stringify({stage:3})));
    await page.reload(); await page.waitForFunction(()=>document.body.dataset.docModel==='loaded',null,{timeout:30000});
    await page.click('#continueStory');
    assert.equal(await page.locator('body').getAttribute('data-city-chunk'),'0,-1','moving to a distant checkpoint loads the correct chunk');
    assert.ok(parseInt(await page.locator('body').getAttribute('data-loaded-chunks'),10)<=9,'rendered chunks stay bounded');
    assert.equal(await page.locator('#bossName').innerText(),'DOCTOR OCTOPUS');
    assert.equal(await page.locator('body').getAttribute('data-boss-model'),'docock','actual Doctor Octopus mesh is in the scene');
    assert.deepEqual(errors,[]);
    console.log('Browser smoke test passed: WebGL, cameras, villain damage, civilian interaction and swing takeoff/release.');
  } finally {await browser.close();}
})().catch(err=>{console.error(err);console.error('::error::'+String(err.stack||err).replace(/%/g,'%25').replace(/\n/g,'%0A').replace(/\r/g,'%0D'));process.exit(1);});
