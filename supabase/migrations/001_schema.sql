-- All financial writes are transactional RPCs, not browser-trusted totals.
create type public.app_role as enum ('owner','staff','technician');
create type public.job_status as enum ('pending','scheduled','waiting_part','in_progress','completed','cancelled');
create table public.profiles(id uuid primary key references auth.users on delete cascade, name text not null, mobile text, active boolean not null default true, created_at timestamptz not null default now());
create table public.user_roles(user_id uuid primary key references auth.users on delete cascade, role public.app_role not null);
create function public.has_role(wanted public.app_role) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from user_roles r join profiles p on p.id=r.user_id where r.user_id=auth.uid() and r.role=wanted and p.active) $$;
create function public.office() returns boolean language sql stable security definer set search_path=public as $$ select has_role('owner') or has_role('staff') $$;
create table public.customers(id uuid primary key default gen_random_uuid(),name text not null,mobile text not null unique check(mobile ~ '^[6-9][0-9]{9}$'),alternate_mobile text,address text not null,addresses jsonb not null default '[]',notes text default '',whatsapp_opt_in boolean not null default false,opt_out boolean not null default false,tags text[] not null default '{}',created_at timestamptz not null default now(),deleted_at timestamptz);
create table public.technicians(id uuid primary key default gen_random_uuid(),user_id uuid unique references profiles(id),name text not null,mobile text not null,active boolean not null default true);
create sequence public.complaint_seq;
create table public.complaints(id uuid primary key default gen_random_uuid(),number text not null unique default ('BE-'||lpad(nextval('public.complaint_seq')::text,6,'0')),customer_id uuid not null references customers,appliance text not null check(appliance in ('ac','washing','microwave','other')),brand text default '',reported_name text,reported_address text,issue text not null,status job_status not null default 'pending',priority text not null default 'normal' check(priority in ('normal','urgent')),visit_at timestamptz,technician_id uuid references technicians,source text not null default 'link' check(source in ('link','phone','walkin')),internal_notes text default '',created_at timestamptz not null default now(),updated_at timestamptz not null default now(),feedback_token uuid not null default gen_random_uuid(),public_upload_token uuid not null default gen_random_uuid());
create table public.complaint_photos(id uuid primary key default gen_random_uuid(),complaint_id uuid not null references complaints on delete cascade,path text not null unique,kind text not null default 'before' check(kind in ('before','after')),created_at timestamptz not null default now());
create table public.complaint_status_history(id uuid primary key default gen_random_uuid(),complaint_id uuid not null references complaints,status job_status not null,changed_by uuid references profiles,actor_name text not null default 'Customer',created_at timestamptz not null default now());
create table public.inventory_items(id uuid primary key default gen_random_uuid(),name text not null,category text not null,sku text unique,purchase_price numeric(12,2) not null default 0 check(purchase_price>=0),selling_price numeric(12,2) not null default 0 check(selling_price>=0),stock_quantity integer not null default 0 check(stock_quantity>=0),low_stock_level integer not null default 2 check(low_stock_level>=0),supplier text default '');
create sequence public.bill_seq;
create table public.bills(id uuid primary key default gen_random_uuid(),number text unique not null default ('BB-'||lpad(nextval('public.bill_seq')::text,6,'0')),customer_id uuid not null references customers,complaint_id uuid references complaints,subtotal numeric(12,2) not null check(subtotal>=0),service_charge numeric(12,2) not null default 0 check(service_charge>=0),discount numeric(12,2) not null default 0 check(discount>=0),gst_rate numeric(5,2) not null default 0 check(gst_rate between 0 and 100),gst_amount numeric(12,2) not null default 0,total numeric(12,2) not null check(total>=0),pdf_path text,created_at timestamptz not null default now(),deleted_at timestamptz,idempotency_key uuid not null unique);
create table public.bill_items(id uuid primary key default gen_random_uuid(),bill_id uuid not null references bills,inventory_id uuid references inventory_items,name text not null,quantity integer not null check(quantity>0),unit_price numeric(12,2) not null check(unit_price>=0));
create table public.payments(id uuid primary key default gen_random_uuid(),bill_id uuid not null references bills,amount numeric(12,2) not null check(amount>0),mode text not null check(mode in ('cash','upi','card')),created_at timestamptz not null default now(),idempotency_key uuid unique not null);
create table public.warranties(id uuid primary key default gen_random_uuid(),complaint_id uuid not null unique references complaints,customer_id uuid not null references customers,appliance text not null,coverage text not null,expires_at date not null,created_at timestamptz not null default now());
create table public.service_reminders(id uuid primary key default gen_random_uuid(),complaint_id uuid unique references complaints,customer_id uuid not null references customers,appliance text not null default 'ac',due_date date not null,done boolean not null default false);
create table public.amc_plans(id uuid primary key default gen_random_uuid(),customer_id uuid not null references customers,plan_name text not null,appliance text not null,price numeric(12,2) not null check(price>=0),free_visits integer not null check(free_visits>0),visits_used integer not null default 0 check(visits_used>=0 and visits_used<=free_visits),start_date date not null,end_date date not null check(end_date>=start_date));
create table public.stock_movements(id uuid primary key default gen_random_uuid(),inventory_id uuid not null references inventory_items,bill_id uuid references bills,quantity integer not null check(quantity<>0),reason text not null,created_by uuid references profiles,created_at timestamptz not null default now());
create table public.expenses(id uuid primary key default gen_random_uuid(),category text not null,amount numeric(12,2) not null check(amount>0),note text default '',date date not null default current_date);
create table public.message_templates(id uuid primary key default gen_random_uuid(),name text not null,body text not null);
create table public.campaigns(id uuid primary key default gen_random_uuid(),template_id uuid references message_templates,name text not null,body text not null,created_at timestamptz not null default now());
create table public.campaign_recipients(id uuid primary key default gen_random_uuid(),campaign_id uuid not null references campaigns,customer_id uuid not null references customers,sent_at timestamptz,unique(campaign_id,customer_id));
create table public.feedback(id uuid primary key default gen_random_uuid(),complaint_id uuid not null unique references complaints,rating integer not null check(rating between 1 and 5),comment text default '',created_at timestamptz not null default now());
create table public.shop_settings(id integer primary key check(id=1),name text not null default 'BALAJI ELECTRIC REPAIR AND SERVICES',address text not null default 'Shop No 2, Juhu Road, Andheri',phone1 text not null default '7021935696',phone2 text not null default '9769972070',logo_path text,gst_number text default '',upi_id text default '',review_url text default '',footer text default 'Thank you for choosing Balaji Electric.',default_warranty integer not null default 3);
insert into shop_settings(id) values(1);
-- Not reachable from browser; contains hashes, not mobile/IP in cleartext.
create table public.public_rate_limits(key text primary key,window_start timestamptz not null default now(),hits integer not null default 1);
create function public.assigned_job(j uuid) returns boolean language sql stable security definer set search_path=public as $$ select has_role('technician') and exists(select 1 from complaints c join technicians t on t.id=c.technician_id where c.id=j and t.user_id=auth.uid() and t.active) $$;
create function public.can_job(j uuid) returns boolean language sql stable security definer set search_path=public as $$ select office() or assigned_job(j) $$;
-- Every table has RLS; no public SELECT or anonymous direct INSERT.
do $$ declare t text; begin foreach t in array array['profiles','user_roles','customers','complaints','complaint_photos','complaint_status_history','technicians','bills','bill_items','payments','warranties','service_reminders','amc_plans','inventory_items','stock_movements','expenses','message_templates','campaigns','campaign_recipients','feedback','shop_settings','public_rate_limits'] loop execute format('alter table public.%I enable row level security',t); end loop; end $$;
create policy profile_self on profiles for select to authenticated using(id=auth.uid() or office());
create policy roles_self on user_roles for select to authenticated using(user_id=auth.uid() or has_role('owner'));
create policy customer_office on customers for all to authenticated using(office()) with check(office());
create policy job_read on complaints for select to authenticated using(can_job(id));
create policy job_insert on complaints for insert to authenticated with check(office());
-- No direct UPDATE: update_job RPC checks allowed fields for technicians.
create policy photo_read on complaint_photos for select to authenticated using(can_job(complaint_id));
create policy photo_insert on complaint_photos for insert to authenticated with check(can_job(complaint_id) and split_part(path,'/',1)=complaint_id::text);
create policy history_read on complaint_status_history for select to authenticated using(can_job(complaint_id));
create policy technician_read on technicians for select to authenticated using(office() or user_id=auth.uid());
create policy technician_owner on technicians for all to authenticated using(has_role('owner')) with check(has_role('owner'));
create policy bill_read on bills for select to authenticated using(office());
create policy items_read on bill_items for select to authenticated using(office());
create policy payments_read on payments for select to authenticated using(office());
create policy warranty_office on warranties for all to authenticated using(office()) with check(office());
create policy reminders_office on service_reminders for all to authenticated using(office()) with check(office());
create policy amc_office on amc_plans for all to authenticated using(office()) with check(office());
create policy inventory_owner on inventory_items for all to authenticated using(has_role('owner')) with check(has_role('owner'));
create policy movements_read on stock_movements for select to authenticated using(has_role('owner'));
create policy expenses_owner on expenses for all to authenticated using(has_role('owner')) with check(has_role('owner'));
create policy templates_owner on message_templates for all to authenticated using(has_role('owner')) with check(has_role('owner'));
create policy campaigns_owner on campaigns for all to authenticated using(has_role('owner')) with check(has_role('owner'));
create policy recipients_owner on campaign_recipients for all to authenticated using(has_role('owner')) with check(has_role('owner'));
create policy feedback_office on feedback for select to authenticated using(office());
create policy settings_read on shop_settings for select to authenticated using(office());
create policy settings_owner on shop_settings for update to authenticated using(has_role('owner')) with check(has_role('owner'));
create index jobs_customer on complaints(customer_id);
create index jobs_technician on complaints(technician_id,status,visit_at);
create index jobs_created on complaints(created_at desc);
create index status_job on complaint_status_history(complaint_id,created_at);
create index bill_customer on bills(customer_id);
create index payment_bill on payments(bill_id);
create function public.log_status() returns trigger language plpgsql security definer set search_path=public as $$ begin
 if TG_OP='INSERT' or old.status is distinct from new.status then
 insert into complaint_status_history(complaint_id,status,changed_by,actor_name) values(new.id,new.status,auth.uid(),coalesce((select name from profiles where id=auth.uid()),case when new.source='link' then 'Customer' else 'Shop' end)); end if; new.updated_at=now();return new;end $$;
create trigger status_audit after insert or update of status on complaints for each row execute function log_status();
-- Redacted stock catalogue; no purchase costs for staff.
create function public.parts_catalog() returns table(id uuid,name text,selling_price numeric,stock_quantity integer) language plpgsql security definer set search_path=public as $$ begin if not office() then raise exception 'ACCESS_DENIED';end if; return query select i.id,i.name,i.selling_price,i.stock_quantity from inventory_items i order by i.name;end $$;
create function public.job_contact(j uuid) returns table(name text,mobile text,address text) language plpgsql security definer set search_path=public as $$ begin if not can_job(j) then raise exception 'ACCESS_DENIED';end if;return query select coalesce(x.reported_name,c.name),c.mobile,coalesce(x.reported_address,c.address) from customers c join complaints x on x.customer_id=c.id where x.id=j;end $$;
create function public.update_job(j uuid,s job_status,n text default null,t uuid default null,v timestamptz default null) returns void language plpgsql security definer set search_path=public as $$ begin
 if not can_job(j) then raise exception 'ACCESS_DENIED';end if;
 if length(coalesce(n,''))>10000 then raise exception 'INVALID_INPUT';end if;
 if office() then update complaints set status=s,internal_notes=coalesce(n,internal_notes),technician_id=t,visit_at=v,updated_at=now() where id=j;
 else update complaints set status=s,internal_notes=coalesce(n,internal_notes),updated_at=now() where id=j;end if;
 end $$;
create function public.submit_admin_job(p jsonb) returns uuid language plpgsql security definer set search_path=public as $$ declare cid uuid;j uuid;begin
 if not office() then raise exception 'ACCESS_DENIED';end if;
 insert into customers(name,mobile,address,whatsapp_opt_in) values(p->>'name',p->>'mobile',p->>'address',coalesce((p->>'whatsapp_opt_in')::boolean,false)) on conflict(mobile) do update set name=excluded.name,address=excluded.address where customers.deleted_at is null returning id into cid;
 if cid is null then raise exception 'CUSTOMER_ARCHIVED';end if;
 insert into complaints(customer_id,appliance,brand,issue,priority,visit_at,technician_id,source) values(cid,p->>'appliance',p->>'brand',p->>'issue',coalesce(p->>'priority','normal'),nullif(p->>'visit_at','')::timestamptz,nullif(p->>'technician_id','')::uuid,coalesce(p->>'source','phone')) returning id into j;return j;end $$;
-- Atomic limiter. Row-level conflict serializes same key.
create function public.consume_rate(k text,maximum integer,seconds integer) returns boolean language plpgsql security definer set search_path=public as $$ declare h integer;begin
 insert into public_rate_limits(key) values(k) on conflict(key) do update set hits=case when public_rate_limits.window_start<now()-make_interval(secs=>seconds) then 1 else public_rate_limits.hits+1 end,window_start=case when public_rate_limits.window_start<now()-make_interval(secs=>seconds) then now() else public_rate_limits.window_start end returning hits into h;return h<=maximum;end $$;
revoke all on function public.consume_rate(text,integer,integer) from public,anon,authenticated;grant execute on function public.consume_rate(text,integer,integer) to service_role;
create function public.submit_public_job(p jsonb) returns jsonb language plpgsql security definer set search_path=public as $$ declare cid uuid;r complaints;begin
 if not consume_rate('mobile:'||md5(p->>'mobile'),3,3600) then raise exception 'RATE_LIMIT';end if;
 -- Existing customer identities/address/consent never overwritten by unauthenticated submissions.
 insert into customers(name,mobile,address,whatsapp_opt_in) values(p->>'name',p->>'mobile',p->>'address',coalesce((p->>'whatsapp_opt_in')::boolean,false)) on conflict(mobile) do nothing;
 select id into cid from customers where mobile=p->>'mobile' and deleted_at is null;
 if cid is null then raise exception 'CUSTOMER_ARCHIVED';end if;
 insert into complaints(customer_id,appliance,brand,issue,reported_name,reported_address) values(cid,p->>'appliance',p->>'brand',p->>'issue',p->>'name',p->>'address') returning * into r;
 return jsonb_build_object('id',r.id,'number',r.number,'upload_token',r.public_upload_token);
 end $$;
revoke all on function public.submit_public_job(jsonb) from public,anon,authenticated;grant execute on function public.submit_public_job(jsonb) to service_role;
create function public.save_bill(p jsonb) returns uuid language plpgsql security definer set search_path=public as $$
declare bid uuid;li jsonb;sub numeric=0;tax numeric;tot numeric;svc numeric=coalesce((p->>'service_charge')::numeric,0);disc numeric=coalesce((p->>'discount')::numeric,0);rate numeric=coalesce((p->>'gst_rate')::numeric,0);received numeric=coalesce((p->>'received')::numeric,0);qty integer;price numeric;iid uuid;begin
 if not office() then raise exception 'ACCESS_DENIED';end if;
 perform pg_advisory_xact_lock(hashtextextended(p->>'idempotency_key',0));
 select id into bid from bills where idempotency_key=(p->>'idempotency_key')::uuid;if bid is not null then return bid;end if;
 if svc<0 or disc<0 or rate<0 or rate>100 or received<0 or jsonb_array_length(p->'items')>100 then raise exception 'INVALID_AMOUNT';end if;
 if rate>0 and not exists(select 1 from shop_settings where gst_number<>'') then raise exception 'GST_REQUIRED';end if;
 if not exists(select 1 from customers where id=(p->>'customer_id')::uuid and deleted_at is null) then raise exception 'INVALID_CUSTOMER';end if;
 if nullif(p->>'complaint_id','') is not null and not exists(select 1 from complaints where id=(p->>'complaint_id')::uuid and customer_id=(p->>'customer_id')::uuid) then raise exception 'INVALID_COMPLAINT';end if;
 -- Deterministic locking avoids deadlocks; grouped stock verification handles duplicate line items.
 perform id from inventory_items where id in(select nullif(value->>'inventory_id','')::uuid from jsonb_array_elements(p->'items')) order by id for update;
 for li in select value from jsonb_array_elements(p->'items') loop qty=(li->>'quantity')::integer;price=(li->>'unit_price')::numeric;if qty<=0 or price<0 or length(coalesce(li->>'name',''))=0 then raise exception 'INVALID_ITEMS';end if;sub=sub+qty*price;end loop;
 if disc>sub+svc then raise exception 'INVALID_DISCOUNT';end if;tax=round((sub+svc-disc)*rate/100,2);tot=round(sub+svc-disc+tax,2);if received>tot then raise exception 'OVERPAYMENT';end if;
 insert into bills(customer_id,complaint_id,subtotal,service_charge,discount,gst_rate,gst_amount,total,idempotency_key) values((p->>'customer_id')::uuid,nullif(p->>'complaint_id','')::uuid,sub,svc,disc,rate,tax,tot,(p->>'idempotency_key')::uuid) returning id into bid;
 for li in select value from jsonb_array_elements(p->'items') loop qty=(li->>'quantity')::integer;price=(li->>'unit_price')::numeric;iid=nullif(li->>'inventory_id','')::uuid;
 if iid is not null then update inventory_items set stock_quantity=stock_quantity-qty where id=iid and stock_quantity>=qty;if not found then raise exception 'LOW_STOCK';end if;insert into stock_movements(inventory_id,bill_id,quantity,reason,created_by) values(iid,bid,-qty,'Invoice usage',auth.uid());end if;
 insert into bill_items(bill_id,inventory_id,name,quantity,unit_price) values(bid,iid,li->>'name',qty,price);end loop;
 if received>0 then insert into payments(bill_id,amount,mode,idempotency_key) values(bid,received,p->>'mode',(p->>'idempotency_key')::uuid);end if;return bid;end $$;
create function public.add_payment(b uuid,a numeric,m text,k uuid) returns void language plpgsql security definer set search_path=public as $$ declare due numeric;begin
 if not office() then raise exception 'ACCESS_DENIED';end if;
 perform id from bills where id=b and deleted_at is null for update;if not found then raise exception 'INVALID_BILL';end if;
 if exists(select 1 from payments where idempotency_key=k) then return;end if;
 select total-coalesce((select sum(amount) from payments where bill_id=b),0) into due from bills where id=b;
 if a<=0 or a>due then raise exception 'OVERPAYMENT';end if;
 insert into payments(bill_id,amount,mode,idempotency_key) values(b,a,m,k);end $$;
create function public.stock_adjust(i uuid,q integer,r text) returns void language plpgsql security definer set search_path=public as $$ begin
 if not has_role('owner') then raise exception 'ACCESS_DENIED';end if;
 update inventory_items set stock_quantity=stock_quantity+q where id=i and stock_quantity+q>=0;if not found then raise exception 'LOW_STOCK';end if;
 insert into stock_movements(inventory_id,quantity,reason,created_by) values(i,q,r,auth.uid());end $$;
create function public.archive_bill(b uuid) returns void language plpgsql security definer set search_path=public as $$ begin if not has_role('owner') then raise exception 'ACCESS_DENIED';end if;update bills set deleted_at=now() where id=b;end $$;
create function public.set_bill_pdf(b uuid,p text) returns void language plpgsql security definer set search_path=public as $$ begin if not office() or split_part(p,'/',1)<>b::text then raise exception 'ACCESS_DENIED';end if;update bills set pdf_path=p where id=b;end $$;
-- RPCs are authenticated-only by default. Helpers are callable but only return booleans.
revoke all on function public.parts_catalog(),public.job_contact(uuid),public.update_job(uuid,job_status,text,uuid,timestamptz),public.submit_admin_job(jsonb),public.save_bill(jsonb),public.add_payment(uuid,numeric,text,uuid),public.stock_adjust(uuid,integer,text),public.archive_bill(uuid),public.set_bill_pdf(uuid,text) from public,anon;
grant execute on function public.parts_catalog(),public.job_contact(uuid),public.update_job(uuid,job_status,text,uuid,timestamptz),public.submit_admin_job(jsonb),public.save_bill(jsonb),public.add_payment(uuid,numeric,text,uuid),public.stock_adjust(uuid,integer,text),public.archive_bill(uuid),public.set_bill_pdf(uuid,text) to authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('complaint-photos','complaint-photos',false,5242880,array['image/jpeg','image/png','image/webp']),('bills','bills',false,10485760,array['application/pdf']),('logos','logos',false,2097152,array['image/png','image/jpeg','image/webp']);
create policy photo_storage_read on storage.objects for select to authenticated using(bucket_id='complaint-photos' and public.can_job((storage.foldername(name))[1]::uuid));
create policy photo_storage_insert on storage.objects for insert to authenticated with check(bucket_id='complaint-photos' and public.can_job((storage.foldername(name))[1]::uuid));
create policy bill_storage_office on storage.objects for all to authenticated using(bucket_id='bills' and public.office()) with check(bucket_id='bills' and public.office());
create policy logo_read on storage.objects for select to authenticated using(bucket_id='logos' and public.office());
create policy logo_owner on storage.objects for all to authenticated using(bucket_id='logos' and public.has_role('owner')) with check(bucket_id='logos' and public.has_role('owner'));
alter publication supabase_realtime add table public.complaints;
