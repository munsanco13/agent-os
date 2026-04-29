# Vulnerability disclosure policy

If you discover a security vulnerability in this project, please report it privately. **Do not open a public issue.**

## Reporting

- **Preferred:** GitHub Security Advisory — Settings → Security → Advisories → Report a vulnerability
- **Email:** <<SECURITY_EMAIL>>

Include:
- Description of the issue and where it lives (file path, line, or URL)
- Reproduction steps or proof-of-concept
- Impact assessment (what an attacker could do)
- Whether you've disclosed this elsewhere

## Response

- Acknowledgement within 72 hours.
- Initial triage within 7 days.
- Patch or mitigation timeline communicated within 14 days.

## Scope

In scope:
- The application code in this repository
- Build tooling and CI workflows that ship to production
- Documented integrations (auth, payments, third-party APIs)

Out of scope:
- Issues requiring physical access to a developer's machine
- Self-XSS that requires the user to paste attacker-controlled JS into devtools
- Rate limiting on dev-only endpoints

## Hall of fame

Researchers who report valid issues will be credited here (with permission).
