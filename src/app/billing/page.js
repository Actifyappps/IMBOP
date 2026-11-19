"use client";

import {useEffect,useState} from "react";
import Nav from "../../components/Nav";
import Footer from "../../components/Footer";
import {supabase} from "../../lib/supabase";

const money=(n)=>new Intl.NumberFormat("en-KE",{style:"currency",currency:"KES",maximumFractionDigits:2}).format(Number(n)||0);
const date=(v)=>v?new Intl.DateTimeFormat("en-KE",{dateStyle:"medium"}).format(new Date(v)):"—";

export default function BillingPage(){
 const [user,setUser]=useState(null),[summary,setSummary]=useState(null),[receipts,setReceipts]=useState([]),[loading,setLoading]=useState(true),[message,setMessage]=useState(""),[selected,setSelected]=useState(null),[paymentIntentId,setPaymentIntentId]=useState(null),[paymentState,setPaymentState]=useState(null),[paymentMethod,setPaymentMethod]=useState(null),[latestReceipt,setLatestReceipt]=useState(null);
 const [pay,setPay]=useState({method:"MPESA",provider:"M-PESA",phone:"",amount:""}),[bankInstructions,setBankInstructions]=useState([]);
 const load=async()=>{
  setLoading(true);setMessage("");
  const {data:{user:u}}=await supabase.auth.getUser();setUser(u);
  if(!u){setLoading(false);return}
  const ctx=await supabase.rpc("get_my_institution_admin_context");
  if(ctx.error||!ctx.data?.institution_id){setMessage(ctx.error?.message||"No institution billing account is available for this account.");setLoading(false);return}
  const id=ctx.data.institution_id;
  const [s,r,b]=await Promise.all([supabase.rpc("get_my_billing_dashboard",{p_institution_id:id}),supabase.rpc("get_my_billing_receipts",{p_institution_id:id}),supabase.rpc("get_my_billing_payment_instructions",{p_institution_id:id})]);
  if(s.error)setMessage(s.error.message);else setSummary({...s.data,institution_id:id});
  if(r.error)setMessage(m=>m||r.error.message);else { setReceipts(r.data||[]); if(r.data?.length) setLatestReceipt(r.data[0]); } if(!b.error)setBankInstructions(b.data||[]);
  setLoading(false);
 };
 useEffect(()=>{load()},[]);
 const invoice=summary?.latest_invoice;
 const outstanding=Number(summary?.outstanding_kes||0);
 const canPay=outstanding>0;
 const startPay=(inv)=>{setSelected(inv);setPay({method:"MPESA",provider:"M-PESA",phone:"",amount:String(Math.max(0,Number(inv?.outstanding_kes||inv?.total_kes||0)))});};
 const createIntent=async()=>{
  if(!selected)return;
  const amount=Number(pay.amount);\n  const maxPayable=Number(selected?.outstanding_kes||selected?.total_kes||0);\n  if(!amount||amount<=0)return setMessage("Enter a valid payment amount.");\n  if(maxPayable>0&&amount>maxPayable)return setMessage(`You cannot pay more than the outstanding bill of ${money(maxPayable)}.`);
  if(pay.method==="MPESA"&&!pay.phone.trim())return setMessage("Enter the M-Pesa phone number for this payment.");
  setMessage("");setLoading(true);
  const {data,error}=await supabase.functions.invoke("imbop-payment-provider",{body:{operation:"start",institution_id:summary.institution_id,invoice_id:selected.id,amount_kes:amount,payment_method:pay.method,phone:pay.phone.trim()||null}});
  setLoading(false);
  if(error){setMessage(error.message||"Unable to start payment.");return}
  if(!data?.payment_intent_id){setMessage("Payment request was not created.");return}
  setPaymentIntentId(data.payment_intent_id);
  setPaymentState(data.status||"CREATED");
  setPaymentMethod(pay.method);
  setSelected(null);
  setMessage(data.customer_message||data.message||"Payment request created.");
 };
 useEffect(()=>{if(!paymentIntentId)return;let active=true;const poll=async()=>{const {data,error}=await supabase.from("billing_payment_intents").select("id,status,metadata").eq("id",paymentIntentId).single();if(!active||error)return;setPaymentState(data.status);if(data.status==="SUCCEEDED"){setMessage("Payment confirmed. Your IMBOP receipt has been issued.");await load();}else if(["FAILED","CANCELLED","EXPIRED"].includes(data.status)){setMessage("Payment "+data.status.toLowerCase()+". You can start another payment when ready.");}};poll();const timer=setInterval(poll,4000);return()=>{active=false;clearInterval(timer)}},[paymentIntentId]);
 const queryProvider=async()=>{if(!paymentIntentId||paymentMethod!=="MPESA")return;setMessage("Checking M-PESA payment status…");const {data,error}=await supabase.functions.invoke("imbop-payment-provider",{body:{operation:"mpesa_query",payment_intent_id:paymentIntentId}});if(error){setMessage(error.message||"Unable to check M-PESA status.");return}setPaymentState(data?.status||"PENDING");setMessage(data?.reconciled?"M-PESA payment reconciled and confirmed.":"M-PESA is still processing. IMBOP will continue waiting for confirmation.");};
 if(loading)return <><Nav authenticated/><main className="wrap"><div className="card">Loading Billing & Payments…</div></main><Footer/></>;
 if(!user)return <><Nav/><main className="wrap"><div className="card"><div className="eyebrow">IMBOP BILLING & PAYMENTS</div><h1>Sign in to view billing</h1><p>Your institution billing account is available to authorised institution administrators.</p><a className="btn" href="/login?next=/billing">SIGN IN</a></div></main><Footer/></>;
 return <><Nav authenticated/><main className="wrap">
  <div className="eyebrow">IMBOP BILLING & PAYMENTS</div><header className="admin-hero"><div><div className="eyebrow">INSTITUTION ACCOUNT</div><h1>{summary?.institution_name||"Institution Billing"}</h1><p>See your bill, pay your invoice, receive receipts and review payment history.</p></div></header>
  {message&&<div className="notice" role="status">{message}</div>}
  <section className="admin-grid">
   <article className="admin-card"><div className="eyebrow">CURRENT PLAN</div><h2>{summary?.plan_code||"FOUNDING_PILOT"}</h2><p>{Number(summary?.imbop_onboards||0).toLocaleString("en-KE")} IMBOP ONBOARDS</p><strong>{money(summary?.monthly_fee_kes||0)} / month</strong></article>
   <article className="admin-card"><div className="eyebrow">OUTSTANDING</div><h2>{money(outstanding)}</h2><p>{summary?.compliance_status||"—"}</p>{canPay&&<button className="admin-btn admin-btn-primary" onClick={()=>startPay(invoice)}>PAY BILL</button>}</article>
   <article className="admin-card"><div className="eyebrow">LATEST INVOICE</div><h2>{invoice?.invoice_number||"No invoice"}</h2><p>{invoice?date(invoice.period_start)+" — "+date(invoice.period_end):"Your invoices will appear here."}</p>{invoice&&<button className="admin-btn" onClick={()=>setSelected({...invoice,viewOnly:true})}>VIEW BILL</button>}</article>
  </section>
  {paymentIntentId&&<section className="card"><div className="eyebrow">PAYMENT STATUS</div><h2>{paymentState||"CREATED"}</h2><p>Payment request <b>{paymentIntentId}</b> is being tracked by IMBOP.</p>{paymentState==="PENDING"&&paymentMethod==="MPESA"&&<button className="admin-btn" onClick={queryProvider}>CHECK M-PESA STATUS</button>}{paymentState==="SUCCEEDED"&&latestReceipt&&<div className="notice"><div className="eyebrow">RECEIPT ISSUED</div><h3>{latestReceipt.receipt_number}</h3><p>{money(latestReceipt.amount_kes)} · {date(latestReceipt.issued_at)}</p></div>}{["FAILED","CANCELLED","EXPIRED"].includes(paymentState)&&<button className="admin-btn admin-btn-primary" onClick={()=>{setPaymentIntentId(null);setPaymentState(null);}}>START ANOTHER PAYMENT</button>}</section>}
  <section className="admin-section"><div className="eyebrow">PAYMENT HISTORY</div><h2>Receipts</h2><p>Confirmed payments and issued receipts for this institution.</p>{receipts.length?<div className="admin-grid">{receipts.map(r=><article className="admin-card" key={r.receipt_id}><div className="eyebrow">RECEIPT</div><h3>{r.receipt_number}</h3><p><b>{money(r.amount_kes)}</b> · {r.payment_method||"—"}{r.provider?" · "+r.provider:""}</p><p>{date(r.issued_at)}{r.provider_reference?" · "+r.provider_reference:""}</p></article>)}</div>:<div className="card empty-state"><p>No confirmed payments or receipts yet.</p></div>}</section>
  <section className="card"><div className="eyebrow">PAYMENT CHANNELS</div><p><b>M-PESA · AIRTEL MONEY · BANK TRANSFER · CARD</b></p><p>You can pay the full outstanding balance or make a smaller payment now, subject to the invoice balance. M-PESA is connected through the secure provider adapter; Airtel Money, Bank Transfer and Card remain configuration-gated until their provider rails are approved.</p></section>
 </main>
 {selected&&!selected.viewOnly&&<div className="admin-drawer-backdrop" onMouseDown={e=>e.target===e.currentTarget&&!loading&&setSelected(null)}><aside className="admin-drawer" role="dialog" aria-modal="true"><button className="admin-drawer-close" onClick={()=>setSelected(null)}>×</button><div className="eyebrow">PAY BILL</div><h2>{selected.invoice_number}</h2><div className="notice"><div className="eyebrow">OUTSTANDING BILL</div><h3>{money(selected.outstanding_kes||selected.total_kes)}</h3></div><label className="label">PAYMENT METHOD<select className="input" value={pay.method} onChange={e=>setPay(x=>({...x,method:e.target.value,provider:e.target.value==="MPESA"?"M-PESA":e.target.value==="AIRTEL_MONEY"?"Airtel Money":""}))}><option value="MPESA">M-PESA</option><option value="AIRTEL_MONEY">Airtel Money</option><option value="BANK_TRANSFER">Bank Transfer</option><option value="CARD">Card</option></select></label><label className="label">PAYING HOW MUCH NOW<input className="input" type="number" min="1" max={selected.outstanding_kes||selected.total_kes||undefined} step="1" value={pay.amount} onChange={e=>setPay(x=>({...x,amount:e.target.value}))} placeholder="KES …"/></label><div className="admin-actions"><button className="admin-btn" type="button" onClick={()=>setPay(x=>({...x,amount:String(Number(selected.outstanding_kes||selected.total_kes||0))}))}>PAY FULL BALANCE</button></div>{["MPESA","AIRTEL_MONEY"].includes(pay.method)&&<label className="label">MOBILE NUMBER<input className="input" inputMode="tel" value={pay.phone} onChange={e=>setPay(x=>({...x,phone:e.target.value}))} placeholder="07xx xxx xxx"/></label>}{pay.method==="BANK_TRANSFER"&&<div className="notice"><div className="eyebrow">BANK TRANSFER INSTRUCTIONS</div>{bankInstructions.length?bankInstructions.map((b,i)=><div key={i} style={{marginTop:"0.75rem"}}><b>{b.bank_name}</b><br/>{b.account_name}<br/>Account: <b>{b.account_number}</b>{b.branch_name&&<><br/>Branch: {b.branch_name}</>}{b.swift_code&&<><br/>SWIFT: {b.swift_code}</>}{b.reference_prefix&&<><br/>Reference: <b>{b.reference_prefix}-{selected.invoice_number}</b></>}{b.instructions&&<><br/>{b.instructions}</>}</div>):<p>No bank transfer instructions have been configured yet. Please contact SE billing administration.</p>}</div>}{pay.method==="MPESA"&&<div className="notice">M-PESA payment will use a secure STK Push when the provider credentials and production callback are configured.</div>}{["AIRTEL_MONEY","CARD"].includes(pay.method)&&<div className="notice">This payment channel is ready for provider configuration; no live charge is initiated until its approved rail is enabled.</div>}<div className="admin-actions"><button className="admin-btn" onClick={()=>setSelected(null)}>CANCEL</button><button className="admin-btn admin-btn-primary" onClick={createIntent} disabled={loading}>{loading?"CREATING…":"CONTINUE TO PAY"}</button></div></aside></div>}
 </> 
}
