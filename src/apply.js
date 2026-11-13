const c=SETTINGS,p=panelById(c.panel);if(!p)throw Error('Painel ausente');
let ws=p.widgets().filter((w,i,a)=>a.findIndex(x=>x.id===w.id)===i);
let task=ws.find(w=>w.type==='org.kde.plasma.icontasks');
if(!task)throw Error('Gerenciador somente com ícones ausente');
const launcher=ws.find(w=>['org.kde.plasma.kickoff','org.kde.plasma.kicker','org.kde.plasma.kickerdash'].includes(w.type));
if(!launcher)throw Error('Menu de aplicativos ausente');
let helper=ws.find(w=>w.type==='local.breezecompact');
if(!helper)helper=p.addWidget('local.breezecompact');
if(!helper)throw Error('Widget auxiliar não carregou');
helper.currentConfigGroup=['General'];
let left=p.widgetById(Number(helper.readConfig('leftId',0))),right=p.widgetById(Number(helper.readConfig('rightId',0)));
if(!left)left=p.addWidget('org.kde.plasma.panelspacer');if(!right)right=p.addWidget('org.kde.plasma.panelspacer');
for(const w of [left,right]){w.currentConfigGroup=['General'];w.writeConfig('expanding',true);w.reloadConfig();}
p.height=c.height;
let rest=ws.filter(w=>![launcher.id,task.id,helper.id,left.id,right.id].includes(w.id)).sort((a,b)=>a.index-b.index);
let order=[launcher,left,task,right,...rest,helper];order.forEach((w,i)=>w.index=i);
task.currentConfigGroup=['General'];task.writeConfig('groupingStrategy',0);task.writeConfig('fill',false);task.writeConfig('iconSpacing',c.app_spacing);task.reloadConfig();
for(const w of ws)if(w.type==='org.kde.plasma.systemtray'){w.currentConfigGroup=['General'];w.writeConfig('scaleIconsToFit',!c.small_tray);w.writeConfig('iconSpacing',c.tray_spacing);w.reloadConfig();}
for(const [k,v] of Object.entries({center:c.center,radius:c.radius,style:c.style,alpha:c.alpha,accent:c.accent,leftId:left.id,rightId:right.id})){helper.writeConfig(k,v);}helper.reloadConfig();
print('OK');
