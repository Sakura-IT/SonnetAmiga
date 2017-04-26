SonnetAmiga
===========

This project is an attempt at reimplementation of WarpOS for Sonnet Crescendo
7200 PCI cards.

The main part of the project is a library, which aims at API and ABI
compatibility with WarpOS powerpc.library.

This project is in an early stage of development. Don't expect it to do
anything useful (yet).

# Hardware

SonnetAmiga has the following hardware requirements:
- Amiga 3000/3000T/4000/4000T.
- ELBOX Mediator for one of the above Amiga models. 3.3V PCI power rail is 
  necessary. Note that among big box Mediators, only 3000Di, 4000D 3V and 4000Di
  3V is equipped with it by default. We're investigating if it's possible to mod
  the other models.
- Sonnet Crescendo 7200 with local memory installed (up to 128 or 256MB
  depending on installed graphics card).
- 3Dfx Voodoo 3, 4, 5 or ATI Radeon 9200 (ID $5960, $5964 and $5C63) graphics card.

# Building

See the "Building SonnetAmiga project from source" article on project's Wiki:
https://github.com/Sakura-IT/SonnetAmiga/wiki

Automated binary builds are available from Jenkins: https://sonnet.uguu.waw.pl/jenkins/job/sonnetamiga/

# Installation

Just drop powerpc.library into your `LIBS:`. When powerpc.library is installed you also need InitPPC.
You can execute the initialization program from a shell after workbench has loaded or if you feel lucky
you can add it to the startup-sequence after LoadMonDrvs and before AddDataTypes
using `Run >NIL: <NIL: C:InitPPC`.

The initialization is needed to correctly patch the system. Do not run WarpOS (patched) binaries without
first running the initialization program.

The included library **IS NOT COMPATIBLE** with the powerpc.library from the WarpUp distribution.

**DO NOT INSTALL BOTH WARPUP LIBRARIES AND SONNET LIBRARIES!!!**

# Options

Currently the following options are supported through variables in ENVARC:sonnet

- EnEDOMem (0 or 1): Enable if you have EDO RAM installed. Default = 0.
- Debug (0-3): set the level of debug messages. 0 = no messages (default).
- EnAlignExc (0 or 1): Enable the installation of a user handler for the
  Align Exception. Default = 0.
- DisL2Cache: (0 or 1): Disable the L2 cache. Default = 0.
- DisL2Flush: (0 or 1): Disables the full flush of the L2 cache. 
  Can speed up things if it doesn't crash. Default = 0.
- EnDAccessExc: See EnAlignExc, but now for the Data Access Exception (DSI).

# Bugs

We're using GitHub Issues for bug tracking:
https://github.com/Sakura-IT/SonnetAmiga/issues

If you find any new bugs, please report them. Note that repository on GitHub
is just a public mirror of CVS development repostiory. Therefore, if you are
crazy enough to send patches, don't use GitHub Pull Requests, just make a
unified diff and attach it to the issue. Or mail it.

# Disclaimers

We, the developers, are officially stating that all code interacting with 
Mediator boards was developed without access to the official Mediator SDK.
This project is not endorsed by ELBOX in any way.


