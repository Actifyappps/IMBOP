"use client";
import Link from "next/link";
import Nav from "../../components/Nav";
import Footer from "../../components/Footer";

export default function ApplicationConfirmation(){
  return <><Nav/><main className="wrap">
    <div className="card confirmation-card" style={{maxWidth:820,margin:"auto",textAlign:"center"}}>
      <div className="eyebrow">APPLICATION RECEIVED</div>
      <h1>Thank You. Your Application Is In.</h1>
      <p><b>Application ≠ Publication.</b></p>
      <p>Your Institution Member application has been received and is now <b>PENDING REVIEW</b> by the authorised institution. It will not become public until that institution reviews and publishes it.</p>
      <div className="notice" style={{margin:"24px 0",textAlign:"left"}}>
        <b>What happens next?</b><br/>
        The institution reviews the application and may publish, return, or reject it. If published, the member and their business can become discoverable through IMBOP according to the institution's visibility settings.
      </div>
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
