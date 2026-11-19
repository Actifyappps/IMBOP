"use client";
import {useEffect,useMemo,useState} from "react";
import Nav from "../../components/Nav";
import Footer from "../../components/Footer";
import {supabase} from "../../lib/supabase";

const emptyBusiness={name:"",description:"",business_type:"",sector:"",value_chain:"",county:"",sub_county:"",location:"",msea_registration_ref:"",brs_enterprise_name:"",brs_registration_ref:""};
const emptyProfile={headline:"",public_description:"",contact_phone:"",contact_email:"",public_location:"",visibility:"INSTITUTION"};
const emptyItem={intent_type:"OFFER",title:"",short_summary:"",description:"",category:"",sector:"",value_chain:"",quantity:"",location:"",price_basis:"",availability:"",required_by:"",contact_preference:""};
const emptyOpportunity={opportunity_type:"PARTNERSHIP",title:"",short_summary:"",description:"",sector:"",value_chain:"",audience:"",location:"",opportunity_scale:"",timeline:"",participation_terms:"",contact_preference:""};

export default function ContentWorkspace(){
 const [user,setUser]=useState(null),[institution,setInstitution]=useState(null),[isAdmin,setIsAdmin]=useState(false);
 const [businesses,setBusinesses]=useState([]),[profiles,setProfiles]=useState([]),[items,setItems]=useState([]),[opportunities,setOpportunities]=useState([]),[media,setMedia]=useState([]);
 const [tab,setTab]=useState("business"),[editor,setEditor]=useState(null),[form,setForm]=useState({}),[busy,setBusy]=useState(false),[message,setMessage]=useState("Loading…");

 const load=async()=>{
  const {data:{user:u}}=await supabase.auth.getUser(); if(!u){location.href="/login";return} setUser(u);
  const admin=await supabase.rpc("get_my_institution_admin_context"); let inst=admin.data?.[0]||null;
  if(inst){setIsAdmin(true)} else {
   const m=await supabase.from("memberships").select("institution_id,institutions(id,name)").eq("user_id",u.id).eq("status","active").limit(1).maybeSingle();
   if(m.error||!m.data){setMessage("No active institution membership was found.");return}
   inst={institution_id:m.data.institution_id,institution_name:m.data.institutions?.name||"Institution"};
  }
  setInstitution(inst); const iid=inst.institution_id;
  const [b,p,i,o,c]=await Promise.all([
   supabase.from("businesses").select("*").eq("institution_id",iid).order("created_at",{ascending:false}),
   supabase.from("business_profiles").select("*").eq("institution_id",iid).order("updated_at",{ascending:false}),
   supabase.from("market_items").select("*").eq("institution_id",iid).order("updated_at",{ascending:false}),
   supabase.from("opportunities").select("*").eq("institution_id",iid).order("updated_at",{ascending:false}),
   supabase.from("content_media").select("*").eq("institution_id",iid).order("sort_order")
  ]);
  const err=[b,p,i,o,c].find(x=>x.error); if(err){setMessage(err.error.message);return}
  setBusinesses(b.data||[]);setProfiles(p.data||[]);setItems(i.data||[]);setOpportunities(o.data||[]);setMedia(c.data||[]);setMessage("");
 };
 useEffect(()=>{load()},[]);

 const profileMap=useMemo(()=>Object.fromEntries(profiles.map(p=>[p.business_id,p])),[profiles]);
 const open=(type,row=null)=>{
  setEditor({type,id:row?.id||null});
  setForm(row?{...row}:type==="business"?{...emptyBusiness}:type==="profile"?{...emptyProfile}:type==="item"?{...emptyItem}:{...emptyOpportunity});
 };
 const save=async()=>{
  if(!editor)return;setBusy(true);setMessage("");try{
   const iid=institution.institution_id;let r;
   if(editor.type==="business"){
    const data={...form,institution_id:iid,created_by_user_id:user.id,slug:(form.name||"").toLowerCase().trim().replace(/[^a-z0-9]+/g,"-").replace(/^-|-$/g,"").slice(0,180)||crypto.randomUUID().slice(0,8)};
    r=editor.id?await supabase.from("businesses").update(data).eq("id",editor.id):await supabase.from("businesses").insert(data);
   } else if(editor.type==="profile"){
    const business_id=form.business_id||businesses[0]?.id;if(!business_id)throw new Error("Create a business first.");
    if(editor.id && form.publication_state==="PUBLISHED"){if(!isAdmin)throw new Error("Published business profiles are controlled through institutional review.");const unpublish=await supabase.rpc("review_institution_business_profile",{p_profile_id:editor.id,p_action:"UNPUBLISH",p_notes:"Profile edited; returned to draft for review."});if(unpublish.error)throw unpublish.error;form={...form,publication_state:"UNPUBLISHED",visibility:"INSTITUTION",published_at:null,published_by_user_id:null}}
    const data={...form,business_id,institution_id:iid,profile_status:"ACTIVE",publication_state:editor.id?"DRAFT":"DRAFT",visibility:form.visibility==="PUBLIC"?"INSTITUTION":(form.visibility||"INSTITUTION"),published_at:null,published_by_user_id:null};r=editor.id?await supabase.from("business_profiles").update(data).eq("id",editor.id):await supabase.from("business_profiles").insert(data);
   } else if(editor.type==="item"){
    const data={...form,institution_id:iid,created_by_user_id:user.id,status:"DRAFT",publication_state:form.publication_state||"DRAFT"};
    r=editor.id?await supabase.from("market_items").update(data).eq("id",editor.id):await supabase.from("market_items").insert(data);
   } else {
    const data={...form,institution_id:iid,created_by_user_id:user.id,status:"DRAFT",publication_state:form.publication_state||"DRAFT",visibility:form.visibility||"INSTITUTION",verification_state:form.verification_state||"UNVERIFIED"};
    r=editor.id?await supabase.from("opportunities").update(data).eq("id",editor.id):await supabase.from("opportunities").insert(data);
   }
   if(r.error)throw r.error;setEditor(null);setForm({});await load();setMessage("Saved. Editing does not publish automatically.");
  }catch(e){setMessage(e.message)}finally{setBusy(false)}
 };
 const submit=async(table,id)=>{setBusy(true);let r;if(table==="business_profiles"){r=await supabase.from(table).update({publication_state:"SUBMITTED"}).eq("id",id)}else{r=await supabase.from(table).update({publication_state:"SUBMITTED"}).eq("id",id)}setMessage(r.error?r.error.message:"Submitted for institutional review.");if(!r.error)await load();setBusy(false)};
 const review=async(table,id,state)=>{setBusy(true);const fn=table==="business_profiles"?"review_institution_business_profile":table==="market_items"?"review_institution_market_item":"review_institution_opportunity";const r=await supabase.rpc(fn,{[table==="business_profiles"?"p_profile_id":table==="market_items"?"p_item_id":"p_opportunity_id"]:id,p_action:state==="PUBLISHED"?"PUBLISH":state==="RETURNED"?"RETURN":state,p_notes:null});setMessage(r.error?r.error.message:"Review decision recorded.");if(!r.error)await load();setBusy(false)};
 const upload=async(e,type,id)=>{const f=e.target.files?.[0];if(!f)return;if(f.size>10*1024*1024){setMessage("Images are limited to 10 MB.");return}setBusy(true);try{const path=user.id+"/"+crypto.randomUUID()+"-"+f.name.replace(/[^a-zA-Z0-9._-]/g,"-");const u=await supabase.storage.from("imbop-media").upload(path,f,{contentType:f.type});if(u.error)throw u.error;const r=await supabase.from("content_media").insert({institution_id:institution.institution_id,owner_user_id:user.id,entity_type:type,entity_id:id,media_type:"IMAGE",storage_path:path,alt_text:f.name,visibility:"INSTITUTION"});if(r.error){await supabase.storage.from("imbop-media").remove([path]);throw r.error}setMessage("Photo added.");await load()}catch(x){setMessage(x.message)}finally{setBusy(false);e.target.value=""}};
 const removeMedia=async(m)=>{setBusy(true);const s=await supabase.storage.from("imbop-media").remove([m.storage_path]);if(s.error){setMessage(s.error.message);setBusy(false);return}const r=await supabase.from("content_media").delete().eq("id",m.id);setMessage(r.error?r.error.message:"Photo removed.");await load();setBusy(false)};

 const card=(row,type,table,entityType)=> <article className="admin-card" key={row.id}>
  <div className="admin-card-head"><div><div className="eyebrow">{type==="item"?row.intent_type:row.opportunity_type||row.business_type||"BUSINESS"}</div><h3>{row.name||row.title}</h3><p className="admin-contact">{row.sector||row.category||row.location||"Details to complete"}</p></div><span className="status-badge">{row.publication_state||row.status}</span></div>
  <p className="admin-description">{row.short_summary||row.description||"No description yet."}</p>
  <div className="admin-actions"><button className="admin-btn" onClick={()=>open(type,row)}>EDIT</button>{table&&["DRAFT","RETURNED","UNPUBLISHED"].includes(row.publication_state)&&<button className="admin-btn admin-btn-primary" onClick={()=>submit(table,row.id)} disabled={busy}>SUBMIT FOR REVIEW</button>}{isAdmin&&table&&row.publication_state==="PENDING_REVIEW"&&<><button className="admin-btn admin-btn-primary" onClick={()=>review(table,row.id,"PUBLISHED")} disabled={busy}>PUBLISH</button><button className="admin-btn admin-btn-danger" onClick={()=>review(table,row.id,"RETURNED")} disabled={busy}>RETURN</button></>}</div>
  {entityType&&<MediaPanel media={media.filter(m=>m.entity_type===entityType&&m.entity_id===row.id)} upload={e=>upload(e,entityType,row.id)} remove={removeMedia}/>}
 </article>;

 return <><Nav authenticated/><main className="wrap content-page">
  <div className="admin-hero"><div className="eyebrow">CONTENT WORKSPACE</div><h1>{institution?.institution_name||"Institution"}</h1><p>Your editable space for businesses, profiles, offers, needs and opportunities.</p></div>
  <div className="content-nav">{[["business","BUSINESSES"],["offers","I OFFER · I NEED"],["opportunities","OPPORTUNITIES"]].map(([x,t])=><button key={x} className={"filter-chip "+(tab===x?"active":"")} onClick={()=>setTab(x)}>{t}</button>)}</div>
  {message&&<div className="notice">{message}</div>}
  {tab==="business"&&<section className="admin-section"><div className="section-heading"><div><div className="eyebrow">01 — BUSINESS FOUNDATION</div><h2>Businesses & Profiles</h2></div><button className="admin-btn admin-btn-primary" onClick={()=>open("business")}>ADD BUSINESS</button></div><div className="admin-grid">{businesses.map(b=><article className="admin-card" key={b.id}><div className="admin-card-head"><div><div className="eyebrow">{b.business_type||"BUSINESS"}</div><h3>{b.name}</h3><p className="admin-contact">{b.sector||"Sector not set"}{b.location?" · "+b.location:""}</p></div><span className="status-badge">{b.status}</span></div><p className="admin-description">{b.description||"No business description yet."}</p><div className="admin-actions"><button className="admin-btn" onClick={()=>open("business",b)}>EDIT BUSINESS</button>{profileMap[b.id]&&profileMap[b.id].publication_state!=="PUBLISHED"&&<button className="admin-btn" onClick={()=>open("profile",profileMap[b.id])}>EDIT PROFILE</button>}{!profileMap[b.id]&&<button className="admin-btn" onClick={()=>open("profile",{business_id:b.id,...emptyProfile})}>CREATE PROFILE</button>}</div>{profileMap[b.id]&&<div className="admin-actions"><span className="status-badge">{profileMap[b.id].publication_state||"DRAFT"}</span>{["DRAFT","RETURNED","UNPUBLISHED"].includes(profileMap[b.id].publication_state)&&<button className="admin-btn admin-btn-primary" onClick={()=>submit("business_profiles",profileMap[b.id].id)} disabled={busy}>SUBMIT PROFILE FOR REVIEW</button>}{isAdmin&&profileMap[b.id].publication_state==="PENDING_REVIEW"&&<><button className="admin-btn admin-btn-primary" onClick={()=>review("business_profiles",profileMap[b.id].id,"PUBLISHED")} disabled={busy}>PUBLISH PROFILE</button><button className="admin-btn admin-btn-danger" onClick={()=>review("business_profiles",profileMap[b.id].id,"RETURNED")} disabled={busy}>RETURN PROFILE</button></>}</div>}<MediaPanel media={media.filter(m=>m.entity_type==="BUSINESS"&&m.entity_id===b.id)} upload={e=>upload(e,"BUSINESS",b.id)} remove={removeMedia}/></article>)}</div>{!businesses.length&&<div className="card empty-state">No business yet. Start with the business foundation.</div>}</section>}
  {tab==="offers"&&<section className="admin-section"><div className="section-heading"><div><div className="eyebrow">02 — MEMBER MAGNET</div><h2>I OFFER · I NEED</h2></div><div className="admin-actions"><button className="admin-btn admin-btn-primary" onClick={()=>open("item",{...emptyItem,intent_type:"OFFER"})}>I OFFER</button><button className="admin-btn" onClick={()=>open("item",{...emptyItem,intent_type:"NEED"})}>I NEED</button></div></div><div className="admin-grid">{items.map(x=>card(x,"item","market_items",x.intent_type))}</div>{!items.length&&<div className="card empty-state">No offers or needs yet.</div>}</section>}
  {tab==="opportunities"&&<section className="admin-section"><div className="section-heading"><div><div className="eyebrow">03 — OPPORTUNITY</div><h2>Opportunities</h2></div><button className="admin-btn admin-btn-primary" onClick={()=>open("opportunity")}>ADD OPPORTUNITY</button></div><div className="admin-grid">{opportunities.map(x=>card(x,"opportunity","opportunities","OPPORTUNITY"))}</div>{!opportunities.length&&<div className="card empty-state">No opportunities yet.</div>}</section>}
 </main>{editor&&<Editor type={editor.type} form={form} setForm={setForm} businesses={businesses} close={()=>!busy&&setEditor(null)} save={save} busy={busy}/>}<Footer/></>;
}

function Field({label,name,value,setForm,multi=false}){return <label className="label">{label}{multi?<textarea className="input content-textarea" rows={5} value={value||""} onChange={e=>setForm(f=>({...f,[name]:e.target.value}))}/>:<input className="input" value={value||""} onChange={e=>setForm(f=>({...f,[name]:e.target.value}))}/>}</label>}
function Editor({type,form,setForm,businesses,close,save,busy}){
 const fields=type==="business"?[["Business / Enterprise Name","name"],["Description","description",true],["Business Type","business_type"],["Sector","sector"],["Value Chain","value_chain"],["County","county"],["Sub-County","sub_county"],["Location","location"],["MSEA Registration Ref","msea_registration_ref"],["BRS Enterprise Name","brs_enterprise_name"],["BRS Registration Ref","brs_registration_ref"]]:type==="profile"?[["Profile Headline","headline"],["Public Description","public_description",true],["Contact Phone","contact_phone"],["Contact Email","contact_email"],["Public Location","public_location"]]:type==="item"?[["Title","title"],["Short Summary","short_summary"],["Detailed Description","description",true],["Category","category"],["Sector","sector"],["Value Chain","value_chain"],["Quantity / Requirement","quantity"],["Location / Service Area","location"],["Price / Pricing Basis","price_basis"],["Availability","availability"],["Required By","required_by"],["Contact / Enquiry Preference","contact_preference"]]:[["Opportunity Type","opportunity_type"],["Title","title"],["Short Summary","short_summary"],["Detailed Description","description",true],["Sector","sector"],["Value Chain","value_chain"],["Who is it for?","audience"],["Location","location"],["Opportunity Size / Scale","opportunity_scale"],["Timeline","timeline"],["Participation / Commercial Terms","participation_terms",true],["Contact / Enquiry Preference","contact_preference"]];
 return <div className="admin-drawer-backdrop" onMouseDown={e=>e.target===e.currentTarget&&close()}><aside className="admin-drawer"><button className="admin-drawer-close" onClick={close}>×</button><div className="eyebrow">EDITABLE CONTENT</div><h2>{type==="business"?"Business":type==="profile"?"Business Profile":type==="item"?(form.intent_type==="NEED"?"I NEED":"I OFFER"):"Opportunity"}</h2><p>Save as draft. When ready, submit for institutional review. Editing never publishes automatically.</p>{type==="profile"&&<label className="label">Business<select className="input" value={form.business_id||""} onChange={e=>setForm(f=>({...f,business_id:e.target.value}))}>{businesses.map(b=><option key={b.id} value={b.id}>{b.name}</option>)}</select></label>}{type==="item"&&<label className="label">Intent<select className="input" value={form.intent_type||"OFFER"} onChange={e=>setForm(f=>({...f,intent_type:e.target.value}))}><option>OFFER</option><option>NEED</option></select></label>}{fields.map(([label,name,multi])=><Field key={name} label={label} name={name} value={form[name]} setForm={setForm} multi={multi}/>)}{type==="profile"&&<label className="label">Visibility<select className="input" value={form.visibility||"INSTITUTION"} onChange={e=>setForm(f=>({...f,visibility:e.target.value}))}><option>PRIVATE</option><option>INSTITUTION</option><option>PUBLIC</option></select></label>}<div className="admin-actions"><button className="admin-btn" onClick={close} disabled={busy}>CANCEL</button><button className="admin-btn admin-btn-primary" onClick={save} disabled={busy}>{busy?"SAVING…":"SAVE DRAFT"}</button></div></aside></div>
}
function MediaPanel({media,upload,remove}){return <div className="media-panel"><div className="media-head"><strong>PHOTOS</strong><label className="admin-btn">ADD PHOTO<input hidden type="file" accept="image/jpeg,image/png,image/webp" onChange={upload}/></label></div>{media.length?<div className="media-list">{media.map(m=><div className="media-row" key={m.id}><span>{m.alt_text||"Image"}</span><button className="admin-btn admin-btn-danger" onClick={()=>remove(m)}>REMOVE</button></div>)}</div>:<span className="media-empty">No photos yet.</span>}<small>JPEG, PNG or WebP · max 10 MB.</small></div>}
