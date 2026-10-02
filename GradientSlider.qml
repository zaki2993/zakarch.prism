import QtQuick
import qs.Commons

// Slider whose track *is* the value space (hue wheel, lightness ramp).
// Click or drag only; the scroll wheel passes through to the panel.
Item {
  id: root

  property var   trackColors: ["#000000", "#FFFFFF"]
  property real  value: 0            // 0..1
  property color knobColor: "#FFFFFF"
  property color foreground: Color.popups.text
  property bool  dragging: false
  property real  liveValue: value
  signal moved(real value)

  onValueChanged: if (!dragging) liveValue = value
  implicitHeight: Style.space(22)

  Rectangle {
    id: track
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: Style.space(10)
    radius: height / 2
    border.width: 1
    border.color: Util.alpha(root.foreground, 0.12)
    gradient: Gradient {
      id: g
      orientation: Gradient.Horizontal
    }
    Component.onCompleted: root.rebuild()
  }

  Component { id: stopComp; GradientStop {} }
  onTrackColorsChanged: rebuild()
  function rebuild() {
    var old = []
    for (var j = 0; j < g.stops.length; j++) old.push(g.stops[j])
    var out = []
    var n = trackColors.length
    for (var i = 0; i < n; i++)
      out.push(stopComp.createObject(root, { position: n > 1 ? i / (n - 1) : 0, color: trackColors[i] }))
    g.stops = out
    for (var k = 0; k < old.length; k++) old[k].destroy()
  }

  Rectangle {
    width: Style.space(16)
    height: width
    radius: width / 2
    anchors.verticalCenter: track.verticalCenter
    x: Math.max(0, Math.min(root.width - width, root.width * root.liveValue - width / 2))
    color: root.knobColor
    border.width: Style.space(2)
    border.color: "#FFFFFF"
    scale: mouse.containsMouse || root.dragging ? 1.15 : 1
    Behavior on scale { NumberAnimation { duration: 110 } }
    Rectangle {
      anchors.fill: parent
      anchors.margins: -1
      radius: width / 2
      color: "transparent"
      border.width: 1
      border.color: "#66000000"
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    preventStealing: true
    function at(x) { return Math.max(0, Math.min(1, x / root.width)) }
    onPressed: function(m) { root.dragging = true; root.liveValue = at(m.x); root.moved(root.liveValue) }
    onPositionChanged: function(m) { if (root.dragging) { root.liveValue = at(m.x); root.moved(root.liveValue) } }
    onReleased: { root.dragging = false; root.liveValue = root.value }
    onCanceled: { root.dragging = false; root.liveValue = root.value }
  }
}
