import {createClient} from 'https://esm.sh/@supabase/supabase-js@2.49.1';
import {reply,checkOrigin,cors} from '../_shared/http.ts';
const db=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
Deno.serve(async req=>{if(req.method==='OPTIONS')return new Response('ok',{headers:cors(req)});if(req.method!=='POST'||!checkOrigin(req))return reply(req,{error:'Invalid request. Check your details and retry.'},403);
 try{
 const ip=req.headers.get('x-forwarded-for')?.split(',')[0]??'unknown';
 const hash=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(ip)))).map(x=>x.toString(16).padStart(2,'0')).join('');
 const rate=await db.rpc('consume_rate',{k:'ip:'+hash,maximum:30,seconds:3600});if(rate.error||!rate.data)return reply(req,{error:'Too many requests. Try again in one hour.'},429);
 const contentType=req.headers.get('content-type')??'';
 if(contentType.includes('multipart/form-data')){
 const f=await req.formData(),file=f.get('file'),id=f.get('id')?.toString(),token=f.get('token')?.toString();
 if(!(file instanceof File)||file.size>5*1024*1024||!['image/jpeg','image/png','image/webp'].includes(file.type))return reply(req,{error:'Choose a JPG, PNG or WebP photo under 5 MB.'},400);
 const bytes=new Uint8Array(await file.slice(0,16).arrayBuffer());const validMagic=file.type==='image/jpeg'?bytes[0]===255&&bytes[1]===216:file.type==='image/png'?bytes[0]===137&&bytes[1]===80&&bytes[2]===78&&bytes[3]===71:bytes[0]===82&&bytes[1]===73&&bytes[2]===70&&bytes[3]===70&&bytes[8]===87&&bytes[9]===69&&bytes[10]===66&&bytes[11]===80;if(!validMagic)return reply(req,{error:'The file is not a valid image. Choose a JPG, PNG or WebP photo.'},400);
 const {data:job}=await db.from('complaints').select('id').eq('id',id).eq('public_upload_token',token).gt('created_at',new Date(Date.now()-30*60*1000).toISOString()).maybeSingle();if(!job)return reply(req,{error:'Photo upload link expired. Contact the shop.'},403);
 // Per-job lock and count are enforced again by SQL registration; orphan cleanup is documented.
 const path=`${id}/${crypto.randomUUID()}.${file.type.split('/')[1]}`;
 const uploaded=await db.storage.from('complaint-photos').upload(path,file);if(uploaded.error)throw uploaded.error;
 const inserted=await db.rpc('register_public_photo',{j:id,t:token,p:path});if(inserted.error){await db.storage.from('complaint-photos').remove([path]);return reply(req,{error:'You can upload up to 3 photos.'},400);}return reply(req,{ok:true});
 }
 const body=await req.text();if(body.length>24000)return reply(req,{error:'The request is too long. Shorten your description.'},400);const p=JSON.parse(body);
 if(p.action==='submit'){
 if(p.website)return reply(req,{error:'Request rejected. Contact the shop if it persists.'},400);
 if(!/^[6-9]\d{9}$/.test(p.mobile??'')||typeof p.name!=='string'||p.name.trim().length<2||p.name.length>120||typeof p.address!=='string'||p.address.length<8||p.address.length>1500||typeof p.issue!=='string'||p.issue.length<5||p.issue.length>5000||!['ac','washing','microwave','other'].includes(p.appliance)||String(p.brand??'').length>200)return reply(req,{error:'Enter a name, valid 10-digit mobile, address and issue description.'},400);
 const {data,error}=await db.rpc('submit_public_job',{p});if(error)return reply(req,{error:error.message.includes('RATE_LIMIT')?'Too many complaints from this number. Try again in one hour.':'Unable to save complaint. Check details or call the shop.'},400);return reply(req,data);
 }
 if(p.action==='track'){
 if(!/^[6-9]\d{9}$/.test(p.mobile??'')||!/^BE-\d{4,10}$/.test(p.number??''))return reply(req,{error:'Check the mobile and complaint number.'},400);
 const {data:c}=await db.from('customers').select('id').eq('mobile',p.mobile).maybeSingle();
 const {data:j}=c?await db.from('complaints').select('id,number,status,appliance,created_at').eq('customer_id',c.id).eq('number',p.number).maybeSingle():{data:null};
 if(!j)return reply(req,{error:'Complaint not found. Check the numbers or call us.'},404);
 const {data:timeline}=await db.from('complaint_status_history').select('status,created_at').eq('complaint_id',j.id).order('created_at');return reply(req,{number:j.number,status:j.status,appliance:j.appliance,timeline});
 }
 if(p.action==='feedback'){
 if(!/^[0-9a-f-]{36}$/i.test(p.token??'')||![1,2,3,4,5].includes(p.rating)||String(p.comment??'').length>1000)return reply(req,{error:'Choose a rating from 1 to 5.'},400);
 const {data:j}=await db.from('complaints').select('id').eq('feedback_token',p.token).eq('status','completed').maybeSingle();if(!j)return reply(req,{error:'This feedback link is not valid.'},404);
 const {error}=await db.from('feedback').insert({complaint_id:j.id,rating:p.rating,comment:p.comment??''});if(error)return reply(req,{error:'Feedback has already been submitted.'},409);return reply(req,{ok:true});
 }return reply(req,{error:'Invalid request. Check your details and retry.'},400);
 }catch{return reply(req,{error:'Service unavailable. Try again shortly.'},500);}
});
