const state={partner:'a',energy:3,snapshot:null};
const $=id=>document.getElementById(id);
const energyLabels=['خیلی کم','کم','متوسط','خوب','زیاد'];

function renderEnergy(){
  $('energy-options').innerHTML=energyLabels.map((label,index)=>`<button type="button" class="energy ${state.energy===index+1?'active':''}" data-energy="${index+1}" title="${label}">${['😴','😮‍💨','🙂','😊','⚡'][index]}</button>`).join('');
  document.querySelectorAll('.energy').forEach(button=>button.onclick=()=>{state.energy=Number(button.dataset.energy);renderEnergy();});
}

async function api(path,options={}){
  const response=await fetch(path,{headers:{'Content-Type':'application/json'},...options});
  if(!response.ok){const error=await response.json().catch(()=>({message:'خطایی رخ داد'}));throw new Error(error.message||'خطایی رخ داد');}
  return response.status===204?null:response.json();
}

async function load(){state.snapshot=await api('/api/demo');render();}

function render(){
  const s=state.snapshot;
  $('status-a').textContent=`نفر اول: ${s.responseStatus.a?'ثبت شد ✓':'منتظر پاسخ'}`;
  $('status-b').textContent=`نفر دوم: ${s.responseStatus.b?'ثبت شد ✓':'منتظر پاسخ'}`;
  $('reveal-card').classList.toggle('hidden',!s.ready);
  $('options-section').classList.toggle('hidden',!s.ready);
  if(s.ready){
    $('reveal-title').textContent=s.reveal.title;
    $('reveal-summary').textContent=s.reveal.summary;
    $('reveal-note').textContent=s.reveal.note;
    $('options').innerHTML=s.options.map(option=>`
      <article class="option">
        <div class="option-head"><div><span class="badge">${option.type}</span><h2>${option.title}</h2></div><span class="meta">${option.duration} · بودجه ${option.budget}</span></div>
        <p>${option.instructions}</p>
        <div class="vote-area">
          <button data-vote="${option.id}:2">انتخاب اول</button>
          <button data-vote="${option.id}:1">قابل قبول</button>
        </div>
      </article>`).join('');
    document.querySelectorAll('[data-vote]').forEach(button=>button.onclick=async()=>{
      const [optionId,value]=button.dataset.vote.split(':').map(Number);
      state.snapshot=await api(`/api/demo/votes/${state.partner}`,{method:'POST',body:JSON.stringify({optionId,value})});
      alert(`رأی ${state.partner==='a'?'نفر اول':'نفر دوم'} ثبت شد. حالا تب نفر دیگر را انتخاب کنید.`);
      render();
    });
  }
  const hasResult=Boolean(s.match||s.selectedOptionId);
  $('result-card').classList.toggle('hidden',!hasResult);
  if(hasResult){
    const selected=s.options.find(x=>x.id===s.selectedOptionId)||s.match;
    $('match-result').innerHTML=`<div class="match"><span class="badge">Match</span><h2>${selected.title}</h2><p>${selected.instructions}</p>${s.selectedOptionId?' <strong>برای این هفته انتخاب شد ✓</strong>':`<button class="select-button" id="confirm-selection">انتخاب این برنامه</button>`}</div>`;
    const confirm=$('confirm-selection');
    if(confirm)confirm.onclick=async()=>{state.snapshot=await api(`/api/demo/select/${selected.id}`,{method:'POST'});render();};
  }
}

document.querySelectorAll('.tab').forEach(tab=>tab.onclick=()=>{
  state.partner=tab.dataset.partner;
  document.querySelectorAll('.tab').forEach(x=>x.classList.toggle('active',x===tab));
});

$('sync-form').onsubmit=async event=>{
  event.preventDefault();
  try{
    state.snapshot=await api(`/api/demo/responses/${state.partner}`,{method:'PUT',body:JSON.stringify({
      energy:state.energy,need:$('need').value,budget:$('budget').value,duration:$('duration').value,setting:$('setting').value
    })});
    render();
    if(!state.snapshot.ready){
      const next=state.partner==='a'?'b':'a';
      document.querySelector(`[data-partner="${next}"]`).click();
      $('need').value='';
    } else $('reveal-card').scrollIntoView({behavior:'smooth'});
  }catch(error){alert(error.message);}
};

$('reset-button').onclick=async()=>{await api('/api/demo/reset',{method:'POST'});state.partner='a';document.querySelector('[data-partner="a"]').click();state.energy=3;renderEnergy();await load();};

renderEnergy();
load().catch(error=>alert(error.message));