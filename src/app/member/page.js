"use client";
import {useEffect,useState} from "react";
import Link from "next/link";
import Nav from "../../components/Nav";
import Footer from "../../components/Footer";
import {supabase} from "../../lib/supabase";

export default function Member(){
 const[u,setU]=useState(null),[loading,setLoading]=useState(true),[error,setError]=useState("");
 useEffect(()=>{(async()=>{
  const{data:{user}}=await supabase.auth.getUser();
  if(!user){location.href="/login";return}
  setU(user);
  const{data,error}=await supabase.from("memberships").select("id,institution_id,status").eq("user_id",user.id).eq("status","active").limit(1).maybeSingle();
  if(error){setError(error.message);setLoading(false);return}
  if(!data){setError("Your account is authenticated, but no active IMBOP membership was found.");setLoading(false);return}
  setLoading(false);
 })().catch(e=>{setError(e.message||"Unable to load your member workspace.");setLoading(false)})},[]);
 if(loading)return <><Nav/><main className="wrap"><div className="card"><div className="eyebrow">AUTHENTICATED ACCESS</div><h1>Loading your member workspace…</h1></div></main><Footer/></>;
 if(error)return <><Nav/><main className="wrap"><div className="card"><div className="eyebrow">MEMBER ACCESS</div><h1>Member access unavailable</h1><div className="notice error">{error}</div><div className="actions"><Link className="btn" href="/login">SIGN IN AGAIN</Link><Link className="btn alt" href="/apply">APPLY / JOIN</Link></div></div></main><Footer/></>;
 return <><Nav authenticated/><main className="wrap"><div className="admin-hero"><div className="eyebrow">AUTHORISED MEMBER</div><h1>Welcome</h1><p>{u?.email||""}</p><p className="admin-description">Your IMBOP space is where your profile, business, offers, needs and opportunities become useful, editable content.</p><div className="actions"><Link className="btn" href="/content">MY CONTENT</Link><Link className="btn alt" href="/discover">DISCOVER</Link><Link className="btn alt" href="/apply">APPLY / JOIN</Link></div></div></main><Footer/></>;
}
