const clamp = (n, low, high) => Math.max(low, Math.min(high, n));
// Project gravity onto screen-right, so either landscape direction works and
// heading (alpha) cannot change steering. No integration of gyro drift.
export function screenRoll(beta, gamma, screenAngle) {
  if (![beta, gamma, screenAngle].every(Number.isFinite)) return null;
  const b = beta * Math.PI / 180, g = gamma * Math.PI / 180, a = screenAngle * Math.PI / 180;
  const right = Math.cos(b) * Math.sin(g) * Math.cos(a) - Math.sin(b) * Math.sin(a);
  return Math.asin(clamp(right, -1, 1)) * 180 / Math.PI;
}
export class TiltSteering {
  constructor() { this.neutral = null; this.raw = null; this.angle = null; this.value = 0; this.fullTurn = 25; }
  sample(beta, gamma, angle) {
    const raw = screenRoll(beta, gamma, angle);
    if (raw === null) return false;
    if (this.angle !== angle) this.neutral = null;
    this.angle = angle; this.raw = raw;
    if (this.neutral === null) this.center();
    return true;
  }
  center() { this.neutral = this.raw; this.value = 0; }
  reset() { this.neutral = null; this.raw = null; this.value = 0; this.angle = null; }
  update(delta) {
    const change = this.raw === null || this.neutral === null ? 0 : this.raw - this.neutral;
    const target = Math.sign(change) * clamp((Math.abs(change) - 2) / (this.fullTurn - 2), 0, 1);
    this.value += (target - this.value) * (1 - Math.exp(-clamp(delta, 0, .1) / .10));
    return this.value;
  }
}
