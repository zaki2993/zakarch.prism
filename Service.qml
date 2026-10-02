import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import "Engine.js" as E

// ---------------------------------------------------------------------------
// Prism service — owns every setting, persists them, and drives Hyprland.
//
// The bar widget reads/writes this object through bar.shell.serviceFor().
// All Hyprland changes go out as one atomic `hyprctl eval` Lua chunk, so a
// slider drag never leaves the compositor half-configured. Live effects:
//   spin     → Hyprland `borderangle` loop animation (runs in the compositor)
//   glow     → palette-tinted decoration shadow
//   breathe  → a timer alternating bright/dim stops; the `border` animation
//              curve blends between them so it reads as a slow pulse
//   cycle    → palette rotation using the same blend
// ---------------------------------------------------------------------------
Item {
  id: root

  property var shell: null
  property var manifest: null

  // ── persisted settings (mirrors Engine.defaults) ──────────────────────────
  property bool   enabled:         E.defaults.enabled
  property string paletteId:       E.defaults.paletteId
  property var    customStops:     E.defaults.customStops.slice()
  property bool   gradient:        E.defaults.gradient
  property int    angle:           E.defaults.angle
  property int    inactiveTone:    E.defaults.inactiveTone
  property int    borderSize:      E.defaults.borderSize
  property int    rounding:        E.defaults.rounding
  property int    corner:          E.defaults.corner
  property int    gapsIn:          E.defaults.gapsIn
  property int    gapsOut:         E.defaults.gapsOut
  property int    spin:            E.defaults.spin
  property int    glow:            E.defaults.glow
  property int    morph:           E.defaults.morph
  property int    breathe:         E.defaults.breathe
  property int    dim:             E.defaults.dim
  property int    inactiveOpacity: E.defaults.inactiveOpacity
  property int    cycleSeconds:    E.defaults.cycleSeconds
  property bool   cycleShuffle:    E.defaults.cycleShuffle
  property bool   cycleFavorites:  E.defaults.cycleFavorites
  property var    favorites:       []
  property bool   tintShell:       E.defaults.tintShell
  property var    savedLooks:      []

  // ── derived / runtime ─────────────────────────────────────────────────────
  property var    themeStops:  ["#E3A6C8", "#C792EA", "#7FBEC4"]
  property string lookName:    ""        // name of the look last applied, cleared on manual edits
  property var    undoStack:   []
  property bool   loaded:      false
  property bool   ipcReady:    false
  property bool   breathLow:   false
  property string lastError:   ""

  readonly property var stops: paletteId === E.THEME_ID ? themeStops
                             : paletteId === E.CUSTOM_ID ? customStops
                             : (E.paletteById(paletteId) || E.palettes[0]).stops
  readonly property string paletteName: paletteId === E.THEME_ID ? "Theme"
                                      : paletteId === E.CUSTOM_ID ? "Custom"
                                      : (E.paletteById(paletteId) || E.palettes[0]).name
  readonly property color inactiveBorder: E.inactiveColor(stops, inactiveTone)
  readonly property bool canUndo: undoStack.length > 0

  readonly property string home:      Quickshell.env("HOME")
  readonly property string stateDir:  home + "/.local/state/omarchy/zakarch.prism"
  readonly property string statePath: stateDir + "/settings.json"
  readonly property string themePath: home + "/.local/state/omarchy/current/theme/colors.toml"

  // ── snapshots (undo + looks) ──────────────────────────────────────────────
  function snapshot() {
    var s = {}
    for (var i = 0; i < E.lookKeys.length; i++) {
      var k = E.lookKeys[i]
      s[k] = Array.isArray(root[k]) ? root[k].slice() : root[k]
    }
    return s
  }

  function restore(s) {
    var clean = E.sanitize(Object.assign(snapshot(), s))
    for (var i = 0; i < E.lookKeys.length; i++) {
      var k = E.lookKeys[i]
      if (s[k] !== undefined) root[k] = clean[k]
    }
  }

  property double _lastUndoPush: 0
  // Group bursts (slider drags, wheel spins) into one undo step.
  function pushUndo() {
    var now = Date.now()
    if (now - _lastUndoPush > 700) {
      var next = undoStack.slice(-24)
      var snap = snapshot()
      snap.__look = lookName
      next.push(snap)
      undoStack = next
    }
    _lastUndoPush = now
  }

  function undo() {
    if (!undoStack.length) return
    var next = undoStack.slice()
    var s = next.pop()
    undoStack = next
    _lastUndoPush = 0
    restore(s)
    lookName = s.__look || ""
    commit()
  }

  // ── public setters ────────────────────────────────────────────────────────
  // Every UI edit funnels through set(): undo point, then commit.
  function set(key, value) {
    if (root[key] === value) return
    pushUndo()
    root[key] = value
    if (E.lookKeys.indexOf(key) !== -1) lookName = ""
    commit()
  }

  function choosePalette(id) {
    if (id === paletteId) return
    if (id !== E.THEME_ID && id !== E.CUSTOM_ID && !E.paletteById(id)) return
    pushUndo()
    paletteId = id
    lookName = ""
    commit()
  }

  function setCustomStop(i, hex) {
    var v = E.normHex(hex)
    if (!v) return
    // Editing starts from whatever palette is showing.
    var next = (paletteId === E.CUSTOM_ID ? customStops : stops).slice()
    if (next[i] === v && paletteId === E.CUSTOM_ID) return
    pushUndo()
    next[i] = v
    customStops = next
    paletteId = E.CUSTOM_ID
    lookName = ""
    commit()
  }

  // Seed the custom stops from whatever is showing, so editing starts there.
  function forkToCustom() {
    if (paletteId === E.CUSTOM_ID) return
    pushUndo()
    customStops = stops.slice()
    paletteId = E.CUSTOM_ID
    lookName = ""
    commit()
  }

  function toggleFavorite(id) {
    if (!E.paletteById(id)) return
    var next = favorites.slice()
    var at = next.indexOf(id)
    if (at === -1) next.push(id)
    else next.splice(at, 1)
    favorites = next
    commit()
  }

  function isFavorite(id) { return favorites.indexOf(id) !== -1 }

  function shuffle() {
    pushUndo()
    paletteId = E.nextPaletteId(paletteId, favorites, cycleFavorites && favorites.length > 1, true)
    lookName = ""
    commit()
  }

  function applyLook(look, name) {
    pushUndo()
    _lastUndoPush = 0
    restore(look)
    lookName = name || look.name || ""
    commit()
  }

  function saveLook(name) {
    var label = String(name || "").trim()
    if (!label) label = paletteName + " " + borderSize + "px"
    var next = savedLooks.filter(function(l) { return l.name !== label })
    next.unshift({ name: label, look: snapshot() })
    savedLooks = next.slice(0, 12)
    lookName = label
    commit()
  }

  function deleteLook(i) {
    var next = savedLooks.slice()
    next.splice(i, 1)
    savedLooks = next
    commit()
  }

  function resetAll() {
    pushUndo()
    _lastUndoPush = 0
    restore(E.defaults)
    lookName = ""
    commit()
  }

  function setEnabled(on) {
    if (on === enabled) return
    enabled = on
    if (on) {
      commit()
    } else {
      breathTimer.stop()
      cycleTimer.stop()
      releaseShell()
      saveTimer.restart()
      // Hand control back to the theme / user config.
      reloadProc.running = true
    }
  }

  // ── apply pipeline ────────────────────────────────────────────────────────
  // commit() = persist + push to Hyprland (debounced) + resync timers.
  function commit() {
    if (!loaded) return
    saveTimer.restart()
    if (!enabled) return
    syncTimers()
    syncShell()
    applyTimer.restart()
  }

  function hyprState() {
    return {
      gradient: gradient, angle: angle, inactiveTone: inactiveTone,
      borderSize: borderSize, rounding: rounding, corner: corner, gapsIn: gapsIn, gapsOut: gapsOut,
      spin: spin, glow: glow, morph: morph, breathe: breathe,
      dim: dim, inactiveOpacity: inactiveOpacity
    }
  }

  property string _pendingLua: ""
  function send(lua) {
    if (!ipcReady) { ipcReadyTimer.restart(); return }
    if (evalProc.running) { _pendingLua = lua; return }
    evalProc.command = ["hyprctl", "eval", lua]
    evalProc.running = true
  }

  function applyNow() {
    if (!loaded || !enabled) return
    send(E.fullLua(hyprState(), stops, breathLow ? 0.45 : 0))
  }

  function syncTimers() {
    var b = E.breaths[Math.max(0, Math.min(breathe, E.breaths.length - 1))]
    if (enabled && loaded && b.ms > 0) {
      breathTimer.interval = b.ms
      if (!breathTimer.running) breathTimer.start()
    } else {
      breathTimer.stop()
      breathLow = false
    }
    if (enabled && loaded && cycleSeconds > 0) {
      var ms = cycleSeconds * 1000
      if (cycleTimer.interval !== ms || !cycleTimer.running) {
        cycleTimer.interval = ms
        cycleTimer.restart()
      }
    } else {
      cycleTimer.stop()
    }
  }

  // ── shell surfaces (popups, notifications, menu follow the border) ────────
  property bool   _shellOwned: false
  property var    _shellOriginal: ({})
  property bool   _syncingShell: false

  function shellKeys() {
    return {
      "hyprland.active-border": E.shellGradient(stops, gradient, angle),
      // Plugin popups and notifications take the window border width too.
      "hyprland.active-border-width": String(borderSize),
      "popups.border-width": String(borderSize),
      "notifications.border-width": String(borderSize)
    }
  }

  function syncShell() {
    if (typeof Color === "undefined" || !Color) return
    if (typeof Style !== "undefined" && Style && enabled) Style.cornerRadius = rounding
    if (!tintShell || !enabled) { releaseShell(); return }
    var want = shellKeys()
    var cur = Color.shellValues || {}
    var differs = false
    for (var k in want) if (cur[k] !== want[k]) differs = true
    if (!differs) return
    _syncingShell = true
    var vals = {}
    for (var key in cur) vals[key] = cur[key]
    for (var w in want) {
      // Remember the theme's value so turning tinting off restores it.
      if (!_shellOwned || cur[w] !== _lastShell[w]) _shellOriginal[w] = cur[w]
      vals[w] = want[w]
    }
    _lastShell = want
    _shellOwned = true
    Color.shellValues = vals
    _syncingShell = false
  }
  property var _lastShell: ({})

  function releaseShell() {
    if (!_shellOwned || typeof Color === "undefined" || !Color) return
    _syncingShell = true
    var vals = {}
    var cur = Color.shellValues || {}
    for (var key in cur) vals[key] = cur[key]
    for (var k in _shellOriginal) {
      if (_shellOriginal[k] === undefined) delete vals[k]
      else vals[k] = _shellOriginal[k]
    }
    Color.shellValues = vals
    _shellOwned = false
    _shellOriginal = {}
    _lastShell = {}
    _syncingShell = false
    if (typeof Style !== "undefined" && Style && Style.refresh) Style.refresh()
  }

  // ── persistence ───────────────────────────────────────────────────────────
  function load(raw) {
    var d = {}
    try { d = JSON.parse(raw || "{}") } catch (e) { d = {} }
    var s = E.sanitize(d)
    for (var k in s) root[k] = s[k]
    lookName = typeof d.lookName === "string" ? d.lookName : ""
    loaded = true
  }

  function save() {
    var out = { version: 1, lookName: lookName }
    for (var k in E.defaults) out[k] = Array.isArray(root[k]) ? root[k].slice() : root[k]
    out.savedLooks = savedLooks
    stateFile.setText(JSON.stringify(out, null, 2) + "\n")
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: { root.load(text()); root.afterLoad() }
    onLoadFailed: { root.load("{}"); root.afterLoad() }
  }

  function afterLoad() {
    syncTimers()
    syncShell()
    ipcReadyTimer.restart()
  }

  FileView {
    id: themeFile
    path: root.themePath
    watchChanges: true
    printErrors: false
    onLoaded: {
      var t = E.themeStops(text())
      if (!t) return
      var changed = t.stops.join() !== root.themeStops.join()
      root.themeStops = t.stops
      if (changed && root.paletteId === E.THEME_ID) root.commit()
    }
    onFileChanged: reload()
  }

  // ── processes ─────────────────────────────────────────────────────────────
  Process {
    id: ensureDir
    command: ["mkdir", "-p", root.stateDir]
    onExited: stateFile.reload()
  }

  Process {
    id: evalProc
    stdout: StdioCollector { id: evalOut }
    onExited: function(code) {
      var out = String(evalOut.text || "").trim()
      root.lastError = code === 0 && (out === "" || out === "ok") ? "" : (out || ("hyprctl exited " + code))
      if (root.lastError) console.warn("[prism] hyprctl eval:", root.lastError)
      if (root._pendingLua) {
        var next = root._pendingLua
        root._pendingLua = ""
        root.send(next)
      }
    }
  }

  Process {
    id: reloadProc
    command: ["hyprctl", "reload"]
    // Shell corners follow Hyprland's rounding again once the theme is back.
    onExited: if (typeof Style !== "undefined" && Style && Style.refresh) Style.refresh()
  }

  // ── timers ────────────────────────────────────────────────────────────────
  // First hyprctl call waits for Hyprland IPC to settle after a shell start.
  Timer {
    id: ipcReadyTimer
    interval: 1200
    onTriggered: { root.ipcReady = true; root.applyNow() }
  }

  // Coalesce slider drags into ~25 applies per second at most.
  Timer {
    id: applyTimer
    interval: 40
    onTriggered: root.applyNow()
  }

  Timer {
    id: saveTimer
    interval: 400
    onTriggered: root.save()
  }

  Timer {
    id: breathTimer
    repeat: true
    onTriggered: {
      root.breathLow = !root.breathLow
      root.send(E.colorLua(root.hyprState(), root.stops, root.breathLow ? 0.45 : 0))
    }
  }

  Timer {
    id: cycleTimer
    repeat: true
    onTriggered: {
      root.paletteId = E.nextPaletteId(root.paletteId, root.favorites, root.cycleFavorites, root.cycleShuffle)
      root.lookName = ""
      root.saveTimer.restart()
      root.syncShell()
      root.send(E.colorLua(root.hyprState(), root.stops, root.breathLow ? 0.45 : 0))
    }
  }

  // A theme switch or `hyprctl reload` resets borders; put ours back.
  Timer {
    id: reapplyTimer
    interval: 150
    onTriggered: root.applyNow()
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name !== "configreloaded" || !root.enabled) return
      themeFile.reload()
      reapplyTimer.restart()
    }
  }

  // The shell re-merges theme values on theme change; re-assert our tint.
  Timer {
    id: shellResync
    interval: 250
    onTriggered: root.syncShell()
  }

  Connections {
    target: (typeof Color !== "undefined") ? Color : null
    ignoreUnknownSignals: true
    function onShellValuesChanged() {
      if (root.loaded && root.enabled && root.tintShell && !root._syncingShell) shellResync.restart()
    }
  }

  Component.onCompleted: ensureDir.running = true
  Component.onDestruction: releaseShell()
}
