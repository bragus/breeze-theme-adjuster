use eframe::egui::{self, Color32, Pos2, Rect, Vec2};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use std::{fs, path::PathBuf, process::Command};
type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;
const ID: &str = "local.breezecompact";
const INSPECT: &str = r#"print(JSON.stringify(panels().map(p=>({id:p.id,height:p.height,location:p.location,floating:p.floating,widgets:p.widgets().filter((w,i,a)=>a.findIndex(x=>x.id===w.id)===i).sort((a,b)=>a.index-b.index).map(w=>{w.currentConfigGroup=['General'];return {id:w.id,type:w.type,index:w.index,values:{groupingStrategy:w.readConfig('groupingStrategy',1),fill:w.readConfig('fill',true),iconSpacing:w.readConfig('iconSpacing',1),scaleIconsToFit:w.readConfig('scaleIconsToFit',false)}}})}))));"#;
fn home() -> PathBuf { PathBuf::from(std::env::var_os("HOME").expect("HOME ausente")) }
fn data() -> PathBuf { home().join(".local/share/breeze-editor") }
fn run(program:&str,args:&[&str])->Result<String> {
    let mut c=if std::path::Path::new("/.flatpak-info").exists() {let mut c=Command::new("flatpak-spawn");c.args(["--host",program]);c} else {Command::new(program)};
    let o=c.args(args).output()?;
    if !o.status.success(){return Err(format!("{program}: {}{}",String::from_utf8_lossy(&o.stderr),String::from_utf8_lossy(&o.stdout)).into())}
    Ok(String::from_utf8(o.stdout)?)
}
fn script(s:&str)->Result<String>{
    let out=run("gdbus",&["call","--session","--dest","org.kde.plasmashell","--object-path","/PlasmaShell","--method","org.kde.PlasmaShell.evaluateScript",s])?;
    let body=out.trim().strip_prefix("('").and_then(|s|s.strip_suffix("',)")).unwrap_or(out.trim()).replace("\\'", "'").replace("\\\\", "\\");
    if body.contains("Error:")||body.contains("error:"){return Err(body.into())} Ok(body)
}
fn write(file:&str,group:&str,key:&str,value:&str)->Result<()> {run("kwriteconfig6",&["--file",file,"--group",group,"--key",key,value])?;Ok(())}
#[derive(Serialize,Deserialize,Clone)]
#[serde(default)]
struct Settings { panel:u64,height:u32,radius:u32,style:usize,alpha:u32,center:bool,small_tray:bool,tray_spacing:u32,app_spacing:u32,toolbar:u32,rounded:bool,accent:String,tray_size:u32,tray_gap:u32,panel_gap:u32,left_space:u32,right_space:u32,center_offset:i32,gray:u32,inactive_alpha:u32,time_size:u32,date_size:u32,clock_custom:bool,show_titles:bool,title_width:u32 }
impl Default for Settings {fn default()->Self{Self{panel:523,height:32,radius:8,style:1,alpha:22,center:true,small_tray:true,tray_spacing:1,app_spacing:0,toolbar:16,rounded:true,accent:"#7a7d82".into(),tray_size:18,tray_gap:4,panel_gap:4,left_space:0,right_space:0,center_offset:0,gray:220,inactive_alpha:6,time_size:14,date_size:11,clock_custom:true,show_titles:false,title_width:160}}}
fn snapshot()->Result<Value>{Ok(serde_json::from_str(&script(INSPECT)?)?)}
fn backup(panels:&Value)->Result<()> {
    let dir=data().join("backup");if dir.exists(){return Ok(())}
    let tmp=data().join("backup-new");fs::create_dir_all(&tmp)?;
    for n in ["kdeglobals","breezerc","plasmarc"] {let src=home().join(".config").join(n);if src.exists(){fs::copy(src,tmp.join(n))?;}}
    fs::write(tmp.join("panels.json"),serde_json::to_vec_pretty(panels)?)?;
    fs::write(tmp.join("applets-original.conf"),fs::read(home().join(".config/plasma-org.kde.plasma.desktop-appletsrc"))?)?;
    fs::rename(tmp,dir)?;Ok(())
}
fn install_helper()->Result<bool> {
    let dest=home().join(".local/share/plasma/plasmoids").join(ID);let existing=dest.join("metadata.json").exists();
    let dir=if existing{dest}else{data().join("helper")};fs::create_dir_all(dir.join("contents/ui"))?;fs::create_dir_all(dir.join("contents/config"))?;
    let mut changed=false;
    for (n,s) in [("metadata.json",include_str!("../helper/metadata.json")),("contents/ui/main.qml",include_str!("../helper/contents/ui/main.qml")),("contents/ui/TrayIcon.qml",include_str!("../helper/contents/ui/TrayIcon.qml")),("contents/ui/ClockControl.qml",include_str!("../helper/contents/ui/ClockControl.qml")),("contents/config/main.xml",include_str!("../helper/contents/config/main.xml"))] {
        if fs::read_to_string(dir.join(n)).unwrap_or_default()!=s {fs::write(dir.join(n),s)?;changed=true;}
    }
    if !existing{run("kpackagetool6",&["--type","Plasma/Applet","--install",dir.to_str().ok_or("Caminho inválido")?])?;}Ok(existing&&changed)
}
// A moldura tem nove partes: cantos não esticam quando o painel muda de largura.
fn panel_svg(radius:u32)->String {
    let r=radius.max(1);let m=1;let n=r*2+m;
    let mut svg=format!(r##"<svg xmlns="http://www.w3.org/2000/svg" width="{}" height="{}"><style id="current-color-scheme">.ColorScheme-Background{{color:#131618;}}</style>"##,n*6,n);
    for (i,p) in ["","north-","south-","east-","west-","mask-"].iter().enumerate() {
        let ox=i as u32*n;let fill=if *p=="mask-" {"#ffffff"}else{"currentColor"};
        for (name,x,y,w,h) in [("center",r,r,m,m),("top",r,0,m,r),("bottom",r,r+m,m,r),("left",0,r,r,m),("right",r+m,r,r,m)] {
            svg+=&format!(r#"<rect id="{p}{name}" class="ColorScheme-Background" x="{}" y="{y}" width="{w}" height="{h}" fill="{fill}"/>"#,ox+x);
        }
        for (name,x,y,d) in [("topleft",0,0,format!("M {r} 0 L {r} {r} L 0 {r} Q 0 0 {r} 0")),("topright",r+m,0,format!("M 0 0 Q {r} 0 {r} {r} L 0 {r} Z")),("bottomleft",0,r+m,format!("M 0 0 L {r} 0 L {r} {r} Q 0 {r} 0 0")),("bottomright",r+m,r+m,format!("M 0 0 L {r} 0 Q {r} {r} 0 {r} Z"))] {
            svg+=&format!(r#"<path id="{p}{name}" class="ColorScheme-Background" transform="translate({},{y})" d="{d}" fill="{fill}"/>"#,ox+x);
        }
    }
    for side in ["left","right","top","bottom"] {svg+=&format!(r#"<rect id="hint-{side}-margin" width="1" height="1" fill="none"/>"#);}
    svg+"</svg>"
}
fn theme(s:&Settings)->Result<()> {
    let name=if fs::read_to_string(data().join("theme")).unwrap_or_default()=="breeze-compact-a" {"breeze-compact-b"}else{"breeze-compact-a"};
    let dir=home().join(".local/share/plasma/desktoptheme").join(name);
    fs::create_dir_all(dir.join("widgets"))?;
    fs::write(dir.join("metadata.json"),json!({"KPlugin":{"Id":name,"Name":"Breeze Compact","Version":"1.0","License":"MIT"},"X-Plasma-API":"5.0"}).to_string())?;
    fs::write(dir.join("plasmarc"),"[Settings]\nFallbackTheme=default\n[ContrastEffect]\nenabled=false\n[BlurBehindEffect]\nenabled=true\n")?;
    for path in ["widgets","opaque/widgets","translucent/widgets"] {fs::create_dir_all(dir.join(path))?;fs::write(dir.join(path).join("panel-background.svg"),panel_svg(s.radius))?;}
    for path in ["widgets","opaque/widgets","translucent/widgets","solid/widgets"] {
        fs::create_dir_all(dir.join(path))?;let target=dir.join(path).join("tasks.svg");
        if s.style!=0 {fs::write(target,include_bytes!("../assets/tasks-clear.svg"))?;}else if target.exists(){fs::remove_file(target)?;}
    }
    run("plasma-apply-desktoptheme",&[name])?;fs::write(data().join("theme"),name)?;Ok(())
}
fn apply(s:&Settings)->Result<()> {
    let panels=snapshot()?;
    let p=panels.as_array().and_then(|a|a.iter().find(|p|p["id"].as_u64()==Some(s.panel))).ok_or("Painel não encontrado. Reabra o editor.")?;
    if !p["widgets"].as_array().unwrap().iter().any(|w|w["type"]=="org.kde.plasma.icontasks") {return Err("Selecione um painel com Gerenciador de tarefas somente com ícones.".into())}
    if !["bottom","top"].contains(&p["location"].as_str().unwrap_or("")){return Err("Use um painel horizontal para esta centralização.".into())}
    backup(&panels)?;let reload=install_helper()?;
    let js=include_str!("apply.js").replace("SETTINGS",&serde_json::to_string(s)?);
    script(&js)?;
    write("kdeglobals","MainToolbarIcons","Size",&s.toolbar.to_string())?;
    write("kdeglobals","ToolbarIcons","Size",&s.toolbar.to_string())?;
    write("breezerc","Windeco","ButtonSize","ButtonSmall")?;
    write("breezerc","Common","RoundedCorners",if s.rounded{"true"}else{"false"})?;
    theme(s)?;run("gdbus",&["call","--session","--dest","org.kde.KWin","--object-path","/KWin","--method","org.kde.KWin.reconfigure"])?;
    fs::write(data().join("settings.json"),serde_json::to_vec_pretty(s)?)?;if reload{run("systemctl",&["--user","restart","plasma-plasmashell.service"])?;}Ok(())
}
fn restore()->Result<()> {
    let dir=data().join("backup");let panels:Value=serde_json::from_slice(&fs::read(dir.join("panels.json"))?)?;
    let js=include_str!("restore.js").replace("SNAPSHOT",&panels.to_string());script(&js)?;
    for (file,group,key) in [("kdeglobals","MainToolbarIcons","Size"),("kdeglobals","ToolbarIcons","Size"),("breezerc","Windeco","ButtonSize"),("breezerc","Common","RoundedCorners")] {
        let text=fs::read_to_string(dir.join(file)).unwrap_or_default();
        let heading=format!("[{group}]");let prefix=format!("{key}=");
        let old=text.lines().skip_while(|l|*l!=heading).skip(1).take_while(|l|!l.starts_with('[')).find_map(|l|l.strip_prefix(&prefix));
        if let Some(v)=old {write(file,group,key,v)?;}else{run("kwriteconfig6",&["--file",file,"--group",group,"--key",key,"--delete"])?;}
    }
    let conf=fs::read_to_string(dir.join("plasmarc")).unwrap_or_default();
    let previous=conf.lines().skip_while(|l|*l!="[Theme]").skip(1).take_while(|l|!l.starts_with('[')).find_map(|l|l.strip_prefix("name=")).unwrap_or("default");
    run("plasma-apply-desktoptheme",&[previous])?;
    run("gdbus",&["call","--session","--dest","org.kde.KWin","--object-path","/KWin","--method","org.kde.KWin.reconfigure"])?;
    fs::rename(&dir,data().join(format!("restaurado-{}",std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs())))?;Ok(())
}
const STYLES:[&str;5]=["Breeze original","Suave + traço","Suave + ponto","Contorno","Neutro"];
struct Editor {s:Settings,panels:Value,status:String}
impl eframe::App for Editor {
    fn ui(&mut self,ui:&mut egui::Ui,_:&mut eframe::Frame){
        egui::CentralPanel::default().show(ui,|ui|{
            ui.heading("Breeze compacto");ui.label("Menu à esquerda · tarefas sem agrupar");ui.add_space(12.);
            let (rect,_)=ui.allocate_exact_size(Vec2::new(ui.available_width(),66.),egui::Sense::hover());let paint=ui.painter();
            paint.rect_filled(rect,12,Color32::from_rgb(19,22,24));
            let col=Color32::from_hex(&self.s.accent).unwrap_or(Color32::LIGHT_BLUE);
            for (i,x) in [rect.left()+22.,rect.center().x-42.,rect.center().x,rect.center().x+42.,rect.right()-25.].iter().enumerate(){
                let r=Rect::from_center_size(Pos2::new(*x,rect.center().y),Vec2::splat(34.));
                if (1..4).contains(&i){
                    if self.s.style==3 {paint.rect_stroke(r,self.s.radius as u8,egui::Stroke::new(1.,col),egui::StrokeKind::Inside);}else if self.s.style!=0 {paint.rect_filled(r,self.s.radius as u8,if self.s.style==4{Color32::from_gray(self.s.gray as u8)}else{col}.gamma_multiply(if i==2{self.s.alpha as f32/100.}else{self.s.inactive_alpha as f32/100.}));}
                    paint.rect_filled(Rect::from_center_size(Pos2::new(*x,r.bottom()-2.),Vec2::new(if self.s.style==2{4.}else{16.},3.)),2,col);
                }
                paint.rect_stroke(Rect::from_center_size(r.center(),Vec2::splat(if i==4{14.}else{18.})),3,egui::Stroke::new(1.5,Color32::LIGHT_GRAY),egui::StrokeKind::Inside);
            }
            ui.small("Prévia ilustrativa dos fundos; Aplicar altera o painel real.");ui.add_space(12.);
            egui::ScrollArea::vertical().max_height((ui.available_height()-100.).max(120.)).show(ui,|ui|{
            egui::ComboBox::from_label("Painel").selected_text(format!("Painel {}",self.s.panel)).show_ui(ui,|ui|{if let Some(a)=self.panels.as_array(){for p in a{if let Some(id)=p["id"].as_u64(){ui.selectable_value(&mut self.s.panel,id,format!("Painel {id} — {} px",p["height"]));}}}});
            ui.add(egui::Slider::new(&mut self.s.height,28..=48).text("Altura do painel (px)"));
            ui.add(egui::Slider::new(&mut self.s.radius,2..=16).text("Raio do painel e tarefas (px)"));
            ui.checkbox(&mut self.s.center,"Centralizar tarefas no painel");
            ui.small("Desativar muda só a posição; o visual das tarefas permanece igual.");
            ui.checkbox(&mut self.s.show_titles,"Mostrar títulos das janelas");
            ui.add_enabled(self.s.show_titles,egui::Slider::new(&mut self.s.title_width,80..=240).text("Largura das tarefas com título (px)"));
            ui.separator();ui.strong("Tray e espaços");
            ui.add(egui::Slider::new(&mut self.s.tray_size,12..=32).text("Ícones da tray (px)"));
            ui.add(egui::Slider::new(&mut self.s.tray_gap,0..=24).text("Espaço entre ícones da tray (px)"));
            ui.add(egui::Slider::new(&mut self.s.panel_gap,0..=20).text("Espaço entre widgets (px)"));
            ui.add(egui::Slider::new(&mut self.s.left_space,0..=200).text("Espaçador após o menu: mínimo (px)"));
            ui.add(egui::Slider::new(&mut self.s.right_space,0..=200).text("Espaçador à direita: mínimo (px)"));
            ui.add(egui::Slider::new(&mut self.s.center_offset,-240..=240).text("Deslocar centro das tarefas (px)"));
            ui.small("Com centralização, os espaçadores crescem para equilibrar o painel.");
            ui.add(egui::Slider::new(&mut self.s.app_spacing,0..=2).text("Espaçamento das tarefas"));
            ui.separator();ui.strong("Data e hora");
            ui.checkbox(&mut self.s.clock_custom,"Tamanhos personalizados no relógio");
            ui.add_enabled(self.s.clock_custom,egui::Slider::new(&mut self.s.time_size,8..=28).text("Hora (px)"));
            ui.add_enabled(self.s.clock_custom,egui::Slider::new(&mut self.s.date_size,8..=24).text("Data (px)"));
            ui.small("Os textos se ajustam à altura disponível e mantêm o formato e o fuso do KDE.");
            ui.separator();ui.strong("Aplicativos e fundos");
            egui::ComboBox::from_label("Ícones das barras dos aplicativos").selected_text(format!("{} px",self.s.toolbar)).show_ui(ui,|ui|{for n in [16,22,24,32]{ui.selectable_value(&mut self.s.toolbar,n,format!("{n} px"));}});
            ui.checkbox(&mut self.s.rounded,"Cantos arredondados do Breeze Enhanced");
            ui.small("Janelas: opção nativa, sem raio livre. Barras: reabra os aplicativos.");ui.add_space(10.);
            egui::ComboBox::from_label("Fundo das tarefas").selected_text(STYLES[self.s.style.min(4)]).show_ui(ui,|ui|{for (i,n) in STYLES.iter().enumerate(){ui.selectable_value(&mut self.s.style,i,*n);}});
            ui.add(egui::Slider::new(&mut self.s.alpha,8..=65).text("Opacidade do fundo ativo (%)"));
            ui.add(egui::Slider::new(&mut self.s.inactive_alpha,0..=50).text("Opacidade do fundo inativo (%)"));
            ui.add_enabled(self.s.style==4,egui::Slider::new(&mut self.s.gray,0..=255).text("Tom de cinza no modo Neutro"));
            ui.horizontal(|ui|{ui.label("Cor do destaque");let mut c=Color32::from_hex(&self.s.accent).unwrap_or(Color32::GRAY);if ui.color_edit_button_srgba(&mut c).changed(){self.s.accent=format!("#{:02x}{:02x}{:02x}",c.r(),c.g(),c.b());}});
            });
            ui.add_space(14.);ui.horizontal(|ui|{
                if ui.button("Aplicar").clicked(){self.status=match apply(&self.s){Ok(_)=>"Aplicado. O backup anterior está preservado.".into(),Err(e)=>format!("Falha: {e}. Use Restaurar se necessário.")};}
                if ui.add_enabled(data().join("backup").exists(),egui::Button::new("Restaurar anterior")).clicked(){self.status=match restore(){Ok(_)=>"Configuração anterior restaurada. Reabra os aplicativos.".into(),Err(e)=>format!("Falha ao restaurar: {e}")};}
            });ui.add_space(6.);ui.label(&self.status);
        });
    }
}
fn main()->Result<()> {
    let cli=std::env::args().nth(1).unwrap_or_default();
    if cli=="--inspect"{println!("{}",snapshot()?);return Ok(())}
    if cli=="--restore"{restore()?;println!("Restaurado");return Ok(())}
    let panels=snapshot()?;
    let mut s:Settings=fs::read(data().join("settings.json")).ok().and_then(|b|serde_json::from_slice(&b).ok()).unwrap_or_default();
    if !panels.as_array().unwrap().iter().any(|p|p["id"].as_u64()==Some(s.panel)){s.panel=panels[0]["id"].as_u64().ok_or("Nenhum painel encontrado")?;}
    s.title_width=s.title_width.clamp(80,240);s.style=s.style.min(4);s.height=s.height.clamp(28,48);s.tray_size=s.tray_size.clamp(12,32);s.tray_gap=s.tray_gap.min(24);s.gray=s.gray.min(255);s.time_size=s.time_size.clamp(8,28);s.date_size=s.date_size.clamp(8,24);
    if cli=="--apply"{apply(&s)?;println!("Aplicado");return Ok(())}
    eframe::run_native("Breeze compacto",eframe::NativeOptions{viewport:egui::ViewportBuilder::default().with_inner_size([640.,860.]).with_min_inner_size([580.,620.]),..Default::default()},Box::new(move |cc|{cc.egui_ctx.set_visuals(egui::Visuals::dark());Ok(Box::new(Editor{s,panels,status:"Alterações só são gravadas ao clicar em Aplicar.".into()}))})).map_err(|e|e.to_string())?;Ok(())
}
