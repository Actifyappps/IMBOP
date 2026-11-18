import Nav from "../../components/Nav";
import Footer from "../../components/Footer";

export const metadata = { title: "Terms of Use | IMBOP" };

export default function Terms() {
  return (
    <>
      <Nav />
      <main className="wrap">
        <div className="platform-label">
          <b>IMBOP</b>
          <span>Institutional Members Business &amp; Opportunities Platform</span>
        </div>
        <div className="card">
          <div className="notice">DRAFT: owner approved, legal validation pending</div>
          <h1 style={{ margin: "12px 0 8px" }}>IMBOP Terms of Use</h1>
          <p>
            By using IMBOP, you agree to comply with these Terms, applicable institutional rules and published
            platform notices.
          </p>
          <h2>Institutional authority</h2>
          <p>
            Participating institutions remain responsible for membership authority and publication decisions within
            their institutional space. Application is not membership approval and application is not publication.
          </p>
          <h2>User responsibilities</h2>
          <p>
            Users must provide accurate information, use authorised accounts, respect privacy, avoid unlawful content,
            and not attempt to bypass access controls.
          </p>
          <h2>Enquiries and introductions</h2>
          <p>
            Enquiries and introductions made through IMBOP are requests to connect. IMBOP does not by itself create
            a contract, partnership, sale, investment, loan, employment relationship or other transaction between
            users, members or institutions.
          </p>
          <h2>Platform role</h2>
          <p>
            IMBOP provides institutional economic-network infrastructure for authorised discovery, enquiries,
            introductions and related institutional workflows. Saintsway Equity (SE) and Actify Inc. do not guarantee
            the accuracy, suitability, performance or outcome of a business, offer, need or relationship presented by
            a user or institution.
          </p>
          <h2>Contact</h2>
          <p>
            Saintsway Equity (SE)<br />
            P.O. Box 50517 - 00200, Nairobi<br />
            +254 723 645 108 / +254 786 219 058<br />
            saintswayequity@gmail.com
          </p>
        </div>
      </main>
      <Footer />
    </>
  );
}
