const resource=typeof GetParentResourceName==='function'?GetParentResourceName():'traffic';
const state={routes:{},zones:{},obstacles:{},mode:'normal',editing:null};
const $=s=>document.querySelector(s);
function post(n,d={}){fetch('https://'+resource+'/'+n,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(d)})}
function esc(v){return String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[c]))}
function render(){
 $('#mode').textContent=state.mode.toUpperCase();$('#routes').textContent=Object.keys(state.routes).length;$('#zones').textContent=Object.keys(state.zones).length;$('#obstacles').textContent=Object.keys(state.obstacles).length;
 const modes=['normal','light','heavy','stop','emergency','race'];
 $('#modes').innerHTML=modes.map(m=>'<button class="'+(m===state.mode?'active':'')+'" data-mode="'+m+'">'+m+'</button>').join('');
 $('#routeList').innerHTML=Object.values(state.routes).map(r=>'<div class="item"><div><strong>'+esc(r.name||r.id)+'</strong><small>'+((r.points||[]).length)+' points</small></div><div><button data-edit="'+esc(r.id)+'">Edit</button><button data-route="'+esc(r.id)+'">Delete</button></div></div>').join('')||'<small>No learned routes.</small>';
 $('#zoneList').innerHTML=Object.values(state.zones).map(z=>'<div class="item"><small>'+esc(z.name||z.type||z.id)+'</small><button data-zone="'+esc(z.id)+'">Delete</button></div>').join('')||'<small>No zones.</small>';
 $('#obstacleList').innerHTML=Object.values(state.obstacles).sort((a,b)=>(b.hits||0)-(a.hits||0)).slice(0,30).map(o=>'<div class="item"><div><strong>'+esc(o.hits||0)+' hits</strong><small>'+Number(o.x).toFixed(1)+', '+Number(o.y).toFixed(1)+'</small></div><button data-obstacle="'+esc(o.id)+'">Clear</button></div>').join('')||'<small>No learned hotspots yet.</small>';
 document.querySelectorAll('[data-mode]').forEach(b=>b.onclick=()=>{state.mode=b.dataset.mode;post('setMode',{mode:state.mode});render()});
 document.querySelectorAll('[data-edit]').forEach(b=>b.onclick=()=>editRoute(b.dataset.edit));
 document.querySelectorAll('[data-route]').forEach(b=>b.onclick=()=>post('deleteRoute',{id:b.dataset.route}));
 document.querySelectorAll('[data-zone]').forEach(b=>b.onclick=()=>post('deleteZone',{id:b.dataset.zone}));
 document.querySelectorAll('[data-obstacle]').forEach(b=>b.onclick=()=>post('deleteObstacle',{id:b.dataset.obstacle}));
}
function editRoute(id){
 const r=JSON.parse(JSON.stringify(state.routes[id]));if(!r)return;state.editing=r;
 $('#editor').classList.add('show');$('#routeName').value=r.name||r.id;$('#loop').checked=!!r.loop;renderPoints();
}
function renderPoints(){
 const pts=state.editing.points||[];
 $('#points').innerHTML=pts.map((p,i)=>'<div class="point"><span>#'+(i+1)+'</span><input data-p="'+i+'" data-k="x" value="'+Number(p.x).toFixed(3)+'"><input data-p="'+i+'" data-k="y" value="'+Number(p.y).toFixed(3)+'"><input data-p="'+i+'" data-k="z" value="'+Number(p.z).toFixed(3)+'"><input data-p="'+i+'" data-k="heading" value="'+Number(p.heading||0).toFixed(1)+'"><button data-remove="'+i+'">×</button></div>').join('');
 document.querySelectorAll('[data-remove]').forEach(b=>b.onclick=()=>{state.editing.points.splice(Number(b.dataset.remove),1);renderPoints()});
 document.querySelectorAll('[data-p]').forEach(i=>i.onchange=()=>{state.editing.points[Number(i.dataset.p)][i.dataset.k]=Number(i.value)});
}
$('#save').onclick=()=>{if(!state.editing)return;state.editing.name=$('#routeName').value.trim()||state.editing.id;state.editing.loop=$('#loop').checked;post('updateRoute',{route:state.editing});closeEditor()};
$('#cancel').onclick=closeEditor;
$('#addPoint').onclick=()=>{const pts=state.editing.points;const p=pts[pts.length-1]||{x:0,y:0,z:0,heading:0};pts.push({x:p.x,y:p.y,z:p.z,heading:p.heading});renderPoints()};
function closeEditor(){state.editing=null;$('#editor').classList.remove('show')}
window.addEventListener('message',e=>{
 if(e.data.action==='open'||e.data.action==='data'){state.routes=e.data.routes||{};state.zones=e.data.zones||{};state.obstacles=e.data.obstacles||{};state.mode=e.data.mode||'normal';render()}
});
$('#close').onclick=()=>post('close');document.addEventListener('keydown',e=>{if(e.key==='Escape')post('close')});
