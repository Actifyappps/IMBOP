import Link from "next/link";
import Image from "next/image";

export default function Footer(){
  return <footer>
    <div className="footer-inner">
      <div className="footer-brand">
        <Image src="/imbop-logo.svg" alt="" width={28} height={28}/>
        <strong>IMBOP</strong>
        <span aria-hidden="true">|</span>
        <strong>BY SAINTSWAY EQUITY</strong>
      </div>
      <nav className="footer-links" aria-label="Footer">
        <Link href="/contact">CONTACT</Link>
        <Link href="/plans">PLANS</Link>
        <Link href="/privacy">PRIVACY</Link>
        <Link href="/terms">TERMS</Link>
      </nav>
    </div>
  </footer>
}