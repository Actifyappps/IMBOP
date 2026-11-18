import Link from "next/link";

export default function Footer(){
  return <footer>
    <div className="footer-inner">
      <div className="footer-brand">
        <strong>SAINTSWAY EQUITY</strong>
        <span>IMBOP</span>
      </div>
      <nav className="footer-links" aria-label="Footer">
        <Link href="/contact">CONTACT</Link>
        <Link href="/privacy">PRIVACY</Link>
        <Link href="/terms">TERMS</Link>
      </nav>
    </div>
  </footer>
}