-- Opt-in demo seed, NOT production customer data. Remove with cleanup-demo.sql.
insert into customers(id,name,mobile,address,tags,whatsapp_opt_in) values
('10000000-0000-4000-8000-000000000001','Asha Sharma','9000000001','Andheri West, Mumbai',array['demo'],true),
('10000000-0000-4000-8000-000000000002','Rahul Verma','9000000002','Juhu Road, Mumbai',array['demo'],true),
('10000000-0000-4000-8000-000000000003','Priya Mehta','9000000003','Vile Parle, Mumbai',array['demo'],false),
('10000000-0000-4000-8000-000000000004','Imran Khan','9000000004','Andheri East, Mumbai',array['demo'],true),
('10000000-0000-4000-8000-000000000005','Neha Patil','9000000005','DN Nagar, Mumbai',array['demo'],true) on conflict do nothing;
insert into complaints(id,customer_id,appliance,issue,status,source,created_at) select ('20000000-0000-4000-8000-'||lpad(n::text,12,'0'))::uuid,('10000000-0000-4000-8000-'||lpad(((n-1)%5+1)::text,12,'0'))::uuid,(array['ac','washing','microwave','other'])[(n-1)%4+1],'Demo: appliance not working correctly',(array['pending','scheduled','in_progress','completed']::job_status[])[(n-1)%4+1],'walkin',now()-make_interval(days=>n%4) from generate_series(1,8)n on conflict do nothing;
insert into inventory_items(id,name,category,sku,purchase_price,selling_price,stock_quantity,low_stock_level) values
('30000000-0000-4000-8000-000000000001','AC capacitor','Capacitor','DEMO-CAP',250,450,8,3),
('30000000-0000-4000-8000-000000000002','Washing motor','Motor','DEMO-MOTOR',1400,2200,2,3),
('30000000-0000-4000-8000-000000000003','Microwave magnetron','Magnetron','DEMO-MAG',900,1500,5,2) on conflict do nothing;
insert into message_templates(name,body) values
('Diwali','Hi {name}, happy Diwali from {shop}! {offer}'),('Holi','Hi {name}, happy Holi! {shop}: {offer}'),('Navratri','Hi {name}, happy Navratri! {shop}: {offer}'),('Eid','Hi {name}, happy Eid! {shop}: {offer}'),('Raksha Bandhan','Hi {name}, happy Raksha Bandhan! {shop}: {offer}'),('New Year','Hi {name}, happy New Year! {shop}: {offer}'),('Summer AC service','Hi {name}, get your AC serviced before summer. {shop}: {offer}'),('Monsoon check-up','Hi {name}, book an appliance check-up before monsoon. {shop}: {offer}'),('Service reminder','Hi {name}, your appliance service is due. Call {shop} to schedule your visit.');
