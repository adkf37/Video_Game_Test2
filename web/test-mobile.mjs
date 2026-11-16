import {chromium, webkit} from 'playwright';
import assert from 'node:assert/strict';
import fs from 'node:fs';
const base = process.env.GAME_TEST_URL || 'http://127.0.0.1:8088';
const out = process.env.GAME_TEST_ARTIFACT_DIR || '../build/mobile-qa';
fs.mkdirSync(out,{recursive:true});
const usingWebkit = process.env.GAME_TEST_BROWSER === 'webkit';
const browser = usingWebkit ? await webkit.launch({headless:true}) : await chromium.launch({channel:'chrome',headless:true});
const context = await browser.newContext({viewport:{width:390,height:844},deviceScaleFactor:2,isMobile:true,hasTouch:true});
const page = await context.newPage();
const errors = [];
const platformLimitations = [];
page.on('pageerror',e=>errors.push(String(e)));
page.on('console',m=>{
  if (m.type() !== 'error') return;
  // Playwright's Windows WebKit port uses Godot's dummy audio driver. Keep this
  // explicit in the report; Chromium still requires working real audio output.
  if (usingWebkit && (m.text().startsWith('WARNING: Trying to play stream') || m.text().includes('at: start_sample_playback'))) platformLimitations.push(m.text());
  else errors.push(m.text());
});
// Exercise the iOS permission contract without pretending to be physical hardware.
await page.addInitScript(() => {
  window.motionRequests = 0;
  if (window.DeviceOrientationEvent) DeviceOrientationEvent.requestPermission = async () => { window.motionRequests++; return 'granted'; };
  window.audioMeters=[];
  if(window.AudioNode) {
    const connect=AudioNode.prototype.connect;
    AudioNode.prototype.connect=function(destination,...args) {
      const result=connect.call(this,destination,...args);
      if(destination instanceof AudioDestinationNode) {
        const meter=this.context.createAnalyser(); meter.fftSize=2048;
        connect.call(this,meter); window.audioMeters.push(meter);
      }
      return result;
    };
  }
});
const raceState = number => page.waitForFunction(n=>document.querySelector('#play').dataset.raceState===String(n),number,{timeout:90000});
try {
  await page.goto(`${base}/mobile`,{waitUntil:'networkidle'});
  await page.locator('#launch:enabled').waitFor();
  assert.equal(await page.locator('#game').getAttribute('src'),null,'engine stays unloaded until requested');
  assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'portrait page fits');
  await page.screenshot({path:`${out}/mobile-camp-portrait.png`,fullPage:true});
  assert.equal(await page.locator('#tilt-option').count(),0,'tilt is disabled');
  assert.equal(await page.locator('#course option').count(),4);
  assert.equal(await page.locator('#difficulty option').count(),3);
  assert.equal(await page.locator('#breed option').count(),4);
  assert.equal(await page.locator('#sled_style option').count(),4);
  await page.locator('#course').selectOption('3');
  await page.locator('#difficulty').selectOption('2');
  await page.locator('#breed').selectOption('3');
  await page.locator('#sled_style').selectOption('3');
  await page.locator('#launch').click();
  await page.locator('#rotate').waitFor({state:'visible'});
  await page.setViewportSize({width:844,height:390});
  await raceState(0);
  await page.locator('#ready').waitFor({state:'visible'});
  assert.deepEqual(await page.locator('#play').evaluate(el=>[el.dataset.course,el.dataset.difficulty,el.dataset.breed,el.dataset.sled_style]),['3','2','3','3'],'real engine uses selected garage options');
  assert.equal(await page.evaluate(()=>window.motionRequests),0,'no motion permission requested');
  await page.screenshot({path:`${out}/mobile-ready.png`});
  await page.locator('#start').click();
  await raceState(2);
  await page.waitForFunction(()=>Number(document.querySelector('#speed').textContent)>10);
  if(!usingWebkit) {
    const gameFrame=page.frames().find(f=>f.url().includes('?mobile=1'));
    const rms=await gameFrame.evaluate(async()=>{
      let sum=0,count=0;
      for(let i=0;i<8;i++) {
        for(const meter of window.audioMeters) {
          const samples=new Float32Array(meter.fftSize);meter.getFloatTimeDomainData(samples);
          for(const sample of samples){sum+=sample*sample;count++;}
        }
        await new Promise(resolve=>setTimeout(resolve,50));
      }
      return count?Math.sqrt(sum/count):0;
    });
    assert(rms>.0001,'Start tap unlocks actual mobile game audio');
    console.log('MOBILE AUDIO PASS',rms);
  }
  const point = async selector => {
    const b = await page.locator(selector).boundingBox();
    return {x:b.x+b.width/2,y:b.y+b.height/2,radiusX:5,radiusY:5,force:1};
  };
  const right = {...await point('#right'),id:1}, boost = {...await point('#boost'),id:2};
  const before = Number(await page.locator('#energy').getAttribute('value'));
  if (!usingWebkit) {
    const cdp = await context.newCDPSession(page);
    await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[right,boost]});
    await page.waitForFunction(()=>Number(document.querySelector('#play').dataset.steer)>.9);
    await page.waitForTimeout(500);
    assert(Number(await page.locator('#energy').getAttribute('value'))<before,'boost drains while steering with another finger');
    await cdp.send('Input.dispatchTouchEvent',{type:'touchCancel',touchPoints:[]});
  } else {
    await page.mouse.move(right.x,right.y); await page.mouse.down();
    await page.waitForFunction(()=>Number(document.querySelector('#play').dataset.steer)>.9);
    await page.mouse.up();
    await page.mouse.move(boost.x,boost.y); await page.mouse.down();
    await page.waitForTimeout(500); await page.mouse.up();
    assert(Number(await page.locator('#energy').getAttribute('value'))<before,'boost drains');
  }
  await page.waitForFunction(()=>Number(document.querySelector('#play').dataset.steer)===0);
  assert.equal(await page.locator('.held').count(),0,'cancel releases every pointer');
  await page.screenshot({path:`${out}/mobile-driving.png`});
  await page.locator('#pause').click(); await raceState(3);
  const frozen = await page.locator('#time').textContent();
  await page.waitForTimeout(400); assert.equal(await page.locator('#time').textContent(),frozen);
  await page.locator('#camera').click(); await page.waitForFunction(()=>document.querySelector('#camera').textContent==='Chase view');
  await page.locator('#mute').click(); await page.waitForFunction(()=>document.querySelector('#mute').textContent==='Sound off');
  await page.locator('#mute').click();
  await page.screenshot({path:`${out}/mobile-pause.png`});
  const volume = parseInt(await page.locator('#volume').textContent());
  await page.locator('#quieter').click();
  await page.waitForFunction(v=>parseInt(document.querySelector('#volume').textContent)===v-10,volume);
  await page.locator('#louder').click();
  await page.locator('#resume').click(); await raceState(2);
  // Orientation data is ignored even when the browser provides it.
  await page.evaluate(()=>{const e=new Event('deviceorientation');Object.assign(e,{beta:65,gamma:65});dispatchEvent(e);});
  await page.waitForTimeout(150);
  assert.equal(Number(await page.locator('#play').getAttribute('data-steer')),0);
  // Upright rotation pauses the simulation and requires explicit resume.
  await page.setViewportSize({width:390,height:844});
  await raceState(3); await page.locator('#rotate').waitFor({state:'visible'});
  await page.screenshot({path:`${out}/mobile-rotate.png`});
  await page.setViewportSize({width:844,height:390});
  await page.locator('#paused').waitFor({state:'visible'});
  await page.locator('#resume').click(); await raceState(2);
  await page.evaluate(()=>dispatchEvent(new Event('blur'))); await raceState(3);
  await page.locator('#paused .leave').click();
  assert.equal(await page.locator('#game').getAttribute('src'),'about:blank');
  assert(await page.locator('#camp').isVisible());
  await page.reload({waitUntil:'networkidle'});
  assert.equal(await page.locator('#course').inputValue(),'3','garage survives refresh');
  // Load every other course with different dogs/sleds and all difficulties.
  for (const course of [0,1,2]) {
    await page.locator('#course').selectOption(String(course));
    await page.locator('#difficulty').selectOption(String(course));
    await page.locator('#breed').selectOption(String(course));
    await page.locator('#sled_style').selectOption(String(course));
    await page.locator('#launch:enabled').click();
    await page.waitForFunction(c=>document.querySelector('#play').dataset.course===String(c) && !document.querySelector('#ready').hidden,course,{timeout:90000});
    assert.deepEqual(await page.locator('#play').evaluate(el=>[el.dataset.course,el.dataset.difficulty,el.dataset.breed,el.dataset.sled_style]),Array(4).fill(String(course)));
    await page.locator('#start').click(); await raceState(2);
    await page.waitForFunction(()=>Number(document.querySelector('#speed').textContent)>10);
    await page.screenshot({path:`${out}/mobile-course-${course}.png`});
    await page.locator('#pause').click(); await raceState(3);
    await page.locator('#paused .leave').click();
  }
  if(errors.length) throw new Error(errors.join('\n'));
  if(platformLimitations.length) console.log('WEBKIT LIMITATION: Windows automation uses a dummy audio driver; audio is verified in Chrome, not in this WebKit run.');
  console.log('MOBILE WEB PASS: portrait/landscape, no motion prompts, engine startup, auto-acceleration, simultaneous steering/boost, touch cancellation, all tracks/difficulties/dogs/sleds, garage persistence, volume, pause, camera, mute, rotation, blur and exit. Physical-phone testing remains outstanding.');
} catch (error) {
  await page.screenshot({path:`${out}/failure.png`,fullPage:true}).catch(()=>{});
  console.log('MOBILE FAILURE',JSON.stringify({errors,ui:await page.evaluate(()=>({state:document.querySelector('#play').dataset.raceState,camera:document.querySelector('#camera').textContent,paused:!document.querySelector('#paused').hidden}))}));
  throw error;
} finally { await browser.close(); }
