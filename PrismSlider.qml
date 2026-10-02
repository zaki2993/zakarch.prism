import QtQuick
import qs.Commons

// Slider that only changes on a deliberate click or drag. Unlike the shell's
// PanelSlider it ignores the scroll wheel, so scrolling the panel past it
// never edits a setting.
Item {
  id: root

  property real  value: 0
  property real  minimum: 0
  property real  maximum: 1
  property real  step: 1
  property color fillColor: Color.accent
  property color knobColor: Color.foreground
  property color trackColor: Util.alpha(Color.popups.text, 0.12)
  property color tickColor: Color.popups.background
  property int   tickCount: 0
  property bool  dragging: false
  property real  liveValue: value
  signal moved(real value)
  signal released(real value)

  onValueChanged: if (!dragging) liveValue = value
  implicitWidth: Style.space(200)
  implicitHeight: Style.space(22)

  readonly property real range: Math.max(0.0001, maximum - minimum)
  readonly property real progress: Math.max(0, Math.min(1, (liveValue - minimum) / range))

  Rectangle {
    id: track
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: Style.space(5)
    radius: height / 2
    color: root.trackColor
  }

  Rectangle {
    anchors.verticalCenter: track.verticalCenter
    height: track.height
    radius: track.radius
    width: track.width * root.progress
    color: root.fillColor
    Behavior on width { enabled: !root.dragging; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
  }

  Repeater {
    model: root.tickCount > 1 ? root.tickCount : 0
    Rectangle {
      required property int index
      width: Math.max(1, Style.space(2))
      height: track.height + Style.space(4)
      color: root.tickColor
      anchors.verticalCenter: track.verticalCenter
      x: Math.max(0, Math.min(track.width - width, track.width * index / (root.tickCount - 1) - width / 2))
    }
  }

  Rectangle {
    width: Style.space(15); height: width; radius: width / 2
    anchors.verticalCenter: track.verticalCenter
    x: Math.max(0, Math.min(track.width - width, track.width * root.progress - width / 2))
    color: root.knobColor
    border.width: Style.space(2)
    border.color: root.tickColor
    scale: mouse.containsMouse || root.dragging ? 1.15 : 1
    Behavior on scale { NumberAnimation { duration: 110 } }
    Behavior on x { enabled: !root.dragging; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    preventStealing: true
    // No onWheel: the wheel passes through to the panel's scroll view.
    function at(x) {
      var raw = root.minimum + Math.max(0, Math.min(1, x / track.width)) * root.range
      raw = Math.round(raw / root.step) * root.step
      return Math.max(root.minimum, Math.min(root.maximum, raw))
    }
    onPressed: function(m) {
      root.dragging = true
      root.liveValue = at(m.x)
      root.moved(root.liveValue)
    }
    onPositionChanged: function(m) {
      if (!root.dragging) return
      var v = at(m.x)
      if (v !== root.liveValue) { root.liveValue = v; root.moved(v) }
    }
    onReleased: {
      root.dragging = false
      root.released(root.liveValue)
      root.liveValue = root.value
    }
    onCanceled: { root.dragging = false; root.liveValue = root.value }
  }
}
