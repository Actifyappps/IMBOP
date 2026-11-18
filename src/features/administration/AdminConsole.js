"use client";

import { useEffect, useState } from "react";
import Nav from "../../components/Nav";
import Footer from "../../components/Footer";
import { supabase } from "../../lib/supabase";

const REVIEWABLE = ["SUBMITTED", "PENDING_REVIEW", "RETURNED"];

export default function AdminConsole({section="dashboard"}) {
  const [applications, setApplications] = useState([]);
  const [institutions, setInstitutions] = useState([]);
  const [onboarding, setOnboarding] = useState([]);
  const [loading, setLoading] = useState(true);
  const [working, setWorking] = useState(null);
  const [message, setMessage] = useState("");
  const [adminDrafts, setAdminDrafts] = useState({});
  const [pricingPlans, setPricingPlans] = useState([]);
  const [commRecipients, setCommRecipients] = useState([]);
  const [commTemplates, setCommTemplates] = useState([]);
  const [commDraft, setCommDraft] = useState({recipient:"",template:"",subject:"",body:""});
  const [drawer, setDrawer] = useState(null);
  const [drawerText, setDrawerText] = useState("");
  const [drawerForm, setDrawerForm] = useState({email:"",first:"",last:""});

  async function loadData() {
    setLoading(true); setMessage("");
    const [a, i, o, p, cr, ct] = await Promise.all([
      supabase.from("institution_applications").select("*").in("status", REVIEWABLE).order("submitted_at", {ascending:true}),
      supabase.from("institutions").select("id,name,legal_name,slug,status,status_reason,created_at,deleted_at").order("created_at", {ascending:true}),
      supabase.rpc("platform_institution_onboarding_overview"),
      supabase.rpc("get_platform_pricing_plans"),
      supabase.rpc("get_platform_communication_recipients"),
      supabase.rpc("get_platform_communication_templates")
    ]);
    if (a.error) setMessage(a.error.message);
    if (i.error) setMessage((p)=>p || i.error.message);
    if (o.error) setMessage((p)=>p || o.error.message);
    if (p.error) setMessage((m)=>m || p.error.message);
    if (cr.error) setMessage((m)=>m || cr.error.message);
    if (ct.error) setMessage((m)=>m || ct.error.message);
    setApplications(a.data || []); setInstitutions(i.data || []); setOnboarding(o.data || []); setPricingPlans(p.data || []);
    setCommRecipients(cr.data || []); setCommTemplates(ct.data || []); setLoading(false);
  }
  useEffect(()=>{loadData()},[]);

  function readiness(id) {
    return onboarding.find(x=>x.id===id) || {};
  }

  async function reviewApplication(id, action, suppliedNotes) {
    if (drawer) setDrawer(null);
    let notes = suppliedNotes || "";
    if ((action === "RETURN" || action === "REJECT") && !notes.trim()) return setMessage("Review notes/reason are required.");
    if (action === "APPROVE" && !window.confirm("Approve and onboard this institution application?")) return;
    setWorking(id); setMessage("");
    const {data,error}=await supabase.rpc("review_institution_application",{p_application_id:id,p_action:action==="RETURN"?"RETURNED":action==="REJECT"?"REJECTED":action,p_notes:notes||null});
    if(error){setMessage(error.message);setWorking(null);return}
    if(!data?.ok){setMessage(data?.message||data?.error||"Institution application action failed.");setWorking(null);return}
    setMessage(action==="REVIEW"?"Institution application moved to PENDING REVIEW.":action==="APPROVE"?"Institution application approved and onboarded as PENDING.":"Institution application decision recorded.");
    await loadData(); setWorking(null);
  }

  async function configureInstitution(id) {
    if (!window.confirm("Complete the standard IMBOP institution configuration for this institution?")) return;
    setWorking(id); setMessage("");
    const {error}=await supabase.rpc("platform_configure_institution",{p_institution_id:id});
    if(error){setMessage(error.message);setWorking(null);return}
    setMessage("Institution configuration completed and audited.");
    await loadData(); setWorking(null);
  }

  async function assignAdmin(id, form) {
    const d=adminDrafts[id]||{};
    const email=form?.email ?? d.email ?? "";
    const first=form?.first ?? d.first ?? "";
    const last=form?.last ?? d.last ?? "";
    setDrawer(null);
    if(!email.trim()||!email.includes("@"))return setMessage("A valid administrator email is required.");
    setWorking(id); setMessage("");
    const {data:{session}}=await supabase.auth.getSession();
    if(!session?.access_token){setMessage("Your authenticated platform session is required.");setWorking(null);return}
    const base=process.env.NEXT_PUBLIC_SUPABASE_URL;
    const anon=process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    const r=await fetch(base+"/functions/v1/platform-institution-admin-invite",{method:"POST",headers:{Authorization:"Bearer "+session.access_token,apikey:anon,"Content-Type":"application/json"},body:JSON.stringify({institution_id:id,email:email.trim(),first_name:first.trim(),last_name:last.trim()})});
    const data=await r.json().catch(()=>({}));
    if(!r.ok||!data?.ok){setMessage(data?.error||"Administrator assignment failed.");setWorking(null);return}
    setMessage(data.invited?"Administrator invitation sent and active administrator assignment created.":"Existing user assigned as institution administrator.");
    await loadData(); setWorking(null);
  }

  async function manageInstitution(id, action, suppliedReason) {
    const reason=suppliedReason ?? "";
    setDrawer(null);
    if(!reason.trim())return setMessage("A reason is required.");
    setWorking(id);setMessage("");
    const {data,error}=await supabase.rpc("manage_institution",{p_institution_id:id,p_action:action,p_reason:reason.trim()});
    if(error){setMessage(error.message);setWorking(null);return}
    if(!data?.ok){setMessage(data?.message||data?.error||"Institution lifecycle action failed.");setWorking(null);return}
    setMessage(action+" completed and audited.");await loadData();setWorking(null);
  }

  async function dispatchOneQueuedEmail() {
    if (!window.confirm("Process one queued IMBOP email now?")) return;
    setWorking("email-dispatch"); setMessage("");
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) {
        setMessage("Your authenticated platform session is required to process queued email.");
        return;
      }
      const base = process.env.NEXT_PUBLIC_SUPABASE_URL;
      const apikey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
      const response = await fetch(base + "/functions/v1/imbop-email-dispatcher", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${session.access_token}`,
          apikey,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({})
      });
      const data = await response.json().catch(() => ({}));
      if (!response.ok) {
        setMessage(data?.message || data?.error || `Email dispatcher returned HTTP ${response.status}.`);
      } else if (!data?.ok) {
        setMessage(data?.message || data?.error || `Email dispatcher returned ${data?.status || "an error"}.`);
      } else if (data.status === "EMPTY_QUEUE") {
        setMessage("Email dispatcher ran successfully: the queue is empty.");
      } else {
        setMessage(`Email dispatcher completed: ${data.status || "OK"}.`);
      }
    } catch (e) {
      setMessage(e instanceof Error ? e.message : "Email dispatcher invocation failed.");
    } finally {
      setWorking(null);
    }
  }

  function controls(i){
    const s=String(i.status||"").toUpperCase();
    if(i.deleted_at)return <button className="admin-btn admin-btn-primary" onClick={()=>openDrawer("lifecycle",{id:i.id,action:"RESTORE",title:"Restore institution"})>RESTORE</button>;
    return <>
      {s!=="ACTIVE"&&<button className="admin-btn admin-btn-primary" onClick={()=>openDrawer("lifecycle",{id:i.id,action:"ACTIVATE",title:"Activate institution"})>ACTIVATE</button>}
      <button className="admin-btn" onClick={()=>openDrawer("lifecycle",{id:i.id,action:"PAUSE",title:"Pause institution"})>PAUSE</button>
      <button className="admin-btn" onClick={()=>openDrawer("lifecycle",{id:i.id,action:"SUSPEND",title:"Suspend institution"})>SUSPEND</button>
      <button className="admin-btn admin-btn-danger" onClick={()=>openDrawer("lifecycle",{id:i.id,action:"SHUT",title:"Shut institution"})>SHUT</button>
      <button className="admin-btn admin-btn-danger" onClick={()=>openDrawer("lifecycle",{id:i.id,action:"DELETE",title:"Delete institution"})>DELETE</button>
    </>;
  }

  
  function openDrawer(type, payload={}) {
    setDrawer({type,...payload});
    setDrawerText(payload.text || "");
    if(type==="assign-admin") setDrawerForm({email:"",first:"",last:""});
  }

  if(loading)return <><Nav authenticated/><main className="wrap"><div className="card">Loading platform administration…</div></main><Footer/></>;

  return <><Nav authenticated/><main className="wrap admin-page">
    <div className="platform-label"><b>SE PLATFORM ADMINISTRATION</b><span>Controlled platform-owner administration</span></div>
    <header className="admin-hero"><div><div className="eyebrow">CONTROLLED ADMIN</div><h1>SE Platform Administration</h1><p>Review institutional applications, complete onboarding readiness, and manage the controlled institution lifecycle.</p></div></header>
    <div className="admin-command-nav">
      <div className="admin-command-links">
        <a className={section==="dashboard"?"active":""} href="/admin">COMMAND CENTRE</a>
        <a className={section==="applications"?"active":""} href="/admin/applications">APPLICATIONS <span>{applications.length}</span></a>
        <a className={section==="readiness"?"active":""} href="/admin/readiness">READINESS <span>{onboarding.filter(x=>!x.ready_to_activate && !x.status?.toLowerCase?.().includes("deleted")).length}</span></a>
        <a className={section==="lifecycle"?"active":""} href="/admin/lifecycle">LIFECYCLE <span>{institutions.length}</span></a>
        <a className={section==="communications"?"active":""} href="/admin/communications">COMMUNICATIONS</a>
        <a className={section==="pricing"?"active":""} href="/admin/pricing">PRICING</a>
      </div>
    </div>
    {message&&<div className="notice admin-message" role="status">{message}</div>}

    {section === "dashboard" && (
      <section className="admin-command-centre">
        <div className="admin-section-heading">
          <div><div className="eyebrow">COMMAND CENTRE</div><h2>What needs your attention?</h2></div>
          <span className="count-badge">Controlled platform operations</span>
        </div>
        <div className="admin-command-grid">
          <a className="admin-command-card" href="/admin/applications"><div className="eyebrow">01 · ADMISSION GATE</div><h3>Institution Applications</h3><p>Review, approve, return or reject institutions seeking entry to IMBOP.</p><strong>{applications.length} awaiting action →</strong></a>
          <a className="admin-command-card" href="/admin/readiness"><div className="eyebrow">02 · ONBOARDING & READINESS</div><h3>Institution Readiness</h3><p>Complete configuration, assign administrators and prepare approved institutions for activation.</p><strong>{onboarding.filter(x=>!x.ready_to_activate && !x.status?.toLowerCase?.().includes("deleted")).length} need action →</strong></a>
          <a className="admin-command-card" href="/admin/lifecycle"><div className="eyebrow">03 · CONTROL</div><h3>Institution Lifecycle</h3><p>Manage active and existing institutions through their operating lifecycle.</p><strong>{institutions.length} institutions →</strong></a>
          <a className="admin-command-card" href="/admin/communications"><div className="eyebrow">04 · COMMUNICATIONS CENTRE</div><h3>SE Admin Communications</h3><p>Send controlled administrative communications and process queued email.</p><strong>{commRecipients.length} institution admins →</strong></a>
          <a className="admin-command-card admin-command-card-secondary" href="/admin/pricing"><div className="eyebrow">05 · COMMERCIAL CONTROL</div><h3>IMBOP Pricing &amp; Plans</h3><p>Configure the numbers-based institutional pricing model and transition rules.</p><strong>{pricingPlans.length} plans →</strong></a>
        </div>
      </section>
    )}
    {section === "applications" && (
    <section className="admin-section">
      <div className="section-heading"><div><div className="eyebrow">ADMISSION GATE</div><h2>Institution Applications</h2></div><span className="count-badge">{applications.length} awaiting action</span></div>
      {!applications.length?<div className="card empty-state">No institution applications awaiting action.</div>:<div className="admin-grid">{applications.map(a=><article className="admin-card" key={a.id}>
        <div className="admin-card-head"><div><div className="eyebrow">APPLICATION</div><h3>{a.institution_name}</h3><p className="admin-contact">{a.contact_name} · {a.contact_email}</p></div><span className="status-badge">{a.status}</span></div>
        <div className="detail-grid">
          <div><span>Legal name</span><strong>{a.legal_name||"—"}</strong></div><div><span>Type</span><strong>{a.institution_type||"—"}</strong></div>
          <div><span>Phone</span><strong>{a.contact_phone||"—"}</strong></div><div><span>Members</span><strong>{a.membership_size??"—"}</strong></div>
          <div><span>Location</span><strong>{a.location||"—"}</strong></div><div><span>Website</span><strong>{a.website||"—"}</strong></div>
        </div>
        {a.description&&<p className="admin-description">{a.description}</p>}
        <div className="admin-actions">
          <button className="admin-btn" disabled={working===a.id} onClick={()=>openDrawer("review",{id:a.id,action:"REVIEW",title:"Start application review"})}>START REVIEW</button>
          <button className="admin-btn admin-btn-primary" disabled={working===a.id} onClick={()=>openDrawer("review",{id:a.id,action:"APPROVE",title:"Approve institution application"})}>APPROVE</button>
          <button className="admin-btn" disabled={working===a.id} onClick={()=>openDrawer("review",{id:a.id,action:"RETURN",title:"Return institution application"})}>RETURN</button>
          <button className="admin-btn admin-btn-danger" disabled={working===a.id} onClick={()=>openDrawer("review",{id:a.id,action:"REJECT",title:"Reject institution application"})}>REJECT</button>
        </div>
      </article>)}</div>}
    </section>
    )}

    {section === "readiness" && (
    <section className="admin-section">
      <div className="section-heading"><div><div className="eyebrow">ONBOARDING & READINESS</div><h2>Institution Readiness</h2></div><span className="count-badge">{onboarding.filter(x=>!x.ready_to_activate && !x.status?.toLowerCase?.().includes("deleted")).length} need action</span></div>
      <div className="admin-grid">{institutions.filter(i=>!i.deleted_at).map(i=>{const r=readiness(i.id);return <article className="admin-card" key={i.id}>
        <div className="admin-card-head"><div><div className="eyebrow">ONBOARDING</div><h3>{i.name}</h3></div><span className={"status-badge "+(r.ready_to_activate?"":"status-deleted")}>{r.ready_to_activate?"READY":"NOT READY"}</span></div>
        <div className="detail-grid">
          <div><span>Configuration</span><strong>{r.configured?"COMPLETE":"REQUIRED"}</strong></div>
          <div><span>Active administrators</span><strong>{r.active_admin_count??0}</strong></div>
          <div><span>Activation</span><strong>{r.ready_to_activate?"READY":"BLOCKED"}</strong></div>
          <div><span>Admin contact</span><strong>{r.admin_emails?.length?r.admin_emails.join(", "):"None assigned"}</strong></div>
        </div>
        <div className="admin-actions">
          {!r.configured&&<button className="admin-btn admin-btn-primary" disabled={working===i.id} onClick={()=>openDrawer("confirm-config",{id:i.id,title:"Complete institution configuration"})}>COMPLETE CONFIGURATION</button>}
          {(r.active_admin_count??0)<1&&<button className="admin-btn" disabled={working===i.id} onClick={()=>openDrawer("assign-admin",{id:i.id,title:"Assign / invite institution administrator"})>ASSIGN / INVITE ADMIN</button>}
          {r.ready_to_activate&&String(i.status).toUpperCase()!=="ACTIVE"&&<button className="admin-btn admin-btn-primary" disabled={working===i.id} onClick={()=>manageInstitution(i.id,"ACTIVATE")}>ACTIVATE</button>}
        </div>
      </article>})}</div>
    </section>
    )}

    {section === "pricing" && (
    <section className="admin-section">
      <div className="section-heading"><div><div className="eyebrow">COMMERCIAL CONTROL</div><h2>IMBOP Pricing &amp; Plans</h2></div><span className="count-badge">{pricingPlans.length} plans</span></div>
      <div className="card pricing-admin-note"><b>SE IMBOP is the pricing authority.</b> The first 50 IMBOP Onboards are free. Beyond 50, the Institution moves to the applicable numbers-based plan. The first transition month may use the discounted minimum configured below. Individual Institution Members are not billed.</div>
      <div className="pricing-admin-grid">{pricingPlans.map(plan=><article className="admin-card pricing-admin-card" key={plan.id}>
        <div className="admin-card-head"><div><div className="eyebrow">{plan.plan_code}</div><h3>{plan.plan_name}</h3></div><span className="status-badge">{plan.pricing_mode}</span></div>
        <div className="detail-grid">
          <div><span>IMBOP Onboards</span><strong>{plan.min_onboards.toLocaleString("en-KE")} – {plan.max_onboards==null?"50,001+":plan.max_onboards.toLocaleString("en-KE")}</strong></div>
          <div><span>Standard monthly fee</span><strong>{plan.monthly_fee_kes==null?"NEGOTIATED":"KES "+Number(plan.monthly_fee_kes).toLocaleString("en-KE")}</strong></div>
          <div><span>Transition minimum</span><strong>{plan.transition_minimum_kes==null?"—":"KES "+Number(plan.transition_minimum_kes).toLocaleString("en-KE")}</strong></div>
          <div><span>Status</span><strong>{plan.active?"ACTIVE":"HIDDEN"}</strong></div>
        </div>
        <details className="pricing-edit"><summary>EDIT PLAN FIGURES</summary>
          <div className="grid">
            <div><label className="label">PLAN NAME</label><input className="input" defaultValue={plan.plan_name} id={"pn-"+plan.id}/></div>
            <div><label className="label">MONTHLY FEE (KES)</label><input className="input" type="number" min="0" defaultValue={plan.monthly_fee_kes??""} id={"pf-"+plan.id}/></div>
          </div>
          <div className="grid">
            <div><label className="label">TRANSITION MINIMUM (KES)</label><input className="input" type="number" min="0" defaultValue={plan.transition_minimum_kes??""} id={"pt-"+plan.id}/></div>
            <div><label className="label">PRICING MODE</label><select className="input" defaultValue={plan.pricing_mode} id={"pm-"+plan.id}><option>FREE</option><option>STANDARD</option><option>NEGOTIATED</option></select></div>
          </div>
          <label className="label">DESCRIPTION</label><textarea className="textarea" defaultValue={plan.description||""} id={"pd-"+plan.id}/>
          <button className="admin-btn admin-btn-primary" disabled={working===plan.id} onClick={async()=>{
            setWorking(plan.id);setMessage("");
            const v=await supabase.rpc("upsert_platform_pricing_plan",{p_plan_code:plan.plan_code,p_plan_name:document.getElementById("pn-"+plan.id).value,p_min_onboards:plan.min_onboards,p_max_onboards:plan.max_onboards,p_monthly_fee_kes:document.getElementById("pf-"+plan.id).value===""?null:Number(document.getElementById("pf-"+plan.id).value),p_transition_minimum_kes:document.getElementById("pt-"+plan.id).value===""?null:Number(document.getElementById("pt-"+plan.id).value),p_pricing_mode:document.getElementById("pm-"+plan.id).value,p_description:document.getElementById("pd-"+plan.id).value,p_active:plan.active});
            if(v.error||!v.data?.ok)setMessage(v.error?.message||v.data?.error||"Pricing update failed.");else{setMessage("Pricing plan updated.");await loadData();}
            setWorking(null);
          }}>SAVE PRICING PLAN</button>
        </details>
      </article>)}</div>
    </section>
    )}

    {section === "communications" && (
    <section className="admin-section">
      <div className="section-heading"><div><div className="eyebrow">COMMUNICATIONS CENTRE</div><h2>SE Admin Communications</h2></div><span className="count-badge">{commRecipients.length} institution admins</span></div>
      <div className="card pricing-admin-note"><b>Controlled communications only.</b> Messages sent here are recorded as ADMIN communications and delivered in-app. Email delivery is intentionally not marked as sent until an approved email provider is connected.</div>
      <div className="card">
        <div className="grid">
          <div><label className="label">RECIPIENT</label><select className="input" value={commDraft.recipient} onChange={e=>setCommDraft(d=>({...d,recipient:e.target.value}))}>
            <option value="">Select institution administrator</option>
            {commRecipients.map(r=><option key={r.user_id} value={r.user_id}>{r.institution_name} — {r.email}</option>)}
          </select></div>
          <div><label className="label">TEMPLATE</label><select className="input" value={commDraft.template} onChange={e=>{
            const t=commTemplates.find(x=>x.template_code===e.target.value);
            setCommDraft(d=>({...d,template:e.target.value,subject:t?.default_subject||d.subject,body:t?.default_body||d.body}));
          }}><option value="">Custom message</option>{commTemplates.map(t=><option key={t.template_code} value={t.template_code}>{t.template_name}</option>)}</select></div>
        </div>
        <label className="label">SUBJECT</label><input className="input" value={commDraft.subject} onChange={e=>setCommDraft(d=>({...d,subject:e.target.value}))}/>
        <label className="label">MESSAGE</label><textarea className="textarea" rows="7" value={commDraft.body} onChange={e=>setCommDraft(d=>({...d,body:e.target.value}))}/>
        <button className="admin-btn admin-btn-primary" disabled={working==="comm"} onClick={async()=>{
          const r=commRecipients.find(x=>x.user_id===commDraft.recipient);
          if(!r||!commDraft.subject.trim()||!commDraft.body.trim()) return setMessage("Recipient, subject and message are required.");
          setWorking("comm");setMessage("");
          const v=await supabase.rpc("send_platform_in_app_communication",{p_recipient_user_id:r.user_id,p_institution_id:r.institution_id,p_subject:commDraft.subject,p_body:commDraft.body,p_communication_type:commTemplates.find(x=>x.template_code===commDraft.template)?.communication_type||"PLATFORM_NOTICE",p_event_type:"ADMIN_MESSAGE"});
          if(v.error||!v.data?.ok)setMessage(v.error?.message||v.data?.error||"Communication send failed.");
          else {setMessage("Communication recorded and delivered in-app.");setCommDraft({recipient:"",template:"",subject:"",body:""});}
          setWorking(null);
        }}>SEND IN-APP COMMUNICATION</button>
        <div className="admin-actions" style={{marginTop:"0.75rem"}}>
          <button className="admin-btn" disabled={working==="email-dispatch"} onClick={dispatchOneQueuedEmail}>{working==="email-dispatch"?"PROCESSING…":"PROCESS ONE QUEUED EMAIL"}</button>
        </div>
      </div>
    </section>
    )}

    {section === "lifecycle" && (
    <section className="admin-section">
      <div className="section-heading"><div><div className="eyebrow">CONTROL</div><h2>Institution Lifecycle</h2></div><span className="count-badge">{institutions.length} institutions</span></div>
      <div className="admin-grid">{institutions.map(i=><article className="admin-card" key={i.id}>
        <div className="admin-card-head"><div><div className="eyebrow">INSTITUTION</div><h3>{i.name}</h3></div><span className={"status-badge "+(i.deleted_at?"status-deleted":"")}>{i.deleted_at?"DELETED":String(i.status||"").toUpperCase()}</span></div>
        {i.slug==="imbop-gate-2-security-test"&&<span className="test-badge">GATE 2 TEST</span>}
        {i.status_reason&&<p className="admin-description"><strong>Status note:</strong> {i.status_reason}</p>}
        <div className="admin-actions lifecycle-actions">{controls(i)}</div>
      </article>)}</div>
    </section>
    )}
  </main>    {drawer && <div className="admin-drawer-backdrop" onClick={()=>setDrawer(null)}>
      <aside className="admin-drawer" role="dialog" aria-modal="true" onClick={e=>e.stopPropagation()}>
        <button className="admin-drawer-close" onClick={()=>setDrawer(null)} aria-label="Close">×</button>
        <div className="eyebrow">CONTROLLED ACTION</div>
        <h2>{drawer.title}</h2>
        {drawer.type==="review" && <>{drawer.action==="APPROVE" ? <p>Approve this institution application and move the institution into pending onboarding.</p> : <><label className="label">REVIEW NOTES / REASON</label><textarea className="textarea" rows="6" value={drawerText} onChange={e=>setDrawerText(e.target.value)} /></>}</>}
        {drawer.type==="confirm-config" && <p>Complete the standard IMBOP configuration for this institution. The action will be audited.</p>}
        {drawer.type==="assign-admin" && <div className="grid">
          <div><label className="label">EMAIL</label><input className="input" value={drawerForm.email} onChange={e=>setDrawerForm(f=>({...f,email:e.target.value}))}/></div>
          <div><label className="label">FIRST NAME</label><input className="input" value={drawerForm.first} onChange={e=>setDrawerForm(f=>({...f,first:e.target.value}))}/></div>
          <div><label className="label">LAST NAME</label><input className="input" value={drawerForm.last} onChange={e=>setDrawerForm(f=>({...f,last:e.target.value}))}/></div>
        </div>}
        {drawer.type==="lifecycle" && <><p>{drawer.action} is a controlled lifecycle action and will be recorded in the audit trail.</p><label className="label">REASON</label><textarea className="textarea" rows="5" value={drawerText} onChange={e=>setDrawerText(e.target.value)} /></>}
        <div className="admin-actions">
          <button className="admin-btn" onClick={()=>setDrawer(null)}>CANCEL</button>
          <button className="admin-btn admin-btn-primary" onClick={()=>{
            if(drawer.type==="review") reviewApplication(drawer.id,drawer.action,drawerText);
            else if(drawer.type==="confirm-config") configureInstitution(drawer.id).then(()=>setDrawer(null));
            else if(drawer.type==="assign-admin") assignAdmin(drawer.id,drawerForm);
            else if(drawer.type==="lifecycle") manageInstitution(drawer.id,drawer.action,drawerText);
          }}>CONFIRM</button>
        </div>
      </aside>
    </div>}
<Footer/></>;
}
