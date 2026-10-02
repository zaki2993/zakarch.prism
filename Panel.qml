import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Engine.js" as E

// ---------------------------------------------------------------------------
// Prism — Border Studio. Bar glyph + popup studio.
// All state lives in Service.qml; this file is presentation only.
//   click → open · right-click → shuffle · middle-click → pause
// ---------------------------------------------------------------------------
Panel {
  id: root
  moduleName: "zakarch.prism"
  manageIpc: false

  // ── service lookup (the service may mount after the bar) ─────────────────
  property var svc: null
  function resolveService() {
    var s = bar && bar.shell ? bar.shell.serviceFor("zakarch.prism") : null
    if (s !== svc) svc = s
  }
  onBarChanged: resolveService()
  Component.onCompleted: resolveService()
  Timer {
    interval: 600
    repeat: true
    running: !root.svc || !root.svc.loaded
    onTriggered: root.resolveService()
  }

  readonly property bool ready: !!svc && svc.loaded
  readonly property var  stops: ready ? svc.stops : ["#8B5CF6", "#22D3EE", "#34D399"]
  readonly property color lead: stops[0]
  readonly property color fg: Color.popups.text
  readonly property color bg: Color.popups.background
  readonly property color muted: Util.alpha(fg, 0.58)
  readonly property color faint: Util.alpha(fg, 0.08)
  readonly property string ff: Style.font.family

  property int activeTab: 0
  property bool typing: false          // a text field owns the keyboard
  readonly property var tabs: ["Palette", "Shape", "Effects", "Looks"]

  function sp(px) { return Style.space(px) }

  // ── facet corners on every plugin popup ──────────────────────────────────
  FacetInjector {
    id: facets
    origin: root
    bar: root.bar
    active: root.ready && root.svc.enabled && root.svc.corner === 0 && Style.cornerRadius > 0
  }

  function paletteCards() {
    if (!ready) return []
    var out = [{ id: E.THEME_ID, name: "Theme", stops: svc.themeStops }]
    for (var i = 0; i < E.palettes.length; i++) out.push(E.palettes[i])
    out.push({ id: E.CUSTOM_ID, name: "Custom", stops: svc.customStops })
    return out
  }

  function statusLine() {
    if (!ready) return "Starting…"
    if (!svc.enabled) return "Paused"
    var head = svc.lookName !== "" ? svc.lookName : svc.paletteName
    var corner = svc.corner !== 1 && svc.rounding > 0 ? " " + E.corners[svc.corner].name.toLowerCase() : ""
    return head + " · " + svc.borderSize + "px · r" + svc.rounding + corner + " · gaps " + svc.gapsIn + "/" + svc.gapsOut
  }

  function stopsFor(look) {
    if (look.paletteId === E.THEME_ID) return ready ? svc.themeStops : stops
    if (look.paletteId === E.CUSTOM_ID) return look.customStops || stops
    var p = E.paletteById(look.paletteId)
    return p ? p.stops : stops
  }

  // omarchy-shell zakarch.prism.widget toggle  (bind it to a key if you like)
  IpcHandler {
    target: "zakarch.prism.widget"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function shuffle(): void { if (root.ready) root.svc.shuffle() }
    function undo(): void { if (root.ready) root.svc.undo() }
    function facetReport(): string { facets.scan(); return facets.report() }
    function status(): string { return root.ready ? root.statusLine() + (root.svc.lastError ? " · error: " + root.svc.lastError : "") : "not ready" }
    function pause(): void { if (root.ready) root.svc.setEnabled(!root.svc.enabled) }
    function tab(index: int): void { root.activeTab = Math.max(0, Math.min(root.tabs.length - 1, index)) }
    function palette(id: string): void { if (root.ready) root.svc.choosePalette(id) }
    function look(name: string): string {
      if (!root.ready) return "not ready"
      var all = E.looks.concat(root.svc.savedLooks.map(function(l) { return Object.assign({ name: l.name }, l.look) }))
      for (var i = 0; i < all.length; i++)
        if (all[i].name.toLowerCase() === name.toLowerCase()) { root.svc.applyLook(all[i], all[i].name); return all[i].name }
      return "unknown look"
    }
  }

  visible: true
  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight

  // ── bar button ────────────────────────────────────────────────────────────
  BarIconButton {
    id: btn
    anchors.fill: parent
    bar: root.bar
    text: ""
    iconComponent: iconComp
    slotSize: Style.bar.iconSlot
    tooltipText: !root.ready ? "Prism" : !root.svc.enabled ? "Prism · paused" : "Prism · " + root.svc.paletteName
    onPressed: function(b) { if (b === Qt.LeftButton) root.toggle() }
  }

  Component {
    id: iconComp
    Item {
      anchors.fill: parent
      PrismIcon {
        anchors.centerIn: parent
        width: Math.round(parent.width * 0.86)
        height: width
        stops: root.stops
        live: root.ready && root.svc.enabled
        spinning: root.ready && root.svc.spin > 0 && root.svc.gradient
        breatheMs: root.ready ? E.breaths[root.svc.breathe].ms : 0
        idleColor: root.barForeground
      }
    }
  }

  // ── reusable bits ─────────────────────────────────────────────────────────
  component Caps: Text {
    textFormat: Text.PlainText
    color: root.muted
    font.family: root.ff
    font.pixelSize: Style.font.caption - 1
    font.bold: true
    font.letterSpacing: 1.4
  }

  component Body: Text {
    textFormat: Text.PlainText
    color: root.fg
    font.family: root.ff
    font.pixelSize: Style.font.bodySmall
    elide: Text.ElideRight
  }

  component Card: Rectangle {
    radius: root.sp(10)
    color: Util.alpha(root.fg, 0.035)
    border.width: 1
    border.color: Util.alpha(root.fg, 0.07)
  }

  component IconButton: Rectangle {
    id: ib
    property string glyph: ""
    property string hint: ""
    property bool lit: false
    signal clicked()
    width: root.sp(28); height: width
    radius: root.sp(8)
    color: ibMouse.pressed ? Util.alpha(root.lead, 0.25)
         : ibMouse.containsMouse ? Util.alpha(root.fg, 0.10)
         : lit ? Util.alpha(root.lead, 0.14) : Util.alpha(root.fg, 0.04)
    border.width: 1
    border.color: ibMouse.containsMouse || lit ? Util.alpha(root.lead, 0.7) : Util.alpha(root.fg, 0.10)
    opacity: enabled ? 1 : 0.35
    Behavior on color { ColorAnimation { duration: 120 } }
    Text {
      anchors.centerIn: parent
      text: ib.glyph
      color: root.fg
      font.family: root.ff
      font.pixelSize: Style.font.body + 4
    }
    MouseArea {
      id: ibMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: ib.clicked()
    }
  }

  component Chip: Rectangle {
    id: chip
    property string label: ""
    property bool on: false
    signal clicked()
    height: root.sp(22)
    radius: root.sp(6)
    color: on ? Util.alpha(root.lead, 0.22) : chipMouse.containsMouse ? Util.alpha(root.fg, 0.09) : Util.alpha(root.fg, 0.04)
    border.width: 1
    border.color: on ? Util.alpha(root.lead, 0.85) : Util.alpha(root.fg, 0.07)
    Behavior on color { ColorAnimation { duration: 110 } }
    Text {
      anchors.centerIn: parent
      text: chip.label
      color: chip.on ? root.fg : root.muted
      font.family: root.ff
      font.pixelSize: Style.font.caption
      font.weight: chip.on ? Font.DemiBold : Font.Normal
    }
    MouseArea {
      id: chipMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: chip.clicked()
    }
  }

  // Slider row with headline value and quick picks. `glyph` draws the
  // little diagram on the left.
  component ValueRow: Card {
    id: vr
    property string title: ""
    property string unit: "px"
    property int value: 0
    property int minimum: 0
    property int maximum: 10
    property var picks: []
    property Component glyph: null
    signal valuePicked(int value)
    width: parent ? parent.width : 0
    implicitHeight: vrCol.implicitHeight + root.sp(20)

    Column {
      id: vrCol
      x: root.sp(10); y: root.sp(10)
      width: parent.width - root.sp(20)
      spacing: root.sp(6)

      Item {
        width: parent.width
        height: root.sp(30)
        Rectangle {
          id: glyphBox
          width: root.sp(30); height: width
          radius: root.sp(8)
          color: Util.alpha(root.lead, 0.10)
          border.width: 1
          border.color: Util.alpha(root.lead, 0.35)
          Loader { anchors.fill: parent; anchors.margins: root.sp(7); sourceComponent: vr.glyph }
        }
        Body {
          anchors.left: glyphBox.right
          anchors.leftMargin: root.sp(10)
          anchors.verticalCenter: parent.verticalCenter
          text: vr.title
          font.bold: true
        }
        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: root.sp(3)
          Text {
            id: vrNum
            text: vr.value
            color: root.fg
            font.family: root.ff
            font.pixelSize: Style.font.heading + 2
            font.bold: true
          }
          Text {
            anchors.baseline: vrNum.baseline
            text: vr.unit
            color: root.muted
            font.family: root.ff
            font.pixelSize: Style.font.caption
          }
        }
      }

      PrismSlider {
        width: parent.width
        minimum: vr.minimum
        maximum: vr.maximum
        step: 1
        value: vr.value
        fillColor: root.lead
        knobColor: root.stops[1]
        tickCount: vr.maximum - vr.minimum <= 12 ? vr.maximum - vr.minimum + 1 : 0
        tickColor: root.bg
        onMoved: function(v) { vr.valuePicked(Math.round(v)) }
        onReleased: function(v) { vr.valuePicked(Math.round(v)) }
      }

      Row {
        width: parent.width
        spacing: root.sp(4)
        Repeater {
          model: vr.picks
          delegate: Chip {
            required property var modelData
            width: (vrCol.width - root.sp(4) * (vr.picks.length - 1)) / vr.picks.length
            label: String(modelData)
            on: vr.value === modelData
            onClicked: vr.valuePicked(modelData)
          }
        }
      }
    }
  }

  // Titled effect selector: name, hint, segmented options.
  component EffectRow: Column {
    id: er
    property string title: ""
    property string hint: ""
    property var options: []
    property int current: 0
    property bool usable: true
    signal picked(int index)
    width: parent ? parent.width : 0
    spacing: root.sp(6)
    Item {
      width: parent.width
      height: erTitle.implicitHeight
      Body { id: erTitle; text: er.title; font.bold: true }
      Text {
        anchors.right: parent.right
        anchors.left: erTitle.right
        anchors.leftMargin: root.sp(12)
        anchors.verticalCenter: erTitle.verticalCenter
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
        text: er.hint
        color: er.usable ? root.muted : Util.alpha(Color.urgent, 0.9)
        font.family: root.ff
        font.pixelSize: Style.font.caption
      }
    }
    Segmented {
      width: parent.width
      options: er.options
      current: er.current
      stops: root.stops
      active: er.usable
      onPicked: function(i) { er.picked(i) }
    }
  }

  component SwitchLine: Item {
    id: sl
    property string title: ""
    property string hint: ""
    property bool checked: false
    signal toggled()
    width: parent ? parent.width : 0
    height: Math.max(slText.implicitHeight, slSwitch.implicitHeight)
    Column {
      id: slText
      anchors.left: parent.left
      anchors.right: slSwitch.left
      anchors.rightMargin: root.sp(10)
      anchors.verticalCenter: parent.verticalCenter
      spacing: 1
      Body { width: parent.width; text: sl.title; font.bold: true }
      Text {
        width: parent.width
        visible: sl.hint !== ""
        text: sl.hint
        wrapMode: Text.WordWrap
        color: root.muted
        font.family: root.ff
        font.pixelSize: Style.font.caption
      }
    }
    ToggleSwitch {
      id: slSwitch
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      checked: sl.checked
      accent: root.lead
      foreground: root.fg
      onToggled: sl.toggled()
    }
  }

  // ── popup ─────────────────────────────────────────────────────────────────
  KeyboardPanel {
    id: popup
    anchorItem: btn
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: catcher
    contentWidth: popup.fittedContentWidth(root.sp(456))
    contentHeight: popup.fittedContentHeight(body.implicitHeight, root.sp(860))

    PanelKeyCatcher {
      id: catcher
      anchors.fill: parent
      blocked: root.typing
      onCloseRequested: root.close()
      onTabRequested: function(d) { root.switchPanel(d) }

      Flickable {
        id: scroller
        anchors.fill: parent
        contentWidth: width
        contentHeight: body.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        clip: true

        Column {
          id: body
          width: scroller.width
          spacing: root.sp(12)

          // ═══ header ═══════════════════════════════════════════════════════
          Item {
            width: parent.width
            height: root.sp(40)

            PrismIcon {
              id: headIcon
              width: root.sp(34); height: width
              anchors.verticalCenter: parent.verticalCenter
              stops: root.stops
              live: root.ready && root.svc.enabled
              spinning: root.opened
              breatheMs: root.ready ? E.breaths[root.svc.breathe].ms : 0
              idleColor: root.fg
            }

            Column {
              anchors.left: headIcon.right
              anchors.leftMargin: root.sp(12)
              anchors.right: headActions.left
              anchors.rightMargin: root.sp(10)
              anchors.verticalCenter: parent.verticalCenter
              spacing: root.sp(2)
              Row {
                spacing: root.sp(8)
                Text {
                  text: "Prism"
                  color: root.fg
                  font.family: root.ff
                  font.pixelSize: Style.font.heading + 2
                  font.bold: true
                }
                Caps {
                  anchors.baseline: parent.children[0].baseline
                  text: "BORDER STUDIO"
                }
              }
              Text {
                width: parent.width
                text: root.statusLine()
                elide: Text.ElideRight
                color: root.muted
                font.family: root.ff
                font.pixelSize: Style.font.caption
              }
            }

            Row {
              id: headActions
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: root.sp(6)
              IconButton {
                glyph: "↶"
                enabled: root.ready && root.svc.canUndo
                onClicked: root.svc.undo()
              }
              IconButton {
                glyph: "⇄"
                enabled: root.ready && root.svc.enabled
                onClicked: root.svc.shuffle()
              }
              ToggleSwitch {
                anchors.verticalCenter: parent.verticalCenter
                cursorRing: false
                checked: root.ready && root.svc.enabled
                accent: root.lead
                foreground: root.fg
                onToggled: if (root.ready) root.svc.setEnabled(!root.svc.enabled)
              }
            }
          }

          Text {
            visible: root.ready && root.svc.lastError !== ""
            width: parent.width
            wrapMode: Text.WordWrap
            text: root.ready ? "Hyprland said: " + root.svc.lastError : ""
            color: Color.urgent
            font.family: root.ff
            font.pixelSize: Style.font.caption
          }

          // ═══ live strip: the border itself, with spin / breathe / glow ══════
          PrismFrame {
            id: strip
            width: parent.width
            height: root.sp(34)
            radius: height / 2
            cornerPower: root.ready ? E.corners[root.svc.corner].power : 2
            stops: root.stops
            gradient: root.ready ? root.svc.gradient : true
            angle: root.ready ? root.svc.angle : 45
            borderWidth: root.ready ? Math.max(1.5, Math.min(root.svc.borderSize, 3)) : 2
            active: root.ready && root.svc.enabled
            inactiveColor: Util.alpha(root.fg, 0.25)
            glow: root.ready && root.svc.glow > 0 ? 1 : 0
            spinMs: root.ready ? E.spins[root.svc.spin].speed * 100 : 0
            breatheMs: root.ready ? E.breaths[root.svc.breathe].ms : 0
            fill: Qt.darker(root.bg, 1.25)
            animate: root.opened

            readonly property var effects: !root.ready ? [] : [
              { on: root.svc.spin > 0 && root.svc.gradient, t: root.svc.spin === 3 ? "Spin" : E.spins[root.svc.spin].name + " spin" },
              { on: root.svc.glow > 0, t: E.glows[root.svc.glow].name + " glow" },
              { on: root.svc.breathe > 0, t: E.breaths[root.svc.breathe].name + " breath" },
              { on: root.svc.dim > 0 || root.svc.inactiveOpacity < 100, t: "Focus dim" },
              { on: root.svc.cycleSeconds > 0, t: "Cycle" }
            ].filter(function(b) { return b.on }).map(function(b) { return b.t })

            Rectangle {
              id: liveDot
              x: root.sp(12)
              anchors.verticalCenter: parent.verticalCenter
              width: root.sp(7); height: width; radius: width / 2
              color: strip.active ? root.stops[1] : root.muted
              SequentialAnimation on opacity {
                running: root.opened && strip.active
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                onRunningChanged: if (!running) liveDot.opacity = 1
              }
            }

            Text {
              anchors.left: liveDot.right
              anchors.leftMargin: root.sp(9)
              anchors.right: stripAction.left
              anchors.rightMargin: root.sp(8)
              anchors.verticalCenter: parent.verticalCenter
              elide: Text.ElideRight
              textFormat: Text.PlainText
              font.family: root.ff
              font.pixelSize: Style.font.caption
              color: strip.active ? root.fg : root.muted
              text: !root.ready ? "Starting…"
                  : !root.svc.enabled ? "Paused · your theme's borders are showing"
                  : strip.effects.length ? strip.effects.join("  ·  ")
                  : "Static border · add motion in Effects"
            }

            Text {
              id: stripAction
              anchors.right: parent.right
              anchors.rightMargin: root.sp(14)
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              font.family: root.ff
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1
              color: root.ready && !root.svc.enabled ? root.stops[1]
                   : stripMouse.containsMouse ? root.fg : root.muted
              text: root.ready && !root.svc.enabled ? "RESUME" : "EFFECTS →"
              visible: root.ready && (!root.svc.enabled || root.activeTab !== 2)
            }

            MouseArea {
              id: stripMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (!root.ready) return
                if (!root.svc.enabled) root.svc.setEnabled(true)
                else root.activeTab = 2
              }
            }
          }

          // ═══ tabs ═════════════════════════════════════════════════════════
          Item {
            width: parent.width
            height: root.sp(30)
            readonly property real cell: width / root.tabs.length

            Rectangle {
              anchors.bottom: parent.bottom
              width: parent.width; height: 1
              color: root.faint
            }

            Rectangle {
              id: tabGlow
              anchors.bottom: parent.bottom
              height: root.sp(2)
              radius: 1
              width: parent.cell * 0.56
              x: parent.cell * root.activeTab + (parent.cell - width) / 2
              Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
              gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.stops[0] }
                GradientStop { position: 0.5; color: root.stops[1] }
                GradientStop { position: 1; color: root.stops[2] }
              }
            }
            Rectangle {
              anchors.bottom: tabGlow.top
              x: tabGlow.x; width: tabGlow.width; height: root.sp(10)
              gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Util.alpha(root.stops[1], 0.16) }
              }
            }

            Row {
              anchors.fill: parent
              Repeater {
                model: root.tabs
                Item {
                  required property var modelData
                  required property int index
                  width: parent.width / root.tabs.length
                  height: parent.height
                  Text {
                    anchors.centerIn: parent
                    text: modelData
                    color: root.activeTab === index ? root.fg : tabMouse.containsMouse ? Util.alpha(root.fg, 0.85) : root.muted
                    font.family: root.ff
                    font.pixelSize: Style.font.body
                    font.weight: root.activeTab === index ? Font.DemiBold : Font.Normal
                    Behavior on color { ColorAnimation { duration: 140 } }
                  }
                  MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activeTab = index
                  }
                }
              }
            }
          }

          // ═══ tab pages ════════════════════════════════════════════════════
          Loader {
            width: parent.width
            active: root.ready
            sourceComponent: [paletteTab, shapeTab, effectsTab, looksTab][root.activeTab]
          }

          Text {
            visible: !root.ready
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Waiting for the Prism service… (omarchy plugin enable zakarch.prism)"
            wrapMode: Text.WordWrap
            color: root.muted
            font.family: root.ff
            font.pixelSize: Style.font.caption
          }

          Item { width: 1; height: root.sp(2) }
        }
      }
    }
  }

  // ═══ PALETTE TAB ════════════════════════════════════════════════════════
  Component {
    id: paletteTab
    Column {
      spacing: root.sp(10)

      Item {
        width: parent.width
        height: palCaps.implicitHeight
        Caps { id: palCaps; text: "PALETTE" }
      }

      Grid {
        id: palGrid
        width: parent.width
        columns: 4
        columnSpacing: root.sp(6)
        rowSpacing: root.sp(6)
        readonly property real cellW: (width - columnSpacing * (columns - 1)) / columns

        Repeater {
          model: root.paletteCards()
          delegate: Rectangle {
            id: pc
            required property var modelData
            readonly property bool selected: root.svc.paletteId === modelData.id
            readonly property bool fav: root.svc.isFavorite(modelData.id)
            readonly property bool hot: pcMouse.containsMouse
            width: palGrid.cellW
            height: root.sp(46)
            radius: root.sp(9)
            color: selected ? Util.alpha(modelData.stops[0], 0.13) : hot ? Util.alpha(root.fg, 0.07) : Util.alpha(root.fg, 0.03)
            border.width: selected ? 1.5 : 1
            border.color: selected ? modelData.stops[0] : hot ? Util.alpha(root.fg, 0.2) : Util.alpha(root.fg, 0.06)
            scale: pcMouse.pressed ? 0.96 : 1
            Behavior on scale { NumberAnimation { duration: 90 } }
            Behavior on color { ColorAnimation { duration: 120 } }

            // The "light bar".
            Rectangle {
              id: lightBar
              x: root.sp(6); y: root.sp(6)
              width: parent.width - root.sp(12)
              height: root.sp(14)
              radius: root.sp(5)
              gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: pc.modelData.stops[0] }
                GradientStop { position: 0.5; color: pc.modelData.stops[1] }
                GradientStop { position: 1; color: pc.modelData.stops[2] }
              }
              // Gloss
              Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 1
                height: parent.height / 2 - 1
                radius: parent.radius - 1
                color: Util.alpha("#FFFFFF", 0.18)
              }
              Text {
                visible: pc.modelData.id === "theme" || pc.modelData.id === "custom"
                anchors.centerIn: parent
                text: pc.modelData.id === "theme" ? "LIVE" : "✎ YOURS"
                color: E.contrast(pc.modelData.stops[1])
                font.family: root.ff
                font.pixelSize: Style.font.caption - 3
                font.bold: true
                font.letterSpacing: 1
              }
            }

            Text {
              anchors.left: lightBar.left
              anchors.right: star.left
              anchors.bottom: parent.bottom
              anchors.bottomMargin: root.sp(6)
              text: pc.modelData.name
              elide: Text.ElideRight
              color: pc.selected ? root.fg : root.muted
              font.family: root.ff
              font.pixelSize: Style.font.caption
              font.weight: pc.selected ? Font.DemiBold : Font.Normal
            }

            Text {
              id: star
              anchors.right: lightBar.right
              anchors.bottom: parent.bottom
              anchors.bottomMargin: root.sp(5)
              visible: pc.modelData.id !== "theme" && pc.modelData.id !== "custom" && (pc.fav || pc.hot)
              text: pc.fav ? "★" : "☆"
              color: pc.fav ? pc.modelData.stops[1] : root.muted
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              id: pcMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: function(m) {
                var onStar = m.x > star.x - root.sp(4) && m.y > star.y - root.sp(4)
                if (onStar && star.visible) root.svc.toggleFavorite(pc.modelData.id)
                else root.svc.choosePalette(pc.modelData.id)
              }
            }
          }
        }
      }

      // Gradient direction
      Card {
        width: parent.width
        implicitHeight: gradRow.implicitHeight + root.sp(20)
        Row {
          id: gradRow
          x: root.sp(10); y: root.sp(10)
          width: parent.width - root.sp(20)
          spacing: root.sp(14)
          AngleDial {
            id: dial
            angle: root.svc.angle
            stops: root.stops
            foreground: root.fg
            enabledLook: root.svc.gradient
            onMoved: function(a) { root.svc.set("angle", a) }
          }
          Column {
            width: parent.width - dial.width - parent.spacing
            spacing: root.sp(8)
            SwitchLine {
              title: "Gradient"
              hint: root.svc.gradient ? "Drag the dial or tap a preset" : "Solid " + root.svc.paletteName.toLowerCase() + " border"
              checked: root.svc.gradient
              onToggled: root.svc.set("gradient", !root.svc.gradient)
            }
            Row {
              spacing: root.sp(4)
              Repeater {
                model: [0, 45, 90, 135, 180, 270]
                Chip {
                  required property var modelData
                  width: root.sp(38)
                  label: modelData + "°"
                  on: root.svc.gradient && root.svc.angle === modelData
                  onClicked: { if (!root.svc.gradient) root.svc.set("gradient", true); root.svc.set("angle", modelData) }
                }
              }
            }
          }
        }
      }

      // Custom palette editor
      Card {
        id: editor
        width: parent.width
        implicitHeight: edCol.implicitHeight + root.sp(20)
        readonly property bool editing: root.svc.paletteId === "custom"
        property int stop: 0
        property real h: 0
        property real s: 0.8
        property real l: 0.6
        function pull() {
          var c = E.hsl(root.svc.customStops[stop])
          if (c.s > 0.02) h = c.h
          s = c.s
          l = c.l
        }
        function push() { root.svc.setCustomStop(stop, E.fromHsl(h, s, l)) }
        onStopChanged: pull()
        onEditingChanged: if (editing) pull()
        Component.onCompleted: pull()

        Column {
          id: edCol
          x: root.sp(10); y: root.sp(10)
          width: parent.width - root.sp(20)
          spacing: root.sp(8)

          Item {
            width: parent.width
            height: root.sp(24)
            Body { anchors.verticalCenter: parent.verticalCenter; text: "Mix your own"; font.bold: true }
            Chip {
              visible: !editor.editing
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: root.sp(150)
              label: "Start from " + root.svc.paletteName + " →"
              onClicked: { root.svc.forkToCustom(); editor.pull() }
            }
          }

          Row {
            visible: editor.editing
            width: parent.width
            spacing: root.sp(6)
            Repeater {
              model: 3
              Rectangle {
                id: stopSw
                required property int index
                readonly property bool on: editor.stop === index
                width: (edCol.width - root.sp(12)) / 3
                height: root.sp(30)
                radius: root.sp(8)
                color: root.svc.customStops[index]
                border.width: on ? 2 : 1
                border.color: on ? root.fg : Util.alpha(root.fg, 0.15)
                Text {
                  anchors.centerIn: parent
                  text: root.svc.customStops[stopSw.index]
                  color: E.contrast(root.svc.customStops[stopSw.index])
                  font.family: root.ff
                  font.pixelSize: Style.font.caption
                  font.bold: stopSw.on
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: editor.stop = stopSw.index
                }
              }
            }
          }

          Repeater {
            // Static model: rebuilding it mid-drag would kill the slider.
            model: editor.editing ? ["Hue", "Saturation", "Light"] : []
            Row {
              required property var modelData
              required property int index
              width: edCol.width
              spacing: root.sp(8)
              Text {
                width: root.sp(62)
                anchors.verticalCenter: parent.verticalCenter
                text: modelData
                color: root.muted
                font.family: root.ff
                font.pixelSize: Style.font.caption
              }
              GradientSlider {
                width: parent.width - root.sp(70)
                trackColors: index === 0 ? ["#FF0000", "#FFFF00", "#00FF00", "#00FFFF", "#0000FF", "#FF00FF", "#FF0000"]
                           : index === 1 ? [E.fromHsl(editor.h, 0, editor.l), E.fromHsl(editor.h, 1, editor.l)]
                           : ["#000000", E.fromHsl(editor.h, editor.s, 0.5), "#FFFFFF"]
                foreground: root.fg
                knobColor: root.svc.customStops[editor.stop]
                value: index === 0 ? editor.h / 360 : index === 1 ? editor.s : editor.l
                onMoved: function(v) {
                  if (index === 0) editor.h = v * 359.9
                  else if (index === 1) editor.s = v
                  else editor.l = v
                  editor.push()
                }
              }
            }
          }
        }
      }

      // Inactive border tone
      Card {
        width: parent.width
        implicitHeight: inCol.implicitHeight + root.sp(20)
        Column {
          id: inCol
          x: root.sp(10); y: root.sp(10)
          width: parent.width - root.sp(20)
          spacing: root.sp(4)
          Item {
            width: parent.width
            height: root.sp(20)
            Body { anchors.verticalCenter: parent.verticalCenter; text: "Unfocused border"; font.bold: true }
            Rectangle {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: root.sp(44); height: root.sp(14); radius: root.sp(4)
              color: root.svc.inactiveBorder
              border.width: 1
              border.color: Util.alpha(root.fg, 0.2)
            }
          }
          PrismSlider {
            width: parent.width
            minimum: 0; maximum: 100; step: 5
            value: root.svc.inactiveTone
            fillColor: root.svc.inactiveBorder
            knobColor: root.stops[1]
            onMoved: function(v) { root.svc.set("inactiveTone", Math.round(v)) }
            onReleased: function(v) { root.svc.set("inactiveTone", Math.round(v)) }
          }
          Item {
            width: parent.width
            height: root.sp(12)
            Text { text: "Charcoal"; color: root.muted; font.family: root.ff; font.pixelSize: Style.font.caption - 1 }
            Text { anchors.right: parent.right; text: "Tinted"; color: root.muted; font.family: root.ff; font.pixelSize: Style.font.caption - 1 }
          }
        }
      }
    }
  }

  // ═══ SHAPE TAB ══════════════════════════════════════════════════════════
  Component {
    id: shapeTab
    Column {
      spacing: root.sp(8)

      ValueRow {
        title: "Border width"
        value: root.svc.borderSize
        minimum: 0; maximum: 10
        picks: [0, 1, 2, 3, 4, 6]
        onValuePicked: function(v) { root.svc.set("borderSize", v) }
        glyph: Component {
          Rectangle {
            color: "transparent"
            radius: 3
            border.width: Math.max(1, Math.min(5, root.svc.borderSize))
            border.color: root.stops[0]
          }
        }
      }

      Card {
        width: parent.width
        implicitHeight: cornerCol.implicitHeight + root.sp(20)
        Column {
          id: cornerCol
          x: root.sp(10); y: root.sp(10)
          width: parent.width - root.sp(20)
          spacing: root.sp(8)
          Item {
            width: parent.width
            height: root.sp(18)
            Body { anchors.verticalCenter: parent.verticalCenter; text: "Corner shape"; font.bold: true }
            Text {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: root.svc.rounding === 0 ? "Needs a corner radius above 0" : "Hyprland rounding_power " + E.corners[root.svc.corner].power.toFixed(1)
              color: root.svc.rounding === 0 ? Util.alpha(Color.urgent, 0.9) : root.muted
              font.family: root.ff
              font.pixelSize: Style.font.caption
            }
          }
          Row {
            width: parent.width
            spacing: root.sp(6)
            Repeater {
              model: E.corners
              Rectangle {
                id: cs
                required property var modelData
                required property int index
                readonly property bool on: root.svc.corner === index
                width: (cornerCol.width - root.sp(6) * (E.corners.length - 1)) / E.corners.length
                height: root.sp(70)
                radius: root.sp(9)
                color: on ? Util.alpha(root.lead, 0.14) : csMouse.containsMouse ? Util.alpha(root.fg, 0.07) : Util.alpha(root.fg, 0.03)
                border.width: on ? 1.5 : 1
                border.color: on ? root.lead : Util.alpha(root.fg, 0.08)
                scale: csMouse.pressed ? 0.96 : 1
                Behavior on scale { NumberAnimation { duration: 90 } }
                PrismFrame {
                  x: root.sp(14); y: root.sp(9)
                  width: parent.width - root.sp(28)
                  height: root.sp(34)
                  stops: root.stops
                  gradient: root.svc.gradient
                  angle: root.svc.angle
                  borderWidth: root.sp(3)
                  radius: root.sp(16)
                  cornerPower: cs.modelData.power
                  active: cs.on || csMouse.containsMouse
                  inactiveColor: Util.alpha(root.fg, 0.3)
                  fill: Qt.darker(root.bg, 1.2)
                  glow: cs.on ? 1 : 0
                  animate: false
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.bottom: parent.bottom
                  anchors.bottomMargin: root.sp(7)
                  text: cs.modelData.name
                  color: cs.on ? root.fg : root.muted
                  font.family: root.ff
                  font.pixelSize: Style.font.caption
                  font.weight: cs.on ? Font.DemiBold : Font.Normal
                }
                MouseArea {
                  id: csMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.svc.set("corner", cs.index)
                    if (root.svc.rounding === 0) root.svc.set("rounding", 12)
                  }
                }
              }
            }
          }
        }
      }

      ValueRow {
        title: "Corner radius"
        value: root.svc.rounding
        minimum: 0; maximum: 32
        picks: [0, 4, 8, 12, 16, 24]
        onValuePicked: function(v) { root.svc.set("rounding", v) }
        glyph: Component {
          Item {
            clip: true
            PrismFrame {
              width: parent.width * 2; height: parent.height * 2
              stops: [root.stops[0], root.stops[0], root.stops[0]]
              gradient: false
              borderWidth: 2
              radius: root.svc.rounding * 0.5
              cornerPower: E.corners[root.svc.corner].power
              fill: "transparent"
              animate: false
            }
          }
        }
      }

      ValueRow {
        title: "Gaps between windows"
        value: root.svc.gapsIn
        minimum: 0; maximum: 40
        picks: [0, 2, 4, 8, 12, 20]
        onValuePicked: function(v) { root.svc.set("gapsIn", v) }
        glyph: Component {
          Row {
            spacing: Math.min(6, root.svc.gapsIn * 0.4)
            Rectangle { width: (parent.width - parent.spacing) / 2; height: parent.height; radius: 2; color: root.stops[0] }
            Rectangle { width: (parent.width - parent.spacing) / 2; height: parent.height; radius: 2; color: root.stops[1] }
          }
        }
      }

      ValueRow {
        title: "Gaps to screen edge"
        value: root.svc.gapsOut
        minimum: 0; maximum: 60
        picks: [0, 4, 8, 16, 24, 40]
        onValuePicked: function(v) { root.svc.set("gapsOut", v) }
        glyph: Component {
          Rectangle {
            color: "transparent"
            border.width: 1
            border.color: Util.alpha(root.fg, 0.4)
            radius: 2
            Rectangle {
              anchors.fill: parent
              anchors.margins: 1 + Math.min(5, root.svc.gapsOut * 0.2)
              radius: 2
              color: root.stops[0]
            }
          }
        }
      }
    }
  }

  // ═══ EFFECTS TAB ════════════════════════════════════════════════════════
  Component {
    id: effectsTab
    Column {
      spacing: root.sp(10)

      Card {
        width: parent.width
        implicitHeight: motionCol.implicitHeight + root.sp(22)
        Column {
          id: motionCol
          x: root.sp(11); y: root.sp(11)
          width: parent.width - root.sp(22)
          spacing: root.sp(12)
          Caps { text: "LIGHT & MOTION" }
          EffectRow {
            title: "Spin"
            hint: root.svc.gradient ? "Gradient orbits the focused window" : "Turn on Gradient to spin"
            usable: root.svc.gradient
            options: E.spins.map(function(s) { return s.name })
            current: root.svc.spin
            onPicked: function(i) { root.svc.set("spin", i) }
          }
          EffectRow {
            title: "Glow"
            hint: "Palette-tinted halo"
            options: E.glows.map(function(g) { return g.name })
            current: root.svc.glow
            onPicked: function(i) { root.svc.set("glow", i) }
          }
          EffectRow {
            title: "Breathe"
            hint: "Border slowly pulses"
            options: E.breaths.map(function(b) { return b.name })
            current: root.svc.breathe
            onPicked: function(i) { root.svc.set("breathe", i) }
          }
          EffectRow {
            title: "Color morph"
            hint: "Blend time for color changes"
            options: E.morphs.map(function(m) { return m.name })
            current: root.svc.morph
            onPicked: function(i) { root.svc.set("morph", i) }
          }
        }
      }

      Card {
        width: parent.width
        implicitHeight: focusCol.implicitHeight + root.sp(22)
        Column {
          id: focusCol
          x: root.sp(11); y: root.sp(11)
          width: parent.width - root.sp(22)
          spacing: root.sp(6)
          Caps { text: "FOCUS" }
          Repeater {
            model: [
              { k: "dim", t: "Dim unfocused", min: 0, max: 80, unit: "%" },
              { k: "inactiveOpacity", t: "Unfocused opacity", min: 50, max: 100, unit: "%" }
            ]
            Column {
              required property var modelData
              width: focusCol.width
              spacing: 0
              Item {
                width: parent.width
                height: root.sp(18)
                Body { anchors.verticalCenter: parent.verticalCenter; text: modelData.t; font.bold: true }
                Text {
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.svc[modelData.k] + modelData.unit
                  color: root.fg
                  font.family: root.ff
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                }
              }
              PrismSlider {
                width: parent.width
                minimum: modelData.min; maximum: modelData.max; step: 5
                value: root.svc[modelData.k]
                fillColor: root.lead
                knobColor: root.stops[1]
                onMoved: function(v) { root.svc.set(modelData.k, Math.round(v)) }
                onReleased: function(v) { root.svc.set(modelData.k, Math.round(v)) }
              }
            }
          }
        }
      }

      Card {
        width: parent.width
        implicitHeight: cycleCol.implicitHeight + root.sp(22)
        Column {
          id: cycleCol
          x: root.sp(11); y: root.sp(11)
          width: parent.width - root.sp(22)
          spacing: root.sp(10)
          Caps { text: "AUTO-CYCLE" }
          EffectRow {
            title: "Change palette every"
            hint: root.svc.cycleSeconds > 0 ? "Morphs to the next palette" : "Off"
            options: E.cycles.map(function(c) { return c.name })
            current: {
              for (var i = 0; i < E.cycles.length; i++) if (E.cycles[i].seconds === root.svc.cycleSeconds) return i
              return -1
            }
            onPicked: function(i) { root.svc.set("cycleSeconds", E.cycles[i].seconds) }
          }
          Row {
            width: parent.width
            spacing: root.sp(6)
            Chip {
              width: (parent.width - root.sp(6)) / 2
              label: root.svc.cycleShuffle ? "⇄  Shuffle order" : "→  In order"
              on: root.svc.cycleShuffle
              onClicked: root.svc.set("cycleShuffle", !root.svc.cycleShuffle)
            }
            Chip {
              width: (parent.width - root.sp(6)) / 2
              label: "★  Favorites only (" + root.svc.favorites.length + ")"
              on: root.svc.cycleFavorites
              onClicked: root.svc.set("cycleFavorites", !root.svc.cycleFavorites)
            }
          }
        }
      }
    }
  }

  // ═══ LOOKS TAB ══════════════════════════════════════════════════════════
  Component {
    id: looksTab
    Column {
      spacing: root.sp(10)

      Caps { text: "CURATED LOOKS" }

      Grid {
        id: lookGrid
        width: parent.width
        columns: 2
        columnSpacing: root.sp(8)
        rowSpacing: root.sp(8)
        Repeater {
          model: E.looks
          delegate: Rectangle {
            id: lk
            required property var modelData
            readonly property bool current: root.svc.lookName === modelData.name
            readonly property var lookStops: root.stopsFor(modelData)
            width: (lookGrid.width - lookGrid.columnSpacing) / 2
            height: root.sp(72)
            radius: root.sp(10)
            readonly property var tags: {
              var t = []
              if (modelData.corner !== 1) t.push(E.corners[modelData.corner].name)
              if (modelData.spin > 0) t.push("Spin")
              if (modelData.glow > 0) t.push(E.glows[modelData.glow].name)
              if (modelData.breathe > 0) t.push("Breathe")
              if (modelData.dim > 0) t.push("Focus")
              return t.slice(0, 3)
            }
            color: current ? Util.alpha(lookStops[0], 0.12) : lkMouse.containsMouse ? Util.alpha(root.fg, 0.07) : Util.alpha(root.fg, 0.03)
            border.width: current ? 1.5 : 1
            border.color: current ? lookStops[0] : lkMouse.containsMouse ? Util.alpha(lookStops[0], 0.5) : Util.alpha(root.fg, 0.06)
            scale: lkMouse.pressed ? 0.97 : 1
            Behavior on scale { NumberAnimation { duration: 90 } }

            Rectangle {
              id: miniStage
              x: root.sp(7); y: root.sp(7)
              width: root.sp(74); height: parent.height - root.sp(14)
              radius: root.sp(7)
              color: Qt.darker(root.bg, 1.5)
              // Palette haze behind the window.
              Rectangle {
                anchors.fill: parent
                radius: parent.radius
                opacity: 0.35
                gradient: Gradient {
                  orientation: Gradient.Horizontal
                  GradientStop { position: 0; color: Util.alpha(lk.lookStops[0], 0.45) }
                  GradientStop { position: 1; color: "transparent" }
                }
              }
              PrismFrame {
                anchors.fill: parent
                anchors.margins: root.sp(8) + Math.min(3, lk.modelData.gapsOut * 0.2)
                cornerPower: E.corners[lk.modelData.corner].power
                stops: lk.lookStops
                gradient: lk.modelData.gradient
                angle: lk.modelData.angle
                borderWidth: Math.max(1, lk.modelData.borderSize * 0.8)
                radius: lk.modelData.rounding * 0.6
                glow: lk.modelData.glow
                spinMs: E.spins[lk.modelData.spin].speed * 100
                breatheMs: E.breaths[lk.modelData.breathe].ms
                animate: root.opened && lkMouse.containsMouse
                fill: Qt.darker(root.bg, 1.1)
              }
            }

            Column {
              anchors.left: miniStage.right
              anchors.leftMargin: root.sp(9)
              anchors.right: parent.right
              anchors.rightMargin: root.sp(8)
              anchors.verticalCenter: parent.verticalCenter
              spacing: root.sp(2)
              Body { width: parent.width; text: lk.modelData.name; font.bold: true }
              Text {
                width: parent.width
                text: lk.modelData.tagline
                elide: Text.ElideRight
                color: root.muted
                font.family: root.ff
                font.pixelSize: Style.font.caption - 1
              }
              Row {
                spacing: root.sp(3)
                topPadding: root.sp(2)
                Repeater {
                  model: lk.tags
                  Rectangle {
                    required property var modelData
                    height: root.sp(14)
                    width: tagText.implicitWidth + root.sp(8)
                    radius: root.sp(4)
                    color: Util.alpha(lk.lookStops[1], 0.12)
                    border.width: 1
                    border.color: Util.alpha(lk.lookStops[1], 0.35)
                    Text {
                      id: tagText
                      anchors.centerIn: parent
                      text: modelData.toUpperCase()
                      color: lk.lookStops[1]
                      font.family: root.ff
                      font.pixelSize: Style.font.caption - 3
                      font.bold: true
                      font.letterSpacing: 0.6
                    }
                  }
                }
              }
            }

            MouseArea {
              id: lkMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.svc.applyLook(lk.modelData, lk.modelData.name)
            }
          }
        }
      }

      Item { width: 1; height: root.sp(2) }
      Caps { text: "YOUR LOOKS" }

      // Save row
      Row {
        width: parent.width
        spacing: root.sp(6)
        Rectangle {
          width: parent.width - saveBtn.width - parent.spacing
          height: root.sp(30)
          radius: root.sp(8)
          color: Util.alpha(root.fg, 0.05)
          border.width: 1
          border.color: lookName.activeFocus ? root.lead : Util.alpha(root.fg, 0.12)
          TextInput {
            id: lookName
            anchors.fill: parent
            anchors.leftMargin: root.sp(10)
            anchors.rightMargin: root.sp(10)
            verticalAlignment: TextInput.AlignVCenter
            color: root.fg
            selectionColor: Util.alpha(root.lead, 0.5)
            font.family: root.ff
            font.pixelSize: Style.font.bodySmall
            maximumLength: 28
            clip: true
            onActiveFocusChanged: root.typing = activeFocus
            Keys.onReturnPressed: { root.svc.saveLook(text); text = ""; catcher.forceActiveFocus() }
            Keys.onEscapePressed: { text = ""; catcher.forceActiveFocus() }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              visible: !parent.text && !parent.activeFocus
              text: "Name this look…"
              color: Util.alpha(root.fg, 0.35)
              font: parent.font
            }
          }
        }
        Chip {
          id: saveBtn
          width: root.sp(96)
          height: root.sp(30)
          label: "Save current"
          on: true
          onClicked: { root.svc.saveLook(lookName.text); lookName.text = ""; catcher.forceActiveFocus() }
        }
      }

      Text {
        visible: root.svc.savedLooks.length === 0
        width: parent.width
        wrapMode: Text.WordWrap
        text: "Tune a look you love, name it, and it lands here — one click to bring it back."
        color: root.muted
        font.family: root.ff
        font.pixelSize: Style.font.caption
      }

      Repeater {
        model: root.svc.savedLooks
        delegate: Rectangle {
          id: saved
          required property var modelData
          required property int index
          readonly property var lookStops: root.stopsFor(modelData.look)
          width: parent ? parent.width : 0
          height: root.sp(34)
          radius: root.sp(8)
          color: svMouse.containsMouse ? Util.alpha(root.fg, 0.07) : Util.alpha(root.fg, 0.03)
          border.width: 1
          border.color: root.svc.lookName === modelData.name ? lookStops[0] : Util.alpha(root.fg, 0.06)

          MouseArea {
            id: svMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.svc.applyLook(saved.modelData.look, saved.modelData.name)
          }

          Rectangle {
            id: svBar
            x: root.sp(9)
            anchors.verticalCenter: parent.verticalCenter
            width: root.sp(40); height: root.sp(10); radius: height / 2
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop { position: 0; color: saved.lookStops[0] }
              GradientStop { position: 0.5; color: saved.lookStops[1] }
              GradientStop { position: 1; color: saved.lookStops[2] }
            }
          }
          Body {
            anchors.left: svBar.right
            anchors.leftMargin: root.sp(10)
            anchors.right: svMeta.left
            anchors.rightMargin: root.sp(8)
            anchors.verticalCenter: parent.verticalCenter
            text: saved.modelData.name
            font.bold: root.svc.lookName === saved.modelData.name
          }
          Text {
            id: svMeta
            anchors.right: svDel.left
            anchors.rightMargin: root.sp(8)
            anchors.verticalCenter: parent.verticalCenter
            text: (saved.modelData.look.borderSize || 0) + "px · r" + (saved.modelData.look.rounding || 0)
            color: root.muted
            font.family: root.ff
            font.pixelSize: Style.font.caption - 1
          }
          Rectangle {
            id: svDel
            anchors.right: parent.right
            anchors.rightMargin: root.sp(5)
            anchors.verticalCenter: parent.verticalCenter
            width: root.sp(24); height: width; radius: root.sp(6)
            color: delMouse.containsMouse ? Util.alpha(Color.urgent, 0.25) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "✕"
              color: delMouse.containsMouse ? Color.urgent : root.muted
              font.pixelSize: Style.font.caption
            }
            MouseArea {
              id: delMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.svc.deleteLook(saved.index)
            }
          }
        }
      }

      Item { width: 1; height: root.sp(2) }
      Chip {
        width: parent.width
        label: "Reset everything to Prism defaults"
        onClicked: root.svc.resetAll()
      }
    }
  }
}
