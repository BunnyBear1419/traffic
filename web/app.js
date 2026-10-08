const resource=typeof GetParentResourceName==='function'?GetParentResourceName():'traffic';
const state={routes:{},zones:{},obstacles:{},mode:'normal',npc:{managed:0,repairs:0},intelligence:{},performance:{},editing:null};
const $=s=>document.querySelector(s);
function post(n,d={}){fetch('https://'+resource+'/'+n,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(d)})}
function esc(v){return String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[c]))}
function renderHealth(){
 const n=state.npc||{},i=state.intelligence||{};
 $('#health').innerHTML='<div class="healthGrid"><div><b>'+esc(n.managed||0)+'</b><small>Managed NPCs</small></div><div><b>'+esc(n.repairs||0)+'</b><small>Appearance repairs</small></div><div><b>'+esc(n.invisible||0)+'</b><small>Invisible detected</small></div><div><b>'+esc(n.mismatched||0)+'</b><small>Clothing mismatches</small></div><div><b>'+esc(i.congestion||0)+'</b><small>Congestion events</small></div><div><b>'+esc(i.gridlocks||0)+'</b><small>Gridlock releases</small></div></div>';
}
function drawHeatmap(){
 const c=$('#heatmap'),ctx=c.getContext('2d'),w=c.width,h=c.height;ctx.clearRect(0,0,w,h);ctx.fillStyle='#0a0d13';ctx.fillRect(0,0,w,h);
 const pts=[];
 Object.values(state.routes).forEach(r=>(r.points||[]).forEach(p=>pts.push({x:+p.x,y:+p.y,t:'route',v:+(r.confidence||0)})));
 Object.values(state.obstacles).forEach(o=>pts.push({x:+o.x,y:+o.y,t:'hot',v:+(o.hits||1)}));
 Object.values(state.zones).forEach(z=>pts.push({x:+z.x,y:+z.y,t:'zone',v:1}));
 if(!pts.length)return;
 const xs=pts.map(p=>p.x),ys=pts.map(p=>p.y),minX=Math.min(...xs),maxX=Math.max(...xs),minY=Math.min(...ys),maxY=Math.max(...ys),sx=maxX-minX||1,sy=maxY-minY||1;
 pts.forEach(p=>{const x=20+((p.x-minX)/sx)*(w-40),y=20+((maxY-p.y)/sy)*(h-40);ctx.beginPath();ctx.arc(x,y,p.t==='hot'?Math.min(16,4+p.v*1.5):p.t==='zone'?9:3,0,Math.PI*2);ctx.fillStyle=p.t==='hot'?'#ff6b6b':p.t==='zone'?'#f0c674':'#8aa7ff';ctx.globalAlpha=p.t==='route'?.45:.8;ctx.fill()});ctx.globalAlpha=1;
}
function render(){
 $('#mode').textContent=state.mode.toUpperCase();$('#routes').textContent=Object.keys(state.routes).length;$('#zones').textContent=Object.keys(state.zones).length;$('#obstacles').textContent=Object.keys(state.obstacles).length;$('#npcManaged').textContent=state.npc.managed||0;$('#npcRepairs').textContent=state.npc.repairs||0;
 const modes=['normal','light','heavy','stop','emergency','race'];$('#modes').innerHTML=modes.map(m=>'<button class="'+(m===state.mode?'active':'')+'" data-mode="'+m+'">'+m+'</button>').join('');
 $('#routeList').innerHTML=Object.values(state.routes).sort((a,b)=>(b.confidence||0)-(a.confidence||0)).map(r=>'<div class="item"><div><strong>'+esc(r.name||r.id)+'</strong><small>'+((r.points||[]).length)+' points • confidence '+Number(r.confidence||0).toFixed(1)+' • '+Number(r.successes||0)+' successes / '+Number(r.failures||0)+' failures</small></div><div><button data-edit="'+esc(r.id)+'">Edit</button><button data-route="'+esc(r.id)+'">Delete</button></div></div>').join('')||'<small>No learned routes.</small>';
 $('#zoneList').innerHTML=Object.values(state.zones).map(z=>'<div class="item"><div><strong>'+esc(z.name||z.type||z.id)+'</strong><small>'+esc(z.type)+' • radius '+Number(z.radius||0).toFixed(0)+'</small></div><button data-zone="'+esc(z.id)+'">Delete</button></div>').join('')||'<small>No zones.</small>';
 $('#obstacleList').innerHTML=Object.values(state.obstacles).sort((a,b)=>(b.hits||0)-(a.hits||0)).slice(0,40).map(o=>'<div class="item"><div><strong>'+esc(o.category||'unknown')+' • '+esc(o.hits||0)+' hits</strong><small>'+Number(o.x).toFixed(1)+', '+Number(o.y).toFixed(1)+', '+Number(o.z).toFixed(1)+' • '+esc(o.reason||'blocked')+'</small></div><button data-obstacle="'+esc(o.id)+'">Clear</button></div>').join('')||'<small>No learned hotspots yet.</small>';
 renderHealth();drawHeatmap();
 document.querySelectorAll('[data-mode]').forEach(b=>b.onclick=()=>{state.mode=b.dataset.mode;post('setMode',{mode:state.mode});render()});
 document.querySelectorAll('[data-edit]').forEach(b=>b.onclick=()=>editRoute(b.dataset.edit));
 document.querySelectorAll('[data-route]').forEach(b=>b.onclick=()=>post('deleteRoute',{id:b.dataset.route}));
 document.querySelectorAll('[data-zone]').forEach(b=>b.onclick=()=>post('deleteZone',{id:b.dataset.zone}));
 document.querySelectorAll('[data-obstacle]').forEach(b=>b.onclick=()=>post('deleteObstacle',{id:b.dataset.obstacle}));
}
function editRoute(id){const r=JSON.parse(JSON.stringify(state.routes[id]));if(!r)return;state.editing=r;$('#editor').classList.add('show');$('#routeName').value=r.name||r.id;$('#loop').checked=!!r.loop;renderPoints()}
function renderPoints(){const pts=state.editing.points||[];$('#points').innerHTML=pts.map((p,i)=>'<div class="point"><span>#'+(i+1)+'</span><input data-p="'+i+'" data-k="x" value="'+Number(p.x).toFixed(3)+'"><input data-p="'+i+'" data-k="y" value="'+Number(p.y).toFixed(3)+'"><input data-p="'+i+'" data-k="z" value="'+Number(p.z).toFixed(3)+'"><input data-p="'+i+'" data-k="heading" value="'+Number(p.heading||0).toFixed(1)+'"><button data-remove="'+i+'">×</button></div>').join('');document.querySelectorAll('[data-remove]').forEach(b=>b.onclick=()=>{state.editing.points.splice(Number(b.dataset.remove),1);renderPoints()});document.querySelectorAll('[data-p]').forEach(i=>i.onchange=()=>{state.editing.points[Number(i.dataset.p)][i.dataset.k]=Number(i.value)})}
$('#save').onclick=()=>{if(!state.editing)return;state.editing.name=$('#routeName').value.trim()||state.editing.id;state.editing.loop=$('#loop').checked;post('updateRoute',{route:state.editing});closeEditor()};$('#cancel').onclick=closeEditor;$('#addPoint').onclick=()=>{const pts=state.editing.points,p=pts[pts.length-1]||{x:0,y:0,z:0,heading:0};pts.push({x:p.x,y:p.y,z:p.z,heading:p.heading});renderPoints()};function closeEditor(){state.editing=null;$('#editor').classList.remove('show')}
$('#createZone').onclick=()=>post('createZone',{type:$('#zoneType').value,radius:Number($('#zoneRadius').value)||60});
window.addEventListener('message',e=>{if(e.data.action==='open'||e.data.action==='data'){state.routes=e.data.routes||{};state.zones=e.data.zones||{};state.obstacles=e.data.obstacles||{};state.mode=e.data.mode||'normal';state.npc=e.data.npc||{};state.intelligence=e.data.intelligence||{};state.performance=e.data.performance||{};render()}});
$('#close').onclick=()=>post('close');document.addEventListener('keydown',e=>{if(e.key==='Escape')post('close')});
