import http from 'node:http';

const HOST='127.0.0.1';
const PORT=4097;
const RUNTIME_VERSION='0.3.4';
const OLLAMA='http://127.0.0.1:11434';
let selectedModel=null;
let detectedModels=[];

async function ollamaModels(){
  try{
    const response=await fetch(`${OLLAMA}/api/tags`,{signal:AbortSignal.timeout(2500)});
    if(!response.ok)return[];
    const data=await response.json();
    return Array.isArray(data?.models)?data.models.map(item=>String(item?.name??item?.model??'')).filter(Boolean):[];
  }catch{return[];}
}
function chooseModel(models){
  return models.find(name=>/^qwen3:1\.7b$/i.test(name))
    ??models.find(name=>/^qwen3:/i.test(name))
    ??models.find(name=>/^llama3\.2:3b$/i.test(name))
    ??models.find(name=>/^assistente-corso:/i.test(name))
    ??models.find(name=>/^llama3\.2:/i.test(name))
    ??models[0]??null;
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
  return [
    'Sei un revisore OCR locale rapido. Non spiegare il ragionamento.',
    'Non inventare testo, coordinate o campi. Rispondi SOLO con JSON valido.',
    'Controlla soprattutto coerenza della classe documento e falsi campi/regioni.',
    'Schema risposta:',
    '{"documentClass":"receipt|invoice|contract|book-page|blank-form|filled-form|letter|generic-document|unknown","documentClassConfidence":0.0,"structureCoherent":true,"issues":[{"code":"...","severity":"info|warning|error","message":"..."}],"regionSuggestions":[{"regionId":"...","role":"fillable-field|line-item|table-cell|total|payment|header|paragraph|signature|decorative|unknown","confidence":0.0,"reason":"..."}],"suggestedFillableFieldIds":[],"summary":"..."}',
    'INPUT:',
    JSON.stringify(request)
  ].join('\n');
}
function parseModelJson(raw){
  const clean=String(raw??'').trim().replace(/^```json\s*/i,'').replace(/^```\s*/,'').replace(/```$/,'').trim();
  try{return JSON.parse(clean);}catch{throw new Error('Ollama non ha restituito JSON valido.');}
}
async function review(request){
  const models=await ollamaModels();
  if(models.length){detectedModels=models;selectedModel=chooseModel(models);}
  if(!selectedModel)throw new Error('Ollama non disponibile o nessun modello locale compatibile.');
  const response=await fetch(`${OLLAMA}/api/chat`,{
    method:'POST',
    headers:{'Content-Type':'application/json'},
    signal:AbortSignal.timeout(22000),
    body:JSON.stringify({
      model:selectedModel,
      stream:false,
      think:false,
      keep_alive:'2m',
      messages:[{role:'user',content:promptFor(request)}],
      options:{temperature:0.1,num_ctx:2048,num_predict:420}
    })
  });
  if(!response.ok)throw new Error(`Ollama HTTP ${response.status}`);
  const data=await response.json();
  return{model:selectedModel,result:parseModelJson(data?.message?.content)};
}

const server=http.createServer(async(req,res)=>{
  cors(req,res);
  if(req.method==='OPTIONS'){res.statusCode=204;res.end();return;}
  const url=new URL(req.url||'/',`http://${HOST}:${PORT}`);
  if(req.method==='GET'&&url.pathname==='/health'){
    const models=await ollamaModels();
    if(models.length){detectedModels=models;selectedModel=chooseModel(models);}
    json(res,200,{ok:true,bridge:true,runtimeVersion:RUNTIME_VERSION,ollama:models.length>0,ollamaUrl:OLLAMA,selectedModel,models,reviewMode:'ollama-direct'});
    return;
  }
  if(req.method==='POST'&&url.pathname==='/start-ai'){
    const models=await ollamaModels();
    if(models.length){detectedModels=models;selectedModel=chooseModel(models);}
    json(res,selectedModel?200:503,{ok:Boolean(selectedModel),selectedModel,models,error:selectedModel?undefined:'Ollama non disponibile.'});
    return;
  }
  if(req.method==='POST'&&url.pathname==='/review'){
    try{
      const body=await readBody(req);
      const result=await review(body);
      json(res,200,{ok:true,...result});
    }catch(error){
      const message=error instanceof Error?error.message:String(error);
      const timeout=error instanceof DOMException&&error.name==='TimeoutError';
      json(res,timeout?504:500,{ok:false,error:timeout?'Revisione AI interrotta dopo 22 secondi per proteggere le risorse del PC.':message});
    }
    return;
  }
  json(res,404,{error:'Not found'});
});
server.on('error',error=>{console.error('OCR Local Runtime non avviato:',error.message);process.exitCode=1;});
server.listen(PORT,HOST,async()=>{
  const models=await ollamaModels();
  if(models.length){detectedModels=models;selectedModel=chooseModel(models);}
  console.log(`OCR Local Runtime ${RUNTIME_VERSION} attivo su http://${HOST}:${PORT}`);
  console.log(`AI locale: Ollama diretto su ${OLLAMA}`);
  console.log(selectedModel?`Modello selezionato: ${selectedModel} (thinking disattivato, contesto 2048)`:'Ollama non disponibile.');
});
