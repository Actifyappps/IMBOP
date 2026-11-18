"use client";

import {useEffect,useState} from "react";
import {useParams} from "next/navigation";
import Link from "next/link";
import Nav from "../../../components/Nav";
import Footer from "../../../components/Footer";
import {supabase} from "../../../lib/supabase";

export default function InstitutionSpace(){
  const {slug}=useParams();
  const [institution,setInstitution]=useState(null);
  const [loading,setLoading]=useState(true);
  const [error,setError]=useState("");

  useEffect(()=>{
    let active=true;
    async function load(){
      setLoading(true);
      setError("");
      const {data,error}=await supabase.rpc("search_public_institutions",{
        p_query:slug||"",
        p_min_onboards:null,
        p_max_onboards:null,
        p_limit:1,
        p_offset:0
      });
      if(!active)return;
      if(error){
        setError(error.message||"Unable to load this institution.");
        setInstitution(null);
      }else{
        setInstitution((data||[]).find(x=>x.slug===slug)||null);
      }
      setLoading(false);
    }
    if(slug)load();
    return()=>{active=false};
  },[slug]);

  if(loading)return <><Nav/><main className="wrap"><div className="card"><div className="eyebrow">IMBOP SPACE</div><h1>Loading institution…</h1><p>Loading the institution's public IMBOP space.</p></div></main><Footer/></>;

  if(error||!institution)return <><Nav/><main className="wrap"><div className="card"><div className="eyebrow">IMBOP SPACE</div><h1>Institution Not Found</h1><p>{error||"This institution is not currently available as a public IMBOP Space."}</p><Link className="btn" href="/discover">BACK TO DISCOVER</Link></div></main><Footer/></>;

  return <><Nav/><main className="wrap">
    <div className="eyebrow">IMBOP SPACE</div>
    <div className="institution-space-hero card"><h1>{institution.name}</h1>
      {institution.institution_type&&<p className="institution-type">{institution.institution_type}</p>}
      <div className="onboard-metric"><strong>{new Intl.NumberFormat("en-KE").format(Number(institution.imbop_onboards)||0)}</strong><span>IMBOP ONBOARDS</span></div>
      <p>{institution.description||"Institutional member space on IMBOP."}</p>
    </div>
    <div className="card institution-space-note"><div className="eyebrow">MEMBERS-ONLY ECONOMIC NETWORK</div>
      <h2>This is the institution's IMBOP space.</h2>
      <p>The institution's published member profiles, businesses, offers, needs and opportunities will live here as its network is built.</p>
      <p><b>Explore. Know. Discover. Enquire. Connect.</b></p>
      <Link className="btn alt" href="/discover">BACK TO INSTITUTION DISCOVERY</Link>
    </div>
  </main><Footer/></>;
}
