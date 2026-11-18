"use client";
import {useEffect,useState} from "react";
import Link from "next/link";
import Nav from "../../components/Nav";
import Footer from "../../components/Footer";
import {supabase} from "../../lib/supabase";

const presets=[
  {label:"Any",min:null,max:null},{label:"1+",min:1,max:null},{label:"100+",min:100,max:null},
  {label:"500+",min:500,max:null},{label:"1,000+",min:1000,max:null},{label:"5,000+",min:5000,max:null},
  {label:"10,000+",min:10000,max:null},{label:"25,000+",min:25000,max:null},{label:"50,000+",min:50000,max:null}
];
function formatNumber(value){return new Intl.NumberFormat("en-KE").format(Number(value)||0)}

export default function Discover(){
  const[q,setQ]=useState(""),[preset,setPreset]=useState("Any"),[min,setMin]=useState(""),[max,setMax]=useState(""),[initial,setInitial]=useState("");
  const[items,setItems]=useState([]),[total,setTotal]=useState(0),[page,setPage]=useState(0),[loading,setLoading]=useState(true),[error,setError]=useState("");

  async function load(nextPage=0){
    setLoading(true);setError("");
    const selected=presets.find(x=>x.label===preset)||presets[0];
    const customMin=min===""?null:Math.max(0,Number(min)), customMax=max===""?null:Math.max(0,Number(max));
    const pMin=customMin!==null?customMin:selected.min, pMax=customMax!==null?customMax:selected.max;
    const rpcName=initial?"search_public_institutions_by_initial":"search_public_institutions";
    const rpcArgs=initial?{p_initial:initial,p_query:q.trim()||null,p_min_onboards:pMin,p_max_onboards:pMax,p_limit:12,p_offset:nextPage*12}:{p_query:q.trim()||null,p_min_onboards:pMin,p_max_onboards:pMax,p_limit:12,p_offset:nextPage*12};
    const {data,error}=await supabase.rpc(rpcName,rpcArgs);
    if(error){setError(error.message);setItems([]);setTotal(0)}
    else{setItems(data||[]);setTotal(Number(data?.[0]?.total_count||0));setPage(nextPage)}
    setLoading(false);
  }
  useEffect(()=>{load(0)},[preset,initial]);
  const pages=Math.ceil(total/12);

  return <><Nav/><main className="wrap">
    <div className="eyebrow">PUBLIC INSTITUTION DISCOVERY</div>
    <h1>Discover IMBOP Institutions</h1>
    <p>Explore institutions participating in IMBOP and the size of their onboarded member networks.</p>

    <section className="discovery-controls card">
      <label className="label" htmlFor="institution-search">SEARCH INSTITUTIONS</label>
      <div className="discovery-search">
        <input id="institution-search" className="input" value={q} onChange={e=>setQ(e.target.value)} onKeyDown={e=>e.key==="Enter"&&load(0)} placeholder="Search by institution name, type or description"/>
        <button className="btn" onClick={()=>load(0)}>SEARCH</button>
      </div>
      <div className="filter-heading">ALPHABETICAL</div>
      <div className="filter-presets">
        <button type="button" className={"filter-chip "+(!initial?"active":"")} onClick={()=>setInitial("")}>ALL</button>
        {"ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("").map(letter=><button key={letter} type="button" className={"filter-chip "+(initial===letter?"active":"")} onClick={()=>{setInitial(letter);setPage(0)}}>{letter}</button>)}
      </div>
      <div className="filter-heading">IMBOP ONBOARDS</div>
      <div className="filter-presets">{presets.map(x=><button key={x.label} type="button" className={"filter-chip "+(preset===x.label?"active":"")} onClick={()=>{setPreset(x.label);if(min||max){setMin("");setMax("")}}}>{x.label}</button>)}</div>
      <div className="range-row">
        <div><label className="label" htmlFor="min-onboards">MINIMUM</label><input id="min-onboards" className="input" type="number" min="0" value={min} onChange={e=>{setMin(e.target.value);setPreset("")}} placeholder="e.g. 1000"/></div>
        <div><label className="label" htmlFor="max-onboards">MAXIMUM</label><input id="max-onboards" className="input" type="number" min="0" value={max} onChange={e=>{setMax(e.target.value);setPreset("")}} placeholder="e.g. 10000"/></div>
        <button className="btn range-button" onClick={()=>load(0)}>APPLY RANGE</button>
      </div>
    </section>

    {error&&<div className="notice error">{error}</div>}
    <div className="discovery-results-head"><div><b>{loading?"Searching…":formatNumber(total)}</b> {loading?"":"institutions"}</div><span>Showing participating institutions only</span></div>
    {loading?<div className="card empty-state">Loading institutions…</div>:items.length===0?<div className="card empty-state">No institutions match your search and IMBOP onboard filter.</div>:<div className="institution-grid">
      {items.map(x=><article className="institution-card card" key={x.institution_id}>
        <div className="eyebrow">IMBOP INSTITUTION</div><h2>{x.name}</h2>
        {x.institution_type&&<div className="institution-type">{x.institution_type}</div>}
        <div className="onboard-metric"><strong>{formatNumber(x.imbop_onboards)}</strong><span>IMBOP ONBOARDS</span></div>
        {x.description&&<p>{x.description}</p>}
        <Link className="btn" href={"/institution/"+x.slug}>VISIT IMBOP SPACE</Link>
      </article>)}
    </div>}
    {!loading&&pages>1&&<div className="pagination"><button className="btn alt" disabled={page===0} onClick={()=>load(page-1)}>PREVIOUS</button><span>PAGE {page+1} OF {pages}</span><button className="btn alt" disabled={page>=pages-1} onClick={()=>load(page+1)}>NEXT</button></div>}
  </main><Footer/></>
}