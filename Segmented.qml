import QtQuick
import qs.Commons

// Pill row of mutually exclusive options with a sliding, palette-lit thumb.
Item {
  id: root

  property var    options: []          // strings
  property int    current: 0
  property var    stops: ["#8B5CF6", "#22D3EE", "#34D399"]
  property color  foreground: Color.popups.text
  property bool   active: true         // false → dimmed, still clickable
  signal picked(int index)

  implicitHeight: Style.space(28)
  readonly property real cell: options.length > 0 ? width / options.length : width

  Rectangle {
    anchors.fill: parent
    radius: Math.min(height / 2, Style.space(9))
    color: Util.alpha(root.foreground, 0.05)
    border.width: 1
    border.color: Util.alpha(root.foreground, 0.08)
  }

  Rectangle {
    id: thumb
    visible: root.current >= 0 && root.current < root.options.length
    x: root.cell * Math.max(0, root.current) + Style.space(2)
    y: Style.space(2)
    width: root.cell - Style.space(4)
    height: root.height - Style.space(4)
    radius: Math.min(height / 2, Style.space(7))
    opacity: root.active ? 1 : 0.45
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: Util.alpha(root.stops[0], 0.30) }
      GradientStop { position: 1; color: Util.alpha(root.stops[2], 0.22) }
    }
    border.width: 1
    border.color: Util.alpha(root.stops[0], 0.75)
    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
  }

  Row {
    anchors.fill: parent
    Repeater {
      model: root.options
      delegate: Item {
        required property var modelData
        required property int index
        width: root.cell
        height: root.height
        readonly property bool on: index === root.current
        Text {
          anchors.centerIn: parent
          width: parent.width - Style.space(4)
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
          text: modelData
          textFormat: Text.PlainText
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.weight: parent.on ? Font.DemiBold : Font.Normal
          color: parent.on ? root.foreground : Util.alpha(root.foreground, segMouse.containsMouse ? 0.9 : 0.6)
          Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
          id: segMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.picked(index)
        }
      }
    }
  }
}
