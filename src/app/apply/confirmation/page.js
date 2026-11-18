"use client";
import Link from "next/link";
import Nav from "../../../components/Nav";
import Footer from "../../../components/Footer";

export default function ApplicationConfirmation(){ 
  return <><Nav/><main className="wrap">
    <div className="card confirmation-card" style={{maxWidth:820,margin:"auto",textAlign:"center"}}>
      <div className="eyebrow">APPLICATION RECEIVED</div>
      <h1>Thank You. Your Application Is In.</h1>
      <p>Your Institution Member application has been received and is now <b>PENDING REVIEW</b> by your institution.</p>
      <div className="notice" style={{margin:"24px 0",textAlign:"left"}}>
        <b>What happens next?</b><br/>
        Your Institution will review and may publish, return, or reject it. If published, you and your business, offers and needs will become discoverable to your co-members through your Institution's IMBOP Page. Explore. Know. Discover. Enquire. Connect.
      </div>
      <div className="actions" style={{justifyContent:"center"}}>
        <Link className="btn" href="/discover">EXPLORE IMBOP</Link>
        <Link className="btn alt" href="/">RETURN HOME</Link>
      </div>
      <p><b>Application ≠ Publication.</b></p>
    </div>

    <div className="card" style={{maxWidth:820,margin:"24px auto 0",textAlign:"center"}}>
      <div className="eyebrow">FEATURED SPACE</div>
      <h2>Reach Institutional Members Through IMBOP</h2>
      <p>This space can carry approved institutional announcements, partner messages or advertising as the IMBOP commercial model develops.</p>
    </div>
  </main><Footer/></>
}
