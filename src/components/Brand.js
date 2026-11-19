import Image from "next/image";
import Link from "next/link";

export default function Brand({ compact = false }) {
  return (
    <Link href="/" className="brand-lockup" aria-label="IMBOP home">
      <span className="brand-logo" aria-hidden="true">
        <Image
          src="/imbop-logo.svg"
          alt=""
          width={52}
          height={52}
          priority
        />
      </span>
      <span className="brand-copy">
        <strong>IMBOP</strong>
        {!compact ? (
          <small>Institutional Economic Network Infrastructure</small>
        ) : (
          <small>BY SAINTSWAY EQUITY</small>
        )}
      </span>
    </Link>
  );
}
