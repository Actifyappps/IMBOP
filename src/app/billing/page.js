"use client";

import {useEffect,useState} from "react";
import Nav from "../../components/Nav";
import Footer from "../../components/Footer";
import {supabase} from "../../lib/supabase";

const money=(n)=>new Intl.NumberFormat("en-KE",{style:"currency",currency:"KES",maximumFractionDigits:2}).format(Number(n)||0);
const date=(v)=>v?new Intl.DateTimeFormat("en-KE",{dateStyle:"medium"}).format(new Date(v)):"—";

export default function BillingPage(){
 const [user,setUser]=useState(null),[summary,setSummary]=useState(null),[receipts,setReceipts]=useState([]),[loading,setLoading]=useState(true),[message,setMessage]=useState(""),[selected,setSelected]=useState(null);
 const [pay,setPay]=useState({method:"MPESA",provider:"M-PESA",phone:"",amount:""});
 const load=async()=>{
  setLoading(true);setMessage("");
  const {data:{user:u}}=await supabase.auth.getUser();setUser(u);
  if(!u){setLoading(false);return}
  const ctx=await supabase.rpc("get_my_institution_admin_context");
  if(ctx.error||!ctx.data?.institution_id){setMessage(ctx.error?.message||"No institution billing account is available for this account.");setLoading(false);return}
  const id=ctx.data.institution_id;
  const [s,r]=await Promise.all([supabase.rpc("get_my_institution_billing_summary",{p_institution_id:id}),supabase.rpc("get_my_billing_receipts",{p_institution_id:id})]);
  if(s.error)setMessage(s.error.message);else setSummary({...s.data,institution_id:id});
  if(r.error)setMessage(m=>m||r.error.message);else setReceipts(r.data||[]);
  setLoading(false);
 };
 useEffect(()=>{load()},[]);
 const invoice=summary?.latest_invoice;
 const outstanding=Number(summary?.outstanding_kes||0);
 const canPay=outstanding>0;
 const startPay=(inv)=>{setSelected(inv);setPay({method:"MPESA",provider:"M-PESA",phone:"",amount:String(Math.max(0,Number(inv?.outstanding_kes||inv?.total_kes||0)))});};
 const createIntent=async()=>{
  if(!selected)return;
  const amount=Number(pay.amount);if(!amount||amount<=0)return setMessage("Enter a valid payment amount.");
  if(pay.method==="MPESA"&&!pay.phone.trim())return setMessage("Enter the M-Pesa phone number for this payment.");
  setMessage("");setLoading(true);
  const {data,error}=await supabase.rpc("platform_create_payment_intent",{p_institution_id:summary.institution_id,p_amount_kes:amount,p_payment_method:pay.method,p_invoice_id:selected.id,p_provider:pay.provider||null,p_expires_at:null,p_metadata:{phone:pay.phone.trim()||null,source:"institution_billing_ui"}});
  setLoading(false);
  if(error){setMessage(error.message);return}
  setSelected(null);
  setMessage("Payment request created. The live payment-provider checkout will be connected in the next payment-rail integration stage.");
 };
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
  <section className="admin-section"><div className="eyebrow">PAYMENT HISTORY</div><h2>Receipts</h2><p>Confirmed payments and issued receipts for this institution.</p>{receipts.length?<div className="admin-grid">{receipts.map(r=><article className="admin-card" key={r.receipt_id}><div className="eyebrow">RECEIPT</div><h3>{r.receipt_number}</h3><p><b>{money(r.amount_kes)}</b> · {r.payment_method||"—"}{r.provider?" · "+r.provider:""}</p><p>{date(r.issued_at)}{r.provider_reference?" · "+r.provider_reference:""}</p></article>)}</div>:<div className="card empty-state"><p>No confirmed payments or receipts yet.</p></div>}</section>
  <section className="card"><div className="eyebrow">PAYMENT CHANNELS</div><p><b>M-PESA · AIRTEL MONEY · BANK TRANSFER · CARD</b></p><p>The provider connection will be introduced only after the internal billing ledger and payment flow pass review.</p></section>
 </main>
 {selected&&!selected.viewOnly&&<div className="admin-drawer-backdrop" onMouseDown={e=>e.target===e.currentTarget&&!loading&&setSelected(null)}><aside className="admin-drawer" role="dialog" aria-modal="true"><button className="admin-drawer-close" onClick={()=>setSelected(null)}>×</button><div className="eyebrow">PAY BILL</div><h2>{selected.invoice_number}</h2><p>Outstanding: <b>{money(selected.outstanding_kes||selected.total_kes)}</b></p><label className="label">PAYMENT METHOD<select className="input" value={pay.method} onChange={e=>setPay(x=>({...x,method:e.target.value,provider:e.target.value==="MPESA"?"M-PESA":e.target.value==="AIRTEL_MONEY"?"Airtel Money":""}))}><option value="MPESA">M-PESA</option><option value="AIRTEL_MONEY">Airtel Money</option><option value="BANK_TRANSFER">Bank Transfer</option><option value="CARD">Card</option></select></label><label className="label">AMOUNT (KES)<input className="input" type="number" min="1" value={pay.amount} onChange={e=>setPay(x=>({...x,amount:e.target.value}))}/></label>{["MPESA","AIRTEL_MONEY"].includes(pay.method)&&<label className="label">MOBILE NUMBER<input className="input" inputMode="tel" value={pay.phone} onChange={e=>setPay(x=>({...x,phone:e.target.value}))} placeholder="07xx xxx xxx"/></label>}<div className="notice">This currently creates the secure IMBOP payment request. Live M-Pesa/Airtel checkout will be connected after provider integration review.</div><div className="admin-actions"><button className="admin-btn" onClick={()=>setSelected(null)}>CANCEL</button><button className="admin-btn admin-btn-primary" onClick={createIntent} disabled={loading}>{loading?"CREATING…":"CONTINUE TO PAY"}</button></div></aside></div>}
 </> 
}
