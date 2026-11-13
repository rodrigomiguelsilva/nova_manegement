const app=document.getElementById('app');let state={jobs:[],grades:[],doors:{}},pendingDelete=null,toastTimer;
const resource=()=>GetParentResourceName();
function post(name,data={}){return fetch(`https://${resource()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json; charset=UTF-8'},body:JSON.stringify(data)});}
window.addEventListener('message',e=>{if(e.data.action==='open'){state=e.data.data||state;render();app.classList.remove('hidden')}if(e.data.action==='close')app.classList.add('hidden')});
function close(){app.classList.add('hidden');post('close')}
document.getElementById('close').onclick=close;
document.addEventListener('keydown',e=>{if(e.key==='Escape'){if(!document.getElementById('confirmModal').classList.contains('hidden'))hideModal();else close()}});
document.querySelectorAll('.nav-item').forEach(b=>b.onclick=()=>{document.querySelectorAll('.nav-item,.panel').forEach(x=>x.classList.remove('active'));b.classList.add('active');document.getElementById(b.dataset.tab).classList.add('active');document.getElementById('pageTitle').textContent=b.dataset.tab==='jobs'?'Gestão de empregos':'Gestão de doorlocks'});
function render(){renderJobs();renderDoors()}
function renderJobs(){
 const el=document.getElementById('jobList');el.innerHTML='';const jobs=state.jobs||[];const allGrades=state.grades||[];
 document.getElementById('jobCount').textContent=jobs.length;document.getElementById('gradeCount').textContent=allGrades.length;document.getElementById('jobListCount').textContent=jobs.length+' REGISTOS';
 jobs.forEach(j=>{
  const gs=allGrades.filter(g=>g.job_name===j.name).sort((a,b)=>Number(a.grade)-Number(b.grade));
  const div=document.createElement('div');div.className='item job-item';
  div.innerHTML=`<div class="item-main"><div class="item-icon">▦</div><div><strong>${esc(j.label)}</strong><small>${esc(j.name)}</small></div></div><div class="item-actions"><span class="tag-count">${gs.length} RANKS</span><button class="ghost edit-job">Ver / editar grades</button><button class="danger">Eliminar</button></div><div class="job-grade-editor hidden"><div class="grade-heading"><b>Grades de ${esc(j.label)}</b><button type="button" class="text-btn add-edit-grade">＋ Adicionar grade</button></div><div class="edit-grade-rows"></div><div class="form-actions"><button type="button" class="ghost cancel-edit">Fechar</button><button type="button" class="primary save-edit">Guardar alterações →</button></div></div>`;
  const editor=div.querySelector('.job-grade-editor'), rows=div.querySelector('.edit-grade-rows');
  const addEdit=(g={})=>{const row=document.createElement('div');row.className='grade';row.dataset.grade=String(g.grade??rows.children.length);row.innerHTML=`<input class="g-name" placeholder="nome interno" value="${esc(g.name||'')}"><input class="g-label" placeholder="Nome do cargo" value="${esc(g.label||'')}"><input class="g-salary" type="number" min="0" placeholder="Salário" value="${Number(g.salary)||0}"><button type="button" title="Remover grade">×</button>`;row.querySelector('button').onclick=()=>row.remove();rows.appendChild(row)};
  gs.forEach(g=>addEdit(g));
  div.querySelector('.edit-job').onclick=()=>editor.classList.toggle('hidden');
  div.querySelector('.add-edit-grade').onclick=()=>addEdit({name:'',label:'',salary:0});
  div.querySelector('.cancel-edit').onclick=()=>editor.classList.add('hidden');
  div.querySelector('.save-edit').onclick=()=>{const edited=[...rows.children].map((r,i)=>({grade:i,name:r.querySelector('.g-name').value.trim(),label:r.querySelector('.g-label').value.trim(),salary:Number(r.querySelector('.g-salary').value)||0}));if(!edited.length||edited.some(g=>!g.name||!g.label)){showToast('Cada job tem de ter pelo menos um grade e todos os campos preenchidos.');return}post('updateJob',{name:j.name,label:j.label,grades:edited});showToast('Alterações enviadas.');};
  div.querySelector('.danger').onclick=()=>showDelete('job',j.name,j.label);el.appendChild(div);
 });
 if(!el.children.length)el.innerHTML='<div class="empty">Ainda não existem empregos registados.</div>'
}
function renderDoors(){const el=document.getElementById('doorList');el.innerHTML='';const doors=Object.values(state.doors||{});document.getElementById('doorCount').textContent=doors.length;document.getElementById('doorListCount').textContent=doors.length+' REGISTOS';doors.forEach(d=>{let div=document.createElement('div');div.className='item';let jobs=(d.jobs||[]).join(', ')||'Todos os empregos';div.innerHTML=`<div class="item-main"><div class="item-icon">▣</div><div><strong>${esc(d.label)}</strong><small>ID ${d.id} · ${esc(jobs)} · ${d.locked?'Fechada':'Aberta'}</small></div></div><div class="item-actions"><span class="tag-count">${d.locked?'BLOQUEADA':'ABERTA'}</span><button class="danger">Eliminar</button></div>`;div.querySelector('button').onclick=()=>showDelete('door',d.id,d.label);el.appendChild(div)});if(!el.children.length)el.innerHTML='<div class="empty">Ainda não existem fechaduras registadas.</div>'}
function esc(s){return String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
function showToast(msg){const t=document.getElementById('toast');t.textContent=msg;t.classList.remove('hidden');clearTimeout(toastTimer);toastTimer=setTimeout(()=>t.classList.add('hidden'),3000)}
function showDelete(type,id,label){pendingDelete={type,id};document.getElementById('modalTitle').textContent=type==='job'?'Eliminar emprego':'Eliminar fechadura';document.getElementById('modalText').textContent=`Tens a certeza de que pretendes eliminar "${label}"? Esta ação não pode ser revertida.`;document.getElementById('confirmModal').classList.remove('hidden')}
function hideModal(){document.getElementById('confirmModal').classList.add('hidden');pendingDelete=null}
document.getElementById('modalCancel').onclick=hideModal;
document.getElementById('modalConfirm').onclick=()=>{if(!pendingDelete)return;const item=pendingDelete;hideModal();if(item.type==='job')post('deleteJob',{name:item.id});else post('deleteDoor',{id:item.id});showToast('Pedido de eliminação enviado.')};
const grades=document.getElementById('grades');
function addGrade(name='',label='',salary=0){let row=document.createElement('div');row.className='grade';row.innerHTML=`<input placeholder="nome interno" value="${esc(name)}"><input placeholder="Nome do cargo" value="${esc(label)}"><input type="number" min="0" placeholder="Salário" value="${salary}"><button type="button" title="Remover cargo">×</button>`;row.querySelector('button').onclick=()=>row.remove();grades.appendChild(row)}
document.getElementById('showJobForm').onclick=()=>{document.getElementById('jobForm').classList.remove('hidden');if(!grades.children.length)addGrade('employee','Employee',0)};
document.getElementById('cancelJob').onclick=()=>{document.getElementById('jobForm').classList.add('hidden');grades.innerHTML=''};
document.getElementById('addGrade').onclick=()=>addGrade();
document.getElementById('createJob').onclick=()=>{let name=document.getElementById('jobName').value.trim(),label=document.getElementById('jobLabel').value.trim();let gs=[...grades.children].map(r=>({name:r.children[0].value.trim(),label:r.children[1].value.trim(),salary:Number(r.children[2].value)}));if(!name||!label||!gs.length||gs.some(g=>!g.name||!g.label)){showToast('Preenche todos os campos dos cargos.');return}post('createJob',{name,label,grades:gs});document.getElementById('jobForm').classList.add('hidden');grades.innerHTML='';document.getElementById('jobName').value='';document.getElementById('jobLabel').value='';showToast('Pedido de criação enviado.')};
document.getElementById('showDoorForm').onclick=()=>document.getElementById('doorForm').classList.remove('hidden');
document.getElementById('cancelDoor').onclick=()=>document.getElementById('doorForm').classList.add('hidden');
document.getElementById('createDoor').onclick=()=>{let label=document.getElementById('doorLabel').value.trim();if(!label){showToast('Indica o nome da porta.');return}let jobs=document.getElementById('doorJobs').value.split(',').map(x=>x.trim()).filter(Boolean);post('addDoor',{label,jobs});document.getElementById('doorForm').classList.add('hidden');document.getElementById('doorLabel').value='';document.getElementById('doorJobs').value='';showToast('Pedido de criação da porta enviado.')};
