import QtQuick
import QtQuick.Effects
import qs.Commons

// Gives every bar plugin's popup the Facet corner shape — including plugins
// installed later — without touching their code or the shell's.
//
// Every popup in the shell is a KeyboardPanel or PopupCard: a window with a
// `borderSpec` and an inner BorderSurface "card" at Style.cornerRadius. While
// active, this walks the bar's object tree, and for each such card:
//   · masks the card with the facet outline (layer effect, input untouched)
//   · makes the card's own border transparent at the same width, so content
//     insets don't shift, and paints a faceted border in the popup's colors
// Detaching restores the card's original bindings exactly.
Item {
  id: root

  property Item origin: null          // any item inside the bar
  property bool active: false
  property var  bar: null             // rescans when a popout opens
  property var  attached: []          // [{ win, card, mask, frame }]

  visible: false

  // ── discovery ─────────────────────────────────────────────────────────────
  function isPopupWindow(o) {
    return o && typeof o === "object" && ("borderSpec" in o) && ("contentWidth" in o)
        && ("contentHeight" in o) && ("anchorItem" in o || "anchor" in o) && !("radius" in o)
  }

  function isCard(o) {
    return o && ("borderSpec" in o) && ("contentTopInset" in o) && ("radius" in o)
  }

  function cardOf(win) {
    var list = win.data || []
    for (var i = 0; i < list.length; i++) if (isCard(list[i])) return list[i]
    // Content aliased into the card's holder: walk up from the first child.
    var content = win.contentItem
    if (content && content.length) {
      var c = content[0]
      while (c && c.parent) {
        if (isCard(c.parent)) return c.parent
        c = c.parent
      }
    }
    return null
  }

  function childrenOf(o) {
    var out = []
    try {
      if (o.data && o.data.length !== undefined) for (var i = 0; i < o.data.length; i++) out.push(o.data[i])
      else if (o.children && o.children.length !== undefined) for (var j = 0; j < o.children.length; j++) out.push(o.children[j])
    } catch (e) {}
    return out
  }

  function scan() {
    if (!active || !origin) return
    var top = origin
    while (top.parent) top = top.parent
    var seen = new Set()
    var stack = [top]
    var found = []
    while (stack.length) {
      var o = stack.pop()
      if (!o || seen.has(o)) continue
      seen.add(o)
      if (isPopupWindow(o)) found.push(o)
      var kids = childrenOf(o)
      for (var k = 0; k < kids.length; k++) stack.push(kids[k])
    }
    prune()
    for (var f = 0; f < found.length; f++) attach(found[f])
  }

  // Drop entries whose popup was destroyed (plugin reloads, removals).
  function prune() {
    var keep = []
    for (var i = 0; i < attached.length; i++) {
      var a = attached[i]
      if (a.card && a.win) keep.push(a)
      else {
        if (a.mask) a.mask.destroy()
        if (a.frame) a.frame.destroy()
      }
    }
    attached = keep
  }

  // Checks the card itself, so a second injector (another bar, or an old
  // instance during a plugin reload) never stacks a second border on it.
  function isAttached(card) {
    for (var i = 0; i < attached.length; i++) if (attached[i].card === card) return true
    var kids = card.children
    for (var k = 0; k < kids.length; k++) if (kids[k].objectName === "prismFacetFrame") return true
    return false
  }

  // ── attach / detach ───────────────────────────────────────────────────────
  function widthsOf(spec) {
    var w = spec && spec.widths ? spec.widths : { top: 0, right: 0, bottom: 0, left: 0 }
    return w.top + " " + w.right + " " + w.bottom + " " + w.left
  }

  function stopsOf(spec) {
    if (spec && spec.gradient && spec.gradient.enabled && spec.gradient.colors.length > 1) {
      var c = spec.gradient.colors
      return [c[0], c[Math.floor((c.length - 1) / 2)], c[c.length - 1]]
    }
    var solid = spec ? spec.color : "transparent"
    return [solid, solid, solid]
  }

  function attach(win) {
    var card = cardOf(win)
    if (!card || !card.parent || isAttached(card)) return

    var mask = maskComp.createObject(card.parent, { card: card })
    var frame = frameComp.createObject(card, { win: win })
    if (!mask || !frame) { if (mask) mask.destroy(); if (frame) frame.destroy(); return }

    // Same widths, no paint: content keeps its exact position.
    card.borderSpec = Qt.binding(function() { return Border.flat("transparent", root.widthsOf(win.borderSpec)) })
    card.layer.effect = effectComp
    card.layer.enabled = true

    var next = attached.slice()
    next.push({ win: win, card: card, mask: mask, frame: frame })
    attached = next
  }

  function detach(a) {
    if (a.card) {
      a.card.layer.enabled = false
      a.card.layer.effect = null
      var w = a.win
      if (w) a.card.borderSpec = Qt.binding(function() { return w.borderSpec })
    }
    if (a.mask) a.mask.destroy()
    if (a.frame) a.frame.destroy()
  }

  function detachAll() {
    for (var i = 0; i < attached.length; i++) detach(attached[i])
    attached = []
  }

  onActiveChanged: active ? scan() : detachAll()
  Component.onDestruction: detachAll()

  Timer {
    interval: 4000
    repeat: true
    running: root.active
    onTriggered: root.scan()
  }

  Connections {
    target: root.bar
    ignoreUnknownSignals: true
    function onActivePopoutChanged() { if (root.active) root.scan() }
  }

  // ── pieces created per popup ──────────────────────────────────────────────
  // Card-sized facet outline rendered to a texture, used as the alpha mask.
  Component {
    id: maskComp
    PrismFrame {
      property Item card: null
      objectName: "prismFacetMask"
      x: card ? card.x : 0
      y: card ? card.y : 0
      width: card ? card.width : 0
      height: card ? card.height : 0
      visible: false
      layer.enabled: true
      gradient: false
      borderWidth: 0
      radius: card ? card.radius : 0
      cornerPower: 1
      fill: "#FFFFFF"
      animate: false
    }
  }

  // The faceted border, in whatever colors the popup's own border uses.
  Component {
    id: frameComp
    PrismFrame {
      property var win: null
      objectName: "prismFacetFrame"
      readonly property var spec: win ? win.borderSpec : null
      anchors.fill: parent
      z: 1000
      stops: root.stopsOf(spec)
      gradient: !!(spec && spec.gradient && spec.gradient.enabled)
      angle: spec && spec.gradient ? spec.gradient.angle : 0
      borderWidth: spec && spec.widths ? Math.max(spec.widths.top, spec.widths.left) : 0
      radius: parent ? parent.radius : 0
      cornerPower: 1
      fill: "transparent"
      animate: false
    }
  }

  // Layer effect on the card; finds the sibling mask made for it.
  Component {
    id: effectComp
    MultiEffect {
      maskEnabled: true
      maskThresholdMin: 0.5
      maskSpreadAtMin: 1.0
      maskSource: {
        var kids = parent ? parent.children : []
        for (var i = 0; i < kids.length; i++) if (kids[i].objectName === "prismFacetMask") return kids[i]
        return null
      }
    }
  }

  // Diagnostics for IPC: what got faceted.
  function report() {
    var names = []
    for (var i = 0; i < attached.length; i++) {
      var w = attached[i].win
      var owner = w && w.owner && w.owner.moduleName ? w.owner.moduleName : (w && w.anchorItem ? "popup" : "?")
      names.push(owner)
    }
    return (active ? "active" : "inactive") + " · " + attached.length + " popups: " + names.join(", ")
  }
}
