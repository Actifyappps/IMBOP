"use client";
import {useState} from "react";
import Link from "next/link";
import {useRouter} from "next/navigation";
import Nav from "../../components/Nav";
import {supabase} from "../../lib/supabase";

export default function Login(){
 const[email,setEmail]=useState("");const[password,setPassword]=useState("");const[showPassword,setShowPassword]=useState(false);const[err,setErr]=useState("");const[busy,setBusy]=useState(false);const router=useRouter();
 async function go(e){e.preventDefault();setErr("");setBusy(true);const{error}=await supabase.auth.signInWithPassword({email,password});setBusy(false);if(error)setErr(error.message);else router.push("/workspace")}
 return <><Nav/><main className="wrap"><form className="card" style={{maxWidth:520,margin:"30px auto"}} onSubmit={go}>
  <div className="eyebrow">SECURE ACCESS</div><h1>Sign in</h1>{err&&<div className="notice error">{err}</div>}
  <label className="label">EMAIL</label><input className="input" type="email" value={email} onChange={e=>setEmail(e.target.value)} autoComplete="email" required/>
  <label className="label">PASSWORD</label><div style={{display:"flex",gap:8,alignItems:"center"}}><input className="input" style={{flex:1}} type={showPassword?"text":"password"} value={password} onChange={e=>setPassword(e.target.value)} autoComplete="current-password" required/><button type="button" className="btn alt" onClick={()=>setShowPassword(v=>!v)} aria-label={showPassword?"Hide password":"Show password"}>{showPassword?"HIDE":"SHOW"}</button></div>
  <div style={{marginTop:10}}><Link href="/forgot-password">FORGOT PASSWORD?</Link></div>
  <button className="btn" style={{marginTop:18}} disabled={busy}>{busy?"SIGNING IN…":"SIGN IN"}</button>
 </form></main></>}
