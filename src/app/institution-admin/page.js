{"use client";
import {useEffect,useMemo,useState} from "react";
import {useSearchParams} from "next/navigation";
import {supabase} from "../../lib/supabase";
import Nav from "../../components/Nav";
import Footer from "../../components/Footer";

const money=n=>n==null?"NEGOTIATED":"KES "+Number(n).toLocaleString("en-KE");
const tabs=[["overview","OVERVIEW"],["applications","APPLICATIONS"],["members","MEMBERS"],["space","IMBOP SPACE"],["communications","COMMUNICATIONS"],["plan","PLAN"]];

export default function InstitutionAdmin(){
 const params=useSearchParams(), tab=params.get("tab")||"overview";
 const[ctx,setCtx]=useState(null),[dash,setDash]=useState(null),[apps,setApps]=useState([]),[members,setMembers]=useState([]),[comms,setComms]=useState([]),[space,setSpace]=useState(null),[anns,setAnns]=useState([]),[plans,setPlans]=useState([]),[loading,setLoading]=useState(true),[err,setErr]=useState(""),[notice,setNotice]=useState(""),[working,setWorking]=useState("");
 async function load(){
  setLoading(true);setErr("");
  const c=await supabase.rpc("get_my_institution_admin_context");
  if(c.error||!c.data?.[0]){setErr(c.error?.message||"Institution administrator access required.");setLoading(false);return}
  const institutionId=c.data[0].institution_id;setCtx(c.data[0]);
  const[d,a,m,cm,s,an,p]=await Promise.all([
   supabase.rpc("get_my_institution_admin_dashboard"),
   supabase.from("member_applications").select("id,applicant_name,email,phone,application_payload,status,submitted_at,reviewed_at,review_notes").eq("institution_id",institutionId).order("submitted_at",{ascending:false}),
   supabase.rpc("get_my_institution_admin_members"),
   supabase.rpc("get_my_communications",{p_limit:20,p_offset:0}),
   supabase.from("institution_home_settings").select("*").eq("institution_id",institutionId).maybeSingle(),
   supabase.from("institution_announcements").select("id,title,body,status,visibility,published_at,created_at").eq("institution_id",institutionId).order("created_at",{ascending:false}).limit(10),
   supabase.rpc("get_public_imbop_pricing_plans")
  ]);
  if(d.error)setErr(d.error.message);else setDash(d.data?.[0]||null);
  if(a.error)setErr(a.error.message);else setApps(a.data||[]);
  if(m.error)setErr(m.error.message);else setMembers(m.data||[]);
  if(cm.error)setErr(cm.error.message);else setComms(cm.data||[]);
  if(s.error)setErr(s.error.message);else setSpace(s.data||null);
  if(an.error)setErr(an.error.message);else setAnns(an.data||[]);
  if(p.error)setErr(p.error.message);else setPlans(p.data||[]);
  setLoading(false);
 }
 useEffect(()=>{load()},[]);
 async function review(id,action){setWorking(id+action);setNotice("");const{error}=await supabase.rpc("review_member_application",{p_application_id:id,p_action:action,p_notes:null});if(error)setErr(error.message);else{setNotice("Application updated.");await load()}setWorking("")}
 async function memberAction(id,action){
  let reason=null;if(["REJECT","SUSPEND"].includes(action)){reason=window.prompt("Reason (required):","");if(!reason)return}
  setWorking(id+action);setNotice("");const{error}=await supabase.rpc("manage_my_institution_member",{p_membership_id:id,p_action:action,p_reason:reason});
  if(error)setErr(error.message);else{setNotice("Member status updated.");await load()}setWorking("")
 }
 async function read(id){const{error}=await supabase.rpc("mark_communication_read",{p_communication_id:id});if(!error)setComms(v=>v.map(x=>x.communication_id===id?{...x,delivery_status:"READ"}:x))}
 const pendingApps=apps.filter(a=>["SUBMITTED","PENDING_REVIEW"].includes(a.status)),pendingMembers=members.filter(m=>m.membership_status==="PENDING"),unread=comms.filter(c=>c.delivery_status!=="READ").length;
 const onboards=Number(dash?.onboarded_member_count||0),stated=Number(dash?.stated_membership_count||0),free=Number(dash?.free_onboards||50);
 if(loading)return <><Nav authenticated/><main className="wrap"><div className="card"><div className="eyebrow">INSTITUTION ADMINISTRATION</div><h1>Loading institution workspace…</h1></div></main><Footer/></>;
 if(err&&!ctx)return <><Nav authenticated/><main className="wrap"><div className="notice error">{err}</div></main><Footer/></>;
 const go=t=>{window.location.href=t==="overview"?"/institution-admin":"/institution-admin?tab="+t};
 return <><Nav authenticated/><main className="wrap">
  <div className="eyebrow">INSTITUTION ADMINISTRATION</div><div className="section-heading"><div><h1>{ctx?.institution_name||"Institution workspace"}</h1><p className="muted">Your institution’s control room on IMBOP.</p></div><div className="status-badge">{dash?.institution_status||"ACTIVE"}</div></div>
  {err&&<div className="notice error">{err}</div>}{notice&&<div className="notice">{notice}</div>}
  <nav className="admin-command-nav"><div className="admin-command-links">{tabs.map(([k,l])=><a key={k} href={k==="overview"?"/institution-admin":"/institution-admin?tab="+k} className={tab===k?"active":""}>{l}{k==="applications"&&pendingApps.length?<span>{pendingApps.length}</span>:null}{k==="members"&&pendingMembers.length?<span>{pendingMembers.length}</span>:null}{k==="communications"&&unread?<span>{unread}</span>:null}</a>)}</div></nav>
  {tab==="overview"&&<Overview dash={dash} onboards={onboards} free={free} pendingApps={pendingApps.length} pendingMembers={pendingMembers.length} unread={unread} stated={stated} go={go}/>}
  {tab==="applications"&&<Applications apps={apps} working={working} review={review}/>}
  {tab==="members"&&<Members members={members} working={working} action={memberAction}/>}
  {tab==="space"&&<Space dash={dash} space={space} anns={anns}/>}
  {tab==="communications"&&<Communications items={comms} read={read}/>}
  {tab==="plan"&&<Plan dash={dash} plans={plans} onboards={onboards}/>}
 </main><Footer/></>
}

function Overview({dash,onboards,free,pendingApps,pendingMembers,unread,stated,go}){
 const coverage=Number(dash?.onboarding_coverage_percent||0);
 return <section className="admin-command-centre"><div className="admin-section-heading"><div><div className="eyebrow">01 — WHAT NEEDS YOUR ATTENTION?</div><h2>Institution Command Centre</h2></div></div>
 <section className="billing-hero"><div><div className="eyebrow">IMBOP ONBOARDS</div><div className="billing-number">{onboards.toLocaleString("en-KE")} <span>/ {free.toLocaleString("en-KE")} FREE</span></div><p><b>{onboards<free?((free-onboards)+" starter places remaining."):"Starter allowance reached."}</b></p></div><div className="billing-plan"><span>CURRENT PLAN</span><strong>{dash?.current_plan_name||"Founding / Starter"}</strong><b>{money(dash?.current_monthly_fee_kes)}</b></div></section>
 <div className="admin-command-grid">
  <button className="admin-command-card" onClick={()=>go("applications")}><div className="eyebrow">01</div><h3>Member Applications</h3><p>{pendingApps?pendingApps+" application(s) awaiting review.":"No applications awaiting review."}</p><strong>OPEN APPLICATIONS →</strong></button>
  <button className="admin-command-card" onClick={()=>go("members")}><div className="eyebrow">02</div><h3>Members &amp; Onboards</h3><p>{pendingMembers?pendingMembers+" member(s) awaiting action.":"Member list is up to date."} {stated?coverage.toFixed(1)+"% of stated membership onboarded.":""}</p><strong>OPEN MEMBERS →</strong></button>
  <button className="admin-command-card" onClick={()=>go("space")}><div className="eyebrow">03</div><h3>IMBOP Space</h3><p>Institution profile, announcements and public-facing presence.</p><strong>OPEN IMBOP SPACE →</strong></button>
  <button className="admin-command-card" onClick={()=>go("communications")}><div className="eyebrow">04</div><h3>Communications</h3><p>{unread?unread+" unread communication(s).":"No unread platform communications."}</p><strong>OPEN COMMUNICATIONS →</strong></button>
  <button className="admin-command-card admin-command-card-secondary" onClick={()=>go("plan")}><div className="eyebrow">05</div><h3>Plan &amp; Growth</h3><p>Current numbers-based plan, thresholds and institutional billing.</p><strong>VIEW PLAN →</strong></button>
 </div></section>
}

function Applications({apps,working,review}){return <section className="admin-command-centre"><div className="admin-section-heading"><div><div className="eyebrow">MEMBER APPLICATIONS</div><h2>Review applicants for your institution</h2></div></div>{apps.length===0?<div className="card"><p>No member applications found.</p></div>:apps.map(a=><article className="card" style={{marginTop:12}} key={a.id}><div className="communication-head"><div><div className="eyebrow">{a.status}</div><h2>{a.applicant_name}</h2></div><span className="muted">{a.submitted_at?new Date(a.submitted_at).toLocaleDateString("en-KE"):"—"}</span></div><p>{a.email} · {a.phone||"—"}</p><p><b>{a.application_payload?.business_name||"Member application"}</b></p>{a.review_notes&&<div className="notice">Review note: {a.review_notes}</div>}<div className="actions">{["SUBMITTED","PENDING_REVIEW"].includes(a.status)&&<button className="btn" disabled={working===a.id+"PUBLISH"} onClick={()=>review(a.id,"PUBLISH")}>PUBLISH</button>}{!["REJECTED","PUBLISHED"].includes(a.status)&&<button className="btn alt" disabled={working===a.id+"RETURN"} onClick={()=>review(a.id,"RETURN")}>RETURN</button>}{!["REJECTED","PUBLISHED"].includes(a.status)&&<button className="btn alt" disabled={working===a.id+"REJECT"} onClick={()=>review(a.id,"REJECT")}>REJECT</button>}</div></article>)}</section>}

function Members({members,working,action}){const[q,setQ]=useState(""),[filter,setFilter]=useState("ALL");const list=members.filter(m=>(filter==="ALL"||m.membership_status===filter)&&((m.display_name||"")+" "+(m.email||"")).toLowerCase().includes(q.toLowerCase()));return <section className="admin-command-centre"><div className="admin-section-heading"><div><div className="eyebrow">MEMBERS &amp; ONBOARDS</div><h2>Authorised member base</h2></div><strong>{members.length} RECORDS</strong></div><div className="card"><input className="input" value={q} onChange={e=>setQ(e.target.value)} placeholder="Search members by name or email"/><div className="filter-presets">{["ALL","PENDING","ACTIVE","SUSPENDED","REJECTED"].map(x=><button key={x} className={"filter-chip "+(filter===x?"active":"")} onClick={()=>setFilter(x)}>{x}</button>)}</div></div><div className="communication-list" style={{marginTop:18}}>{list.length?list.map(m=><article className="card" key={m.membership_id}><div className="communication-head"><div><div className="eyebrow">{m.role_code||"MEMBER"} · {m.membership_status}</div><h2>{m.display_name||"Unnamed member"}</h2></div><span className="muted">{m.email||"—"}</span></div><div className="actions">{m.membership_status==="PENDING"&&<><button className="btn" disabled={working===m.membership_id+"APPROVE"} onClick={()=>action(m.membership_id,"APPROVE")}>APPROVE</button><button className="btn alt" disabled={working===m.membership_id+"REJECT"} onClick={()=>action(m.membership_id,"REJECT")}>REJECT</button></>}{m.membership_status==="ACTIVE"&&<button className="btn alt" onClick={()=>action(m.membership_id,"SUSPEND")}>SUSPEND</button>}{m.membership_status==="SUSPENDED"&&<button className="btn" onClick={()=>action(m.membership_id,"REACTIVATE")}>REACTIVATE</button>}</div></article>):<div className="card"><p>No members match this view.</p></div>}</div></section>}

function Space({dash,space,anns}){return <section className="admin-command-centre"><div className="admin-section-heading"><div><div className="eyebrow">IMBOP SPACE</div><h2>Your institution’s public and member-facing presence</h2></div></div><div className="admin-command-grid"><article className="card"><div className="eyebrow">INSTITUTION PROFILE</div><h2>{space?.welcome_title||"Welcome to our institution"}</h2><p>{space?.welcome_message||"No welcome message configured."}</p><div className="detail-grid"><div><span>Public discovery</span><strong>{dash?.public_discovery_enabled?"ENABLED":"NOT ENABLED"}</strong></div><div><span>Public profile</span><strong>{dash?.public_profile_enabled?"ENABLED":"NOT ENABLED"}</strong></div><div><span>Contact email</span><strong>{space?.contact_email||"—"}</strong></div><div><span>Website</span><strong>{space?.public_website_url||"—"}</strong></div></div></article><article className="card"><div className="eyebrow">VISUAL IDENTITY</div><h2>{space?.logo_url?"Logo configured":"Logo not configured"}</h2><p>Logo, hero image and institutional colours are available to the institution space.</p><div className="detail-grid"><div><span>Hero image</span><strong>{space?.hero_image_url?"CONFIGURED":"NOT CONFIGURED"}</strong></div><div><span>Announcements</span><strong>{space?.announcements_enabled?"ENABLED":"DISABLED"}</strong></div></div></article></div><div style={{marginTop:20}}><div className="eyebrow">ANNOUNCEMENTS</div><div className="communication-list" style={{marginTop:10}}>{anns.length?anns.map(a=><article className="card" key={a.id}><div className="communication-head"><h2>{a.title}</h2><span className="muted">{a.status}</span></div><p>{a.body}</p></article>):<div className="card"><p>No announcements yet.</p></div>}</div></div><div className="notice" style={{marginTop:18}}>Your institution manages its space and member operations. SE remains the authority for whether the institution itself is published in the public IMBOP directory.</div></section>}

function Communications({items,read}){return <section className="admin-command-centre"><div className="admin-section-heading"><div><div className="eyebrow">COMMUNICATIONS</div><h2>Messages for your institution</h2></div></div>{items.length?<div className="communication-list">{items.map(c=><article className={"card communication-card "+(c.delivery_status!=="READ"?"communication-unread":"")} key={c.communication_id}><div className="communication-head"><div><div className="eyebrow">{c.event_type||c.communication_type||"NOTICE"}</div><h2>{c.subject}</h2></div><span className="muted">{c.created_at?new Date(c.created_at).toLocaleString("en-KE"):"—"}</span></div><div className="communication-body">{c.body}</div>{c.delivery_status!=="READ"&&<button className="btn alt" onClick={()=>read(c.communication_id)}>MARK AS READ</button>}</article>)}</div>:<div className="card"><p>No communications yet.</p></div>}</section>}

function Plan({dash,plans,onboards}){return <section className="admin-command-centre"><div className="admin-section-heading"><div><div className="eyebrow">PLAN &amp; GROWTH</div><h2>Your IMBOP commercial position</h2></div></div><section className="billing-hero"><div><div className="eyebrow">CURRENT IMBOP ONBOARDS</div><div className="billing-number">{onboards.toLocaleString("en-KE")}</div><p>The Institution is the IMBOP customer. Individual members are not billed separately.</p></div><div className="billing-plan"><span>CURRENT PLAN</span><strong>{dash?.current_plan_name||"—"}</strong><b>{money(dash?.current_monthly_fee_kes)}</b></div></section>{onboards>Number(dash?.free_onboards||50)&&<div className="card growth-message"><div className="eyebrow">GROWTH NOTICE</div><h2>Congratulations — your Institution is growing.</h2><p>Your first 50 IMBOP Onboards were free. The transition minimum is <b>KES {Number(dash?.transition_minimum_kes||5000).toLocaleString("en-KE")}</b>.</p></div>}<div className="plans-grid" style={{marginTop:18}}>{plans.map(p=><article className="card plan-card" key={p.id}><div className="plan-range">{Number(p.min_onboards).toLocaleString("en-KE")}–{p.max_onboards==null?"UP":Number(p.max_onboards).toLocaleString("en-KE")}<span>IMBOP ONBOARDS</span></div><h2>{p.plan_name}</h2><div className="plan-price">{money(p.monthly_fee_kes)}<small>{p.monthly_fee_kes!=null?"/ MONTH":""}</small></div><p>{p.description||""}</p></article>)}</div></section>}