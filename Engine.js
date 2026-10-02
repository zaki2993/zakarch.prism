.pragma library

// ---------------------------------------------------------------------------
// Prism engine — pure data + logic shared by Service.qml and Panel.qml.
// No QML types in here so `node check.js` can exercise every branch.
// ---------------------------------------------------------------------------

var palettes = [
  { id: "aurora",   name: "Aurora",   stops: ["#8B5CF6", "#22D3EE", "#34D399"] },
  { id: "neon",     name: "Neon",     stops: ["#00FF9C", "#00D9FF", "#B026FF"] },
  { id: "synth",    name: "Synth",    stops: ["#F472B6", "#A855F7", "#38BDF8"] },
  { id: "plasma",   name: "Plasma",   stops: ["#F0ABFC", "#A78BFA", "#60A5FA"] },
  { id: "ember",    name: "Ember",    stops: ["#FB7185", "#F97316", "#FACC15"] },
  { id: "solar",    name: "Solar",    stops: ["#FDE047", "#FB923C", "#F43F5E"] },
  { id: "lava",     name: "Lava",     stops: ["#FF3D00", "#FF0055", "#7C3AED"] },
  { id: "citrus",   name: "Citrus",   stops: ["#FDE047", "#BEF264", "#4ADE80"] },
  { id: "forest",   name: "Forest",   stops: ["#A3E635", "#22C55E", "#14B8A6"] },
  { id: "matcha",   name: "Matcha",   stops: ["#D9F99D", "#86EFAC", "#5EEAD4"] },
  { id: "lagoon",   name: "Lagoon",   stops: ["#5EEAD4", "#06B6D4", "#3B82F6"] },
  { id: "ocean",    name: "Ocean",    stops: ["#38BDF8", "#2563EB", "#4F46E5"] },
  { id: "glacier",  name: "Glacier",  stops: ["#E0F2FE", "#67E8F9", "#818CF8"] },
  { id: "twilight", name: "Twilight", stops: ["#818CF8", "#A78BFA", "#E879F9"] },
  { id: "rose",     name: "Rose",     stops: ["#F9A8D4", "#E879F9", "#C084FC"] },
  { id: "sakura",   name: "Sakura",   stops: ["#FDA4AF", "#F9A8D4", "#F0ABFC"] },
  { id: "gold",     name: "Gilded",   stops: ["#FEF3C7", "#FBBF24", "#B45309"] },
  { id: "mono",     name: "Mono",     stops: ["#FFFFFF", "#94A3B8", "#475569"] },
  // Softer palettes after well-loved editor themes.
  { id: "rosepine",   name: "Rosé Pine",   stops: ["#EBBCBA", "#C4A7E7", "#9CCFD8"] },
  { id: "catppuccin", name: "Catppuccin",  stops: ["#CBA6F7", "#F5C2E7", "#89B4FA"] },
  { id: "tokyo",      name: "Tokyo Night", stops: ["#7AA2F7", "#BB9AF7", "#7DCFFF"] },
  { id: "nord",       name: "Nord",        stops: ["#88C0D0", "#81A1C1", "#B48EAD"] },
  { id: "dracula",    name: "Dracula",     stops: ["#BD93F9", "#FF79C6", "#8BE9FD"] },
  { id: "gruvbox",    name: "Gruvbox",     stops: ["#FABD2F", "#FE8019", "#B8BB26"] },
  { id: "everforest", name: "Everforest",  stops: ["#A7C080", "#83C092", "#DBBC7F"] },
  { id: "kanagawa",   name: "Kanagawa",    stops: ["#7E9CD8", "#957FB8", "#DCA561"] },
  { id: "vapor",      name: "Vaporwave",   stops: ["#FF71CE", "#B967FF", "#01CDFE"] },
  { id: "champagne",  name: "Champagne",   stops: ["#F7E7CE", "#E8C39E", "#B08968"] }
]

// Ids with special handling in the Service: "theme" follows the current
// Omarchy theme's colors.toml, "custom" uses the user's own three stops.
var THEME_ID = "theme"
var CUSTOM_ID = "custom"

// Rotating-gradient speeds. `speed` is Hyprland's animation speed
// (1 unit = 100 ms per full loop), so smaller is faster.
// Hyprland rejects speeds above 100, so stay at or below it.
var spins = [
  { name: "Off",   speed: 0 },
  { name: "Drift", speed: 100 },
  { name: "Flow",  speed: 50 },
  { name: "Spin",  speed: 25 },
  { name: "Turbo", speed: 10 }
]

// Corner shape → Hyprland decoration.rounding_power.
// 1 cuts a straight diagonal (a triangle off each corner), 2 is a circle.
var corners = [
  { name: "Facet",    power: 1.0 },
  { name: "Round",    power: 2.0 }
]

// Real glow: Hyprland drop shadow tinted with the palette's lead color.
var glows = [
  { name: "Off",   range: 0,  power: 3, alpha: 0 },
  { name: "Soft",  range: 10, power: 3, alpha: 0x55 },
  { name: "Bloom", range: 20, power: 2, alpha: 0x88 },
  { name: "Neon",  range: 32, power: 1, alpha: 0xCC }
]

// How long a color change takes to blend on the real borders.
var morphs = [
  { name: "Instant", speed: 1 },
  { name: "Quick",   speed: 3 },
  { name: "Smooth",  speed: 8 },
  { name: "Dreamy",  speed: 18 }
]

var breaths = [
  { name: "Off",  ms: 0 },
  { name: "Calm", ms: 2600 },
  { name: "Pulse", ms: 1300 }
]

var cycles = [
  { name: "Off", seconds: 0 },
  { name: "10s", seconds: 10 },
  { name: "30s", seconds: 30 },
  { name: "2m",  seconds: 120 },
  { name: "10m", seconds: 600 }
]

var defaults = {
  enabled: true,
  paletteId: "aurora",
  customStops: ["#F472B6", "#A855F7", "#38BDF8"],
  gradient: true,
  angle: 45,
  inactiveTone: 25,
  borderSize: 2,
  rounding: 10,
  corner: 1,
  gapsIn: 4,
  gapsOut: 8,
  spin: 0,
  glow: 1,
  morph: 2,
  breathe: 0,
  dim: 0,
  inactiveOpacity: 100,
  cycleSeconds: 0,
  cycleShuffle: false,
  cycleFavorites: false,
  favorites: [],
  tintShell: true
}

// Keys that make up a "look" (what presets, saved looks and undo capture).
var lookKeys = ["paletteId", "customStops", "gradient", "angle", "inactiveTone",
                "borderSize", "rounding", "corner", "gapsIn", "gapsOut",
                "spin", "glow", "morph", "breathe", "dim", "inactiveOpacity"]

// Each look is a complete recipe; keys left out keep the current value.
var looks = [
  { name: "Prism",          tagline: "Drifting aurora light",  paletteId: "aurora",     gradient: true,  angle: 45,  inactiveTone: 20, borderSize: 2, rounding: 12, corner: 1, gapsIn: 5,  gapsOut: 10, spin: 1, glow: 2, breathe: 0, dim: 0,  inactiveOpacity: 100 },
  { name: "Rosé Dawn",      tagline: "Soft petal light",     paletteId: "rosepine",   gradient: true,  angle: 135, inactiveTone: 30, borderSize: 2, rounding: 16, corner: 1, gapsIn: 6,  gapsOut: 12, spin: 0, glow: 1, breathe: 0, dim: 0,  inactiveOpacity: 100 },
  { name: "Crystal Facet",  tagline: "Cut-glass corners",   paletteId: "glacier",    gradient: true,  angle: 60,  inactiveTone: 25, borderSize: 3, rounding: 14, corner: 0, gapsIn: 6,  gapsOut: 12, spin: 0, glow: 2, breathe: 0, dim: 0,  inactiveOpacity: 100 },
  { name: "Neon Circuit",   tagline: "Live neon current", paletteId: "vapor",      gradient: true,  angle: 0,   inactiveTone: 15, borderSize: 2, rounding: 8,  corner: 0, gapsIn: 4,  gapsOut: 8,  spin: 3, glow: 3, breathe: 0, dim: 15, inactiveOpacity: 100 },
  { name: "Midnight Tokyo", tagline: "City lights orbit",      paletteId: "tokyo",      gradient: true,  angle: 90,  inactiveTone: 25, borderSize: 2, rounding: 10, corner: 1, gapsIn: 5,  gapsOut: 10, spin: 2, glow: 1, breathe: 0, dim: 10, inactiveOpacity: 100 },
  { name: "Nordic Calm",    tagline: "Frost, slow breath", paletteId: "nord",      gradient: true,  angle: 60,  inactiveTone: 35, borderSize: 2, rounding: 14, corner: 1, gapsIn: 8,  gapsOut: 16, spin: 0, glow: 0, breathe: 1, dim: 0,  inactiveOpacity: 96 },
  { name: "Ember Hearth",   tagline: "Warm heartbeat",      paletteId: "ember",      gradient: true,  angle: 30,  inactiveTone: 20, borderSize: 2, rounding: 12, corner: 1, gapsIn: 5,  gapsOut: 10, spin: 0, glow: 2, breathe: 1, dim: 0,  inactiveOpacity: 100 },
  { name: "Champagne",      tagline: "Hairline gold, airy",    paletteId: "champagne",  gradient: true,  angle: 90,  inactiveTone: 20, borderSize: 1, rounding: 18, corner: 1, gapsIn: 10, gapsOut: 20, spin: 0, glow: 1, breathe: 0, dim: 0,  inactiveOpacity: 100 },
  { name: "Deep Focus",     tagline: "The rest fades away",     paletteId: "theme",      gradient: false, angle: 45,  inactiveTone: 10, borderSize: 2, rounding: 10, corner: 1, gapsIn: 4,  gapsOut: 8,  spin: 0, glow: 1, breathe: 0, dim: 35, inactiveOpacity: 90 },
  { name: "Dracula Noir",   tagline: "Velvet bevels",    paletteId: "dracula",    gradient: true,  angle: 150, inactiveTone: 20, borderSize: 2, rounding: 6,  corner: 0, gapsIn: 4,  gapsOut: 8,  spin: 0, glow: 2, breathe: 0, dim: 10, inactiveOpacity: 100 }
]

// ── color math ─────────────────────────────────────────────────────────────

function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

function normHex(hex) {
  var v = String(hex || "").replace("#", "").trim()
  if (/^[0-9a-fA-F]{3}$/.test(v)) v = v[0] + v[0] + v[1] + v[1] + v[2] + v[2]
  if (!/^[0-9a-fA-F]{6}$/.test(v)) return ""
  return "#" + v.toUpperCase()
}

function rgb(hex) {
  var v = normHex(hex) || "#000000"
  return [parseInt(v.substr(1, 2), 16), parseInt(v.substr(3, 2), 16), parseInt(v.substr(5, 2), 16)]
}

function toHex(r, g, b) {
  function h(c) { return clamp(Math.round(c), 0, 255).toString(16).padStart(2, "0") }
  return ("#" + h(r) + h(g) + h(b)).toUpperCase()
}

// Linear blend of two hex colors; t=0 → a, t=1 → b.
function mix(a, b, t) {
  var x = rgb(a), y = rgb(b)
  return toHex(x[0] + (y[0] - x[0]) * t, x[1] + (y[1] - x[1]) * t, x[2] + (y[2] - x[2]) * t)
}

function hsl(hex) {
  var c = rgb(hex), r = c[0] / 255, g = c[1] / 255, b = c[2] / 255
  var max = Math.max(r, g, b), min = Math.min(r, g, b)
  var h = 0, s = 0, l = (max + min) / 2
  if (max !== min) {
    var d = max - min
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
    if (max === r) h = (g - b) / d + (g < b ? 6 : 0)
    else if (max === g) h = (b - r) / d + 2
    else h = (r - g) / d + 4
    h *= 60
  }
  return { h: h, s: s, l: l }
}

function fromHsl(h, s, l) {
  h = ((h % 360) + 360) % 360
  s = clamp(s, 0, 1); l = clamp(l, 0, 1)
  var c = (1 - Math.abs(2 * l - 1)) * s
  var x = c * (1 - Math.abs((h / 60) % 2 - 1))
  var m = l - c / 2
  var r = 0, g = 0, b = 0
  if (h < 60)       { r = c; g = x }
  else if (h < 120) { r = x; g = c }
  else if (h < 180) { g = c; b = x }
  else if (h < 240) { g = x; b = c }
  else if (h < 300) { r = x; b = c }
  else              { r = c; b = x }
  return toHex((r + m) * 255, (g + m) * 255, (b + m) * 255)
}

// Black or white, whichever reads better on `hex`.
function contrast(hex) {
  var c = rgb(hex).map(function(v) {
    v /= 255
    return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
  })
  return c[0] * 0.2126 + c[1] * 0.7152 + c[2] * 0.0722 > 0.179 ? "#000000" : "#FFFFFF"
}

// ── palette resolution ─────────────────────────────────────────────────────

function paletteById(id) {
  for (var i = 0; i < palettes.length; i++) if (palettes[i].id === id) return palettes[i]
  return null
}

function indexOfPalette(id) {
  for (var i = 0; i < palettes.length; i++) if (palettes[i].id === id) return i
  return -1
}

function cleanStops(stops, fallback) {
  var out = []
  for (var i = 0; i < 3; i++) {
    var v = normHex(stops && stops[i])
    out.push(v || fallback[i])
  }
  return out
}

// Pull three harmonious stops out of an Omarchy colors.toml.
function themeStops(raw) {
  var vals = {}
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var m = lines[i].match(/^\s*([A-Za-z0-9_-]+)\s*=\s*["']?(#[0-9A-Fa-f]{6})/)
    if (m) vals[m[1]] = m[2].toUpperCase()
  }
  var accent = vals.accent || vals.color4 || vals.blue
  if (!accent) return null
  var second = vals.magenta || vals.color5 || vals.bright_magenta || mix(accent, "#FFFFFF", 0.3)
  var third = vals.cyan || vals.color6 || vals.blue || mix(accent, "#000000", 0.3)
  if (second === accent) second = vals.blue || mix(accent, "#FFFFFF", 0.3)
  return { stops: [accent, second, third], background: vals.background || "" }
}

// Active stops after the breathe dip (0 = full brightness).
function dimStops(stops, amount) {
  if (!amount) return stops.slice()
  return stops.map(function(c) { return mix(c, "#000000", amount) })
}

// Inactive border: palette-tinted charcoal. tone 0 → near-black, 100 → vivid.
function inactiveColor(stops, tone) {
  var base = mix(stops[0], stops[stops.length - 1], 0.5)
  return mix("#14141C", base, clamp(tone, 0, 100) / 100 * 0.7)
}

// ── preview geometry ───────────────────────────────────────────────────────

// Clockwise outline of a rect whose corners follow |x|^p + |y|^p = r^p,
// which matches Hyprland's rounding_power (p=1 facet, 2 circle).
function framePoints(x, y, w, h, r, power, steps) {
  r = Math.max(0, Math.min(r, w / 2, h / 2))
  var p = Math.max(0.5, power || 2)
  var n = r < 0.5 ? 0 : (p === 1 ? 1 : (steps || 10))
  var pts = []
  // [center x, center y, sign x, sign y, sweep from-top?]
  var cs = [[x + w - r, y + r, 1, -1, true], [x + w - r, y + h - r, 1, 1, false],
            [x + r, y + h - r, -1, 1, true], [x + r, y + r, -1, -1, false]]
  for (var c = 0; c < 4; c++) {
    var k = cs[c]
    if (n === 0) { pts.push({ x: k[0], y: k[1] }); continue }
    for (var i = 0; i <= n; i++) {
      var t = (k[4] ? (n - i) : i) / n * Math.PI / 2
      var dx = r * Math.pow(Math.cos(t), 2 / p)
      var dy = r * Math.pow(Math.sin(t), 2 / p)
      pts.push({ x: k[0] + k[2] * dx, y: k[1] + k[3] * dy })
    }
  }
  pts.push(pts[0])
  return pts
}

// ── Hyprland Lua ───────────────────────────────────────────────────────────

function rgba(hex, alpha) {
  var a = alpha === undefined ? 0xEE : clamp(Math.round(alpha), 0, 255)
  return "rgba(" + normHex(hex).substr(1) + a.toString(16).padStart(2, "0").toUpperCase() + ")"
}

function luaString(s) { return "\"" + s + "\"" }

function luaBorder(stops, gradient, angle) {
  if (!gradient) return luaString(rgba(stops[0]))
  return "{ colors = { " + stops.map(function(c) { return luaString(rgba(c)) }).join(", ")
       + " }, angle = " + Math.round(angle) + " }"
}

// Everything the plugin owns, as one atomic Lua chunk.
// `s` is a state snapshot, `stops` the resolved active stops.
function fullLua(s, stops, breathDip) {
  var active = luaBorder(dimStops(stops, breathDip || 0), s.gradient, s.angle)
  var inactive = luaString(rgba(inactiveColor(stops, s.inactiveTone)))
  var glow = glows[clamp(s.glow, 0, glows.length - 1)]
  var spin = spins[clamp(s.spin, 0, spins.length - 1)]
  var corner = corners[clamp(s.corner === undefined ? 1 : s.corner, 0, corners.length - 1)]
  var morph = morphs[clamp(s.morph, 0, morphs.length - 1)]
  var breath = breaths[clamp(s.breathe, 0, breaths.length - 1)]
  // While breathing, each half-cycle should blend over its whole duration.
  var borderSpeed = breath.ms > 0 ? Math.max(3, Math.round(breath.ms / 100 * 0.95)) : morph.speed

  var parts = []
  parts.push("hl.curve(\"prismEase\", { type = \"bezier\", points = { { 0.45, 0 }, { 0.25, 1 } } })")
  parts.push("hl.curve(\"prismLinear\", { type = \"bezier\", points = { { 0, 0 }, { 1, 1 } } })")
  parts.push("hl.config({ general = { border_size = " + s.borderSize
           + ", gaps_in = " + s.gapsIn + ", gaps_out = " + s.gapsOut
           + ", col = { active_border = " + active + ", inactive_border = " + inactive + " } }"
           + ", group = { col = { border_active = " + active + ", border_inactive = " + inactive + " } }"
           + ", decoration = { rounding = " + s.rounding
           + ", rounding_power = " + corner.power.toFixed(1)
           + ", dim_inactive = " + (s.dim > 0 ? "true" : "false")
           + ", dim_strength = " + (clamp(s.dim, 0, 100) / 100).toFixed(2)
           + ", inactive_opacity = " + (clamp(s.inactiveOpacity, 10, 100) / 100).toFixed(2)
           + ", shadow = { enabled = " + (glow.alpha > 0 ? "true" : "false")
           + ", range = " + Math.max(1, glow.range) + ", render_power = " + glow.power
           + ", color = " + luaString(rgba(stops[0], glow.alpha))
           + ", color_inactive = " + luaString(rgba("#000000", glow.alpha > 0 ? 0x44 : 0)) + " } } })")
  parts.push("hl.animation({ leaf = \"border\", enabled = true, speed = " + borderSpeed + ", bezier = \"prismEase\" })")
  if (spin.speed > 0 && s.gradient)
    parts.push("hl.animation({ leaf = \"borderangle\", enabled = true, speed = " + Math.min(100, spin.speed) + ", bezier = \"prismLinear\", style = \"loop\" })")
  else
    parts.push("hl.animation({ leaf = \"borderangle\", enabled = false })")
  return "(function() " + parts.join("; ") + " end)()"
}

// Just the border colors — what breathing and palette cycling push every tick.
function colorLua(s, stops, breathDip) {
  var active = luaBorder(dimStops(stops, breathDip || 0), s.gradient, s.angle)
  var inactive = luaString(rgba(inactiveColor(stops, s.inactiveTone)))
  var glow = glows[clamp(s.glow, 0, glows.length - 1)]
  // The halo follows the lead color (and dips with the breath).
  var shadow = glow.alpha > 0
    ? ", decoration = { shadow = { color = " + luaString(rgba(stops[0], glow.alpha * (1 - (breathDip || 0) * 0.8))) + " } }"
    : ""
  return "hl.config({ general = { col = { active_border = " + active + ", inactive_border = " + inactive + " } }"
       + ", group = { col = { border_active = " + active + ", border_inactive = " + inactive + " } }" + shadow + " })"
}

// Shell surfaces read Hyprland-style gradient tokens: "#a #b #c 45deg".
function shellGradient(stops, gradient, angle) {
  return gradient ? stops.join(" ") + " " + Math.round(angle) + "deg" : stops[0]
}

// ── state sanitising ───────────────────────────────────────────────────────

function num(v, fallback, lo, hi) {
  var n = Number(v)
  return isFinite(n) ? clamp(Math.round(n), lo, hi) : fallback
}

function bool(v, fallback) { return v === undefined || v === null ? fallback : v === true }

function sanitize(d) {
  d = d || {}
  var D = defaults
  var known = d.paletteId === THEME_ID || d.paletteId === CUSTOM_ID || !!paletteById(d.paletteId)
  return {
    enabled: bool(d.enabled, D.enabled),
    paletteId: known ? d.paletteId : D.paletteId,
    customStops: cleanStops(d.customStops, D.customStops),
    gradient: bool(d.gradient, D.gradient),
    angle: num(d.angle, D.angle, 0, 359),
    inactiveTone: num(d.inactiveTone, D.inactiveTone, 0, 100),
    borderSize: num(d.borderSize, D.borderSize, 0, 10),
    rounding: num(d.rounding, D.rounding, 0, 32),
    corner: num(d.corner, D.corner, 0, corners.length - 1),
    gapsIn: num(d.gapsIn, D.gapsIn, 0, 40),
    gapsOut: num(d.gapsOut, D.gapsOut, 0, 60),
    spin: num(d.spin, D.spin, 0, spins.length - 1),
    glow: num(d.glow, D.glow, 0, glows.length - 1),
    morph: num(d.morph, D.morph, 0, morphs.length - 1),
    breathe: num(d.breathe, D.breathe, 0, breaths.length - 1),
    dim: num(d.dim, D.dim, 0, 80),
    inactiveOpacity: num(d.inactiveOpacity, D.inactiveOpacity, 50, 100),
    cycleSeconds: num(d.cycleSeconds, D.cycleSeconds, 0, 86400),
    cycleShuffle: bool(d.cycleShuffle, D.cycleShuffle),
    cycleFavorites: bool(d.cycleFavorites, D.cycleFavorites),
    favorites: Array.isArray(d.favorites) ? d.favorites.filter(function(id) { return !!paletteById(id) }) : [],
    tintShell: true,   // shell surfaces always follow the borders
    savedLooks: Array.isArray(d.savedLooks) ? d.savedLooks.filter(function(l) { return l && l.name && l.look }).slice(0, 12) : []
  }
}

// Next palette id for auto-cycle. `rand` is injectable for tests.
function nextPaletteId(current, favorites, onlyFavorites, shuffle, rand) {
  var pool = onlyFavorites && favorites.length > 1 ? favorites.slice() : palettes.map(function(p) { return p.id })
  if (pool.length < 2) return pool[0] || current
  var at = pool.indexOf(current)
  if (shuffle) {
    var r = rand || Math.random
    var pick = current
    while (pick === current) pick = pool[Math.floor(r() * pool.length) % pool.length]
    return pick
  }
  return pool[(at + 1) % pool.length]
}
