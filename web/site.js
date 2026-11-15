const launch = document.querySelector('#launch');
const intro = document.querySelector('#intro');
const playArea = document.querySelector('#play-area');
const frame = document.querySelector('#game');
const controls = document.querySelector('#controls');
const notice = document.querySelector('#notice');
let build;
launch.disabled = true;
fetch('build.json', {cache: 'no-store'}).then(response => {
  if (!response.ok) throw new Error('Build information unavailable');
  return response.json();
}).then(info => {
  build = info;
  document.querySelector('#download-size').textContent = info.downloadMiB + ' MB initial game download';
  document.querySelector('#version').textContent = 'PLAYTEST / ' + info.version;
  launch.disabled = false;
}).catch(() => {
  document.querySelector('#download-size').textContent = 'Could not load the game. Refresh to try again.';
});
document.querySelector('#help-button').addEventListener('click', () => controls.showModal());
controls.addEventListener('click', event => {
  const rect = controls.getBoundingClientRect();
  if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) controls.close();
});
launch.addEventListener('click', () => {
  if (!build) return;
  frame.src = build.gamePath;
  intro.hidden = true;
  playArea.hidden = false;
  playArea.scrollIntoView({behavior: 'auto'});
});
frame.addEventListener('load', () => {
  if (!playArea.hidden) {
    frame.focus();
    try { frame.contentWindow.focus(); } catch (_) {}
  }
});
document.querySelector('#leave').addEventListener('click', () => {
  frame.src = 'about:blank';
  playArea.hidden = true;
  intro.hidden = false;
  launch.focus();
  window.scrollTo(0, 0);
});
document.querySelector('#fullscreen').addEventListener('click', async () => {
  try {
    await document.querySelector('#game-frame').requestFullscreen();
    frame.focus();
  } catch (_) {
    notice.textContent = 'Fullscreen is unavailable here. You can still play in the page.';
    notice.hidden = false;
    window.setTimeout(() => { notice.hidden = true; }, 4500);
  }
});
