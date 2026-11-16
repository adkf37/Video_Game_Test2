import {chromium} from 'playwright';
import fs from 'node:fs';
const base = process.env.GAME_TEST_URL || 'http://127.0.0.1:8088';
const artifactDir = process.env.GAME_TEST_ARTIFACT_DIR || '../artifacts';
fs.mkdirSync(artifactDir,{recursive:true});
const browser = await chromium.launch({channel:'chrome',headless:true});
const page = await browser.newPage({viewport:{width:1440,height:1080}});
// Meter the actual Web Audio output, including Godot's iframe/worklet path.
await page.addInitScript(() => {
  window.__audioMeters = [];
  const connect = AudioNode.prototype.connect;
  AudioNode.prototype.connect = function(destination, ...args) {
    const result = connect.call(this, destination, ...args);
    if (destination instanceof AudioDestinationNode) {
      const analyser = this.context.createAnalyser();
      analyser.fftSize = 2048;
      connect.call(this, analyser);
      window.__audioMeters.push(analyser);
    }
    return result;
  };
});
const errors = [];
const messages = [];
page.on('response', response=>{ if(response.status()>=400) console.log('HTTP ERROR',response.status(),response.url()); });
page.on('pageerror', error=>errors.push(String(error)));
page.on('console', message=>{
  if(message.type()==='error') errors.push(message.text());
  messages.push(message.text());
});
try {
  await page.goto(base,{waitUntil:'networkidle'});
  await page.locator('#launch:not([disabled])').waitFor();
  if(await page.locator('#game').getAttribute('src')) throw new Error('Game downloaded before pressing Play');
  await page.screenshot({path:`${artifactDir}/web-landing.png`,fullPage:true});
  await page.locator('#help-button').click();
  if(!await page.locator('#controls').isVisible()) throw new Error('Controls did not open');
  await page.locator('#controls .close').click();
  const start = Date.now();
  await page.locator('#launch').click();
  const frame = await page.waitForEvent('framenavigated',{predicate:frame=>frame.url().includes('/game/'),timeout:30000}).catch(()=>page.frames().find(frame=>frame.url().includes('/game/')));
  await frame.waitForFunction(()=>!document.querySelector('#status'),null,{timeout:120000});
  const startupMs = Date.now()-start;
  await page.waitForTimeout(2500);
  await page.screenshot({path:`${artifactDir}/web-garage.png`,fullPage:true});
  const info = await frame.evaluate(()=>{
    const canvas=document.querySelector('canvas');
    const gl=canvas.getContext('webgl2');
    const extension=gl?.getExtension('WEBGL_debug_renderer_info');
    return {canvas:[canvas.width,canvas.height],renderer:extension?gl.getParameter(extension.UNMASKED_RENDERER_WEBGL):'unknown',assets:performance.getEntriesByType('resource').map(e=>({name:e.name.split('/').pop(),transfer:e.transferSize,decoded:e.decodedBodySize}))};
  });
  console.log('GAME READY',JSON.stringify({startupMs,...info}));
  // Keyboard launch uses Godot's initially focused Race button.
  await frame.locator('canvas').focus();
  const audioRms = () => frame.evaluate(async () => {
    let energy = 0, count = 0;
    for (let tick = 0; tick < 10; tick++) {
      for (const meter of window.__audioMeters) {
        const samples = new Float32Array(meter.fftSize);
        meter.getFloatTimeDomainData(samples);
        for (const sample of samples) { energy += sample * sample; count++; }
      }
      await new Promise(resolve => setTimeout(resolve, 50));
    }
    return count ? Math.sqrt(energy / count) : 0;
  });
  let musicRms = await audioRms();
  // A saved mute preference may be present; enable it before checking playback.
  if (musicRms < 0.0001) {
    await page.keyboard.press('m');
    await page.waitForTimeout(700);
    musicRms = await audioRms();
  }
  if (musicRms < 0.0001) throw new Error('No audible melody from the game audio output');
  await page.keyboard.press('m');
  await page.waitForTimeout(500);
  const mutedRms = await audioRms();
  if (mutedRms > 0.0001) throw new Error(`Mute leaves audible output: ${mutedRms}`);
  await page.keyboard.press('m');
  await page.waitForTimeout(700);
  const resumedRms = await audioRms();
  if (resumedRms < 0.0001) throw new Error('Music failed to resume after mute');
  console.log('AUDIO PASS', JSON.stringify({musicRms,mutedRms,resumedRms}));
  await page.keyboard.press('Enter');
  await page.waitForTimeout(4500);
  await page.keyboard.down('w');
  await page.waitForTimeout(400);
  await page.keyboard.down('f');
  await page.waitForTimeout(1000);
  await page.screenshot({path:`${artifactDir}/web-turbo-active.png`,fullPage:true});
  await page.waitForTimeout(1100);
  await page.screenshot({path:`${artifactDir}/web-turbo-low.png`,fullPage:true});
  await page.keyboard.up('f');
  await page.waitForTimeout(500);
  await page.screenshot({path:`${artifactDir}/web-turbo-refill.png`,fullPage:true});
  await page.keyboard.up('w');
  await page.keyboard.press('c');
  await page.waitForTimeout(600);
  await page.screenshot({path:`${artifactDir}/web-driving.png`,fullPage:true});
  await page.keyboard.press('Escape');
  await page.waitForTimeout(600);
  await page.screenshot({path:`${artifactDir}/web-pause.png`,fullPage:true});
  const clickGame = async (x,y) => {
    const box = await frame.locator('canvas').boundingBox();
    await page.mouse.click(box.x+x*box.width/1280,box.y+y*box.height/720);
  };
  await clickGame(640,489); // Back to basecamp.
  await page.waitForTimeout(700);
  await clickGame(240,206); // Local two-player mode.
  await page.keyboard.press('ArrowDown');
  await page.keyboard.press('ArrowDown');
  await page.keyboard.press('Enter');
  await page.waitForTimeout(1000);
  await clickGame(240,271); // City Sprint.
  await page.keyboard.press('ArrowDown');
  await page.keyboard.press('ArrowDown');
  await page.keyboard.press('ArrowDown');
  await page.keyboard.press('ArrowDown');
  await page.keyboard.press('Enter');
  await page.waitForTimeout(1000);
  await page.screenshot({path:`${artifactDir}/web-duel-garage.png`,fullPage:true});
  await clickGame(230,535);
  await page.waitForTimeout(4500);
  await page.keyboard.down('w');
  await page.keyboard.down('ArrowUp');
  await page.waitForTimeout(1500);
  await page.keyboard.up('w');
  await page.keyboard.up('ArrowUp');
  await page.keyboard.press('Enter'); // Player 2 musher view.
  await page.waitForTimeout(500);
  await page.screenshot({path:`${artifactDir}/web-duel-driving.png`,fullPage:true});
  await page.locator('#leave').click();
  if(!await page.locator('#intro').isVisible()) throw new Error('Leave game did not restore launch page');
  await page.setViewportSize({width:390,height:844});
  await page.screenshot({path:`${artifactDir}/web-mobile-launch.png`,fullPage:true});
  if(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth)) throw new Error('Mobile launch page overflows');
  fs.writeFileSync(`${artifactDir}/web-browser.log`,messages.join('\n'));
  if(errors.length) throw new Error(errors.join('\n'));
  console.log('WEB CHECKS PASSED: launch, controls, game startup, solo/duel keyboard interaction, leave, mobile layout; no browser errors. Inspect race screenshots to verify canvas state.');
} finally {
  await browser.close();
}
