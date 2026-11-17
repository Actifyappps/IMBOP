"use client";

import { useEffect, useState } from "react";
import { supabase } from "../lib/supabase";

const REVIEWABLE = ["SUBMITTED", "PENDING_REVIEW", "RETURNED"];

const ACTION_LABELS = {
  REVIEW: "START REVIEW",
  APPROVE: "APPROVE",
  RETURN: "RETURN",
  REJECT: "REJECT",
};

export default function AdminPage() {
  const [applications, setApplications] = useState([]);
  const [institutions, setInstitutions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [working, setWorking] = useState(null);
  const [message, setMessage] = useState("");

  async function loadData() {
    setLoading(true);
    setMessage("");

    const [applicationsResult, institutionsResult] = await Promise.all([
      supabase
        .from("institution_applications")
        .select("*")
        .in("status", REVIEWABLE)
        .order("submitted_at", { ascending: true }),
      supabase
        .from("institutions")
        .select("id,name,legal_name,slug,status,status_reason,created_at,deleted_at")
        .order("created_at", { ascending: true }),
    ]);

    if (applicationsResult.error) {
      setMessage(applicationsResult.error.message);
    }

    if (institutionsResult.error) {
      setMessage((previous) => previous || institutionsResult.error.message);
    }

    setApplications(applicationsResult.data || []);
    setInstitutions(institutionsResult.data || []);
    setLoading(false);
  }

  useEffect(() => {
    loadData();
  }, []);

  async function reviewApplication(id, action) {
    const label = ACTION_LABELS[action] || action;
    let notes = "";

    if (action === "RETURN" || action === "REJECT") {
      notes = window.prompt(`${label} application. Enter review notes/reason:`);
      if (notes === null) return;
      notes = notes.trim();
      if (!notes) {
        setMessage("Review notes/reason are required.");
        return;
      }
    }

    if (
      action === "APPROVE" &&
      !window.confirm("Approve and onboard this institution application?")
    ) {
      return;
    }

    setWorking(id);
    setMessage("");

    const { data, error } = await supabase.rpc(
      "review_institution_application",
      {
        p_application_id: id,
        p_action: action,
        p_notes: notes || null,
      }
    );

    if (error) {
      setMessage(error.message);
      setWorking(null);
      return;
    }

    if (!data?.ok) {
      setMessage(
        data?.message ||
          data?.error ||
          "Institution application action failed."
      );
      setWorking(null);
      return;
    }

    setMessage(
      action === "REVIEW"
        ? "Institution application moved to PENDING REVIEW."
        : action === "APPROVE"
        ? "Institution application approved and onboarded as PENDING."
        : action === "RETURN"
        ? "Institution application returned for correction."
        : "Institution application rejected and retained for audit."
    );

    await loadData();
    setWorking(null);
  }

  function isTestInstitution(institution) {
    return (
      institution.slug === "imbop-gate-2-security-test" ||
      institution.name === "IMBOP Gate 2 Security Test Institution"
    );
  }

  function lifecycleControls(institution) {
    const status = String(institution.status || "").toUpperCase();

    if (institution.deleted_at) {
      return (
        <button
          type="button"
          disabled={working === institution.id}
          onClick={() => manageInstitution(institution.id, "RESTORE")}
        >
          RESTORE
        </button>
      );
    }

    if (status === "PENDING") {
      return (
        <>
          <button type="button" onClick={() => manageInstitution(institution.id, "ACTIVATE")}>ACTIVATE</button>
          <button type="button" onClick={() => manageInstitution(institution.id, "PAUSE")}>PAUSE</button>
          <button type="button" onClick={() => manageInstitution(institution.id, "SUSPEND")}>SUSPEND</button>
          <button type="button" onClick={() => manageInstitution(institution.id, "SHUT")}>SHUT</button>
          <button type="button" onClick={() => manageInstitution(institution.id, "DELETE")}>DELETE</button>
        </>
      );
    }

    return (
      <>
        {status !== "ACTIVE" && (
          <button type="button" onClick={() => manageInstitution(institution.id, "ACTIVATE")}>ACTIVATE</button>
        )}
        <button type="button" onClick={() => manageInstitution(institution.id, "PAUSE")}>PAUSE</button>
        <button type="button" onClick={() => manageInstitution(institution.id, "SUSPEND")}>SUSPEND</button>
        <button type="button" onClick={() => manageInstitution(institution.id, "SHUT")}>SHUT</button>
        <button type="button" onClick={() => manageInstitution(institution.id, "DELETE")}>DELETE</button>
      </>
    );
  }

  async function manageInstitution(id, action) {
    const reason = window.prompt(`${action} institution. Enter reason:`);
    if (reason === null) return;

    if (!reason.trim()) {
      setMessage("A reason is required.");
      return;
    }

    setWorking(id);
    setMessage("");

    const { data, error } = await supabase.rpc("manage_institution", {
      p_institution_id: id,
      p_action: action,
      p_reason: reason.trim(),
    });

    if (error) {
      setMessage(error.message);
      setWorking(null);
      return;
    }

    if (!data?.ok) {
      setMessage(
        data?.message ||
          data?.error ||
          "Institution lifecycle action failed."
      );
      setWorking(null);
      return;
    }

    setMessage(`${action} completed and audited.`);
    await loadData();
    setWorking(null);
  }

  if (loading) {
    return (
      <main>
        <p>Loading platform administration…</p>
      </main>
    );
  }

  return (
    <main>
      <header>
        <div>
          <strong>SAINTSWAY EQUITY</strong>
          <div>IMBOP</div>
        </div>
        <nav>
          <a href="/">HOME</a>
          <a href="/discover">DISCOVER</a>
          <a href="/apply">APPLY / JOIN</a>
          <a href="/workspace">WORKSPACE</a>
        </nav>
      </header>

      <section>
        <p>CONTROLLED ADMIN</p>
        <h1>SE PLATFORM ADMINISTRATION</h1>

        {message && <div role="status">{message}</div>}

        <section>
          <h2>INSTITUTION APPLICATIONS</h2>

          {applications.length === 0 ? (
            <p>No institution applications awaiting action.</p>
          ) : (
            applications.map((application) => (
              <article key={application.id}>
                <h3>{application.institution_name}</h3>
                <p>
                  {application.contact_name} · {application.contact_email}
                </p>
                <p><strong>{application.status}</strong></p>
                <p>Legal: {application.legal_name || "—"}</p>
                <p>Type: {application.institution_type || "—"}</p>
                <p>Phone: {application.contact_phone || "—"}</p>
                <p>Members: {application.membership_size ?? "—"}</p>
                <p>Location: {application.location || "—"}</p>
                <p>Website: {application.website || "—"}</p>
                <p>{application.description || ""}</p>

                <div>
                  <button
                    type="button"
                    disabled={working === application.id}
                    onClick={() => reviewApplication(application.id, "REVIEW")}
                  >
                    START REVIEW
                  </button>
                  <button
                    type="button"
                    disabled={working === application.id}
                    onClick={() => reviewApplication(application.id, "APPROVE")}
                  >
                    APPROVE
                  </button>
                  <button
                    type="button"
                    disabled={working === application.id}
                    onClick={() => reviewApplication(application.id, "RETURN")}
                  >
                    RETURN
                  </button>
                  <button
                    type="button"
                    disabled={working === application.id}
                    onClick={() => reviewApplication(application.id, "REJECT")}
                  >
                    REJECT
                  </button>
                </div>
              </article>
            ))
          )}
        </section>

        <section>
          <h2>INSTITUTION LIFECYCLE</h2>

          {institutions.map((institution) => {
            const testInstitution = isTestInstitution(institution);

            return (
              <article key={institution.id}>
                <div>
                  <h3>
                    {institution.name}{" "}
                    {testInstitution && <span className="status">TEST</span>}
                  </h3>
                  <p>
                    {institution.deleted_at
                      ? "DELETED"
                      : String(institution.status || "").toUpperCase()}
                  </p>
                </div>

                {institution.status_reason && (
                  <p>Status note: {institution.status_reason}</p>
                )}

                <div>{lifecycleControls(institution)}</div>
              </article>
            );
          })}
        </section>
      </section>
    </main>
  );
}
