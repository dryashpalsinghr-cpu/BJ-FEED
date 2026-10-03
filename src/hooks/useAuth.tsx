import {createContext,useContext,useEffect,useState,ReactNode} from 'react';
import type {Role} from '../types';import {demo,supabase} from '../lib/supabase';
type Auth={role:Role|null;userId:string|null;name:string;loading:boolean;login:(email:string,password:string)=>Promise<void>;logout:()=>Promise<void>;demoLogin:(role:Role)=>void};
const Context=createContext<Auth>(null!);
export function AuthProvider({children}:{children:ReactNode}){
 const [role,setRole]=useState<Role|null>(()=>demo?(sessionStorage.getItem('demo-role') as Role|null):null),[userId,setUser]=useState<string|null>(demo?'10000000-0000-4000-8000-000000000502':null),[name,setName]=useState('Owner'),[loading,setLoading]=useState(!demo&&!!supabase);
 useEffect(()=>{if(demo||!supabase)return;let alive=true;let generation=0;async function load(id?:string){const g=++generation;setRole(null);setUser(id??null);if(id){const [r,p]=await Promise.all([supabase!.from('user_roles').select('role').eq('user_id',id).single(),supabase!.from('profiles').select('name,active').eq('id',id).single()]);if(!alive||g!==generation)return;if(p.data?.active&&r.data){setRole(r.data.role);setName(p.data.name);}}if(alive&&g===generation)setLoading(false);}
 supabase.auth.getSession().then(({data})=>load(data.session?.user.id));const {data:{subscription}}=supabase.auth.onAuthStateChange((_event,session)=>{setTimeout(()=>{if(alive)void load(session?.user.id)},0)});return()=>{alive=false;subscription.unsubscribe();};},[]);
 return <Context.Provider value={{role,userId,name,loading,login:async(email,password)=>{if(!supabase)throw new Error('Backend not configured. Follow the README setup steps.');const {error}=await supabase.auth.signInWithPassword({email,password});if(error)throw error;},logout:async()=>{if(demo)sessionStorage.removeItem('demo-role');else await supabase?.auth.signOut();setRole(null);setUser(null);},demoLogin:r=>{setName(r==='owner'?'Business Owner':r==='staff'?'Staff Member':'Suresh Kumar');setRole(r);setUser('10000000-0000-4000-8000-000000000502');sessionStorage.setItem('demo-role',r);}}}>{children}</Context.Provider>;
}
export const useAuth=()=>useContext(Context);
