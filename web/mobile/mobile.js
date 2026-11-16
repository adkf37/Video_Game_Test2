const $ = selector => document.querySelector(selector);
const frame = $('#game');
const held = new Map();
let build, active = false, ready = false, state = null;
let lastSend = 0, loadingTimer, wakeLock;
let lastOrientation = screen.orientation?.angle ?? window.orientation ?? 0;
const landscape = () => innerWidth > innerHeight;
const orientation = () => Number(screen.orientation?.angle ?? window.orientation ?? (landscape() ? 90 : 0));
const send = data => { if (active) frame.contentWindow?.postMessage({channel:'dogsled-mobile-command',data}, location.origin); };
const unlockAudio = () => { try { frame.contentWindow?.mobileEngine?.unlockAudio(); } catch (_) {} };
const resetHeld = () => { held.clear(); document.querySelectorAll('.held').forEach(button => button.classList.remove('held')); send({type:'input',steer:0,boost:false,brake:false,drift:false}); };
const optionKeys = ['course','difficulty','breed','sled_style'];
// The garage is useful even with browser storage disabled.
try {
  const saved = JSON.parse(localStorage.getItem('dogsled-mobile-garage') || '{}');
  for (const key of optionKeys) if ([...$(`#${key}`).options].some(option => option.value === String(saved[key]))) $(`#${key}`).value = saved[key];
} catch (_) {}

fetch('/build.json', {cache:'no-store'}).then(response => {
  if (!response.ok) throw new Error('build'); return response.json();
}).then(info => {
  build = info; $('#launch').disabled = false; $('#launch').textContent = 'Load the trail →';
  $('#download').textContent = `${info.downloadMiB} MB first download · No app to install`;
}).catch(() => { $('#download').textContent = 'The trail couldn’t load. Refresh this page to try again.'; });

$('#launch').addEventListener('click', () => {
  if (!build || active) return;
  $('#launch').disabled = true;
  active = true; ready = false; state = null;
  document.body.classList.add('playing'); $('#play').hidden = false;
  $('#loading').hidden = false; $('#loading-title').textContent = 'Harnessing the dogs…';
  $('#loading-copy').textContent = 'The first load takes a little longer. Your race won’t start without you.';
  for (const id of ['ready','paused','finished','race-hud']) $(`#${id}`).hidden = true;
  const options = Object.fromEntries(optionKeys.map(key => [key,$(`#${key}`).value]));
  try { localStorage.setItem('dogsled-mobile-garage', JSON.stringify(options)); } catch (_) {}
  $('#race-label').textContent = `${$('#course').selectedOptions[0].textContent} · ${$('#difficulty').selectedOptions[0].textContent}`;
  frame.src = `${build.gamePath}?${new URLSearchParams({mobile:'1',...options})}`;
  updateOrientation();
  loadingTimer = setTimeout(() => {
    if (!ready) { $('#loading-title').textContent = 'The trail is taking a while.'; $('#loading-copy').textContent = 'On a slow connection, give it another moment. If it stays here, return to basecamp and try again.'; }
  }, 45000);
});

async function keepAwake() {
  try { if ('wakeLock' in navigator && !wakeLock) wakeLock = await navigator.wakeLock.request('screen'); } catch (_) {}
}
function begin(type) {
  if (!ready || !landscape()) return;
  unlockAudio(); resetHeld();
  send({type}); send({type:'input',steer:0,boost:false,brake:false});
  keepAwake();
}
$('#start').addEventListener('click', () => begin('start'));
$('#again').addEventListener('click', () => begin('start'));
$('#resume').addEventListener('click', () => begin('resume'));
function pause(reason = 'Your race is paused.') {
  if (!active) return;
  resetHeld(); send({type:'pause'}); $('#pause-note').textContent = reason;
}
$('#pause').addEventListener('click', () => pause());
$('#camera').addEventListener('click', () => { unlockAudio(); send({type:'camera'}); });
$('#quieter').addEventListener('click', () => { unlockAudio(); send({type:'volume',steps:-1}); });
$('#louder').addEventListener('click', () => { unlockAudio(); send({type:'volume',steps:1}); });
$('#mute').addEventListener('click', () => { unlockAudio(); send({type:'mute'}); });
$('#recover').addEventListener('click', () => { begin('resume'); send({type:'recover'}); });
$('#bone').addEventListener('click', () => { unlockAudio(); if (state?.state === 2) send({type:'throw'}); });

function holdButton(selector, action) {
  const button = $(selector);
  button.addEventListener('pointerdown', event => {
    if (event.button !== 0 || state?.state !== 2) return;
    event.preventDefault(); unlockAudio(); button.setPointerCapture(event.pointerId);
    held.set(event.pointerId, {action,button}); button.classList.add('held');
  });
  const release = event => {
    held.delete(event.pointerId);
    if (![...held.values()].some(item => item.button === button)) button.classList.remove('held');
  };
  button.addEventListener('pointerup', release);
  button.addEventListener('pointercancel', release);
  button.addEventListener('lostpointercapture', release);
  button.addEventListener('contextmenu', event => event.preventDefault());
}
holdButton('#left','left'); holdButton('#right','right'); holdButton('#boost','boost'); holdButton('#brake','brake'); holdButton('#drift','drift');

function updateOrientation() {
  const changed = lastOrientation !== orientation();
  lastOrientation = orientation();
  if (changed && active) pause('Phone orientation changed. Tap Resume when you’re ready.');
  $('#rotate').hidden = !active || landscape();
  if (active && !landscape()) pause('Turn your phone sideways, then tap Resume.');
}
addEventListener('resize', updateOrientation);
screen.orientation?.addEventListener('change', updateOrientation);
addEventListener('orientationchange', updateOrientation);
document.addEventListener('visibilitychange', () => {
  if (document.hidden) { pause('Welcome back. Tap Resume when you’re ready.'); wakeLock?.release(); wakeLock = null; }
});
addEventListener('pagehide', () => pause());
addEventListener('blur', () => { if (active && ready) pause('Tap Resume when you’re ready.'); });

function leave() {
  pause(); active = false; ready = false; state = null; resetHeld();
  clearTimeout(loadingTimer); wakeLock?.release(); wakeLock = null;
  frame.src = 'about:blank'; $('#play').hidden = true; document.body.classList.remove('playing');
  $('#launch').disabled = !build; $('#launch').focus();
}
document.querySelectorAll('.leave').forEach(button => button.addEventListener('click', leave));

addEventListener('message', event => {
  if (!active || event.origin !== location.origin || event.source !== frame.contentWindow) return;
  if (event.data?.channel === 'dogsled-mobile-error') {
    clearTimeout(loadingTimer);
    $('#loading-title').textContent = 'This browser couldn’t start the race.';
    $('#loading-copy').textContent = 'Try an up-to-date browser or another device. You can return to basecamp below.';
    return;
  }
  if (event.data?.channel !== 'dogsled-mobile-state') return;
  const data = event.data.data;
  if (!data?.ready || !Number.isInteger(data.state)) return;
  const previous = state?.state;
  state = data; ready = true; clearTimeout(loadingTimer);
  // Read-only state also provides real gameplay assertions for browser tests.
  $('#play').dataset.raceState = String(data.state);
  $('#play').dataset.steer = String(data.steer);
  for (const key of optionKeys) $('#play').dataset[key] = String(data[key]);
  $('#record').textContent = data.best_time ? `Your best on this track and difficulty: ${data.best_time}` : '';
  $('#volume').textContent = `${Math.round(data.volume * 100)}%`;
  $('#loading').hidden = true;
  $('#ready').hidden = data.state !== 0;
  $('#paused').hidden = data.state !== 3;
  $('#finished').hidden = data.state !== 4;
  $('#race-hud').hidden = ![1,2].includes(data.state);
  $('#place').textContent = `${data.place} / 4`; $('#lap').textContent = `LAP ${data.lap} / ${data.laps}`;
  $('#time').textContent = data.time; $('#speed').textContent = data.speed;
  $('#energy').value = data.boost;
  $('#turbo-left').textContent = `${data.boost}% left`;
  $('#boost').classList.toggle('low-turbo', data.boost <= 25);
  $('#bone').disabled = !data.bone || !data.target || data.chasing > 0 || data.stunned > 0 || data.state !== 2;
  $('#bone-note').textContent = !data.bone ? 'Find one' : data.target ? 'Throw!' : 'Get closer';
  $('#boost').disabled = data.boost <= 0 || data.chasing > 0 || data.stunned > 0 || data.state !== 2;
  $('#countdown').textContent = data.state === 1 ? data.countdown : '';
  $('#toast').textContent = data.toast.replaceAll(' / ', ' · ');
  $('#mute').textContent = data.muted ? 'Sound off' : 'Sound on';
  $('#camera').textContent = data.camera ? 'Chase view' : 'Musher view';
  if (data.state === 4 && previous !== 4) {
    resetHeld(); $('#finish-time').textContent = data.time; $('#results').replaceChildren();
    for (const row of data.results) {
      const li = document.createElement('li'), name = document.createElement('span'), time = document.createElement('span');
      name.textContent = row.name; time.textContent = row.time + (row.estimated ? ' est.' : '');
      li.append(name,time); $('#results').append(li);
    }
  }
  if (previous !== data.state && data.state === 3) resetHeld();
});

function tick(now) {
  if (active && ready && now - lastSend >= 45) {
    lastSend = now;
    const actions = new Set([...held.values()].map(item => item.action));
    const canDrive = landscape() && !document.hidden && [1,2].includes(state?.state);
    const steer = Number(actions.has('right')) - Number(actions.has('left'));
    send({type:'input',steer:canDrive ? steer : 0,boost:canDrive && actions.has('boost'),brake:canDrive && actions.has('brake'),drift:canDrive && actions.has('drift')});
  }
  requestAnimationFrame(tick);
}
requestAnimationFrame(tick);
