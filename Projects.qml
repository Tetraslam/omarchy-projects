// Project launcher: one key, type a few letters, Enter, and you're in an
// OpenCode session in that project. Projects are ranked by zoxide (every cd
// teaches it) and show their current branch, so worktrees read apart.
//
//   Enter        terminal running opencode in the project
//   Shift+Enter  plain terminal there
//   Ctrl+Enter   terminal with the editor open on the project

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool shown: false
  property var projects: []
  property string query: ""
  property int selected: 0
  readonly property var matches: filter(projects, query)
  readonly property string scriptPath: String(Qt.resolvedUrl("projects.py")).replace("file://", "")
  readonly property int visibleRows: 9

  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

  // Subsequence match, preferring hits in the name, at word starts, and
  // contiguous runs; zoxide's order breaks ties.
  function score(text, q) {
    var t = text.toLowerCase()
    var i = 0
    var s = 0
    var run = 0
    for (var k = 0; k < q.length; k++) {
      var found = t.indexOf(q[k], i)
      if (found < 0) return -1
      run = found === i ? run + 1 : 0
      s += 1 + run * 2 + (found === 0 || "/-_. ".indexOf(t[found - 1]) >= 0 ? 3 : 0)
      i = found + 1
    }
    return s
  }

  function filter(list, q) {
    q = q.trim().toLowerCase()
    if (q === "") return list
    var scored = []
    for (var i = 0; i < list.length; i++) {
      var p = list[i]
      var s = Math.max(score(p.name, q) * 2, score(p.display + " " + p.branch, q))
      if (s >= 0) scored.push({ p: p, s: s, i: i })
    }
    scored.sort(function(a, b) { return b.s - a.s || a.i - b.i })
    return scored.map(function(x) { return x.p })
  }

  function open() {
    if (shown) return
    query = ""
    selected = 0
    shown = true
    lister.running = true
  }

  function close() { shown = false }
  function toggle() { shown ? close() : open() }

  function launch(project, mode) {
    if (!project) return
    close()
    var command = ["uwsm-app", "--", "xdg-terminal-exec", "--dir=" + project.path]
    if (mode === "agent") command = command.concat(["bash", "-c", "opencode; exec bash"])
    else if (mode === "editor") command = command.concat(["bash", "-c", "${EDITOR:-hx} .; exec bash"])
    Quickshell.execDetached(command)
    // Teach zoxide the pick, as a cd would.
    Quickshell.execDetached(["zoxide", "add", project.path])
  }

  Process {
    id: lister
    command: ["python3", "-I", root.scriptPath]
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.projects = JSON.parse(text) } catch (error) {}
      }
    }
  }

  GlobalShortcut {
    appid: "projects"
    name: "toggle"
    description: "Project launcher"
    onPressed: root.toggle()
  }

  IpcHandler {
    target: "projects"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  readonly property color fg: Color.menu.text
  readonly property color dim: Qt.darker(fg, 1.5)

  PanelWindow {
    id: surface
    visible: root.shown
    screen: {
      var name = Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name || "") : ""
      for (var i = 0; i < Quickshell.screens.length; i++) if (Quickshell.screens[i].name === name) return Quickshell.screens[i]
      return Quickshell.screens[0]
    }
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "projects"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: if (visible) input.forceActiveFocus()

    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim
      MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Rectangle {
      id: card
      anchors.horizontalCenter: parent.horizontalCenter
      y: parent.height * 0.18
      width: Math.min(parent.width * 0.6, Style.space(620))
      height: column.implicitHeight + Style.space(16)
      radius: Style.space(12)
      color: Color.menu.background
      border.width: Math.max(1, Style.space(1))
      border.color: root.alpha(Color.menu.border, 0.35)

      MouseArea { anchors.fill: parent }

      Column {
        id: column
        x: Style.space(8)
        y: Style.space(8)
        width: parent.width - Style.space(16)
        spacing: Style.space(4)

        Item {
          width: parent.width
          height: Style.space(44)

          Text {
            id: prompt
            anchors.left: parent.left
            anchors.leftMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            text: "›"
            color: root.dim
            font.family: Style.font.family
            font.pixelSize: Style.font.title
          }

          TextInput {
            id: input
            anchors.left: prompt.right
            anchors.leftMargin: Style.space(10)
            anchors.right: parent.right
            anchors.rightMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            text: root.query
            onTextEdited: { root.query = text; root.selected = 0 }
            color: root.fg
            selectionColor: root.alpha(root.fg, 0.3)
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            focus: true

            Text {
              visible: input.text === ""
              text: "Project…"
              color: root.dim
              font: input.font
            }

            Keys.onPressed: function(event) {
              var k = event.key
              var ctrl = event.modifiers & Qt.ControlModifier
              var shift = event.modifiers & Qt.ShiftModifier
              if (k === Qt.Key_Escape) root.close()
              else if (k === Qt.Key_Down || k === Qt.Key_Tab || (ctrl && (k === Qt.Key_J || k === Qt.Key_N)))
                root.selected = Math.min(root.matches.length - 1, root.selected + 1)
              else if (k === Qt.Key_Up || k === Qt.Key_Backtab || (ctrl && (k === Qt.Key_K || k === Qt.Key_P)))
                root.selected = Math.max(0, root.selected - 1)
              else if (k === Qt.Key_Return || k === Qt.Key_Enter)
                root.launch(root.matches[root.selected], ctrl ? "editor" : (shift ? "shell" : "agent"))
              else return
              event.accepted = true
            }
          }
        }

        Rectangle { width: parent.width; height: 1; color: root.alpha(root.fg, 0.08) }

        ListView {
          id: list
          width: parent.width
          height: Math.min(root.matches.length, root.visibleRows) * Style.space(46)
          model: root.matches
          currentIndex: root.selected
          clip: true
          interactive: false
          boundsBehavior: Flickable.StopAtBounds
          highlightMoveDuration: 0
          onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

          delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool current: index === root.selected
            width: list.width
            height: Style.space(46)
            radius: Style.space(8)
            color: current ? Color.menu.selectedBackground : "transparent"

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onPositionChanged: root.selected = row.index
              onClicked: function(mouse) {
                root.launch(row.modelData, (mouse.modifiers & Qt.ControlModifier) ? "editor" : ((mouse.modifiers & Qt.ShiftModifier) ? "shell" : "agent"))
              }
            }

            Column {
              anchors.left: parent.left
              anchors.leftMargin: Style.space(12)
              anchors.right: branch.left
              anchors.rightMargin: Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(1)

              Text {
                width: parent.width
                text: row.modelData.name
                color: row.current ? Color.menu.selectedText : root.fg
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                font.bold: row.current
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                text: row.modelData.display
                color: root.dim
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                elide: Text.ElideMiddle
              }
            }

            Text {
              id: branch
              anchors.right: parent.right
              anchors.rightMargin: Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              width: Math.min(implicitWidth, list.width * 0.42)
              text: row.modelData.branch
              color: root.dim
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              elide: Text.ElideMiddle
              horizontalAlignment: Text.AlignRight
            }
          }
        }

        Text {
          width: parent.width
          topPadding: Style.space(4)
          bottomPadding: Style.space(4)
          text: root.matches.length === 0 && root.projects.length > 0 ? "No project matches" : "↵ opencode   ⇧↵ shell   ⌃↵ editor"
          color: root.dim
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }
}
