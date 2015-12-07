SonnetAmiga
===========

This project is an attempt at reimplementation of WarpOS for Sonnet Crescendo
7200 PCI cards.

The main part of the project is sonnet.library, which aims at API and ABI
compatibility with WarpOS powerpc.library.

This project is in very early stage of development. Don't expect it to do
anything useful (yet).

# Hardware

SonnetAmiga has the following hardware requirements:
- Amiga 1200/3000/3000T/4000/4000T.
- ELBOX Mediator for one of the above Amiga models. 3.3V PCI power rail is 
  necessary. Note that among big box Mediators, only 3000Di is equipped with 
  it by default. For the A1200, this is the 1200TX model. We're
  investigating if it's possible to mod the other models.
- Sonnet Crescendo 7200 with local memory installed (up to 128 or 256MB
  depending on installed graphics card).
- 3Dfx Voodoo 3 or ATI Radeon 9200 (ID $5960 and $5C63) graphics card.

# Building

See TOOLCHAIN file for building instructions.

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


