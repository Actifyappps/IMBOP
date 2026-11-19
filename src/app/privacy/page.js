import Nav from "../../components/Nav";
import Footer from "../../components/Footer";

export const metadata = { title: "Privacy Notice | IMBOP" };

export default function Privacy() {
  return (
    <>
      <Nav />
      <main className="wrap">
        <div className="platform-label">
          <b>IMBOP</b>
          <span>Institutional Members Business &amp; Opportunities Platform</span>
        </div>
        <div className="card">
          <div className="notice">LEGAL REVIEW PENDING</div>
          <h1 style={{ margin: "12px 0 8px" }}>IMBOP Privacy Notice</h1>
          <p>
            IMBOP is a Saintsway Equity (SE) platform. Actify Inc. is engaged by SE as the technology development,
            operation and hosting partner.
          </p>
          <h2>Application is not publication</h2>
          <p>
            Submitting information does not automatically make it public. Publication requires an authorised
            institutional decision, and only eligible fields are presented publicly.
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
