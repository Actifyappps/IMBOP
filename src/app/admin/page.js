"use client";

import { useEffect, useState } from "react";
import Nav from "../components/Nav";
import Footer from "../components/Footer";
import { supabase } from "../lib/supabase";

const REVIEWABLE = ["SUBMITTED", "PENDING_REVIEW", "RETURNED"];

export default function AdminPage() {
  const [applications, setApplications] = useState([]);
  const [institutions, setInstitutions] = useState([]);
  const [onboarding, setOnboarding] = useState([]);
  const [loading, setLoading] = useState(true);
  const [working, setWorking] = useState(null);
  const [message, setMessage] = useState("");
  const [adminDrafts, setAdminDrafts] = useState({});

  async function loadData() {
    setLoading(true); setMessage("");
    const [a, i, o] = await Promise.all([
      supabase.from("institution_applications").select("*").in("status", REVIEWABLE).order("submitted_at", {ascending:true}),
      supabase.from("institutions").select("id,name,legal_name,slug,status,status_reason,created_at,deleted_at").order("created_at", {ascending:true}),
      supabase.rpc("platform_institution_onboarding_overview")
    ]);
    if (a.error) setMessage(a.error.message);
    if (i.error) setMessage((p)=>p || i.error.message);
    if (o.error) setMessage((p)=>p || o.error.message);
    setApplications(a.data || []); setInstitutions(i.data || []); setOnboarding(o.data || []); setLoading(false);
  }
  useEffect(()=>{loadData()},[]);

  function readiness(id) {
    return onboarding.find(x=>x.id===id) || {};
  }

  async function reviewApplication(id, action) {
    let notes = "";
    if (action === "RETURN" || action === "REJECT") {
      notes = window.prompt(action + " application. Enter review notes/reason:");
      if (notes === null) return;
      notes = notes.trim();
      if (!notes) return setMessage("Review notes/reason are required.");
    }
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

  async function assignAdmin(id) {
    const d=adminDrafts[id]||{};
    const email=window.prompt("Institution administrator email:",d.email||"");
    if(email===null)return;
    const first=window.prompt("Administrator first name (optional):",d.first||"");
    if(first===null)return;
    const last=window.prompt("Administrator last name (optional):",d.last||"");
    if(last===null)return;
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

  async function manageInstitution(id, action) {
    const reason=window.prompt(action+" institution. Enter reason:");
    if(reason===null)return;
    if(!reason.trim())return setMessage("A reason is required.");
    setWorking(id);setMessage("");
    const {data,error}=await supabase.rpc("manage_institution",{p_institution_id:id,p_action:action,p_reason:reason.trim()});
    if(error){setMessage(error.message);setWorking(null);return}
    if(!data?.ok){setMessage(data?.message||data?.error||"Institution lifecycle action failed.");setWorking(null);return}
    setMessage(action+" completed and audited.");await loadData();setWorking(null);
  }

  function controls(i){
    const s=String(i.status||"").toUpperCase();
    if(i.deleted_at)return <button className="admin-btn admin-btn-primary" onClick={()=>manageInstitution(i.id,"RESTORE")}>RESTORE</button>;
    return <>
      {s!=="ACTIVE"&&<button className="admin-btn admin-btn-primary" onClick={()=>manageInstitution(i.id,"ACTIVATE")}>ACTIVATE</button>}
      <button className="admin-btn" onClick={()=>manageInstitution(i.id,"PAUSE")}>PAUSE</button>
      <button className="admin-btn" onClick={()=>manageInstitution(i.id,"SUSPEND")}>SUSPEND</button>
      <button className="admin-btn admin-btn-danger" onClick={()=>manageInstitution(i.id,"SHUT")}>SHUT</button>
      <button className="admin-btn admin-btn-danger" onClick={()=>manageInstitution(i.id,"DELETE")}>DELETE</button>
    </>;
  }

  if(loading)return <><Nav authenticated/><main className="wrap"><div className="card">Loading platform administration…</div></main><Footer/></>;

  return <><Nav authenticated/><main className="wrap admin-page">
    <div className="platform-label"><b>SE PLATFORM ADMINISTRATION</b><span>Controlled platform-owner administration</span></div>
    <header className="admin-hero"><div><div className="eyebrow">CONTROLLED ADMIN</div><h1>SE Platform Administration</h1><p>Review institutional applications, complete onboarding readiness, and manage the controlled institution lifecycle.</p></div></header>
    {message&&<div className="notice admin-message" role="status">{message}</div>}

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
          <button className="admin-btn" disabled={working===a.id} onClick={()=>reviewApplication(a.id,"REVIEW")}>START REVIEW</button>
          <button className="admin-btn admin-btn-primary" disabled={working===a.id} onClick={()=>reviewApplication(a.id,"APPROVE")}>APPROVE</button>
          <button className="admin-btn" disabled={working===a.id} onClick={()=>reviewApplication(a.id,"RETURN")}>RETURN</button>
          <button className="admin-btn admin-btn-danger" disabled={working===a.id} onClick={()=>reviewApplication(a.id,"REJECT")}>REJECT</button>
        </div>
      </article>)}</div>}
    </section>

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
          {!r.configured&&<button className="admin-btn admin-btn-primary" disabled={working===i.id} onClick={()=>configureInstitution(i.id)}>COMPLETE CONFIGURATION</button>}
          {(r.active_admin_count??0)<1&&<button className="admin-btn" disabled={working===i.id} onClick={()=>assignAdmin(i.id)}>ASSIGN / INVITE ADMIN</button>}
          {r.ready_to_activate&&String(i.status).toUpperCase()!=="ACTIVE"&&<button className="admin-btn admin-btn-primary" disabled={working===i.id} onClick={()=>manageInstitution(i.id,"ACTIVATE")}>ACTIVATE</button>}
        </div>
      </article>})}</div>
    </section>

    <section className="admin-section">
      <div className="section-heading"><div><div className="eyebrow">CONTROL</div><h2>Institution Lifecycle</h2></div><span className="count-badge">{institutions.length} institutions</span></div>
      <div className="admin-grid">{institutions.map(i=><article className="admin-card" key={i.id}>
        <div className="admin-card-head"><div><div className="eyebrow">INSTITUTION</div><h3>{i.name}</h3></div><span className={"status-badge "+(i.deleted_at?"status-deleted":"")}>{i.deleted_at?"DELETED":String(i.status||"").toUpperCase()}</span></div>
        {i.slug==="imbop-gate-2-security-test"&&<span className="test-badge">GATE 2 TEST</span>}
        {i.status_reason&&<p className="admin-description"><strong>Status note:</strong> {i.status_reason}</p>}
        <div className="admin-actions lifecycle-actions">{controls(i)}</div>
      </article>)}</div>
    </section>
  </main><Footer/></>;
}
