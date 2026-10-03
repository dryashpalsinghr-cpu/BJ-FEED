import {createClient} from '@supabase/supabase-js';
export const demo=import.meta.env.VITE_DEMO_MODE==='true';
export const configured=!!(import.meta.env.VITE_SUPABASE_URL&&import.meta.env.VITE_SUPABASE_ANON_KEY);
export const supabase=configured?createClient(import.meta.env.VITE_SUPABASE_URL,import.meta.env.VITE_SUPABASE_ANON_KEY,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}}):null;
export async function portal(p:Record<string,unknown>|FormData){if(!supabase)throw new Error('Backend not configured. Contact the owner.');const {data,error}=await supabase.functions.invoke('public-portal',{body:p});if(error){let message='Unable to contact the service. Check your connection and retry.';try{const json=await error.context.json();if(json.error)message=json.error;}catch{}throw new Error(message);}if(data?.error)throw new Error(data.error);return data;}
