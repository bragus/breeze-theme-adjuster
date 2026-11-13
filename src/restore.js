const saved=SNAPSHOT;
for(const old of saved){const p=panelById(old.id);if(!p)continue;
const helpers=p.widgets().filter(w=>w.type==='local.breezecompact');
for(const h of helpers){h.currentConfigGroup=['General'];for(const key of ['leftId','rightId']){const spacer=p.widgetById(Number(h.readConfig(key,0)));if(spacer)spacer.remove();}h.remove();}
p.height=old.height;
for(const before of old.widgets){const w=p.widgetById(before.id);if(!w)continue;w.currentConfigGroup=['General'];
if(w.type==='org.kde.plasma.icontasks')for(const k of ['groupingStrategy','fill','iconSpacing'])w.writeConfig(k,before.values[k]);
if(w.type==='org.kde.plasma.systemtray')for(const k of ['scaleIconsToFit','iconSpacing'])w.writeConfig(k,before.values[k]);w.reloadConfig();}
for(const before of old.widgets){const w=p.widgetById(before.id);if(w)w.index=before.index;}
}print('OK');
