import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    Layout.minimumHeight: 0; Layout.maximumHeight: 0; Layout.preferredHeight: 0
    Layout.minimumWidth: 0; Layout.maximumWidth: 0; Layout.preferredWidth: 0
    fullRepresentation: Item { implicitWidth: 0; implicitHeight: 0 }
    readonly property var cfg: Plasmoid.configuration
    property var overlays: []
    property var trayControls: []
    property var clockControl: null
    property var grid: null
    property var tasks: null
    property var launcherItem: null
    property var taskList: tasks?.applet?.taskList ?? null
    property var trayRoot: null
    property var leftSpacer: null
    property var rightSpacer: null
    property int updates: 0
    readonly property real desiredTaskWidth: tasks&&tasks.applet?Math.max(1,tasks.applet.Layout.preferredWidth):1
    Binding {target:root.tasks instanceof Item?root.tasks.Layout:null;property:"maximumWidth";value:root.desiredTaskWidth;when:root.tasks!==null}
    Binding {target:root.tasks instanceof Item?root.tasks.Layout:null;property:"preferredWidth";value:root.desiredTaskWidth;when:root.tasks!==null}
    property bool queued: false
    property bool ready: false
    property real spacerWidth: 0
    Binding { target:root.grid;property:"columnSpacing";value:root.cfg.panelGap;when:root.grid!==null }
    Binding { target:root.leftSpacer instanceof Item?root.leftSpacer.Layout:null;property:"fillWidth";value:false;when:root.leftSpacer!==null }
    Binding { target:root.leftSpacer instanceof Item?root.leftSpacer.Layout:null;property:"minimumWidth";value:root.spacerWidth;when:root.leftSpacer!==null }
    Binding { target:root.leftSpacer instanceof Item?root.leftSpacer.Layout:null;property:"preferredWidth";value:root.spacerWidth;when:root.leftSpacer!==null }
    Binding { target:root.leftSpacer instanceof Item?root.leftSpacer.Layout:null;property:"maximumWidth";value:root.spacerWidth;when:root.leftSpacer!==null }
    Binding { target:root.rightSpacer instanceof Item?root.rightSpacer.Layout:null;property:"fillWidth";value:true;when:root.rightSpacer!==null }
    Binding { target:root.rightSpacer instanceof Item?root.rightSpacer.Layout:null;property:"minimumWidth";value:root.cfg.rightSpace;when:root.rightSpacer!==null }
    function walk(n,fn,d=0) { if(!n||d>20)return; if(fn(n)===false)return; for(const c of Array.from(n.children||[]))walk(c,fn,d+1); }
    function queue() { if(queued)return;queued=true;Qt.callLater(()=>{queued=false;updates++;discover();scanTasks();scanTray();recenter();}); }
    function discover() {
        if(!grid){let p=root.parent;while(p){if(p instanceof GridLayout){grid=p;break;}p=p.parent;}}
        if(!grid)return;
        for(const c of Array.from(grid.children)) {
            const id=Number(c.applet?.plasmoid?.id);const plugin=c.applet?.plasmoid?.pluginName;
            if(id===cfg.leftId)leftSpacer=c;if(id===cfg.rightId)rightSpacer=c;
            if(plugin==='org.kde.plasma.icontasks')tasks=c;
            if(['org.kde.plasma.kickoff','org.kde.plasma.kicker','org.kde.plasma.kickerdash'].includes(plugin))launcherItem=c;
            if(plugin==='org.kde.plasma.systemtray'&&!trayRoot)walk(c,n=>{if(n.visibleLayout!==undefined&&n.systemTrayState!==undefined){trayRoot=n;return false;}});
            if(plugin==='org.kde.plasma.digitalclock'&&!clockControl)walk(c,n=>{
                if(n.objectName!=='digital-clock-compactrepresentation')return;
                const content=Array.from(n.children).find(x=>Array.from(x.children||[]).some(y=>y.rows!==undefined&&y.flow!==undefined));
                const labels=content&&Array.from(content.children).find(x=>x.rows!==undefined&&x.flow!==undefined);
                const time=labels?.children[0],zone=labels?.children[1],date=content&&Array.from(content.children).find(x=>x.text!==undefined);
                if(time&&date)clockControl=clockComponent.createObject(root,{target:n,box:c,content:content,timeSource:time,dateSource:date,zoneSource:zone,settings:cfg});
                return false;
            });
        }
    }
    function recenter() {
        if(!tasks||!leftSpacer||!rightSpacer||!grid||tasks.width<=0)return;
        if(!launcherItem)return;
        const others=Array.from(grid.children).filter(c=>c.applet?.plasmoid&&c!==leftSpacer&&c!==rightSpacer&&c!==tasks&&c.width>0);
        const used=others.reduce((sum,c)=>sum+c.width,0);
        const available=Math.max(0,grid.width-desiredTaskWidth-used-grid.columnSpacing*(others.length+2));
        const maxLeft=Math.max(0,available-cfg.rightSpace);
        const wanted=cfg.center?grid.width/2+cfg.centerOffset-desiredTaskWidth/2-launcherItem.x-launcherItem.width-2*grid.columnSpacing:cfg.leftSpace;
        const next=Math.round(Math.max(0,Math.min(maxLeft,Math.max(Math.min(cfg.leftSpace,maxLeft),wanted))));
        if(Math.abs(spacerWidth-next)>=1)spacerWidth=next;
        ready=true;
    }
    function scanTasks() {
        overlays=overlays.filter(o=>{if(o instanceof Item&&o.target instanceof Item)return true;if(o instanceof Item)o.destroy();return false;});
        if(!taskList)return;
        for(const n of Array.from(taskList.children)) {
            if(n.model===undefined||n.inPopup!==false||overlays.some(o=>o.target===n))continue;
            const frame=Array.from(n.children).find(c=>c.imagePath==='widgets/tasks'&&c.basePrefix!==undefined);
            const o=decoration.createObject(root,{parent:n,target:n,nativeFrame:frame??null});if(o)overlays.push(o);
        }
    }
    function scanTray() {
        trayControls=trayControls.filter(o=>{if(o instanceof Item&&o.target instanceof Item)return true;if(o instanceof Item)o.destroy();return false;});
        if(!trayRoot)return;
        walk(trayRoot.visibleLayout.contentItem,n=>{
            if(n.inVisibleLayout===true&&n.iconContainer&&!trayControls.some(o=>o.target===n.iconContainer)) {
                const o=trayComponent.createObject(root,{target:n.iconContainer,settings:cfg});if(o)trayControls.push(o);return false;
            }
        });
    }
    function sample() {
        cfg.diagnostics=JSON.stringify({version:2,mode:{center:cfg.center,showTitles:cfg.showTitles,style:cfg.style,radius:cfg.radius,gray:cfg.gray},titlesVisible:overlays.filter(o=>o.nativeLabel?.visible??false).length,updates:updates,discoveryRunning:discovery.running,structure:{grid:String(grid),tasks:String(tasks),list:String(taskList),left:String(leftSpacer),right:String(rightSpacer),tray:String(trayRoot)},width:grid?.width,taskX:tasks?.x,taskWidth:tasks?.width,desired:desiredTaskWidth,buttons:overlays.filter(o=>o.target instanceof Item).map(o=>o.target.width),error:tasks?Math.round(tasks.x+tasks.width/2-grid.width/2):0,leftSpacer:leftSpacer?.width,rightSpacer:rightSpacer?.width,overlays:overlays.length,framesHidden:overlays.filter(o=>o.nativeFrame?.opacity===0).length,tray:trayControls.filter(o=>o instanceof Item&&o.target instanceof Item).map(o=>({width:o.target.width,height:o.target.height})),trayCell:trayRoot?.visibleLayout?.cellWidth,clock:clockControl?{time:clockControl.timePixels,date:clockControl.datePixels,width:clockControl.box?.width,height:clockControl.box?.height,sourceHeight:clockControl.target?.height}:null});cfg.writeConfig();
    }
    Connections { target:root.grid;ignoreUnknownSignals:true;function onChildrenChanged(){root.queue();}function onWidthChanged(){Qt.callLater(root.recenter);} }
    Connections { target:root.launcherItem;ignoreUnknownSignals:true;function onWidthChanged(){Qt.callLater(root.recenter);} }
    Connections { target:root.tasks;ignoreUnknownSignals:true;function onWidthChanged(){Qt.callLater(root.recenter);} }
    Connections { target:root.taskList;ignoreUnknownSignals:true;function onChildrenChanged(){root.queue();}function onCountChanged(){root.queue();} }
    Connections { target:root.trayRoot?.visibleLayout?.contentItem??null;ignoreUnknownSignals:true;function onChildrenChanged(){root.queue();} }
    Connections { target:root.trayRoot?.visibleLayout??null;ignoreUnknownSignals:true;function onCountChanged(){root.queue();}function onWidthChanged(){Qt.callLater(root.recenter);} }
    Connections { target:root.clockControl?.box??null;ignoreUnknownSignals:true;function onWidthChanged(){Qt.callLater(root.recenter);} }
    Connections { target:root.cfg;function onCenterChanged(){root.queue();}function onCenterOffsetChanged(){root.queue();}function onLeftSpaceChanged(){root.queue();}function onRightSpaceChanged(){root.queue();}function onProbeChanged(){Qt.callLater(root.sample);} }
    Binding { target:root.trayRoot?.visibleLayout??null;property:"cellWidth";value:root.cfg.traySize+root.cfg.trayGap;when:root.trayRoot!==null }
    Component { id:trayComponent; TrayIcon { } }
    Component { id:clockComponent; ClockControl { } }
    Component { id:decoration
        Item {
            id:item
            required property Item target
            required property var nativeFrame
            anchors.fill:parent;z:-0.5;enabled:false
            property var nativeLabel:null
            function refreshFrame(){if(target){nativeFrame=Array.from(target.children).find(c=>c.imagePath==='widgets/tasks'&&c.basePrefix!==undefined)??null;nativeLabel=Array.from(target.children).find(c=>c.text!==undefined&&c.maximumLineCount!==undefined)??null;}}
            Component.onCompleted:refreshFrame()
            Connections {target:item.target;ignoreUnknownSignals:true;function onChildrenChanged(){item.refreshFrame();}}
            readonly property bool active:target?.model.IsActive??false
            readonly property bool running:!(target?.model.IsLauncher??true)
            readonly property bool hovered:target?.highlighted??false
            readonly property bool urgent:target?.model.IsDemandingAttention??false
            Binding { target:item.nativeFrame;property:"opacity";value:0;when:root.cfg.style!==0&&item.nativeFrame!==null;restoreMode:Binding.RestoreBindingOrValue }
            Binding {target:item.nativeLabel;property:"visible";value:item.running;when:root.cfg.showTitles&&item.nativeLabel!==null}
            Binding {target:item.target instanceof Item?item.target.Layout:null;property:"maximumWidth";value:root.cfg.titleWidth;when:root.cfg.showTitles&&item.running}
            Rectangle {
                anchors.fill:parent;anchors.margins:2
                visible:root.cfg.style!==0&&(item.running||item.hovered)
                radius:Math.min(root.cfg.radius,height/2)
                color:root.cfg.style===3?'transparent':item.urgent?'#f67400':root.cfg.style===4?Qt.rgba(root.cfg.gray/255,root.cfg.gray/255,root.cfg.gray/255,1):root.cfg.accent
                opacity:item.active?root.cfg.alpha/100:item.hovered?0.14:root.cfg.inactiveAlpha/100
                border.width:root.cfg.style===3?1:0;border.color:root.cfg.accent
            }
            Rectangle {
                visible:root.cfg.style!==0&&item.running
                anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:parent.bottom;anchors.bottomMargin:2
                width:root.cfg.style===2?4:item.active?parent.width*0.5:parent.width*0.24
                height:3;radius:1.5
                color:item.urgent?'#f67400':item.active?root.cfg.accent:'#9da3aa'
            }
        }
    }
    Timer { id:discovery; interval:150;running:!root.tasks||!root.taskList||!root.trayRoot||!root.clockControl;repeat:true;triggeredOnStart:true;onTriggered:root.queue() }
    Component.onCompleted: queue()
    Component.onDestruction: {for(const o of overlays)if(o instanceof Item)o.destroy();for(const o of trayControls)if(o instanceof Item)o.destroy();if(clockControl)clockControl.destroy();}
}
