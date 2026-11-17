import Link from "next/link";
import Nav from "./components/Nav";
import Footer from "./components/Footer";

export default function Home() {
  return (
    <>
      <Nav />
      <main>
        <section className="hero">
          <div className="hero-inner">
            <div className="eyebrow">SAINTSWAY EQUITY</div>
            <div className="eyebrow">IMBOP</div>
            <div className="eyebrow">HOME · DISCOVER · APPLY / JOIN · SIGN IN</div>

            <h1>IMBOP — INSTITUTIONAL MEMBERS BUSINESS &amp; OPPORTUNITIES PLATFORM</h1>
            <div className="eyebrow">Institutional Economic Network Infrastructure</div>

            <p>Connecting members and their businesses, offers and needs.</p>

            <h2>Are you a MEMBER of an INSTITUTION?</h2>
            <p>Cooperative, SACCO, Chama, Business Network, Group...</p>

            <p>
              Ask your <b>INSTITUTION TO APPLY</b> to IMBOP, if it <b>HASN'T YET</b>, and{" "}
              <b>CREATE</b> a MEMBERS-ONLY SPACE for all your member profiles, businesses,
              offers, needs &amp; updates.
            </p>

            <p>Then <b>APPLY / JOIN</b> yourself and</p>

            <h2>EXPLORE. KNOW. DISCOVER. ENQUIRE. CONNECT.</h2>
            <p>With your co-members, their businesses &amp; opportunities.</p>

            <p><b>APPLY / JOIN</b> — Institution or Institution Member.</p>

            <p>
              For Members, your institution decides whether to publish.{" "}
              <b>SE IMBOP decides whether to publish Institutions.</b>
            </p>

            <h2>THE PUBLICATION GATE</h2>
            <p><b>Application ≠ Publication.</b></p>

            <p><b>FREE &amp; NO Credit Cards for Institutions &amp; their first 50 members.</b></p>

            <div className="actions" style={{ justifyContent: "center" }}>
              <Link className="btn" href="/discover">DISCOVER</Link>
              <Link className="btn alt" href="/apply">APPLY / JOIN</Link>
            </div>

            <p><b>SAINTSWAY EQUITY</b></p>
            <p><i>The Operating Infrastructure for Trusted MSME &amp; Cooperative Ownership</i></p>
            <p><b>IMBOP · Institutional Members Business &amp; Opportunities Platform</b></p>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
