// Engine sanity checks: `node check.js` (add `--lua` to print the Lua chunk).
const fs = require("fs")
const path = require("path")
const assert = require("assert")

const src = fs.readFileSync(path.join(__dirname, "Engine.js"), "utf8").replace(/^\.pragma library\s*/, "")
const E = new Function(src + "\nreturn { palettes, spins, glows, morphs, breaths, cycles, defaults, looks, lookKeys," +
  " normHex, mix, hsl, fromHsl, contrast, paletteById, themeStops, dimStops, inactiveColor, rgba," +
  " luaBorder, fullLua, corners, framePoints, colorLua, shellGradient, sanitize, nextPaletteId }")()

// colors
assert.strictEqual(E.normHex("abc"), "#AABBCC")
assert.strictEqual(E.normHex("#12345g"), "")
assert.strictEqual(E.mix("#000000", "#FFFFFF", 0.5), "#808080")
assert.strictEqual(E.fromHsl(0, 1, 0.5), "#FF0000")
assert.strictEqual(E.fromHsl(240, 1, 0.5), "#0000FF")
const round = E.hsl("#38BDF8")
assert.strictEqual(E.fromHsl(round.h, round.s, round.l), "#38BDF8")
assert.strictEqual(E.contrast("#FDE047"), "#000000")
assert.strictEqual(E.contrast("#1E1B4B"), "#FFFFFF")
assert.strictEqual(E.rgba("#38bdf8"), "rgba(38BDF8EE)")
assert.strictEqual(E.rgba("#38bdf8", 0x44), "rgba(38BDF844)")

// palettes have unique ids and three valid stops
const ids = new Set()
for (const p of E.palettes) {
  assert(!ids.has(p.id), "duplicate palette " + p.id); ids.add(p.id)
  assert.strictEqual(p.stops.length, 3)
  p.stops.forEach(c => assert(E.normHex(c), p.id + " bad stop " + c))
}
for (const l of E.looks) {
  assert(l.paletteId === "theme" || E.paletteById(l.paletteId), "look palette " + l.name)
  for (const k of E.lookKeys) if (k !== "customStops" && k !== "morph")
    assert(l[k] !== undefined, l.name + " is missing " + k)
  assert.deepStrictEqual(E.sanitize(Object.assign({}, E.defaults, l)).corner, l.corner, l.name + " corner")
}
assert(new Set(E.looks.map(l => l.name)).size === E.looks.length, "look names unique")
for (const sp of E.spins) assert(sp.speed <= 100, "Hyprland caps speed at 100: " + sp.name)

// corner outlines
const facet = E.framePoints(0, 0, 100, 60, 10, 1)
assert(facet.some(p => p.x === 90 && p.y === 0) && facet.some(p => p.x === 100 && Math.abs(p.y - 10) < 1e-9), "facet cuts a straight diagonal")
assert.strictEqual(facet.length, 4 * 2 + 1)
const circle = E.framePoints(0, 0, 100, 60, 10, 2, 8)
const mid = circle[4]   // 45° on the top-right corner
assert(Math.abs(Math.hypot(mid.x - 90, mid.y - 10) - 10) < 1e-6, "power 2 is a circle")
for (const p of E.framePoints(0, 0, 100, 60, 30, 4)) assert(p.x >= -1e-9 && p.x <= 100 + 1e-9 && p.y >= -1e-9 && p.y <= 60 + 1e-9)
assert.strictEqual(E.framePoints(0, 0, 50, 50, 0, 2).length, 5)

// theme parsing
const theme = E.themeStops('accent = "#e3a6c8"\nmagenta = "#c792ea"\ncyan = "#7fbec4"\nbackground = "#171022"')
assert.deepStrictEqual(theme.stops, ["#E3A6C8", "#C792EA", "#7FBEC4"])
assert.strictEqual(E.themeStops("nothing here"), null)

// sanitize clamps and falls back
const s = E.sanitize({ paletteId: "nope", borderSize: 99, angle: -5, favorites: ["neon", "bogus"], gradient: false })
assert.strictEqual(s.paletteId, E.defaults.paletteId)
assert.strictEqual(s.borderSize, 10)
assert.strictEqual(s.angle, 0)
assert.deepStrictEqual(s.favorites, ["neon"])
assert.strictEqual(s.gradient, false)
assert.strictEqual(E.sanitize({ paletteId: "custom" }).paletteId, "custom")

// cycling
assert.strictEqual(E.nextPaletteId("aurora", [], false, false), E.palettes[1].id)
assert.strictEqual(E.nextPaletteId("rose", ["rose", "neon"], true, false), "neon")
assert.strictEqual(E.nextPaletteId("theme", [], false, false), E.palettes[0].id)
let n = 0
assert.notStrictEqual(E.nextPaletteId("aurora", [], false, true, () => (n++ === 0 ? 0 : 0.5)), "aurora")

// lua
const stops = E.palettes[0].stops
const full = E.fullLua(Object.assign({}, E.defaults, { spin: 2, glow: 2 }), stops, 0)
assert(full.startsWith("(function() ") && full.endsWith(" end)()"))
assert(full.includes("style = \"loop\""))
assert(full.includes("angle = 45"))
const flat = E.fullLua(Object.assign({}, E.defaults, { gradient: false, spin: 2, glow: 0 }), stops, 0)
assert(flat.includes("leaf = \"borderangle\", enabled = false"), "spin needs a gradient")
assert(flat.includes("shadow = { enabled = false"))
assert(E.colorLua(E.defaults, stops, 0.3).includes(E.rgba(E.mix(stops[0], "#000000", 0.3))))
assert(E.colorLua(Object.assign({}, E.defaults, { glow: 2 }), stops, 0).includes("shadow = { color = \"" + E.rgba(stops[0], 0x88) + "\""), "cycle/breathe must retint the glow")
assert(!E.colorLua(Object.assign({}, E.defaults, { glow: 0 }), stops, 0).includes("shadow"))
if (process.argv.includes("--color")) { console.log(E.colorLua(Object.assign({}, E.defaults, { glow: 2 }), stops, 0.45)); process.exit(0) }
assert.strictEqual(E.shellGradient(stops, true, 45), stops.join(" ") + " 45deg")

if (process.argv.includes("--looks")) {
  for (const l of E.looks) {
    const st = l.paletteId === "theme" ? E.palettes[0].stops : E.paletteById(l.paletteId).stops
    console.log(E.fullLua(Object.assign({}, E.defaults, l), st, 0))
  }
  process.exit(0)
}
assert(full.includes("rounding_power = 2.0"))
if (process.argv.includes("--lua")) console.log(full)
else console.log("engine ok")
