-- Public discovery uses a public-schema wrapper around the private security-definer implementation.
-- The wrapper runs as the caller, so it must be allowed to EXECUTE the private helper.
-- The private schema remains outside the intended public RPC surface.
grant execute on function private.search_public_institutions(text, integer, integer, integer, integer) to anon, authenticated;
