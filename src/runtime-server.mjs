import http from 'node:http';
import {spawn,spawnSync} from 'node:child_process';

const HOST='127.0.0.1';
const PORT=4097;
const RUNTIME_VERSION='0.3.3';
const OPENCODE_HOST='127.0.0.1';
const OPENCODE_PORT=4098;
const OPENCODE=`http://${OPENCODE_HOST}:${OPENCODE_PORT}`;
const OLLAMA='http://127.0.0.1:11434';
let spawned=false;
let selectedModel=null;
let detectedModels=[];
const sleep=ms=>new Promise(resolve=>setTimeout(resolve,ms));

async function ollamaModels(){
  try{
    const response=await fetch(`${OLLAMA}/api/tags`,{signal:AbortSignal.timeout(2500)});
    if(!response.ok)return[];
    const data=await response.json();
    return Array.isArray(data?.models)
      ? data.models.map(item=>String(item?.name??item?.model??'')).filter(Boolean)
      : [];
  }catch{return[];}
}

function chooseModel(models){
  return models.find(name=>/^qwen3:/i.test(name))
    ??models.find(name=>/^assistente-corso:/i.test(name))
    ??models.find(name=>/^llama3\.2:3b$/i.test(name))
    ??models.find(name=>/^llama3\.2:/i.test(name))
    ??models[0]
    ??null;
}

function buildOpenCodeConfig(models,model){
  const mapped=Object.fromEntries(models.map(name=>[name,{name:`${name} (Ollama local)`}]));
  return{
    $schema:'https://opencode.ai/config.json',
    model:model?`ollama/${model}`:undefined,
    provider:{
      ollama:{
        npm:'@ai-sdk/openai-compatible',
        name:'Ollama local',
        options:{baseURL:'http://127.0.0.1:11434/v1'},
        models:mapped
      }
    }
  };
}

async function openCodeAlive(){
  try{
    const response=await fetch(`${OPENCODE}/global/health`,{signal:AbortSignal.timeout(1500)});
    return response.ok;
  }catch{return false;}
}

function findOpenCodeCommand(){
  if(process.platform==='win32'){
    const found=spawnSync('where',['opencode'],{encoding:'utf8',windowsHide:true});
    if(found.status===0){
      const first=(found.stdout||'').split(/\r?\n/).map(value=>value.trim()).find(Boolean);
      if(first)return first;
    }
    const roaming=process.env.APPDATA;
    if(roaming){
      const candidate=roaming+'\\npm\\opencode.cmd';
      const probe=spawnSync('cmd.exe',['/d','/c','if exist "'+candidate+'" (exit 0) else (exit 1)'],{windowsHide:true});
      if(probe.status===0)return candidate;
    }
    return 'opencode.cmd';
  }
  const found=spawnSync('which',['opencode'],{encoding:'utf8'});
  if(found.status===0){
    const first=(found.stdout||'').split(/\r?\n/).map(value=>value.trim()).find(Boolean);
    if(first)return first;
  }
  return 'opencode';
}

async function startOpenCode(){
  detectedModels=await ollamaModels();
  selectedModel=chooseModel(detectedModels);
  if(!selectedModel){
    return{ok:false,error:'Ollama non risponde su 127.0.0.1:11434 oppure non contiene modelli installati.'};
  }

  if(await openCodeAlive()){
    return{ok:true,alreadyRunning:true,selectedModel,models:detectedModels};
  }

  const command=findOpenCodeCommand();
  const config=buildOpenCodeConfig(detectedModels,selectedModel);
  try{
    const child=spawn(command,['serve','--hostname',OPENCODE_HOST,'--port',String(OPENCODE_PORT)],{
      windowsHide:false,
      stdio:['ignore','pipe','pipe'],
      shell:process.platform==='win32',
      env:{
        ...process.env,
        OPENCODE_CONFIG_CONTENT:JSON.stringify(config),
        OPENCODE_DISABLE_AUTOUPDATE:'true'
      }
    });
    spawned=true;
    child.stdout?.on('data',data=>process.stdout.write(`[OpenCode/Ollama] ${data}`));
    child.stderr?.on('data',data=>process.stderr.write(`[OpenCode/Ollama] ${data}`));
    child.on('error',error=>console.error('[OpenCode/Ollama] errore:',error.message));
    child.on('exit',code=>console.log('[OpenCode/Ollama] terminato con codice',code));
  }catch(error){
    return{ok:false,error:error instanceof Error?error.message:String(error),command};
  }

  for(let attempt=0;attempt<40;attempt++){
    if(await openCodeAlive()){
      return{ok:true,alreadyRunning:false,command,selectedModel,models:detectedModels};
    }
    await sleep(500);
  }
  return{ok:false,error:'OpenCode locale dedicato non ha risposto sulla porta 4098 entro 20 secondi.',command,selectedModel};
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

async function proxy(req,res,path){
  try{
    const body=req.method==='GET'?undefined:await readBody(req);
    const response=await fetch(`${OPENCODE}${path}`,{
      method:req.method,
      headers:req.method==='GET'?undefined:{'Content-Type':'application/json'},
      body:req.method==='GET'?undefined:JSON.stringify(body)
    });
    const text=await response.text();
    res.statusCode=response.status;
    res.setHeader('Content-Type',response.headers.get('content-type')||'application/json; charset=utf-8');
    res.end(text);
  }catch(error){
    json(res,502,{error:error instanceof Error?error.message:String(error)});
  }
}

const server=http.createServer(async(req,res)=>{
  cors(req,res);
  if(req.method==='OPTIONS'){res.statusCode=204;res.end();return;}
  const url=new URL(req.url||'/',`http://${HOST}:${PORT}`);

  if(req.method==='GET'&&url.pathname==='/health'){
    const models=await ollamaModels();
    if(models.length){
      detectedModels=models;
      selectedModel=chooseModel(models);
    }
    json(res,200,{
      ok:true,
      bridge:true,
      runtimeVersion:RUNTIME_VERSION,
      openCode:await openCodeAlive(),
      openCodePort:OPENCODE_PORT,
      ollama:models.length>0,
      ollamaUrl:OLLAMA,
      selectedModel,
      models
    });
    return;
  }

  if(req.method==='POST'&&url.pathname==='/start-ai'){
    const result=await startOpenCode();
    json(res,result.ok?200:500,result);
    return;
  }

  if(url.pathname==='/opencode/global/health'&&req.method==='GET'){
    await proxy(req,res,'/global/health');return;
  }
  if(url.pathname==='/opencode/provider'&&req.method==='GET'){
    await proxy(req,res,'/provider');return;
  }
  if(url.pathname==='/opencode/session'&&(req.method==='GET'||req.method==='POST')){
    await proxy(req,res,'/session');return;
  }
  const match=url.pathname.match(/^\/opencode\/session\/([^/]+)\/message$/);
  if(match&&req.method==='POST'){
    await proxy(req,res,`/session/${encodeURIComponent(decodeURIComponent(match[1]))}/message`);
    return;
  }

  json(res,404,{error:'Not found'});
});

server.on('error',error=>{
  console.error('OCR Local Runtime non avviato:',error.message);
  process.exitCode=1;
});

server.listen(PORT,HOST,async()=>{
  console.log(`OCR Local Runtime ${RUNTIME_VERSION} attivo su http://${HOST}:${PORT}`);
  console.log(`Ollama atteso su ${OLLAMA}`);
  console.log(`OpenCode dedicato usera la porta ${OPENCODE_PORT}`);
  const result=await startOpenCode();
  if(result.ok){
    console.log(`AI locale pronta: Ollama/${result.selectedModel} via OpenCode ${OPENCODE_PORT}`);
  }else{
    console.error('AI locale non avviata:',result.error);
  }
});
