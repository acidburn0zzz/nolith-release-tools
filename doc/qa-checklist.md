# GitLab QA

***TODO (rspeicher):*** Upon publishing this document, the
[manual_testing.md](https://dev.gitlab.org/gitlab/gitlab-ee/blob/master/doc/release/manual_testing.md)
document can be removed from `gitlab-ee`.

## QA Checklist

### Login

- [ ] Regular account login
- [ ] LDAP login (Use the [support document] for the LDAP settings)

### Forks

- [ ] Fork group project
- [ ] Push changes to fork
- [ ] Submit merge request to origin project
- [ ] Accept merge request

### Git

- [ ] Add SSH key
- [ ] Remove SSH key
- [ ] `git clone`, `git push` over SSH
- [ ] `git clone`, `git push` over HTTP with regular account
- [ ] `git clone`, `git push` over HTTP with LDAP account

### Project

- [ ] Create project
- [ ] Create project via repository import
- [ ] Transfer project to new owner
- [ ] Rename project's repository path
- [ ] Add project member
- [ ] Remove project member
- [ ] Remove project
- [ ] Create branch via UI
- [ ] Create tag via UI

### Web editor

- [ ] Create a new file via UI
- [ ] Edit a file via UI
- [ ] Upload a new file via UI
- [ ] Replace a file via UI
- [ ] Remove a file via UI

### Group

- [ ] Create group
- [ ] Create project in group's namespace
- [ ] Add group member
- [ ] Remove group member
- [ ] Remove group

### Markdown

- [ ] Visit / clone [relative links repository] and see if the links are linking to the correct documents in the repository
- [ ] Check if images are rendered in the repository's `README`
- [ ] Click on a [directory link] and see if it correctly takes to the tree view
- [ ] Click on a [file link] and see if it correctly takes to the blob view
- [ ] Check if the links in the `README` when viewed as a [blob] are correct
- [ ] Select the `markdown` branch and check if all links point to the files within the `markdown` branch

### Syntax highlighting

- [ ] Visit/clone [language highlight repository]
- [ ] Check for obvious errors in highlighting

### Upgrader

- [ ] Upgrade from the previous release
- [ ] Run the upgrader script in this release (it should not break)

### Rake tasks

- [ ] Check if `rake gitlab:check` is updated and works
- [ ] Check if `rake gitlab:env:info` is updated and works

[support document]: https://docs.google.com/document/d/1cAHvbdFE6zR5WY-zhn3HsDcACssJE8Cav6WeYq3oCkM/edit#heading=h.2x3u50ukp87w
[relative links repository]: https://dev.gitlab.org/samples/relative-links/tree/master
[directory link]: https://dev.gitlab.org/samples/relative-links/tree/master/documents
[file link]: https://dev.gitlab.org/samples/relative-links/blob/master/documents/0.md
[blob]: https://dev.gitlab.org/samples/relative-links/blob/master/README.md
[language highlight repository]: https://dev.gitlab.org/samples/languages-highlight

---

[Return to Guides](../README.md#guides)
