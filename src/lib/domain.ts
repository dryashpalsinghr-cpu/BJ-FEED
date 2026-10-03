import type {Line,Status,Appliance} from '../types';
export const statusLabels:Record<Status,string>={pending:'Pending',scheduled:'Visit scheduled',waiting_part:'Part not available',in_progress:'Work in progress',completed:'Completed',cancelled:'Cancelled'};
export const appliances:Record<Appliance,string>={ac:'AC',washing:'Washing machine',microwave:'Microwave',other:'Other appliance'};
export const money=(n:number|string)=>new Intl.NumberFormat('en-IN',{style:'currency',currency:'INR',maximumFractionDigits:2}).format(Number(n)||0);
export const date=(s:string)=>s?new Date(s).toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'}):'—';
export const datetime=(s:string)=>new Date(s).toLocaleString('en-IN',{day:'numeric',month:'short',hour:'2-digit',minute:'2-digit'});
export function localDay(d:Date){return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;}
export const today=()=>localDay(new Date());
export function addMonths(n:number){const d=new Date();const day=d.getDate();d.setDate(1);d.setMonth(d.getMonth()+n);d.setDate(Math.min(day,new Date(d.getFullYear(),d.getMonth()+1,0).getDate()));return localDay(d);}
export const validMobile=(s:string)=>/^[6-9]\d{9}$/.test(s);
export const wa=(mobile:string,text:string)=>'https:'+'//wa.me/91'+mobile.replace(/\D/g,'').slice(-10)+'?text='+encodeURIComponent(text);
export const sms=(mobile:string,text:string)=>`sms:+91${mobile}?body=${encodeURIComponent(text)}`;
export function totals(items:Line[],service=0,discount=0,gst=0){const subtotal=items.reduce((a,b)=>a+b.quantity*b.unit_price,0);const base=Math.max(0,subtotal+service-discount);const tax=Math.round((base*gst/100+Number.EPSILON)*100)/100;return {subtotal,tax,total:Math.round((base+tax+Number.EPSILON)*100)/100};}
export function personalize(text:string,name:string,shop:string,offer:string){return text.replaceAll('{name}',name).replaceAll('{shop}',shop).replaceAll('{offer}',offer);}
export function errorHindi(error:unknown){return errorMessage(error)}
export function errorMessage(error:unknown){const m=error instanceof Error?error.message:String(error);if(m.includes('LOW_STOCK'))return 'Not enough stock. Reduce quantity or add stock first.';if(m.includes('OVERPAYMENT'))return 'The payment exceeds the balance. Check the amount.';if(m.includes('GST_REQUIRED'))return 'Add your GST number in Settings before charging GST.';if(m.includes('ACCESS_DENIED')||m.includes('row-level'))return 'Your account does not have permission. Contact the owner.';if(m.includes('Invalid login'))return 'Incorrect email or password. Check your details and try again.';if(m.includes('INVALID_'))return 'Some details are invalid. Check the fields and try again.';if(m.includes('fetch')||m.includes('network'))return 'Connection failed. Check your internet and retry.';return /[\u0900-\u097f]/.test(m)?'Unable to save. Check the details and connection, then retry.':m||'Unable to save. Please retry.';}
