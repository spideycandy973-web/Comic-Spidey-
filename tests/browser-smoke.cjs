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
    await page.evaluate(()=>{window.mockPad={connected:true,mapping:'standard',axes:[0,0,0,0],buttons:Array.from({length:16},()=>({pressed:false}))};Object.defineProperty(navigator,'getGamepads',{configurable:true,value:()=>[window.mockPad]});});
    await page.waitForFunction(()=>document.body.dataset.gamepad==='connected',null,{timeout:20000});
    await page.evaluate(()=>window.mockPad.buttons[5].pressed=true);
    await page.waitForFunction(()=>document.querySelector('#camera').textContent.includes('1ST'),null,{timeout:20000});
    await page.evaluate(()=>{window.mockPad.buttons[5].pressed=false;}); await page.click('#camera'); await page.click('#camera');
    await page.evaluate(()=>Object.defineProperty(navigator,'getGamepads',{configurable:true,value:()=>[]}));
    await page.keyboard.press('Space');
    await page.waitForFunction(()=>['jump','fall'].includes(document.body.dataset.heroAction),null,{timeout:20000});
    await page.waitForFunction(()=>Number(document.querySelector('#webStatus').dataset.altitude)<.1,null,{timeout:30000});
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
    assert.equal(await page.evaluate(()=>JSON.parse(localStorage.getItem('comic-progress-v1')).xp),25);
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
    await page.click('#pause');
    const freeSave=await page.evaluate(()=>JSON.parse(localStorage.getItem('comic-free-v1')));
    assert.ok(Math.hypot(freeSave.x,freeSave.z-9)>1,'free-roam position is saved');
    await page.click('#toMenu'); assert.equal(await page.locator('#continueFree').isVisible(),true);
    assert.equal(await page.locator('#continueStory').isVisible(),true,'story and free saves coexist');
    await page.click('#continueFree');
    assert.ok(Math.abs(Number(await page.locator('body').getAttribute('data-player-x'))-freeSave.x)<.1,'free-roam position restored');
    assert.ok(Math.abs(Number(await page.locator('body').getAttribute('data-player-z'))-freeSave.z)<.1,'free-roam position restored');
    await page.reload(); await page.click('#freeRoam');
    await page.keyboard.down('Shift'); await page.waitForFunction(()=>Number(document.querySelector('#webStatus').dataset.altitude)>.5,null,{timeout:30000});
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
    // Continue directly at a mission checkpoint and verify that USE requires proximity.
    await page.evaluate(()=>localStorage.setItem('comic-story-v1',JSON.stringify({stage:5})));
    await page.reload(); await page.click('#continueStory');
    assert.equal(await page.locator('body').getAttribute('data-story-type'),'interact');
    await page.waitForFunction(()=>document.body.dataset.trafficCenter==='80,-160',null,{timeout:30000});
    assert.match(await page.locator('#talk').innerText(),/USE/);
    await page.keyboard.press('e'); assert.equal(await page.locator('body').getAttribute('data-story-type'),'interact');
    await page.keyboard.down('w');
    for(let i=0;i<100&&(await page.locator('body').getAttribute('data-story-type'))==='interact';i++){await page.keyboard.press('e');await page.waitForTimeout(150);}
    await page.keyboard.up('w'); assert.equal(await page.locator('body').getAttribute('data-story-type'),'travel');
    assert.equal(await page.evaluate(()=>JSON.parse(localStorage.getItem('comic-story-v1')).stage),6);
    // Escort follower is a visible citizen and moves as the player walks toward safety.
    await page.evaluate(()=>localStorage.setItem('comic-story-v1',JSON.stringify({stage:7})));
    await page.reload(); await page.click('#continueStory');
    assert.equal(await page.locator('body').getAttribute('data-story-type'),'escort');
    await page.keyboard.down('s'); await page.waitForFunction(()=>Number(document.body.dataset.escortZ)>-159,null,{timeout:60000}); await page.keyboard.up('s');
    // A crew checkpoint creates actual combat targets.
    await page.evaluate(()=>localStorage.setItem('comic-story-v1',JSON.stringify({stage:9})));
    await page.reload(); await page.click('#continueStory');
    assert.equal(await page.locator('body').getAttribute('data-story-type'),'crew');
    assert.equal(await page.locator('body').getAttribute('data-story-enemies'),'3');
    for(let i=0;i<240&&(await page.locator('body').getAttribute('data-story-enemies'))==='3';i++){await page.keyboard.press('f');await page.waitForTimeout(200);}
    assert.ok(Number(await page.locator('body').getAttribute('data-story-enemies'))<3,`crew can take combat damage and be defeated (health ${await page.locator('#playerHealth').innerText()}, notice ${await page.locator('#notice').innerText()})`);
    // A cosmetic tint genuinely changes the loaded material and survives reload.
    await page.evaluate(()=>localStorage.setItem('comic-progress-v1',JSON.stringify({xp:250,crimes:0,claimed:[]})));
    await page.reload(); await page.waitForFunction(()=>document.body.dataset.heroModel==='loaded',null,{timeout:30000});
    const originalTint=await page.locator('body').getAttribute('data-suit-color'); await page.click('#settingsOpen');
    await page.selectOption('#suitTint','sunset'); assert.equal(await page.locator('body').getAttribute('data-suit-tint'),'sunset');
    assert.notEqual(await page.locator('body').getAttribute('data-suit-color'),originalTint);
    await page.click('#settingsDone'); await page.reload(); await page.waitForFunction(()=>document.body.dataset.heroModel==='loaded',null,{timeout:30000});
    assert.equal(await page.locator('body').getAttribute('data-suit-tint'),'sunset');
    // Customize a real touch control, persist it, and use it in gameplay.
    await page.click('#settingsOpen'); await page.click('#editControls');
    assert.equal(await page.locator('#layoutToolbar').isVisible(),true);
    const before=await page.locator('[data-layout="jump"]').boundingBox();
    await page.mouse.move(before.x+before.width/2,before.y+before.height/2); await page.mouse.down(); await page.mouse.move(320,205,{steps:6}); await page.mouse.up();
    const moved=await page.locator('[data-layout="jump"]').boundingBox();
    assert.ok(Math.abs((moved.x+moved.width/2)-320)<5,'jump control moved to selected position');
    await page.click('#finishLayout'); await page.click('#settingsDone');
    const savedLayout=await page.evaluate(()=>JSON.parse(localStorage.getItem('comic3d-settings')).touchLayout.jump);
    assert.ok(Math.abs(savedLayout.x-.5)<.02);
    await page.reload(); await page.click('#freeRoam');
    const restored=await page.locator('[data-layout="jump"]').boundingBox();
    assert.ok(Math.abs((restored.x+restored.width/2)-320)<5,'custom position survives reload');
    await page.click('#jump'); await page.waitForFunction(()=>Number(document.querySelector('#webStatus').dataset.altitude)>.1,null,{timeout:30000});
    assert.deepEqual(errors,[]);
    console.log('Browser smoke test passed: WebGL, cameras, villain damage, civilian interaction and swing takeoff/release.');
  } finally {await browser.close();}
})().catch(err=>{console.error(err);console.error('::error::'+String(err.stack||err).replace(/%/g,'%25').replace(/\n/g,'%0A').replace(/\r/g,'%0D'));process.exit(1);});
