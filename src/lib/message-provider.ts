// Future adapter boundary. Never call paid provider APIs from the browser.
export interface MessageRequest {customerId:string;templateId?:string;message:string;channel:'whatsapp'|'sms'}
export interface MessageProvider {send(request:MessageRequest):Promise<{deliveryId:string;status:'queued'|'sent'|'failed'}>}
// Implement in a Supabase Edge Function with owner verification, explicit consent checks,
// provider secrets, idempotency keys, delivery webhooks and signed webhook validation.
// Manual queue remains the only current delivery method.
