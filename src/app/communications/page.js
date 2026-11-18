"use client";

import {useEffect,useState} from "react";
import Nav from "../../components/Nav";
import Footer from "../../components/Footer";
import {supabase} from "../../lib/supabase";

export default function CommunicationsPage(){
  const[items,setItems]=useState([]);
  const[loading,setLoading]=useState(true);
  const[error,setError]=useState("");

  async function load(){
    setLoading(true); setError("");
    const {data,error}=await supabase.rpc("get_my_communications",{p_limit:50,p_offset:0});
    if(error)setError(error.message);
    else setItems(data||[]);
    setLoading(false);
  }

  useEffect(()=>{load()},[]);

  async function markRead(id){
    await supabase.rpc("mark_communication_read",{p_communication_id:id});
    setItems(xs=>xs.map(x=>x.id===id?{...x,delivery_status:"READ",read_at:x.read_at||new Date().toISOString()}:x));
  }

  const unread=items.filter(x=>x.delivery_status!=="READ").length;

  return <><Nav authenticated/><main className="wrap communications-page">
    <div className="platform-label"><b>IMBOP COMMUNICATIONS</b><span>Recorded, controlled and auditable</span></div>
    <header className="admin-hero">
      <div className="eyebrow">COMMUNICATION CENTRE</div>
      <h1>Notifications</h1>
      <p>Important IMBOP communications are recorded here. System-generated messages and authorized administrative communications use the same auditable communication infrastructure.</p>
    </header>

    {error&&<div className="notice error">{error}</div>}
    <div className="communication-summary"><b>{unread}</b><span>UNREAD</span><span>·</span><b>{items.length}</b><span>RECENT COMMUNICATIONS</span></div>

    {loading?<div className="card">Loading communications…</div>:
      !items.length?<div className="card empty-state">No communications yet. Important IMBOP events will appear here when they are generated for your account.</div>:
      <div className="communication-list">{items.map(item=><article className={"card communication-card "+(item.delivery_status!=="READ"?"communication-unread":"")} key={item.id}>
        <div className="communication-head">
          <div>
            <div className="eyebrow">{item.event_type||item.communication_type}</div>
            <h2>{item.subject}</h2>
          </div>
          <span className="status-badge">{item.delivery_status==="READ"?"READ":"NEW"}</span>
        </div>
        <p className="communication-body">{item.body}</p>
        <div className="communication-meta">
          <span>{new Date(item.created_at).toLocaleString("en-KE")}</span>
          <span>{item.origin==="SYSTEM"?"SYSTEM":"ADMIN"}</span>
        </div>
        {item.delivery_status!=="READ"&&<button className="admin-btn admin-btn-primary" onClick={()=>markRead(item.id)}>MARK AS READ</button>}
      </article>)}</div>}
  </main><Footer/></>
}
