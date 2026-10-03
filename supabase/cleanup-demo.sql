-- Run ONLY before attaching real bills/warranties to demo jobs. Transaction fails safely if referenced.
begin;
delete from complaint_status_history where complaint_id in(select id from complaints where customer_id in(select id from customers where 'demo'=any(tags)));
delete from complaints where customer_id in(select id from customers where 'demo'=any(tags));
delete from customers where 'demo'=any(tags);
delete from inventory_items where sku like 'DEMO-%';
commit;
