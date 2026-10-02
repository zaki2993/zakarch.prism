import QtQuick
import QtQuick.Shapes
import qs.Commons

// Drag-the-ring dial for the gradient angle (0° = left → right,
// counter-clockwise like Hyprland). The ring shows the live gradient.
Item {
  id: root

  property real  angle: 45
  property var   stops: ["#8B5CF6", "#22D3EE", "#34D399"]
  property color foreground: Color.popups.text
  property bool  enabledLook: true
  signal moved(int angle)

  implicitWidth: Style.space(56)
  implicitHeight: implicitWidth
  opacity: enabledLook ? 1 : 0.4

  readonly property real _rad: angle * Math.PI / 180
  readonly property real _c: width / 2

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: -1
      strokeColor: "transparent"
      fillRule: ShapePath.OddEvenFill
      fillGradient: LinearGradient {
        x1: root._c - Math.cos(root._rad) * root._c; y1: root._c + Math.sin(root._rad) * root._c
        x2: root._c + Math.cos(root._rad) * root._c; y2: root._c - Math.sin(root._rad) * root._c
        GradientStop { position: 0.0; color: root.stops[0] }
        GradientStop { position: 0.5; color: root.stops[1] }
        GradientStop { position: 1.0; color: root.stops[2] }
      }
      PathRectangle { x: 0; y: 0; width: root.width; height: root.height; radius: root.width / 2 }
      PathRectangle {
        x: Style.space(4); y: Style.space(4)
        width: root.width - Style.space(8); height: root.height - Style.space(8)
        radius: (root.width - Style.space(8)) / 2
      }
    }
  }

  // Direction needle
  Rectangle {
    width: root._c - Style.space(10)
    height: Style.space(2)
    radius: height / 2
    x: root._c
    y: root._c - height / 2
    color: root.foreground
    transformOrigin: Item.Left
    rotation: -root.angle
    Rectangle {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(6); height: width; radius: width / 2
      color: root.stops[2]
      border.width: 1
      border.color: root.foreground
    }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.verticalCenter
    anchors.topMargin: Style.space(4)
    text: Math.round(root.angle) + "°"
    font.family: Style.font.family
    font.pixelSize: Style.font.caption - 1
    color: Util.alpha(root.foreground, 0.7)
    visible: Math.sin(root._rad) > -0.5   // dodge the needle
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    preventStealing: true
    function pick(m) {
      var a = Math.atan2(root._c - m.y, m.x - root._c) * 180 / Math.PI
      a = (Math.round(a) + 360) % 360
      // Soft snap to 15° steps near them.
      var snap = Math.round(a / 15) * 15
      if (Math.abs(snap - a) <= 3) a = snap % 360
      root.moved(a)
    }
    // Only the ring grabs; a stray click in the middle changes nothing.
    property bool grabbing: false
    onPressed: function(m) {
      grabbing = Math.hypot(m.x - root._c, m.y - root._c) >= root._c * 0.45
      if (grabbing) pick(m)
      else m.accepted = false
    }
    onPositionChanged: function(m) { if (pressed && grabbing) pick(m) }
    onReleased: grabbing = false
  }
}
