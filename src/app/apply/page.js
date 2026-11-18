"use client";
import {useEffect,useState} from "react";
import Nav from "../components/Nav";
import Footer from "../components/Footer";
import {supabase} from "../lib/supabase";

const empty={name:"",email:"",phone:"",business:"",description:"",sector:"",location:""};
const instEmpty={institution_name:"",legal_name:"",institution_type:"",contact_name:"",contact_email:"",contact_phone:"",membership_size:"",website:"",location:"",description:""};

export default function Apply(){
  const [type,setType]=useState("");
  const [institutions,setInstitutions]=useState([]);
  const [institutionId,setInstitutionId]=useState("");
  const [institutionName,setInstitutionName]=useState("");
  const [member,setMember]=useState(empty);
  const [institution,setInstitution]=useState(instEmpty);
  const [msg,setMsg]=useState("");
  const [busy,setBusy]=useState(false);

  useEffect(()=>{
    supabase.rpc("public_application_institutions")
      .then(({data,error})=>{ if(error)setMsg(error.message); else setInstitutions((data||[]).map(x=>({id:x.institution_id,name:x.institution_name}))); });
  },[]);

  const setMemberField=(k,v)=>setMember(x=>({...x,[k]:v}));
  const setInstitutionField=(k,v)=>setInstitution(x=>({...x,[k]:v}));

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
    window.location.href="/apply/confirmation";
  }

  async function submitInstitution(e){
    e.preventDefault(); setBusy(true); setMsg("");
    const row={
      institution_name:institution.institution_name.trim(), legal_name:institution.legal_name.trim()||null,
      institution_type:institution.institution_type.trim()||null, contact_name:institution.contact_name.trim(),
      contact_email:institution.contact_email.trim(), contact_phone:institution.contact_phone.trim()||null,
      membership_size:institution.membership_size===""?null:Number(institution.membership_size),
      website:institution.website.trim()||null, location:institution.location.trim()||null,
      description:institution.description.trim()||null,
      application_payload:{source:"PUBLIC_IMBOP_APPLICATION",applicant_type:"INSTITUTION"},
      status:"SUBMITTED"
    };
    const {data,error}=await supabase.rpc("create_public_institution_application",{
      p_institution_name:row.institution_name,
      p_legal_name:row.legal_name,
      p_institution_type:row.institution_type,
      p_contact_name:row.contact_name,
      p_contact_email:row.contact_email,
      p_contact_phone:row.contact_phone,
      p_membership_size:row.membership_size,
      p_website:row.website,
      p_location:row.location,
      p_description:row.description
    });
    setBusy(false);
    if(error)return setMsg(error.message);
    window.location.href="/apply/institution-confirmation";
  }

  return <><Nav/><main className="wrap">
    <div className="card" style={{maxWidth:820,margin:"auto"}}>
      <div className="eyebrow">APPLY / JOIN</div>
      <h1>Apply to IMBOP</h1>
      <p><b>Application ≠ Publication.</b> Submission starts a review process. Only an authorised decision-maker can publish a record.</p><div className="notice pricing-disclosure"><b>IMBOP PRICING:</b> Institutions and their first 50 IMBOP Onboards are free. Beyond 50, the Institution moves to a numbers-based plan. <b>Individual Institution Members are not billed.</b> See <a href="/plans"><b>IMBOP Plans &amp; Pricing</b></a>.</div>

      <div className="actions" style={{margin:"20px 0"}}>
        <button className={`btn ${type==="institution"?"":"alt"}`} onClick={()=>{setType("institution");setMsg("")}}>INSTITUTION</button>
        <button className={`btn ${type==="member"?"":"alt"}`} onClick={()=>{setType("member");setMsg("")}}>INSTITUTION MEMBER</button>
      </div>

      {!type && <div className="notice">Choose <b>INSTITUTION</b> or <b>INSTITUTION MEMBER</b> to begin.</div>}

      {type==="member" && <form onSubmit={submitMember}>
        <label className="label">YOUR INSTITUTION</label>
        <input className="input" list="imbop-institutions" value={institutionName}
          onChange={e=>{const value=e.target.value;setInstitutionName(value);const match=institutions.find(x=>x.name.toLowerCase()===value.trim().toLowerCase());setInstitutionId(match?.id||"");}}
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
          <div><label className="label">LOCATION</label><input className="input" value={member.location} onChange={e=>setMemberField("location",e.target.value)} required/></div>
        </div>
        <button className="btn" disabled={busy}>{busy?"SUBMITTING…":"SUBMIT MEMBER APPLICATION"}</button>
      </form>}

      {type==="institution" && <form onSubmit={submitInstitution}>
        <div className="grid">
          <div><label className="label">INSTITUTION NAME</label><input className="input" value={institution.institution_name} onChange={e=>setInstitutionField("institution_name",e.target.value)} required/></div>
          <div><label className="label">LEGAL NAME</label><input className="input" value={institution.legal_name} onChange={e=>setInstitutionField("legal_name",e.target.value)}/></div>
        </div>
        <div className="grid">
          <div><label className="label">INSTITUTION TYPE</label><input className="input" value={institution.institution_type} onChange={e=>setInstitutionField("institution_type",e.target.value)} required/></div>
          <div><label className="label">CURRENT MEMBERSHIP</label><input className="input" type="number" min="0" value={institution.membership_size} onChange={e=>setInstitutionField("membership_size",e.target.value)}/></div>
        </div>
        <div className="grid">
          <div><label className="label">CONTACT NAME</label><input className="input" value={institution.contact_name} onChange={e=>setInstitutionField("contact_name",e.target.value)} required/></div>
          <div><label className="label">CONTACT EMAIL</label><input className="input" type="email" value={institution.contact_email} onChange={e=>setInstitutionField("contact_email",e.target.value)} required/></div>
        </div>
        <div className="grid">
          <div><label className="label">CONTACT PHONE</label><input className="input" value={institution.contact_phone} onChange={e=>setInstitutionField("contact_phone",e.target.value)}/></div>
          <div><label className="label">WEBSITE</label><input className="input" type="url" value={institution.website} onChange={e=>setInstitutionField("website",e.target.value)}/></div>
        </div>
        <label className="label">LOCATION</label><input className="input" value={institution.location} onChange={e=>setInstitutionField("location",e.target.value)} required/>
        <label className="label">ABOUT THE INSTITUTION</label><textarea className="textarea" value={institution.description} onChange={e=>setInstitutionField("description",e.target.value)} required/>
        <div className="notice pricing-disclosure"><b>Institution billing:</b> The Institution is the IMBOP customer. The first 50 IMBOP Onboards are free; beyond 50, numbers-based institutional pricing applies. The first transition month uses a discounted minimum of <b>KES 5,000</b>.</div><button className="btn" disabled={busy}>{busy?"SUBMITTING…":"SUBMIT INSTITUTION APPLICATION"}</button>
      </form>}

      {msg && <div className="notice" style={{marginTop:20}}>{msg}</div>}
    </div>
  </main><Footer/></>
}