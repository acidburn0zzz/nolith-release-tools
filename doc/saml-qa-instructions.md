## Intructions for SAML integration & QA

As a SAML test server we use GitHost's Google SAML. A SAML app has been setup 
using the `githost.io` domain and activated to work with `patricio-ee.gitlap.com`.

In order to test that SAML still works on the newest EE version, you need to update
the `patricio-ee.gitlap.com` server to the latest RC of the Enterprise Edition.

To login via SSH to the server see the server credentials in the support vault
in 1password

Once updated, you need to test that the **Google SAML** login still works.

For this go to: [https://patricio-ee.gitlap.com](https://patricio-ee.gitlap.com)
and login using the `Google SAML` button.

This will take you to Google's login screen. REMEMBER, Google OAuth **is not** 
enabled on this server, only Google SAML is, but the login sreens for both services
are identical.

Use the SAML User credentials to login, they are stored in 1password. Only accounts
that are registered within the **GitHost.io** domain will work.

If everything works as expected, you should be taken to the existing account on 
the GitLab server. If not, please log the error that occured in the 
regressions issue.