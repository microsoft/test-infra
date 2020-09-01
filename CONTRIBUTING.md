Contributing to Open Enclave Test Infra
------------------------------
Thank you for wanting to contribute to the test infrastracture of Open Enclave!


Developer Certificate of Origin
------------------------------

All contributions to the Open Enclave SDK must adhere to the terms of the
[Developer Certificate of Origin (DCO)](https://developercertificate.org/):

> Developer Certificate of Origin
> Version 1.1
>
> Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
> 1 Letterman Drive
> Suite D4700
> San Francisco, CA, 94129
>
> Everyone is permitted to copy and distribute verbatim copies of this
> license document, but changing it is not allowed.
>
> Developer's Certificate of Origin 1.1
>
> By making a contribution to this project, I certify that:
>
> (a) The contribution was created in whole or in part by me and I
>    have the right to submit it under the open source license
>    indicated in the file; or
>
> (b) The contribution is based upon previous work that, to the best
>    of my knowledge, is covered under an appropriate open source
>    license and I have the right under that license to submit that
>    work with modifications, whether created in whole or in part
>    by me, under the same open source license (unless I am
>    permitted to submit under a different license), as indicated
>    in the file; or
>
> (c) The contribution was provided directly to me by some other
>    person who certified (a), (b) or (c) and I have not modified
>    it.
>
> (d) I understand and agree that this project and the contribution
>    are public and that a record of the contribution (including all
>    personal information I submit with it, including my sign-off) is
>    maintained indefinitely and may be redistributed consistent with
>    this project or the open source license(s) involved.

Contributors need to sign-off that they adhere to these requirements by adding
a `Signed-off-by:` line to each commit message:

```
Author: John Doe <johndoe@example.com>
Date:   Wed Nov 6 11:30 2019 +0000

    This is my commit message.

    Signed-off-by: John Doe <johndoe@example.com>
```

Commits without this sign-off cannot be accepted, and the name in the
`Signed-off-by` and `Author` fields should match.

If you have configured your `user.name` and `user.email` via `git config`,
the `Signed-off-by` line can be automatically appended to your commit message
using the `-s` option:

```
$ git commit -s -m "This is my commit message."
```

If you have been sent here by a bot, please run the following on your branch to fix.

```
git commit --amend --signoff --all
git push --force-with-lease origin
```

If a merge commit is giving you troubles please try

```
git commit --amend --no-edit -s
```