const defaultDraft=()=>({energy:3,need:'',budget:'رایگان',duration:'۳۰ دقیقه',setting:'خانه'});
const state={partner:'a',drafts:{a:defaultDraft(),b:defaultDraft()},snapshot:null};
const $=id=>document.getElementById(id);
const energyLabels=['خیلی کم','کم','متوسط','خوب','زیاد'];
const activeDraft=()=>state.drafts[state.partner];

function syncFormFromDraft(){
  const draft=activeDraft();
  $('need').value=draft.need;
  $('budget').value=draft.budget;
  $('duration').value=draft.duration;
  $('setting').value=draft.setting;
  renderEnergy();
}

function renderEnergy(){
  const energy=activeDraft().energy;
  $('energy-options').innerHTML=energyLabels.map((label,index)=>`<button type="button" class="energy ${energy===index+1?'active':''}" data-energy="${index+1}" title="${label}">${['😴','😮‍💨','🙂','😊','⚡'][index]}</button>`).join('');
  document.querySelectorAll('.energy').forEach(button=>button.onclick=()=>{activeDraft().energy=Number(button.dataset.energy);renderEnergy();});
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
        <div class="vote-area"><button data-vote="${option.id}:2">انتخاب اول</button><button data-vote="${option.id}:1">قابل قبول</button></div>
      </article>`).join('');
    document.querySelectorAll('[data-vote]').forEach(button=>button.onclick=async()=>{
      const [optionId,value]=button.dataset.vote.split(':').map(Number);
      state.snapshot=await api(`/api/demo/votes/${state.partner}`,{method:'POST',body:JSON.stringify({optionId,value})});
      alert(`رأی ${state.partner==='a'?'نفر اول':'نفر دوم'} ثبت شد.`);
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

function switchPartner(partner){
  state.partner=partner;
  document.querySelectorAll('.tab').forEach(x=>x.classList.toggle('active',x.dataset.partner===partner));
  syncFormFromDraft();
}

document.querySelectorAll('.tab').forEach(tab=>tab.onclick=()=>switchPartner(tab.dataset.partner));
['need','budget','duration','setting'].forEach(id=>$(id).addEventListener('change',event=>{activeDraft()[id]=event.target.value;}));

$('sync-form').onsubmit=async event=>{
  event.preventDefault();
  try{
    const draft=activeDraft();
    state.snapshot=await api(`/api/demo/responses/${state.partner}`,{method:'PUT',body:JSON.stringify(draft)});
    render();
    if(!state.snapshot.ready){
      switchPartner(state.partner==='a'?'b':'a');
    } else $('reveal-card').scrollIntoView({behavior:'smooth'});
  }catch(error){alert(error.message);}
};

$('reset-button').onclick=async()=>{
  await api('/api/demo/reset',{method:'POST'});
  state.drafts={a:defaultDraft(),b:defaultDraft()};
  switchPartner('a');
  await load();
};

syncFormFromDraft();
load().catch(error=>alert(error.message));
