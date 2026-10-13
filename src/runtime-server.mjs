import http from 'node:http';
import {spawn,spawnSync} from 'node:child_process';
import {existsSync,readdirSync} from 'node:fs';
import {basename,join} from 'node:path';

const HOST='127.0.0.1';
const PORT=4097;
const RUNTIME_VERSION='0.3.7';
const LLAMA_HOST='127.0.0.1';
const LLAMA_PORT=4098;
const LLAMA_BASE=`http://${LLAMA_HOST}:${LLAMA_PORT}`;
const MODEL_FILE='qwen2.5-0.5b-instruct-q4_k_m.gguf';
const BASE=process.env.LOCALAPPDATA?join(process.env.LOCALAPPDATA,'MotoreOCR'):'.';
const MODEL_PATH=process.env.MOTORE_OCR_MODEL||join(BASE,'models',MODEL_FILE);
let childProcess=null;

const sleep=ms=>new Promise(resolve=>setTimeout(resolve,ms));

function findLlamaCommand(){
  if(process.env.MOTORE_OCR_LLAMA_SERVER&&existsSync(process.env.MOTORE_OCR_LLAMA_SERVER))return{command:process.env.MOTORE_OCR_LLAMA_SERVER,prefix:[]};
  const candidates=[];
  if(process.platform==='win32'){
    for(const name of ['llama-server','llama']){
      const found=spawnSync('where',[name],{encoding:'utf8',windowsHide:true});
      if(found.status===0){
        const first=(found.stdout||'').split(/\r?\n/).map(v=>v.trim()).find(Boolean);
        if(first)candidates.push({command:first,prefix:name==='llama'?['serve']:[]});
      }
    }
    const local=process.env.LOCALAPPDATA;
    if(local){
      candidates.push(
        {command:join(local,'Microsoft','WinGet','Links','llama-server.exe'),prefix:[]},
        {command:join(local,'Microsoft','WinGet','Links','llama.exe'),prefix:['serve']},
        {command:join(local,'Programs','llama.cpp','llama-server.exe'),prefix:[]},
        {command:join(local,'Programs','llama.cpp','llama.exe'),prefix:['serve']}
      );
    }
  }else{
    for(const name of ['llama-server','llama']){
      const found=spawnSync('which',[name],{encoding:'utf8'});
      if(found.status===0){
        const first=(found.stdout||'').split(/\r?\n/).map(v=>v.trim()).find(Boolean);
        if(first)candidates.push({command:first,prefix:name==='llama'?['serve']:[]});
      }
    }
  }
  const direct=candidates.find(item=>existsSync(item.command));
  if(direct)return direct;
  if(process.platform==='win32'&&process.env.LOCALAPPDATA){
    const wingetPackages=join(process.env.LOCALAPPDATA,'Microsoft','WinGet','Packages');
    if(existsSync(wingetPackages)){
      try{
        for(const entry of readdirSync(wingetPackages,{recursive:true,withFileTypes:true})){
          if(!entry.isFile())continue;
          const lower=entry.name.toLowerCase();
          if(lower!=='llama-server.exe'&&lower!=='llama.exe')continue;
          const command=join(entry.parentPath??entry.path,entry.name);
          if(existsSync(command))return{command,prefix:lower==='llama.exe'?['serve']:[]};
        }
      }catch(error){
        console.warn('[llama.cpp] ricerca WinGet fallita:',error instanceof Error?error.message:String(error));
      }
    }
  }
  return null;
}

async function llamaAlive(){
  try{
    const response=await fetch(`${LLAMA_BASE}/health`,{signal:AbortSignal.timeout(900)});
    return response.ok;
  }catch{return false;}
}

async function modelId(){
  try{
    const response=await fetch(`${LLAMA_BASE}/v1/models`,{signal:AbortSignal.timeout(1200)});
    if(!response.ok)return'local-model';
    const data=await response.json();
    return String(data?.data?.[0]?.id??'local-model');
  }catch{return'local-model';}
}

async function startLlama(){
  if(await llamaAlive())return{ok:true,alreadyRunning:true,model:basename(MODEL_PATH)};
  if(!existsSync(MODEL_PATH))return{ok:false,error:`Modello AI non trovato: ${MODEL_PATH}`};
  const executable=findLlamaCommand();
  if(!executable)return{ok:false,error:'llama.cpp non trovato. Reinstalla “AI locale leggera”.'};
  try{
    childProcess=spawn(executable.command,[
      ...executable.prefix,
      '-m',MODEL_PATH,
      '--host',LLAMA_HOST,
      '--port',String(LLAMA_PORT),
      '-c','1536',
      '-t','2',
      '--parallel','1'
    ],{
      windowsHide:true,
      stdio:['ignore','pipe','pipe'],
      env:{...process.env}
    });
    console.log(`[llama.cpp] comando: ${executable.command} ${executable.prefix.join(' ')}`);
    childProcess.stdout?.on('data',data=>process.stdout.write(`[llama.cpp] ${data}`));
    childProcess.stderr?.on('data',data=>process.stderr.write(`[llama.cpp] ${data}`));
    childProcess.on('error',error=>console.error('[llama.cpp] errore:',error.message));
    childProcess.on('exit',code=>{console.log('[llama.cpp] terminato con codice',code);childProcess=null;});
  }catch(error){
    return{ok:false,error:error instanceof Error?error.message:String(error)};
  }
  for(let attempt=0;attempt<30;attempt++){
    if(await llamaAlive())return{ok:true,alreadyRunning:false,model:basename(MODEL_PATH)};
    await sleep(250);
  }
  return{ok:false,error:'llama-server non ha risposto entro 7,5 secondi.'};
}

function cors(req,res){
  const origin=req.headers.origin||'*';
  res.setHeader('Access-Control-Allow-Origin',origin);
  res.setHeader('Vary','Origin');
  res.setHeader('Access-Control-Allow-Methods','GET,POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers','Content-Type');
  res.setHeader('Access-Control-Allow-Private-Network','true');
}
function json(res,status,data){
  res.statusCode=status;
  res.setHeader('Content-Type','application/json; charset=utf-8');
  res.end(JSON.stringify(data));
}
async function readBody(req){
  const chunks=[];
  for await(const chunk of req)chunks.push(chunk);
  const raw=Buffer.concat(chunks).toString('utf8');
  return raw?JSON.parse(raw):{};
}
function promptFor(request){
  return[
    'Revisore OCR locale. Rispondi SOLO con JSON valido e molto breve.',
    'Non inventare testo, coordinate, regioni o fieldId.',
    'Controlla classe documento e anomalie strutturali. Se il deterministico è coerente, confermalo senza aggiungere correzioni.',
    'Schema:',
    '{"documentClass":"receipt|invoice|contract|book-page|blank-form|filled-form|letter|generic-document|unknown","documentClassConfidence":0.0,"structureCoherent":true,"issues":[],"tokenSuggestions":[{"tokenId":"...","status":"uncertain|error|unreadable","suggestedText":"...","reason":"..."}],"regionSuggestions":[],"suggestedFillableFieldIds":[],"summary":"..."}',
    'INPUT:',
    JSON.stringify(request)
  ].join('\n');
}
function parseModelJson(raw){
  const text=String(raw??'').trim().replace(/^```json\s*/i,'').replace(/^```\s*/,'').replace(/```$/,'').trim();
  try{return JSON.parse(text);}catch{
    const start=text.indexOf('{'),end=text.lastIndexOf('}');
    if(start>=0&&end>start){try{return JSON.parse(text.slice(start,end+1));}catch{}}
    throw new Error('llama.cpp ha restituito una risposta non JSON.');
  }
}
async function review(request){
  const started=await startLlama();
  if(!started.ok)throw new Error(started.error);
  const id=await modelId();
  const response=await fetch(`${LLAMA_BASE}/v1/chat/completions`,{
    method:'POST',
    headers:{'Content-Type':'application/json'},
    signal:AbortSignal.timeout(16000),
    body:JSON.stringify({
      model:id,
      stream:false,
      temperature:0.1,
      max_tokens:220,
      messages:[{role:'user',content:promptFor(request)}]
    })
  });
  if(!response.ok){
    const detail=await response.text().catch(()=>'');
    throw new Error(`llama.cpp HTTP ${response.status}${detail?`: ${detail.slice(0,300)}`:''}`);
  }
  const data=await response.json();
  return{model:basename(MODEL_PATH),result:parseModelJson(data?.choices?.[0]?.message?.content)};
}

const server=http.createServer(async(req,res)=>{
  cors(req,res);
  if(req.method==='OPTIONS'){res.statusCode=204;res.end();return;}
  const url=new URL(req.url||'/',`http://${HOST}:${PORT}`);

  if(req.method==='GET'&&url.pathname==='/health'){
    const running=await llamaAlive();
    json(res,200,{
      ok:true,bridge:true,runtimeVersion:RUNTIME_VERSION,
      llamaCpp:running,modelInstalled:existsSync(MODEL_PATH),
      selectedModel:existsSync(MODEL_PATH)?basename(MODEL_PATH):null,
      reviewMode:'llama.cpp-light',threads:2,context:1536
    });
    return;
  }
  if(req.method==='POST'&&url.pathname==='/start-ai'){
    const result=await startLlama();
    json(res,result.ok?200:503,result);
    return;
  }
  if(req.method==='POST'&&url.pathname==='/review'){
    try{
      const result=await review(await readBody(req));
      json(res,200,{ok:true,...result});
    }catch(error){
      const timeout=error instanceof DOMException&&(error.name==='TimeoutError'||error.name==='AbortError');
      json(res,timeout?504:500,{ok:false,error:timeout?'Revisione AI interrotta dopo 16 secondi per proteggere le risorse del PC.':error instanceof Error?error.message:String(error)});
    }
    return;
  }
  json(res,404,{error:'Not found'});
});

server.on('error',error=>{console.error('OCR Local Runtime non avviato:',error.message);process.exitCode=1;});
server.listen(PORT,HOST,async()=>{
  console.log(`OCR Local Runtime ${RUNTIME_VERSION} attivo su http://${HOST}:${PORT}`);
  console.log(`AI leggera: llama.cpp su ${LLAMA_BASE}`);
  console.log(`Modello: ${MODEL_PATH}`);
  const result=await startLlama();
  if(result.ok)console.log('AI locale leggera pronta.');
  else console.log('AI locale non avviata:',result.error);
});
