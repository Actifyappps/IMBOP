import Nav from "../../components/Nav";
import Footer from "../../components/Footer";

export const metadata = { title: "Contact | IMBOP" };

export default function Contact() {
  return (
    <>
      <Nav />
      <main className="wrap">
        <div className="platform-label">
          <b>IMBOP</b>
          <span>Institutional Members Business &amp; Opportunities Platform</span>
        </div>
        <div className="card">
          <h1 style={{ margin: "0 0 8px" }}>Contact Saintsway Equity</h1>
          <p className="muted">
            For questions about IMBOP, institutional applications or your data, contact Saintsway Equity (SE).
          </p>
          <p>
            P.O. Box 50517 - 00200, Nairobi<br />
            +254 723 645 108 / +254 786 219 058<br />
            <a href="mailto:saintswayequity@gmail.com">saintswayequity@gmail.com</a>
          </p>
          <p>
            Technology development and operations: Actify Inc.
          </p>
        </div>
      </main>
      <Footer />
    </>
  );
}