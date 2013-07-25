precise_migration
=================

Migration of HTGT to Ubuntu 12.04 (Precise) from 9.something or 10.something

This project creates lists of dependencies, both HTGT local modules (currently held in SVN, soon to be git) and CPAN.

setup_shell -- contains the environment for helping with the migration and also for running htgt.
install_htgt -- cleans the installation folders out and installs (by rsync and in one instance, cp) the locally produced modules

htgt_app/ -- the Catalyst startup script folder and root folder + htgt.yml
htgt_lib/ -- copies of the local htgt modules collected and installed by install_htgt
htgt_perl5/ -- the local_lib perl library with all the cpanm installed dependencies

required_modules.txt -- lists the modules installed with cpanm to make htgt run - I have asked Alex to update this as he adds more modules so that we have a complete list of dependencies.

howto.tex -- is out of date now

Additional local repos need to be checked out in my ~/svn-checkout directory for the install_htgt script to work.

Changes I have made in htgtdb-trunk and htgt-trunk I have not checked in just in case they break the old system.
I haven't yet created gits of those. I haven't made changes in any other checkouts (yet).

David
