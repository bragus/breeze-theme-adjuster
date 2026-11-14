import QtQuick
import QtQuick.Layouts
Item {
    id:control
    required property Item target
    required property Item box
    required property Item content
    required property var timeSource
    required property var dateSource
    required property var zoneSource
    required property var settings
    parent:target
    anchors.fill:parent
    enabled:false
    readonly property real fit:Math.min(1,Math.max(1,settings.panelHeight-4)/Math.max(1,texts.implicitHeight))
    readonly property real timePixels:settings.timeSize*fit
    readonly property real datePixels:settings.dateSize*fit
    readonly property real wantedWidth:Math.ceil(texts.implicitWidth*fit)+12
    Binding {target:control.content;property:"opacity";value:0;when:control.settings.clockCustom}
    Binding {target:control.box.Layout;property:"minimumWidth";value:control.wantedWidth;when:control.settings.clockCustom}
    Binding {target:control.box.Layout;property:"preferredWidth";value:control.wantedWidth;when:control.settings.clockCustom}
    Binding {target:control.box.Layout;property:"maximumWidth";value:control.wantedWidth;when:control.settings.clockCustom}
    Binding {target:control.target.Layout;property:"minimumWidth";value:control.wantedWidth;when:control.settings.clockCustom}
    Binding {target:control.target.Layout;property:"maximumWidth";value:control.wantedWidth;when:control.settings.clockCustom}
    Column {
        id:texts
        anchors.centerIn:parent
        scale:control.fit
        visible:control.settings.clockCustom
        spacing:0
        Text {anchors.horizontalCenter:parent.horizontalCenter;text:control.timeSource.text;color:control.timeSource.color;font.family:control.timeSource.font.family;font.weight:control.timeSource.font.weight;font.pixelSize:control.settings.timeSize;font.features:({"tnum":1})}
        Text {anchors.horizontalCenter:parent.horizontalCenter;text:control.dateSource.text;visible:control.dateSource.visible;color:control.dateSource.color;font.family:control.dateSource.font.family;font.pixelSize:control.settings.dateSize}
        Text {anchors.horizontalCenter:parent.horizontalCenter;text:control.zoneSource?.text??"";visible:(control.zoneSource?.visible??false)&&text.length>0;color:control.timeSource.color;font.family:control.timeSource.font.family;font.pixelSize:control.settings.dateSize}
    }
}
