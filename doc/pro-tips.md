# Pro tips

This is a collection of tips that previous [Release Managers](release-manager.md)
have found to be helpful during their reign. They are _suggestions_, not
requirements. Feel free to contribute your own!

## Add a `git cherry-pick` alias

As merge requests get accepted into master, you're responsible for making sure
they make it into the appropriate `stable` branch. Currently the preferred way
of doing this is via `git cherry-pick`s of the merge commit. As you'll be doing
this a lot, it's helpful to have a [Git alias] to cut down on typing.

```ini
# ~/.gitconfig
[alias]
  cp = cherry-pick
```

```sh
git cp <SHA> -m 1
```

[Git alias]: https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases

## Leave notes to yourself

As the 22nd nears, it can be stressful trying to make sure that everything that
needs to be included in a release is _actually_ included. It can be helpful to,
for example, [leave a note] to yourself (and anyone else interested) in a merge
request after it's been picked into the `stable` branch. Unfortunately, this
isn't [100% fool-proof].

[leave a note]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2530#note_3332148
[100% fool-proof]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2530#note_3347972

## Update the Regression Issue

The [regressions issue](rake-tasks.md#regression_issueversion) is your overview
of the release from the first RC up through any patch releases. It can be
helpful to update any comments as they are addressed so you're not constantly
re-checking things that have already been fixed and merged.

A "best practice" we've developed is editing the notes to reflect their status
as they are addressed. For example, a regression note might look like this after
being reported:

```text
#3531 - User profile pages are timing out - Fix in !1234
```

After being addressed, you might edit it to look like this:

```text
~~#3531 - User profile pages are timing out - Fix in !1234~~

**rspeicher:** Merged, to be included in RC2.
```

The strikethrough formatting makes it easier to scan through the list to find
issues that still need to be addressed, and the added note from the release
manager (**rspeicher**, in this case) gives anyone following the issue a clear
indication of when the fix will be released.

## Use a clipboard history or text expander app

So now that you're constantly [adding notes to yourself] and [updating regression notes],
you might find yourself typing the same things over and over. Unacceptable!

> I use the [Clipboard History and Snippets](https://www.alfredapp.com/help/features/clipboard/)
> feature from Alfred on OS X so that adding something like "Picked into
> `8-4-stable`" is as simple as hitting <kbd>⌥⌘C</kbd>, typing "picked", and
> hitting <kbd>Enter</kbd>.
>
> -- @rspeicher

[adding notes to yourself]: #leave-notes-to-yourself
[updating regression notes]: #update-the-regression-issue

---

[Return to Guides](../README.md#guides)
