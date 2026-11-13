import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    Layout.minimumHeight: 0
    Layout.maximumHeight: 0
    Layout.preferredHeight: 0
    Layout.minimumWidth: 0
    Layout.maximumWidth: 0
    Layout.preferredWidth: 0
    fullRepresentation: Item { implicitWidth: 0; implicitHeight: 0 }
    readonly property var cfg: Plasmoid.configuration
    property var overlays: []
    function layout() { let p=root.parent; while(p) { if(p instanceof GridLayout)return p; p=p.parent; } return null; }
    function walk(n,fn,d=0) { if(!n||d>22)return; if(fn(n)===false)return; for(const c of Array.from(n.children||[]))walk(c,fn,d+1); }
    function update() {
        const grid=layout(); if(!grid)return;
        const children=Array.from(grid.children).filter(c=>c.applet?.plasmoid);
        const tasks=children.find(c=>c.applet.plasmoid.pluginName==='org.kde.plasma.icontasks');
        const left=children.find(c=>Number(c.applet.plasmoid.id)===cfg.leftId);
        const right=children.find(c=>Number(c.applet.plasmoid.id)===cfg.rightId);
        if(tasks&&left&&right) {
            let a=0,b=0;
            for(let i=0;i<children.length;i++) { const c=children[i]; if(c===left||c===right||c===tasks)continue; if(["org.kde.plasma.kickoff","org.kde.plasma.kicker","org.kde.plasma.kickerdash"].includes(c.applet.plasmoid.pluginName))a+=c.width+grid.columnSpacing;else b+=c.width+grid.columnSpacing; }
            const gap=Math.max(0,grid.width-tasks.width-a-b-grid.columnSpacing*4);
            const l=cfg.center?Math.round(Math.max(0,Math.min(gap,left.width+grid.width/2-tasks.x-tasks.width/2))):0;
            left.Layout.fillWidth=false; left.Layout.minimumWidth=l; left.Layout.preferredWidth=l; left.Layout.maximumWidth=l;
            right.Layout.fillWidth=true; right.Layout.minimumWidth=0; right.Layout.maximumWidth=Infinity;
            const diag=JSON.stringify({width:grid.width,taskX:tasks.x,taskWidth:tasks.width,error:Math.round(tasks.x+tasks.width/2-grid.width/2),left:left.width,right:right.width,l:l,gap:gap,a:a,b:b,spacing:grid.columnSpacing,overlays:overlays.length,framesHidden:overlays.filter(o=>o.nativeFrame?.opacity===0).length});
            if(cfg.diagnostics!==diag){cfg.diagnostics=diag;cfg.writeConfig();}
        }
        if(tasks)walk(tasks,n=>{
            if(n.tasksRoot!==undefined&&n.model!==undefined&&n.inPopup===false&&!overlays.some(o=>o.target===n)) {
                let frame=null;for(const c of n.children)if(c.imagePath==='widgets/tasks'){frame=c;break;}
                const o=decoration.createObject(n,{target:n,nativeFrame:frame});if(o)overlays.push(o);
            }
        });
        overlays=overlays.filter(o=>{if(o&&o.target)return true;if(o)o.destroy();return false;});
    }
    Component { id: decoration
        Item {
            id: item
            required property Item target
            required property var nativeFrame
            anchors.fill: parent
            z: -0.5
            enabled: false
            readonly property bool active: target?.model.IsActive??false
            readonly property bool running: !(target?.model.IsLauncher??true)
            readonly property bool hovered: target?.highlighted??false
            readonly property bool urgent: target?.model.IsDemandingAttention??false
            Binding { target: item.nativeFrame; property:"opacity"; value:0; when:root.cfg.style!==0&&item.nativeFrame!==null; restoreMode:Binding.RestoreBindingOrValue }
            Rectangle {
                anchors.fill: parent; anchors.margins:2
                visible:root.cfg.style!==0&&(item.running||item.hovered)
                radius:Math.min(root.cfg.radius,height/2)
                color:root.cfg.style===3?'transparent':item.urgent?'#f67400':root.cfg.style===4?'#ffffff':root.cfg.accent
                opacity:item.active?root.cfg.alpha/100: item.hovered?0.14:0.06
                border.width:root.cfg.style===3?1:0; border.color:root.cfg.accent
            }
            Rectangle {
                visible:root.cfg.style!==0&&item.running
                anchors.horizontalCenter:parent.horizontalCenter; anchors.bottom:parent.bottom; anchors.bottomMargin:2
                width:root.cfg.style===2?4:item.active?parent.width*0.5:parent.width*0.24
                height:3; radius:1.5
                color:item.urgent?'#f67400':item.active?root.cfg.accent:'#9da3aa'
            }
        }
    }
    Component.onDestruction: { for(const o of overlays)if(o)o.destroy(); }
    Timer { interval:350;running:true;repeat:true;triggeredOnStart:true;onTriggered:root.update() }
}
