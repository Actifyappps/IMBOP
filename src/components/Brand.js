import Link from "next/link";
export default function Brand({compact=false}){return <Link href="/" className="brand-lockup"><span className="brand-mark">SE</span><span className="brand-copy"><strong>SAINTSWAY EQUITY</strong>{!compact&&<small>The Operating Infrastructure for Trusted MSME Ownership</small>}</span></Link>}
