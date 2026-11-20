"use client";
import {useEffect,useRef,useState} from "react";
import Nav from "../../components/Nav";
import Footer from "../../components/Footer";
import {supabase} from "../../lib/supabase";

const empty={name:"",email:"",phone:"",business:"",description:"",sector:"",value_chain:"",location:"",offer:"",need:""};
const instEmpty={institution_name:"",brand_name:"",institution_type:"",membership_size:"",contact_name:"",contact_role:"",contact_email:"",contact_phone:"",website:"",county:"",location:"",description:"",authorised:true};
const institutionSubmissionStorageKey="imbop:institution-application-idempotency-key";

export default function Apply(){
  const [type,setType]=useState("");
  const [institutions,setInstitutions]=useState([]);
  const [institutionName,setInstitutionName]=useState("");
  const [member,setMember]=useState(empty);
  const [institution,setInstitution]=useState(instEmpty);
  const [logoFile,setLogoFile]=useState(null);
  const [logoPreview,setLogoPreview]=useState("");
  const [msg,setMsg]=useState("");
  const [busy,setBusy]=useState(false);
  const institutionSubmissionKeyRef=useRef(null);

  useEffect(()=>{
    supabase.rpc("public_application_institutions")
      .then(({data,error})=>{ if(error)setMsg(error.message); else setInstitutions((data||[]).map(x=>({id:x.institution_id,name:x.institution_name}))); });
  },[]);

  useEffect(()=>()=>{ if(logoPreview) URL.revokeObjectURL(logoPreview); },[logoPreview]);

  const setMemberField=(k,v)=>setMember(x=>({...x,[k]:v}));
  const setInstitutionField=(k,v)=>setInstitution(x=>({...x,[k]:v}));

  function getInstitutionSubmissionKey(){
    let key=institutionSubmissionKeyRef.current;
    if(!key){try{key=window.sessionStorage.getItem(institutionSubmissionStorageKey)}catch{}}
    if(!key)key=window.crypto.randomUUID();
    institutionSubmissionKeyRef.current=key;
    try{window.sessionStorage.setItem(institutionSubmissionStorageKey,key)}catch{}
    return key;
  }

  function clearInstitutionSubmissionKey(){
    institutionSubmissionKeyRef.current=null;
    try{window.sessionStorage.removeItem(institutionSubmissionStorageKey)}catch{}
  }

  function chooseLogo(file){
    if(logoPreview) URL.revokeObjectURL(logoPreview);
    setLogoFile(null);
    setLogoPreview("");
    if(!file)return;
    if(!["image/jpeg","image/png","image/webp"].includes(file.type))return setMsg("Logo must be JPG, PNG or WEBP.");
    if(file.size>1048576)return setMsg("Logo must be 1 MB or smaller.");
    setLogoFile(file);
    setLogoPreview(URL.createObjectURL(file));
    setMsg("");
  }

  async function submitMember(e){
    e.preventDefault(); setBusy(true); setMsg("");
    const matchedInstitution=institutions.find(x=>x.name.trim().toLowerCase()===institutionName.trim().toLowerCase());
    if(!matchedInstitution){setBusy(false);return setMsg("Please select or enter the name of an institution currently participating in IMBOP.");}
    const {data,error}=await supabase.rpc("create_public_member_application",{
      p_institution_id:matchedInstitution.id,
      p_applicant_name:member.name.trim(),
      p_email:member.email.trim(),
      p_phone:member.phone.trim(),
      p_payload:{
        source:"PUBLIC_IMBOP_APPLICATION", applicant_type:"MEMBER",
        business_name:member.business, business_description:member.description,
        sector:member.sector, location:member.location, visibility:"PUBLIC"
      }
    });
    setBusy(false);
    if(error)return setMsg(error.message);
    const applicationReference=data?.[0]?.application_reference;
    window.location.href=applicationReference
      ? "/apply/confirmation?reference="+encodeURIComponent(applicationReference)
      : "/apply/confirmation";
  }

  function validateInstitutionSubmission(){
    const name=institution.institution_name.trim();
    const contactName=institution.contact_name.trim();
    const email=institution.contact_email.trim();
    const phone=institution.contact_phone.trim();
    const membership=Number(institution.membership_size);
    if(name.length<2 || name.length>200)return "Institution name must be between 2 and 200 characters.";
    if(contactName.length<2 || contactName.length>200)return "Contact name must be between 2 and 200 characters.";
    if(email.length<5 || email.length>254 || !/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(email))return "Please enter a valid contact email address.";
    if(phone.length<7 || phone.length>30 || !/^\\+?[0-9][0-9 ()-]{5,28}[0-9]$/.test(phone))return "Please enter a valid contact phone number (digits, spaces, +, parentheses or hyphens only).";
    if(!Number.isInteger(membership) || membership<0 || membership>100000000)return "Please enter a valid current membership estimate.";
    return "";
  }

  async function submitInstitution(e){
    e.preventDefault();
    setMsg("");
    const validationMessage=validateInstitutionSubmission();
    if(validationMessage){ setMsg(validationMessage); return; }
    setBusy(true);

    if(logoFile && !["image/jpeg","image/png","image/webp"].includes(logoFile.type)){
      setBusy(false); return setMsg("Logo must be JPG, PNG or WEBP.");
    }
    if(logoFile && logoFile.size>1048576){
      setBusy(false); return setMsg("Logo must be 1 MB or smaller.");
    }

    const submissionKey=getInstitutionSubmissionKey();
    let submissionResult;
    try{
      submissionResult=await supabase.rpc("create_public_institution_application",{
        p_institution_name:institution.institution_name.trim(),
        p_brand_name:institution.brand_name.trim()||null,
        p_institution_type:institution.institution_type.trim(),
        p_membership_size:Number(institution.membership_size),
        p_contact_name:institution.contact_name.trim(),
        p_contact_role:institution.contact_role.trim(),
        p_contact_email:institution.contact_email.trim(),
        p_contact_phone:institution.contact_phone.trim(),
        p_website:institution.website.trim()||null,
        p_hq_county:institution.county.trim(),
        p_hq_location:institution.location.trim(),
        p_description:institution.description.trim(),
        p_authorised:institution.authorised,
        p_submission_idempotency_key:submissionKey
      });
    }catch{
      setBusy(false);
      return setMsg("Submission could not be confirmed. Retry without changing the form to avoid creating a duplicate application.");
    }

    if(!submissionResult){
      setBusy(false);
      return setMsg("Submission could not be confirmed. Please try again.");
    }

    const {data,error}=submissionResult;
    if(error){
      if(error.message?.includes("IDEMPOTENCY_KEY_REUSED_WITH_DIFFERENT_DETAILS"))clearInstitutionSubmissionKey();
      setBusy(false);
      return setMsg(error.message?.includes("IDEMPOTENCY_KEY_REUSED_WITH_DIFFERENT_DETAILS")
        ? "The application details changed after an earlier attempt. Please submit again to continue."
        : error.message);
    }

    const application=data?.[0];
    if(logoFile && application?.application_id && application?.logo_upload_token){
      const extension=logoFile.type==="image/jpeg"?"jpg":logoFile.type.split("/")[1];
      const path="applications/"+application.application_id+"/"+application.logo_upload_token+"."+extension;
      const upload=await supabase.storage.from("imbop-application-logos").upload(path,logoFile,{contentType:logoFile.type,cacheControl:"3600",upsert:false});
      if(!upload.error){
        const attached=await supabase.rpc("attach_public_institution_application_logo",{
          p_application_id:application.application_id,
          p_logo_token:application.logo_upload_token,
          p_logo_storage_path:path
        });
        if(attached.error)setMsg("Application submitted. Your logo could not be attached, but you can add it during readiness.");
      }else{
        setMsg("Application submitted. Your logo could not be uploaded, but you can add it during readiness.");
      }
    }

    clearInstitutionSubmissionKey();
    setBusy(false);
    const applicationReference=application?.application_reference;
    window.location.href=applicationReference
      ? "/apply/institution-confirmation?reference="+encodeURIComponent(applicationReference)
      : "/apply/institution-confirmation";
  }

  return <><Nav/><main className="wrap">
    <div className="card" style={{maxWidth:820,margin:"auto"}}>
      <div className="eyebrow">APPLY / JOIN</div>
      <h1>Apply to IMBOP</h1>
      <div className="notice pricing-disclosure"><b>IMBOP PRICING:</b> Institutions and their first 50 IMBOP Onboards are free. Beyond 50, the Institution moves to a numbers-based plan. <b>Individual Institution Members are not billed.</b> See <a href="/plans"><b>IMBOP Plans &amp; Pricing</b></a>.</div>

      <div className="actions" style={{margin:"20px 0"}}>
        <button className={"btn "+(type==="institution"?"":"alt")} onClick={()=>{setType("institution");setMsg("");}}>INSTITUTION</button>
        <button className={"btn "+(type==="member"?"":"alt")} onClick={()=>{setType("member");setMsg("");}}>INSTITUTION MEMBER</button>
      </div>
      <p><b>Application ≠ Publication.</b> Submission starts a review process. Only an authorised decision-maker can publish a record.</p>

      {!type && <div className="notice">Choose <b>INSTITUTION</b> or <b>INSTITUTION MEMBER</b> to begin.</div>}

      {type==="member" && <form onSubmit={submitMember}>
        <label className="label">YOUR INSTITUTION</label>
        <input className="input" list="imbop-institutions" value={institutionName}
          onChange={e=>setInstitutionName(e.target.value)}
          placeholder="Write or select your institution" required/>
        <datalist id="imbop-institutions">{institutions.map(x=><option key={x.id} value={x.name}/>)}</datalist>
        <div className="grid">
          <div><label className="label">APPLICANT NAME</label><input className="input" value={member.name} onChange={e=>setMemberField("name",e.target.value)} required/></div>
          <div><label className="label">EMAIL</label><input className="input" type="email" value={member.email} onChange={e=>setMemberField("email",e.target.value)} required/></div>
        </div>
        <div className="grid">
          <div><label className="label">PHONE</label><input className="input" value={member.phone} onChange={e=>setMemberField("phone",e.target.value)} required/></div>
          <div><label className="label">BUSINESS / ENTERPRISE NAME</label><input className="input" value={member.business} onChange={e=>setMemberField("business",e.target.value)} required/></div>
        </div>
        <label className="label">BUSINESS DESCRIPTION</label><textarea className="textarea" value={member.description} onChange={e=>setMemberField("description",e.target.value)} required/>
        <div className="grid">
          <div><label className="label">SECTOR</label><input className="input" value={member.sector} onChange={e=>setMemberField("sector",e.target.value)} required/></div>
          <div><label className="label">VALUE CHAIN</label><input className="input" value={member.value_chain} onChange={e=>setMemberField("value_chain",e.target.value)}/></div>
        </div>
        <label className="label">LOCATION</label><input className="input" value={member.location} onChange={e=>setMemberField("location",e.target.value)} required/>
        <label className="label">I OFFER</label><textarea className="textarea" value={member.offer} onChange={e=>setMemberField("offer",e.target.value)} placeholder="What can you provide to other members or the market?"/>
        <label className="label">I NEED</label><textarea className="textarea" value={member.need} onChange={e=>setMemberField("need",e.target.value)} placeholder="What are you looking for from other members or the market?"/>
        <div className="notice">These are starting points for your IMBOP profile. You can edit and expand your content later; editing does not automatically publish it.</div>
        <button className="btn" disabled={busy}>{busy?"SUBMITTING…":"SUBMIT MEMBER APPLICATION"}</button>
      </form>}

      {type==="institution" && <form onSubmit={submitInstitution}>
        <div className="eyebrow" style={{marginTop:8}}>ABOUT YOUR INSTITUTION</div>
        <div className="grid">
          <div><label className="label">INSTITUTION NAME</label><input className="input" value={institution.institution_name} onChange={e=>setInstitutionField("institution_name",e.target.value)} required/></div>
          <div><label className="label">BRAND NAME <span style={{opacity:.6}}>(OPTIONAL)</span></label><input className="input" value={institution.brand_name} onChange={e=>setInstitutionField("brand_name",e.target.value)} placeholder="If different from the institution name"/></div>
        </div>
        <div className="grid">
          <div>
            <label className="label">LOGO <span style={{opacity:.6}}>(OPTIONAL)</span></label>
            <input className="input" type="file" accept="image/jpeg,image/png,image/webp" onChange={e=>chooseLogo(e.target.files?.[0]||null)}/>
            <div style={{fontSize:12,opacity:.7,marginTop:6}}>JPG, PNG or WEBP · max 1 MB</div>
            {logoPreview && <img src={logoPreview} alt="Institution logo preview" style={{display:"block",maxWidth:120,maxHeight:120,objectFit:"contain",marginTop:10,borderRadius:8}}/>}
          </div>
          <div><label className="label">INSTITUTION TYPE</label><input className="input" value={institution.institution_type} onChange={e=>setInstitutionField("institution_type",e.target.value)} placeholder="e.g. Cooperative, SACCO, Chama, Business Network" required/></div>
        </div>
        <div className="grid">
          <div><label className="label">CURRENT MEMBERSHIP ESTIMATE</label><input className="input" type="number" min="0" step="1" value={institution.membership_size} onChange={e=>setInstitutionField("membership_size",e.target.value)} required/></div>
          <div><label className="label">WEBSITE <span style={{opacity:.6}}>(OPTIONAL)</span></label><input className="input" type="url" value={institution.website} onChange={e=>setInstitutionField("website",e.target.value)}/></div>
        </div>

        <div className="eyebrow" style={{marginTop:26}}>WHERE YOU ARE</div>
        <div className="grid">
          <div><label className="label">HQ COUNTY</label><input className="input" value={institution.county} onChange={e=>setInstitutionField("county",e.target.value)} required/></div>
          <div><label className="label">HQ LOCATION</label><input className="input" value={institution.location} onChange={e=>setInstitutionField("location",e.target.value)} placeholder="Town / centre / area" required/></div>
        </div>

        <div className="eyebrow" style={{marginTop:26}}>YOUR AUTHORISED CONTACT</div>
        <div className="grid">
          <div><label className="label">CONTACT NAME</label><input className="input" value={institution.contact_name} onChange={e=>setInstitutionField("contact_name",e.target.value)} required/></div>
          <div><label className="label">CONTACT ROLE / POSITION</label><input className="input" value={institution.contact_role} onChange={e=>setInstitutionField("contact_role",e.target.value)} placeholder="e.g. Chairperson, Secretary, Manager" required/></div>
        </div>
        <div className="grid">
          <div><label className="label">CONTACT EMAIL</label><input className="input" type="email" value={institution.contact_email} onChange={e=>setInstitutionField("contact_email",e.target.value)} required/></div>
          <div><label className="label">CONTACT PHONE</label><input className="input" value={institution.contact_phone} onChange={e=>setInstitutionField("contact_phone",e.target.value)} required/></div>
        </div>

        <div className="eyebrow" style={{marginTop:26}}>ABOUT THE INSTITUTION</div>
        <textarea className="textarea" value={institution.description} onChange={e=>setInstitutionField("description",e.target.value)} placeholder="Briefly tell us who the institution is, who it serves and what it does." required/>

        <label className="label" style={{display:"flex",gap:8,alignItems:"flex-start",marginTop:18}}><input type="checkbox" checked={institution.authorised} onChange={e=>setInstitutionField("authorised",e.target.checked)} required/> <span>I am authorised to submit this application on behalf of this institution.</span></label>

        <div className="notice" style={{marginTop:18}}><b>APPLICATION ≠ PUBLICATION.</b> This application starts SE IMBOP review. Registration, legal evidence, governance and other readiness information are handled later if the application progresses.</div>
        <div className="notice pricing-disclosure"><b>Institution billing:</b> The Institution is the IMBOP customer. The first 50 IMBOP Onboards are free; beyond 50, numbers-based institutional pricing applies. The first transition month uses a discounted minimum of <b>KES 5,000</b>.</div>
        <button className="btn" disabled={busy}>{busy?"SUBMITTING…":"SUBMIT INSTITUTION APPLICATION"}</button>
      </form>}

      {msg && <div className="notice" role="alert" aria-live="polite" style={{marginTop:20}}>{msg}</div>}
    </div>
  </main><Footer/></>
}
