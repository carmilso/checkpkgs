% checkpkg(8) checkpkg User Manuals
% Carlos Millán Soler
% August 2017

# SYNOPSIS

checkpkg [*package*, ...] [*options*]

# DESCRIPTION

Check for Arch Linux packages updates given from arguments or **stdin** with no need to update the local repositories. Not installed and fake packages can also be checked.

# OPTIONS

-o, \--ordered
:   Produce output in the same order as the given packages.

# ENVIRONMENT VARIABLES

*ARCH*
  System's architecture. Default is got from **uname -m**.

*COMMUNITY_TESTING*
  Look for packages also in Community-Testing repository. Default is not set.

*MULTILIB_TESTING*
  Look for packages also in Multilib-Testing repository. Default is not set.

*TESTING*
  Look for packages also in Testing repository. Default is not set.

# EXAMPLES OF USE

➜ checkpkg foo bar fakepkg

➜ checkpkg foo bar fakepkg --ordered

➜ COMMUNITY_TESTING=1 checkpkg foo bar fakepkg

➜ MULTILIB_TESTING=1 checkpkg foo bar fakepkg

➜ TESTING=1 checkpkg foo bar fakepkg

# MORE INFO

The checkpkg source code may be downloaded from https://github.com/carmilso/checkpkg
