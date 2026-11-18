import Link from "next/link";
import Nav from "../../components/Nav";
import Footer from "../../components/Footer";
import {supabase} from "../../lib/supabase";

export default async function InstitutionSpace({params}){
  const {data}=await supabase.rpc("search_public_institutions",{p_query:null,p_min_onboards:null,p_max_onboards:null,p_limit:100,p_offset:0});
  const institution=(data||[]).find(x=>x.slug===params.slug);
  if(!institution) return <><Nav/><main className="wrap"><div className="card"><div className="eyebrow">IMBOP SPACE</div><h1>Institution Not Found</h1><p>This institution is not currently available as a public IMBOP Space.</p><Link className="btn" href="/discover">BACK TO DISCOVER</Link></div></main><Footer/></>;
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