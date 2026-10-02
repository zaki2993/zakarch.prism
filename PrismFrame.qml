import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import "Engine.js" as E

// A mock window drawn the way Hyprland will draw it: gradient border at an
// angle, corner shape from rounding_power (facet / round), optional
// rotation, real blurred glow, breathing dip and the inactive dim.
// Children are placed inside the border.
Item {
  id: root

  property var    stops: ["#8B5CF6", "#22D3EE", "#34D399"]
  property bool   gradient: true
  property real   angle: 45
  property real   borderWidth: 2
  property real   radius: 10
  property real   cornerPower: 2           // Hyprland rounding_power
  property bool   active: true
  property color  inactiveColor: "#2A2A38"
  property int    glow: 0                  // 0..3
  property real   dim: 0                   // 0..1, inactive only
  property int    spinMs: 0                // full revolution, 0 = still
  property int    breatheMs: 0             // half-cycle, 0 = steady
  property color  fill: "#12121A"
  property bool   animate: true            // off while hidden to save frames
  default property alias content: body.data

  readonly property real r: Math.max(0, Math.min(radius, Math.min(width, height) / 2))
  readonly property real bw: Math.max(0, Math.min(borderWidth, Math.min(width, height) / 2))

  // ── outlines ──────────────────────────────────────────────────────────────
  function toPoints(list) {
    var out = []
    for (var i = 0; i < list.length; i++) out.push(Qt.point(list[i].x, list[i].y))
    return out
  }
  readonly property var outerPts: toPoints(E.framePoints(0, 0, width, height, r, cornerPower))
  // Inset radius that keeps the border equally thick along a facet's diagonal.
  readonly property real innerR: Math.max(0, cornerPower <= 1 ? r - bw * (2 - Math.SQRT2) : r - bw)
  readonly property var innerPts: toPoints(E.framePoints(bw, bw, width - bw * 2, height - bw * 2,
                                                         innerR, cornerPower))

  // ── spin ──────────────────────────────────────────────────────────────────
  property real spinOffset: 0
  readonly property real liveAngle: angle + spinOffset
  NumberAnimation on spinOffset {
    running: root.animate && root.active && root.gradient && root.spinMs > 0
    from: 0; to: 360
    duration: Math.max(500, root.spinMs)
    loops: Animation.Infinite
    onRunningChanged: if (!running) root.spinOffset = 0
  }

  // Gradient axis through the center, long enough to span the rect.
  readonly property real _rad: liveAngle * Math.PI / 180
  readonly property real _dx: Math.cos(_rad)
  readonly property real _dy: -Math.sin(_rad)
  readonly property real _half: (Math.abs(width * _dx) + Math.abs(height * _dy)) / 2

  // ── breathe ───────────────────────────────────────────────────────────────
  property real breath: 0
  SequentialAnimation on breath {
    running: root.animate && root.active && root.breatheMs > 0
    loops: Animation.Infinite
    NumberAnimation { from: 0; to: 0.45; duration: root.breatheMs; easing.type: Easing.InOutSine }
    NumberAnimation { from: 0.45; to: 0; duration: root.breatheMs; easing.type: Easing.InOutSine }
    onRunningChanged: if (!running) root.breath = 0
  }

  // ── window body ───────────────────────────────────────────────────────────
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: -1
      strokeColor: "transparent"
      fillColor: root.fill
      PathPolyline { path: root.innerPts }
    }
  }

  // ── glow + border ─────────────────────────────────────────────────────────
  Item {
    anchors.fill: parent
    visible: root.bw > 0

    layer.enabled: root.active && root.glow > 0
    layer.effect: MultiEffect {
      shadowEnabled: true
      shadowColor: root.stops[0]
      shadowBlur: [0, 0.45, 0.75, 1.0][Math.max(0, Math.min(3, root.glow))]
      shadowOpacity: [0, 0.55, 0.8, 1.0][Math.max(0, Math.min(3, root.glow))] * (1 - root.breath)
      shadowScale: 1 + root.glow * 0.012
      blurMax: 12 + root.glow * 10
      shadowHorizontalOffset: 0
      shadowVerticalOffset: 0
    }

    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeWidth: -1
        strokeColor: "transparent"
        fillRule: ShapePath.OddEvenFill
        fillColor: root.active ? (root.gradient ? "transparent" : root.stops[0]) : root.inactiveColor
        fillGradient: root.active && root.gradient ? grad : null
        PathMultiline { paths: [root.outerPts, root.innerPts] }
      }
    }

    LinearGradient {
      id: grad
      x1: root.width / 2 - root._dx * root._half
      y1: root.height / 2 - root._dy * root._half
      x2: root.width / 2 + root._dx * root._half
      y2: root.height / 2 + root._dy * root._half
      GradientStop { position: 0.0; color: root.stops[0] }
      GradientStop { position: 0.5; color: root.stops[1] }
      GradientStop { position: 1.0; color: root.stops[2] }
    }
  }

  // Breathing dims the border toward black, like the real one.
  Shape {
    anchors.fill: parent
    visible: root.breath > 0.001 && root.bw > 0
    opacity: root.breath
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: -1
      strokeColor: "transparent"
      fillRule: ShapePath.OddEvenFill
      fillColor: "#000000"
      PathMultiline { paths: [root.outerPts, root.innerPts] }
    }
  }

  // Unfocused dim over the body.
  Shape {
    anchors.fill: parent
    opacity: root.active ? 0 : root.dim
    visible: opacity > 0.001
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    ShapePath {
      strokeWidth: -1
      strokeColor: "transparent"
      fillColor: "#000000"
      PathPolyline { path: root.innerPts }
    }
  }

  Item {
    id: body
    anchors.fill: parent
    anchors.margins: root.bw
  }
}
