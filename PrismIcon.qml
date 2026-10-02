import QtQuick
import QtQuick.Shapes

// Bar glyph: a rounded-square ring painted with a conical sweep of the live
// palette. It turns when the real borders spin and breathes when they do.
Item {
  id: root

  property var   stops: ["#8B5CF6", "#22D3EE", "#34D399"]
  property bool  spinning: false
  property int   breatheMs: 0
  property bool  live: true            // false → greyed (Prism paused)
  property color idleColor: "#888888"
  property real  ring: Math.max(1.5, width * 0.13)

  property real sweep: 0
  NumberAnimation on sweep {
    running: root.live && root.spinning && root.visible
    from: 0; to: 360; duration: 4200
    loops: Animation.Infinite
  }

  property real glowPhase: 1
  SequentialAnimation on glowPhase {
    running: root.live && root.breatheMs > 0 && root.visible
    loops: Animation.Infinite
    NumberAnimation { from: 1; to: 0.45; duration: root.breatheMs; easing.type: Easing.InOutSine }
    NumberAnimation { from: 0.45; to: 1; duration: root.breatheMs; easing.type: Easing.InOutSine }
    onRunningChanged: if (!running) root.glowPhase = 1
  }

  Shape {
    anchors.fill: parent
    opacity: root.live ? root.glowPhase : 0.55
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: -1
      strokeColor: "transparent"
      fillRule: ShapePath.OddEvenFill
      fillColor: root.live ? "transparent" : root.idleColor
      fillGradient: root.live ? cone : null
      PathRectangle { x: 0; y: 0; width: root.width; height: root.height; radius: root.width * 0.3 }
      PathRectangle {
        x: root.ring; y: root.ring
        width: root.width - root.ring * 2; height: root.height - root.ring * 2
        radius: Math.max(0, root.width * 0.3 - root.ring)
      }
    }
    ConicalGradient {
      id: cone
      centerX: root.width / 2
      centerY: root.height / 2
      angle: root.sweep
      GradientStop { position: 0.0;  color: root.stops[0] }
      GradientStop { position: 0.33; color: root.stops[1] }
      GradientStop { position: 0.66; color: root.stops[2] }
      GradientStop { position: 1.0;  color: root.stops[0] }
    }
  }

  // Core spark — the "light" inside the prism.
  Rectangle {
    anchors.centerIn: parent
    width: Math.max(2, root.width * 0.22)
    height: width
    radius: width / 2
    color: root.live ? root.stops[1] : root.idleColor
    opacity: root.live ? 0.55 + 0.45 * root.glowPhase : 0.4
  }
}
