// Application-facing schema. Regenerate canonical Supabase types after migrations:
// supabase gen types typescript --project-id YOUR_ID > src/lib/generated.database.types.ts
import type {Tables} from '../types';
export type Database={public:{Tables:{[K in keyof Tables]:{Row:Tables[K];Insert:Partial<Tables[K]>;Update:Partial<Tables[K]>;Relationships:[]}};Views:Record<string,never>;Functions:Record<string,{Args:Record<string,unknown>;Returns:unknown}>;Enums:{app_role:'owner'|'staff'|'technician';job_status:'pending'|'scheduled'|'waiting_part'|'in_progress'|'completed'|'cancelled'};CompositeTypes:Record<string,never>}};
