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
            <div className="hero-brand">IMBOP</div>
            <h1>Institutional Members Business &amp; Opportunities Platform</h1>
            <div className="hero-subtitle">Institutional Economic Network Infrastructure</div>

            <p className="hero-intro">Connecting members and their businesses, offers and needs.</p>

            <h2>ARE YOU A MEMBER OF AN INSTITUTION?</h2>
            <p>Cooperative, SACCO, Chama, Business Network, Group...</p>
            <p>
              Ask your <b>INSTITUTION TO APPLY</b> to IMBOP, if it <b>HASN&apos;T YET</b>, and{" "}
              <b>CREATE</b> a <b>MEMBERS-ONLY SPACE</b> for all your member profiles, businesses, offers, needs &amp; updates.
            </p>

            <p className="apply-line">
              Then <b>APPLY / JOIN</b> yourself and
            </p>

            <h2 className="journey-heading">EXPLORE. KNOW. DISCOVER. ENQUIRE. CONNECT.</h2>
            <p>
              With your co-members, their businesses &amp; opportunities.
            </p>

            <p className="apply-line">
              <b>APPLY / JOIN</b> — Either as an Institution or Institution Member.
            </p>

            <p>
              For Members, your institution decides whether to publish.{" "}
              <b>SE IMBOP decides whether to publish Institutions.</b>
            </p>

            <div className="publication-gate">
              <div className="gate-title">The Publication Gate</div>
              <p><b>Application ≠ Publication.</b></p>
            </div>

            <p className="free-line"><b>FREE &amp; NO Credit Cards for Institutions &amp; their first 50 members.</b></p>

            <div className="actions" style={{ justifyContent: "center" }}>
              <Link className="btn" href="/discover">DISCOVER</Link>
              <Link className="btn alt" href="/apply">APPLY / JOIN</Link>
            </div>

            <div className="closing-brand">
              <div>SAINTSWAY EQUITY</div>
              <p><i>The Operating Infrastructure for Trusted MSME &amp; Cooperative Ownership</i></p>
              <div>IMBOP</div>
              <p><i>Institutional Economic Network Infrastructure</i></p>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
