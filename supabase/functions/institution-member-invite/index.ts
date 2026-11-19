const CORS={"Content-Type":"application/json","Access-Control-Allow-Origin":"https://imbop-operations-actifys-projects-3f24c657.vercel.app","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
const json=(x:any,s=200)=>new Response(JSON.stringify(x),{status:s,headers:CORS});
Deno.serve(async(req)=>{
 if(req.method==="OPTIONS")return new Response(null,{status:204,headers:CORS});
 if(req.method!=="POST")return json({error:"Method not allowed"},405);
 try{
  const base=Deno.env.get("SUPABASE_URL")!,anon=Deno.env.get("SUPABASE_ANON_KEY")!,service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,auth=req.headers.get("Authorization");
  if(!auth)return json({error:"Authenticated institution administrator required"},401);
  const au=await fetch(base+"/auth/v1/user",{headers:{apikey:anon,Authorization:auth}});
  const user=await au.json();
  if(!au.ok||!user?.id)return json({error:"Authenticated institution administrator required"},401);
  const h={apikey:service,Authorization:"Bearer "+service,"Content-Type":"application/json"};
  const rest=async(path:string,init:any={})=>{const r=await fetch(base+"/rest/v1/"+path,{...init,headers:{...h,...(init.headers||{})}}),t=await r.text();let d:any;try{d=JSON.parse(t)}catch{d=t}if(!r.ok)throw new Error(typeof d==="string"?d:(d?.message||d?.details||"Database request failed"));return d};
  const body=await req.json(),applicationId=body?.application_id;
  if(!applicationId)return json({error:"Application ID is required"},400);

  const appRows=await rest("member_applications?select=id,institution_id,applicant_name,email,phone,status&id=eq."+encodeURIComponent(applicationId)+"&limit=1");
  if(!appRows.length)return json({error:"Member application not found"},404);
  const app=appRows[0];
  if(app.status!=="PUBLISHED")return json({error:"The member application must be PUBLISHED before an account can be invited"},400);

  const perm=await rest("rpc/has_institution_permission",{method:"POST",body:JSON.stringify({p_institution_id:app.institution_id,p_permission_code:"membership_manage"})});
  if(perm!==true)return json({error:"Institution membership management permission required"},403);

  const roleRows=await rest("roles?select=id&scope=eq.institution&code=eq.member&limit=1");
  if(!roleRows.length)return json({error:"Member role is not configured"},500);
  const roleId=roleRows[0].id;

  const usersRes=await fetch(base+"/auth/v1/admin/users?per_page=1000",{headers:h});
  if(!usersRes.ok)return json({error:"Unable to inspect Auth users"},502);
  const users=await usersRes.json();
  const existing=(users?.users||[]).find((u:any)=>(u.email||"").toLowerCase()===app.email.toLowerCase());

  let uid:string,invited=false;
  if(existing){uid=existing.id;}
  else{
    const inv=await fetch(base+"/auth/v1/invite",{method:"POST",headers:h,body:JSON.stringify({email:app.email,redirect_to:"https://imbop-operations-actifys-projects-3f24c657.vercel.app/reset-password",data:{name:app.applicant_name,institution_id:app.institution_id,member_application_id:app.id}})});
    const txt=await inv.text();let d:any;try{d=JSON.parse(txt)}catch{d={}};
    if(!inv.ok)return json({error:d?.msg||d?.message||d?.error_description||"Unable to send member invitation"},400);
    uid=d?.id||d?.user?.id;invited=true;
    if(!uid)return json({error:"Invitation did not return an Auth identity"},500);
  }

  const memberships=await rest("memberships?select=id,status&institution_id=eq."+encodeURIComponent(app.institution_id)+"&user_id=eq."+encodeURIComponent(uid)+"&limit=1");
  const now=new Date().toISOString();
  let membershipId:string;
  if(memberships.length){
    membershipId=memberships[0].id;
    await rest("memberships?id=eq."+membershipId,{method:"PATCH",headers:{Prefer:"return=minimal"},body:JSON.stringify({status:"active",approved_at:now,updated_at:now})});
  }else{
    const rows=await rest("memberships",{method:"POST",headers:{Prefer:"return=representation"},body:JSON.stringify({id:crypto.randomUUID(),institution_id:app.institution_id,user_id:uid,status:"active",joined_at:now,approved_at:now})});
    membershipId=rows[0].id;
  }

  const existingRole=await rest("membership_roles?select=id&membership_id=eq."+membershipId+"&role_id=eq."+roleId+"&limit=1");
  if(!existingRole.length)await rest("membership_roles",{method:"POST",headers:{Prefer:"return=minimal"},body:JSON.stringify({membership_id:membershipId,role_id:roleId,assigned_at:now,assigned_by:user.id})});

  await rest("member_profiles",{method:"POST",headers:{Prefer:"resolution=merge-duplicates,return=minimal"},body:JSON.stringify({id:crypto.randomUUID(),institution_id:app.institution_id,user_id:uid,visibility:"INSTITUTION",status:"ACTIVE",publication_state:"PUBLISHED"})});

  const pubs=await rest("member_application_publications?select=published_business_id&application_id=eq."+encodeURIComponent(app.id)+"&limit=1");
  if(pubs.length&&pubs[0].published_business_id){
    await rest("businesses?id=eq."+encodeURIComponent(pubs[0].published_business_id),{method:"PATCH",headers:{Prefer:"return=minimal"},body:JSON.stringify({created_by_user_id:uid,updated_at:now})});
  }

  await rest("audit_events",{method:"POST",headers:{Prefer:"return=minimal"},body:JSON.stringify({id:crypto.randomUUID(),actor_user_id:user.id,institution_id:app.institution_id,event_code:"INSTITUTION_MEMBER_INVITED",action:"CREATE",target_type:"MEMBER_APPLICATION",target_id:app.id,metadata:{user_id:uid,membership_id:membershipId,email:app.email,invited}})});
  return json({ok:true,user_id:uid,membership_id:membershipId,invited},201);
 }catch(e){return json({error:e instanceof Error?e.message:"Member invitation failed",code:"function_error"},500)}
});