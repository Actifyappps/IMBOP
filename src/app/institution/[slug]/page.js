"use client";
import {useEffect,useState} from "react";
import {useParams} from "next/navigation";
import Link from "next/link";
import Nav from "../../../components/Nav";
import Footer from "../../../components/Footer";
import {supabase} from "../../../lib/supabase";

export default function InstitutionSpace(){
 const {slug}=useParams(); const [institution,setInstitution]=useState(null),[content,setContent]=useState(null),[loading,setLoading]=useState(true),[error,setError]=useState("");
 useEffect(()=>{let live=true;(async()=>{const {data,error}=await supabase.rpc("search_public_institutions",{p_query:slug||"",p_min_onboards:null,p_max_onboards:null,p_limit:1,p_offset:0});if(!live)return;if(error){setError(error.message);setLoading(false);return}const inst=(data||[]).find(x=>x.slug===slug);if(!inst){setLoading(false);return}setInstitution(inst);const c=await supabase.rpc("get_public_institution_content",{p_institution_id:inst.id});if(live){if(c.error)setError(c.error.message);else setContent(c.data);setLoading(false)}})();return()=>{live=false}},[slug]);
 if(loading)return <><Nav/><main className="wrap"><div className="card"><div className="eyebrow">IMBOP SPACE</div><h1>Loading institution…</h1></div></main><Footer/></>;
 if(error||!institution)return <><Nav/><main className="wrap"><div className="card"><div className="eyebrow">IMBOP SPACE</div><h1>Institution Not Found</h1><p>{error||"This institution is not currently available as a public IMBOP Space."}</p><Link className="btn" href="/discover">BACK TO DISCOVER</Link></div></main><Footer/></>;
 const businesses=content?.businesses||[],items=content?.offers_needs||[],ops=content?.opportunities||[];
 return <><Nav/><main className="wrap">
  <div className="eyebrow">IMBOP SPACE</div><div className="institution-space-hero card"><h1>{institution.name}</h1>{institution.institution_type&&<p className="institution-type">{institution.institution_type}</p>}<div className="onboard-metric"><strong>{new Intl.NumberFormat("en-KE").format(Number(institution.imbop_onboards)||0)}</strong><span>IMBOP ONBOARDS</span></div><p>{institution.description||"Institutional member space on IMBOP."}</p></div>
  <section className="admin-section"><div className="eyebrow">THE NETWORK</div><h2>Published Member Content</h2><p>Discover what this institution’s members and businesses offer, need and make available.</p>
   <div className="admin-grid">{businesses.map(b=><article className="admin-card" key={b.id}><div className="eyebrow">BUSINESS</div><h3>{b.name}</h3><p>{b.headline||b.public_description||b.description||"Published business profile."}</p><p className="admin-contact">{b.sector||""}{b.location?" · "+b.location:""}</p></article>)}{items.map(x=><article className="admin-card" key={x.id}><div className="eyebrow">{x.intent_type}</div><h3>{x.title}</h3><p>{x.short_summary||x.description}</p><p className="admin-contact">{x.category||""}{x.location?" · "+x.location:""}</p></article>)}{ops.map(x=><article className="admin-card" key={x.id}><div className="eyebrow">{x.opportunity_type||"OPPORTUNITY"}</div><h3>{x.title}</h3><p>{x.short_summary||x.description}</p><p className="admin-contact">{x.sector||""}{x.location?" · "+x.location:""}</p></article>)}</div>
   {!businesses.length&&!items.length&&!ops.length&&<div className="card empty-state"><h3>This network is being built.</h3><p>Published member profiles, businesses, offers, needs and opportunities will appear here as the institution grows its IMBOP space.</p></div>}
  </section>
  <div className="card institution-space-note"><div className="eyebrow">PUBLIC DISCOVERY</div><p><b>Explore. Know. Discover. Enquire. Connect.</b></p><Link className="btn alt" href="/discover">BACK TO INSTITUTION DISCOVERY</Link></div>
 </main><Footer/></>;
}