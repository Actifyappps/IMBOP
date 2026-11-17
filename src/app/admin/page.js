"use client";

import { useEffect, useState } from "react";
import Nav from "../components/Nav";
import Footer from "../components/Footer";
import { supabase } from "../lib/supabase";

const REVIEWABLE = ["SUBMITTED", "PENDING_REVIEW", "RETURNED"];

export default function AdminPage() {
  const [applications, setApplications] = useState([]);
  const [institutions, setInstitutions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [working, setWorking] = useState(null);
  const [message, setMessage] = useState("");

  async function loadData() {
    setLoading(true); setMessage("");
    const [a, i] = await Promise.all([
      supabase.from("institution_applications").select("*").in("status", REVIEWABLE).order("submitted_at", {ascending:true}),
      supabase.from("institutions").select("id,name,legal_name,slug,status,status_reason,created_at,deleted_at").order("created_at", {ascending:true})
    ]);
    if (a.error) setMessage(a.error.message);
    if (i.error) setMessage((p)=>p || i.error.message);
    setApplications(a.data || []); setInstitutions(i.data || []); setLoading(false);
  }
  useEffect(()=>{loadData()},[]);

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
    const {data,error}=await supabase.rpc("review_institution_application",{p_application_id:id,p_action:action,p_notes:notes||null});
    if(error){setMessage(error.message);setWorking(null);return}
    if(!data?.ok){setMessage(data?.message||data?.error||"Institution application action failed.");setWorking(null);return}
    setMessage(action==="REVIEW"?"Institution application moved to PENDING REVIEW.":action==="APPROVE"?"Institution application approved and onboarded as PENDING.":action==="RETURN"?"Institution application returned for correction.":"Institution application rejected and retained for audit.");
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
    <header className="admin-hero"><div><div className="eyebrow">CONTROLLED ADMIN</div><h1>SE Platform Administration</h1><p>Review institutional applications and manage the controlled institution lifecycle.</p></div></header>
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
