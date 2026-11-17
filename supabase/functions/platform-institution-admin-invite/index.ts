const CORS={"Content-Type":"application/json","Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
const json=(x:any,s=200)=>new Response(JSON.stringify(x),{status:s,headers:CORS});
Deno.serve(async(req)=>{
 if(req.method==="OPTIONS")return new Response(null,{status:204,headers:CORS});
 if(req.method!=="POST")return json({error:"Method not allowed"},405);
 try{
  const base=Deno.env.get("SUPABASE_URL")!,anon=Deno.env.get("SUPABASE_ANON_KEY")!,service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,auth=req.headers.get("Authorization");
  if(!auth)return json({error:"Authenticated platform administrator required"},401);
  const au=await fetch(base+"/auth/v1/user",{headers:{apikey:anon,Authorization:auth}}),user=await au.json();
  if(!au.ok||!user?.id)return json({error:"Authenticated platform administrator required"},401);
  const h={apikey:service,Authorization:"Bearer "+service,"Content-Type":"application/json"};
  const rest=async(path:string,init:any={})=>{const r=await fetch(base+"/rest/v1/"+path,{...init,headers:{...h,...(init.headers||{})}}),t=await r.text();let d:any;try{d=JSON.parse(t)}catch{d=t}if(!r.ok)throw new Error(typeof d==="string"?d:(d?.message||d?.details||"Database request failed"));return d};
  const body=await req.json(),iid=body?.institution_id,email=(body?.email||"").trim().toLowerCase(),first=(body?.first_name||"").trim(),last=(body?.last_name||"").trim();
  if(!iid||!email||!email.includes("@"))return json({error:"Institution ID and valid email are required"},400);
  const pm=await rest("memberships?select=id&user_id=eq."+encodeURIComponent(user.id)+"&status=eq.active&limit=1");
  if(!pm.length)return json({error:"Active platform membership required"},403);
  const pmr=await rest("membership_roles?select=role_id&membership_id=eq."+pm[0].id),prids=pmr.map((x:any)=>x.role_id);
  const proles=await rest("roles?select=id&scope=eq.platform&code=in.(se_platform_owner,se_operations_admin)&id=in.("+prids.join(",")+")&limit=10");
  if(!proles.length)return json({error:"Platform administration permission required"},403);
  const pids=(await rest("role_permissions?select=permission_id&role_id=in.("+proles.map((x:any)=>x.id).join(",")+")")).map((x:any)=>x.permission_id);
  const ip=await rest("permissions?select=id&code=eq.institution_manage&id=in.("+pids.join(",")+")&limit=1");
  if(!ip.length)return json({error:"Institution management permission required"},403);
  const inst=await rest("institutions?select=id,name,status&id=eq."+encodeURIComponent(iid)+"&limit=1");
  if(!inst.length)return json({error:"Institution not found"},404);
  if(!["pending","active"].includes(inst[0].status))return json({error:"Institution must be PENDING or ACTIVE before an administrator can be assigned"},400);
  const ar=await rest("roles?select=id&scope=eq.institution&code=eq.institution_admin&limit=1");
  if(!ar.length)return json({error:"Institution administrator role is not configured"},500);
  const roleId=ar[0].id,existingMemberships=await rest("memberships?select=id,user_id,status&institution_id=eq."+encodeURIComponent(iid)+"&limit=100");
  const au2=await fetch(base+"/auth/v1/admin/users?per_page=1000",{headers:h});
  if(!au2.ok)return json({error:"Unable to inspect Auth users for administrator assignment"},502);
  const list=await au2.json(),eu=(list?.users||[]).find((u:any)=>(u.email||"").toLowerCase()===email);
  let uid:string,invited=false;
  if(eu){
    uid=eu.id;
    const already=existingMemberships.find((x:any)=>x.user_id===uid);
    if(already){
      await rest("memberships?id=eq."+already.id,{method:"PATCH",headers:{Prefer:"return=minimal"},body:JSON.stringify({status:"active",approved_at:new Date().toISOString(),updated_at:new Date().toISOString()})});
      const existingRoles=await rest("membership_roles?select=id&membership_id=eq."+already.id+"&role_id=eq."+roleId+"&limit=1");
      if(!existingRoles.length)await rest("membership_roles",{method:"POST",headers:{Prefer:"return=minimal"},body:JSON.stringify({membership_id:already.id,role_id:roleId,assigned_at:new Date().toISOString(),assigned_by:user.id})});
      return json({ok:true,institution_id:iid,membership_id:already.id,user_id:uid,role:"institution_admin",reused_existing_membership:true});
    }
  } else {
    const inv=await fetch(base+"/auth/v1/invite",{method:"POST",headers:h,body:JSON.stringify({email})}),txt=await inv.text();let d:any;try{d=JSON.parse(txt)}catch{d={}};
    if(!inv.ok){const ec=d?.code||d?.error_code||"auth_invite_failed";if(ec==="email_address_not_authorized")return json({error:"Supabase email delivery is not yet configured for this recipient. Configure custom SMTP before inviting external institutional administrators.",code:ec},503);if(ec==="over_email_send_rate_limit")return json({error:"Invitation email rate limit reached. Please wait before sending another invitation.",code:ec},429);return json({error:d?.msg||d?.message||d?.error_description||"Unable to send administrator invitation",code:ec},400);}
    uid=d?.id||d?.user?.id;invited=true;if(!uid)return json({error:"Invitation did not return an Auth identity"},500);
  }
  const now=new Date().toISOString();
  await rest("user_profiles",{method:"POST",headers:{Prefer:"resolution=merge-duplicates,return=minimal"},body:JSON.stringify({id:uid,email,first_name:first||null,last_name:last||null,display_name:[first,last].filter(Boolean).join(" ")||email,status:"active"})});
  const nm=await rest("memberships",{method:"POST",headers:{Prefer:"return=representation"},body:JSON.stringify({id:crypto.randomUUID(),institution_id:iid,user_id:uid,status:"active",joined_at:now,approved_at:now})}),mid=nm[0].id;
  await rest("membership_roles",{method:"POST",headers:{Prefer:"return=minimal"},body:JSON.stringify({membership_id:mid,role_id:roleId,assigned_at:now,assigned_by:user.id})});
  await rest("audit_events",{method:"POST",headers:{Prefer:"return=minimal"},body:JSON.stringify({id:crypto.randomUUID(),actor_user_id:user.id,institution_id:iid,event_code:"INSTITUTION_ADMIN_ASSIGNED",action:"CREATE",target_type:"MEMBERSHIP",target_id:mid,metadata:{email,user_id:uid,role:"institution_admin",invited}})});
  return json({ok:true,institution_id:iid,membership_id:mid,user_id:uid,role:"institution_admin",invited},201);
 }catch(e){console.error("platform-institution-admin-invite failure",e);return json({error:e instanceof Error?e.message:"Administrator assignment failed",code:"function_error"},500)}
});