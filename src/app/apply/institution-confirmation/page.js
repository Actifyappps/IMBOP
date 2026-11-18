"use client";
import Link from "next/link";
import Nav from "../../components/Nav";
import Footer from "../../components/Footer";

export default function InstitutionApplicationConfirmation(){
  return <><Nav/><main className="wrap">
    <div className="card confirmation-card" style={{maxWidth:820,margin:"auto",textAlign:"center"}}>
      <div className="eyebrow">APPLICATION RECEIVED</div>
      <h1>Welcome to IMBOP.</h1>
      <p><b>Your Institution Application Is In.</b></p>
      <p><b>Application ≠ Publication.</b></p>
      <p>Your application to join <b>IMBOP — Institutional Economic Network Infrastructure</b> has been received and is now <b>PENDING REVIEW by SE IMBOP</b>.</p>
      <div className="notice" style={{margin:"24px 0",textAlign:"left"}}>
        <b>What happens next?</b><br/>
        <b>SE IMBOP will review your Institution's application and may approve, return, or reject and communicate the outcome to you accordingly.</b>
        <p style={{margin:"16px 0 0"}}>IMBOP will treat <b>you as the Institution Admin</b>. You can always ask the <b>IMBOP Platform Admin</b> to change or update your Institution Admin.</p>
        <p>Once approved, you will receive your <b>IMBOP Platform link</b>, which you can share with your Members. Your Members can then apply to join your Institution's IMBOP space, and <b>you, as Institution Admin, can approve, monitor and/or manage them once onboarded.</b></p>
        <p>You can also configure your Institution's IMBOP space with your <b>information and brand</b>, and build it with your Members' <b>profiles, businesses, offers, needs and opportunities</b>.</p>
        <p style={{marginBottom:0}}><b>The more your Institution builds its IMBOP space, the more there is for Members to Explore. Know. Discover. Enquire. Connect.</b></p>
      </div>
      <div className="notice pricing-disclosure" style={{margin:"24px 0",textAlign:"left"}}><b>IMBOP PRICING:</b> Institutions and their first 50 IMBOP Onboards are free. Beyond 50, the Institution moves to a numbers-based plan. The first transition month uses a discounted minimum of <b>KES 5,000</b>. <b>Individual Institution Members are not billed.</b> <Link href="/plans"><b>View Plans &amp; Pricing.</b></Link></div><p><b>We welcome your Institution into IMBOP.</b></p>
      <div className="actions" style={{justifyContent:"center"}}>
        <Link className="btn" href="/discover">EXPLORE IMBOP</Link>
        <Link className="btn alt" href="/">RETURN HOME</Link>
      </div>
    </div>

    <div className="card" style={{maxWidth:820,margin:"24px auto 0",textAlign:"center"}}>
      <div className="eyebrow">FEATURED SPACE</div>
      <h2>Reach Institutional Members Through IMBOP</h2>
      <p>This space can carry approved institutional announcements, partner messages or advertising as the IMBOP commercial model develops.</p>
    </div>
  </main><Footer/></>
}