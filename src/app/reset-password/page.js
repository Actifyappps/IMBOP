"use client";
import {useEffect,useState} from "react";
import {useRouter} from "next/navigation";
import Nav from "../../components/Nav";
import {supabase} from "../../lib/supabase";

export default function ResetPassword(){
 const[password,setPassword]=useState("");const[confirm,setConfirm]=useState("");const[show,setShow]=useState(false);const[ready,setReady]=useState(false);const[err,setErr]=useState("");const[done,setDone]=useState(false);const[busy,setBusy]=useState(false);const router=useRouter();
 useEffect(()=>{supabase.auth.getSession().then(({data,error})=>{if(error||!data.session)setErr("This reset link is invalid or has expired.");else setReady(true)});},[]);
 async function submit(e){e.preventDefault();setErr("");if(password.length<8)return setErr("Password must be at least 8 characters.");if(password!==confirm)return setErr("Passwords do not match.");setBusy(true);const{error}=await supabase.auth.updateUser({password});setBusy(false);if(error)return setErr(error.message);setDone(true);setTimeout(()=>router.replace("/login"),1200)}
 return <><Nav/><main className="wrap"><form className="card" style={{maxWidth:520,margin:"30px auto"}} onSubmit={submit}><div className="eyebrow">ACCOUNT RECOVERY</div><h1>Set a new password</h1>{err&&<div className="notice error">{err}</div>}{done&&<div className="notice">Password updated. Returning to sign in…</div>}{ready&&!done&&<><label className="label">NEW PASSWORD</label><div style={{display:"flex",gap:8,alignItems:"center"}}><input className="input" style={{flex:1}} type={show?"text":"password"} value={password} onChange={e=>setPassword(e.target.value)} autoComplete="new-password" minLength={8} required/><button type="button" className="btn alt" onClick={()=>setShow(v=>!v)}>{show?"HIDE":"SHOW"}</button></div><label className="label">CONFIRM PASSWORD</label><input className="input" type={show?"text":"password"} value={confirm} onChange={e=>setConfirm(e.target.value)} autoComplete="new-password" minLength={8} required/><button className="btn" style={{marginTop:18}} disabled={busy}>{busy?"UPDATING…":"UPDATE PASSWORD"}</button></>}</form></main></>}
