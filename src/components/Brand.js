import Link from "next/link";
export default function Brand({compact=false}){return <Link href="/" className="brand-lockup"><span className="brand-mark imbop-mark">IM</span><span className="brand-copy"><strong>IMBOP</strong>{!compact?<small>Institutional Economic Network Infrastructure</small>:<small>BY SAINTSWAY EQUITY</small>}</span></Link>}
