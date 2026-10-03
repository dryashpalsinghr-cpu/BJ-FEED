create function public.register_public_photo(j uuid,t uuid,p text) returns void language plpgsql security definer set search_path=public as $$ begin
 perform id from complaints where id=j and public_upload_token=t and created_at>now()-interval '30 minutes' for update;
 if not found or split_part(p,'/',1)<>j::text then raise exception 'ACCESS_DENIED';end if;
 if (select count(*) from complaint_photos where complaint_id=j)>=3 then raise exception 'PHOTO_LIMIT';end if;
 insert into complaint_photos(complaint_id,path) values(j,p);end $$;
revoke all on function public.register_public_photo(uuid,uuid,text) from public,anon,authenticated;grant execute on function public.register_public_photo(uuid,uuid,text) to service_role;
