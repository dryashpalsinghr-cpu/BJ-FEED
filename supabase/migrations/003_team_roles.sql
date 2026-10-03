create function public.set_team_role(u uuid,r app_role,n text,m text) returns void language plpgsql security definer set search_path=public as $$ begin
 if not exists(select 1 from profiles where id=u) then raise exception 'INVALID_USER';end if;
 insert into user_roles(user_id,role) values(u,r) on conflict(user_id) do update set role=excluded.role;
 if r='technician' then insert into technicians(user_id,name,mobile,active) values(u,n,m,true) on conflict(user_id) do update set active=true;
 else update technicians set active=false where user_id=u;end if;end $$;
revoke all on function public.set_team_role(uuid,app_role,text,text) from public,anon,authenticated;
grant execute on function public.set_team_role(uuid,app_role,text,text) to service_role;
