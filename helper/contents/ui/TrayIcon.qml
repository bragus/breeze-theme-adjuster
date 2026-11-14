import QtQuick
import QtQuick.Layouts
Item {
    id:control
    visible:false
    required property Item target
    required property var settings
    readonly property bool valid:target instanceof Item
    readonly property real side: Math.min(settings.traySize,target?.parent?.height??settings.traySize)
    Binding {target:control.valid?control.target.Layout:null;property:"minimumWidth";value:control.side;when:control.valid}
    Binding {target:control.valid?control.target.Layout:null;property:"maximumWidth";value:control.side;when:control.valid}
    Binding {target:control.valid?control.target.Layout:null;property:"minimumHeight";value:control.side;when:control.valid}
    Binding {target:control.valid?control.target.Layout:null;property:"maximumHeight";value:control.side;when:control.valid}
    Binding {target:control.target;property:"implicitWidth";value:control.side;when:control.valid}
    Binding {target:control.target;property:"implicitHeight";value:control.side;when:control.valid}
}
