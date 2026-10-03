export type Role='owner'|'staff'|'technician';
export type Status='pending'|'scheduled'|'waiting_part'|'in_progress'|'completed'|'cancelled';
export type Appliance='ac'|'washing'|'microwave'|'other';
export interface Customer {id:string;name:string;mobile:string;alternate_mobile?:string;address:string;addresses?:string[];notes?:string;whatsapp_opt_in:boolean;opt_out:boolean;tags:string[];created_at:string;deleted_at?:string|null}
export interface Complaint {id:string;number:string;customer_id:string;appliance:Appliance;brand:string;reported_name?:string;reported_address?:string;issue:string;status:Status;priority:string;visit_at:string|null;technician_id:string|null;source:string;internal_notes:string;created_at:string;updated_at:string;feedback_token:string;public_upload_token?:string}
export interface Bill {id:string;number:string;customer_id:string;complaint_id:string|null;subtotal:number;service_charge:number;discount:number;gst_rate:number;gst_amount:number;total:number;pdf_path?:string;created_at:string;deleted_at?:string|null;idempotency_key:string}
export interface Line {id?:string;bill_id?:string;inventory_id?:string|null;name:string;quantity:number;unit_price:number}
export interface Payment {id:string;bill_id:string;amount:number;mode:string;created_at:string;idempotency_key:string}
export interface Inventory {id:string;name:string;category:string;sku:string;purchase_price:number;selling_price:number;stock_quantity:number;low_stock_level:number;supplier:string}
export interface Technician {id:string;user_id:string;name:string;mobile:string;active:boolean}
export interface Warranty {id:string;complaint_id:string;customer_id:string;appliance:Appliance;coverage:string;expires_at:string}
export interface Reminder {id:string;complaint_id:string;customer_id:string;appliance:Appliance;due_date:string;done:boolean}
export interface AMC {id:string;customer_id:string;plan_name:string;appliance:Appliance;price:number;free_visits:number;visits_used:number;start_date:string;end_date:string}
export interface Template {id:string;name:string;body:string}
export interface Campaign {id:string;name:string;body:string;template_id?:string;created_at:string}
export interface Recipient {id:string;campaign_id:string;customer_id:string;sent_at:string|null}
export interface Profile {id:string;name:string;mobile:string;active:boolean}
export interface Settings {id:number;name:string;address:string;phone1:string;phone2:string;gst_number:string;upi_id:string;review_url:string;footer:string;default_warranty:number;logo_path?:string}
export interface History {id:string;complaint_id:string;status:Status;actor_name:string;created_at:string}
export interface Photo {id:string;complaint_id:string;path:string;kind:string}
export interface Expense {id:string;category:string;amount:number;note:string;date:string}
export interface Feedback {id:string;complaint_id:string;rating:number;comment:string;created_at:string}
export interface StockMovement {id:string;inventory_id:string;bill_id?:string;quantity:number;reason:string;created_at:string}
export interface Tables {customers:Customer;complaints:Complaint;bills:Bill;bill_items:Line;payments:Payment;inventory_items:Inventory;technicians:Technician;warranties:Warranty;service_reminders:Reminder;amc_plans:AMC;message_templates:Template;campaigns:Campaign;campaign_recipients:Recipient;profiles:Profile;shop_settings:Settings;complaint_status_history:History;complaint_photos:Photo;expenses:Expense;feedback:Feedback;stock_movements:StockMovement;user_roles:{user_id:string;role:Role}}
export type Table=keyof Tables;
export type Data={ [K in Table]:Tables[K][] };
