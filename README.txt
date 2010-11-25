Gentoo's package database, called "portage", is synchronized
via "rsync" using "emerge --sync". Unfortunately, rsync does
not keep a history of the files. Because of this, an ebuild
(the file describing how to download, compile and install a
Gentoo package) might disappear after an "emerge --sync".

The portage database is hosted on a CVS server, but CVS is
hard to work with (Linus Torvald describe CVS as plain
stupid...) Gentoo developers have talked about switching to
git instead, but this is not done yet and might take a long
time.

If an ebuild disappear from the portage tree, the package
will be hard to recompile without upgrading to a newer version.
With Gentoo, such recompiling will be necessary over time.

This script allows to keep snapshots of the portage tree in
a git repository using tags.
Instead of running "emerge --sync", run the script to:
1) Manually sync the portage tree (either rsync or tarbal);
2) Create a git tag

If a needed ebuild disappear, simply checkout a previous tag
and get the ebuild.

License: GPL3
Homepage: http://github.com/nbigaouette/portage_git_tags
