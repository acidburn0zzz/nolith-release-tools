# Major release

GitLab occassionally releases a new major version (e.g. from 8.X to 9.X).

A major release allows us to make breaking changes, for instance
removing or changing (deprecating) existing APIs and functionalities.

## Handling deprecations

Deprecations should be announced and if necessary replaced one or more 
releases in advance of the major release.

For instance, when going from API v4 to v5, v5 will have to be active for at
least a single release before deprecating v4. In practice, it's very unfriendly
to deprecate an API over a single month and a longer time period might be 
chosen.

## New functionalities and APIs

New functionalities and APIs can freely be added at any time and should not 
be ported back.

## Frequency

At this time, there is no particular frequency to the occurance of major 
releases.