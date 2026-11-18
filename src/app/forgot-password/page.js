"use client";
import {useState} from "react";
import Link from "next/link";
import Nav from "../../components/Nav";
import {supabase} from "../../lib/supabase";

export default function ForgotPassword(){
 const[email,setEmail]=useState("");const[msg,setMsg]=useState("");const[err,setErr]=useState("");const[busy,setBusy]=useState(false);
 async function submit(e){e.preventDefault();setBusy(true);setMsg("");setErr("");const{error}=await supabase.auth.resetPasswordForEmail(email.trim(),{redirectTo:window.location.origin+"/reset-password"});setBusy(false);if(error)setErr(error.message);else setMsg("If an account exists for that email, a password reset link has been sent.");}
 return <><Nav/><main className="wrap"><form className="card" style={{maxWidth:520,margin:"30px auto"}} onSubmit={submit}><div className="eyebrow">ACCOUNT RECOVERY</div><h1>Forgot password?</h1><p className="muted">Enter the email used for your IMBOP account. We will send a secure reset link.</p>{err&&<div className="notice error">{err}</div>}{msg&&<div className="notice">{msg}</div>}<label className="label">EMAIL</label><input className="input" type="email" value={email} onChange={e=>setEmail(e.target.value)} autoComplete="email" required/><button className="btn" style={{marginTop:18}} disabled={busy}>{busy?"SENDING…":"SEND RESET LINK"}</button><div style={{marginTop:14}}><Link href="/login">BACK TO SIGN IN</Link></div></form></main></>}
