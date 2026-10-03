import {createClient} from 'https://esm.sh/@supabase/supabase-js@2.49.1';
import {reply,cors,checkOrigin} from '../_shared/http.ts';
Deno.serve(async req=>{if(req.method==='OPTIONS')return new Response('ok',{headers:cors(req)});if(!checkOrigin(req))return reply(req,{error:'Request rejected. Contact the shop if it persists.'},403);
 const url=Deno.env.get('SUPABASE_URL')!,key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,admin=createClient(url,key);
 const token=(req.headers.get('Authorization')??'').replace('Bearer ','');const {data:{user}}=await admin.auth.getUser(token);if(!user)return reply(req,{error:'Sign in again to continue.'},401);
 const {data:role}=await admin.from('user_roles').select('role').eq('user_id',user.id).single();const {data:profile}=await admin.from('profiles').select('active').eq('id',user.id).single();if(role?.role!=='owner'||!profile?.active)return reply(req,{error:'Only the owner can do this.'},403);
 try{const p=await req.json();
 if(p.action==='role'){if(p.id===user.id||!['owner','staff','technician'].includes(p.role))return reply(req,{error:'Cannot change your own role, or the role is invalid.'},400);const {data:target,error:te}=await admin.from('profiles').select('name,mobile').eq('id',p.id).single();if(te||!target)throw te;const change=await admin.rpc('set_team_role',{u:p.id,r:p.role,n:target.name,m:target.mobile??''});if(change.error)throw change.error;return reply(req,{ok:true});}
 if(p.action==='disable'){if(p.id===user.id)return reply(req,{error:'You cannot disable your own account.'},400);const a=await admin.auth.admin.updateUserById(p.id,{ban_duration:p.active?'none':'876000h'});if(a.error)throw a.error;const b=await admin.from('profiles').update({active:!!p.active}).eq('id',p.id);if(b.error)throw b.error;return reply(req,{ok:true});}
 if(!['owner','staff','technician'].includes(p.role)||typeof p.name!=='string'||!p.name.trim()||p.password?.length<12||!/^\S+@\S+\.\S+$/.test(p.email))return reply(req,{error:'Enter a name, email and password with at least 12 characters.'},400);
 const a=await admin.auth.admin.createUser({email:p.email,password:p.password,email_confirm:true});if(a.error)throw a.error;const id=a.data.user.id;
 try{
 const b=await admin.from('profiles').insert({id,name:p.name,mobile:p.mobile});if(b.error)throw b.error;const c=await admin.from('user_roles').insert({user_id:id,role:p.role});if(c.error)throw c.error;
 if(p.role==='technician'){const d=await admin.from('technicians').insert({user_id:id,name:p.name,mobile:p.mobile});if(d.error)throw d.error;}
 }catch(e){await admin.auth.admin.deleteUser(id);throw e;}return reply(req,{ok:true});
 }catch{return reply(req,{error:'Unable to save account. Check the email and details.'},400);}
});
