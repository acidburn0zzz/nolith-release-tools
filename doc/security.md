# Security Releases

Security vulnerabilities in GitLab and its dependencies are to be addressed with
the highest priority.

Security releases are naturally very similar to [patch releases](patch.md), but
on a much shorter timeline. The goal is to make a security release available as
soon as possible, while ensuring that the security issue is properly addressed
and that the fix does not introduce regressions.

Depending on the severity and the attack surface of the vulnerability, an
immediate patch release consisting of just the security fix may be warranted.
For less severe issues, it may be acceptable to include the fix in a future
patch. This is one case where the release manager _does not_ have final say
concerning a release, and he or she should consult with the GitLab development
team as well as any applicable security experts, such as the person disclosing
the issue.

## Process

Follow the standard [patch release process](patch.md#process), with some
additional considerations:

1. Mark any applicable previous releases as vulnerable on [version.gitlab.com].
1. Ensure the blog post discloses as much information about the vulnerability as
   is responsibly possible. We aim for clarity and transparency, and try to
   avoid secrecy and ambiguity.
1. Coordinate with the Marketing team to send out a security newsletter.
1. If the vulnerability was responsibly disclosed to us by a security
   researcher, ensure they're [publicly acknowledged] and thank them again
   privately as well.

[version.gitlab.com]: https://version.gitlab.com/
[publicly acknowledged]: https://about.gitlab.com/vulnerability-acknowledgements/

## Backporting

For very serious security issues, there is
[precedent](https://about.gitlab.com/2016/03/21/gitlab-8-dot-5-dot-8-released/)
to backport the security fix to previous monthly releases of GitLab. This should
be decided on a case-by-case basis by consulting with the rest of the
GitLab development team.

If a security fix warrants backporting to previous releases, doing a single blog
post that mentions all of the patches at once is acceptable.

---

[Return to Guides](../README.md#guides)
