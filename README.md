SonnetAmiga
===========

This project is an attempt at reimplementation of WarpOS for Sonnet Crescendo
7200 and other PPC PCI cards.

The main part of the project is a library, which aims at API and ABI
compatibility with WarpOS powerpc.library.

This project is in a beta stage of development.

# Hardware

SonnetAmiga has the following hardware requirements:
- Amiga 3000/3000T/4000/4000T.
- ELBOX Mediator for one of the above Amiga models. 3.3V PCI power rail is 
  necessary. Note that among big box Mediators, only 3000Di, 4000D 3V and 4000Di
  3V is equipped with it by default. Other big box Mediators may be used at your
  own risk with a 3.3V modified Sonnet (see Wiki).
- Sonnet Crescendo 7200 with local memory installed (up to 128 or 256MB
  depending on installed graphics card).
- 3Dfx Voodoo 3, 4, 5 or ATI Radeon 9200 (ID $5960, $5961, $5962, $5964 and
  $5C63) graphics card.
- 5V 168 pins FPM DIMMs 2K Refresh (up to 256MB with Voodoo3; 128MB with other
  supported video cards). 128 MB and 256 MB DIMMs are currently not supported.
  Please use up to 3x64 MB.
  
# Now also supporting

- Force PowerPMC-250 MPC7410 card. Tested with 256MB SDRAM on-board.
  Needs a PMC to PCI card with 3.3V regulator.
- Motorola PrPMC800/815 cards with Harrier chip-set and 128/256/512MB SDRAM
  on-board. Also needs a PMC to PCI card with 3.3V regulator and enough Amps.
  Up to 384MB supported on the 512MB cards if enough Zorro III space available.
- BigFoot Killer NIC M1 with 400MHz e300 core and 64MB on-board
- BigFoot Killer NIC K1 with 333MHz e300 core and 64MB on-board

# Software

- Elbox' pci.library 13.8+ required.
- THOR's mmulib package recommended.

# Building

See the "Building SonnetAmiga project from source" article on project's Wiki:
https://github.com/Sakura-IT/SonnetAmiga/wiki

Automated binary builds are available from Jenkins: https://jenkins.sakura-it.pl/job/sonnetamiga/

# Installation

Sadly, you cannot just drop powerpc.library into your `LIBS:`. When powerpc.library is installed you
also **NEED** InitPPC. If you run InitPPC from the startup-sequence after LoadMonDrvs and before
AddDataTypes using `Run >NIL: <NIL: C:InitPPC`, then you can add powerpc.library to LIBS:. For all
other cases see the installation wiki.

The initialization is needed to correctly patch the system. Do not run WarpOS (patched) binaries without
first running the initialization program.

The included library **IS NOT COMPATIBLE** with the powerpc.library from the WarpUp distribution.

**DO NOT INSTALL BOTH WARPUP LIBRARIES AND SONNET LIBRARIES!!!**

# Options

Currently the following options are supported through variables in ENVARC:sonnet

- EnEDOMem (0 or 1): Enable if you have EDO RAM installed. Default = 0.
- Debug (0-3): Set the level of debug messages. 0 = no messages (default).
- EnAlignExc (0 or 1): Enable the Alignment Exception (or in other words disable
  the unaligned access emulation). Default = 0.
- DisL2Cache (0 or 1): Disable the L2 cache. Default = 0.
- DisL2Flush (0 or 1): Disables the full flush of the L2 cache. 
  Can speed up things if it doesn't crash. Default = 0.
- EnDAccessExc: See EnAlignExc, but now for the Data Access Exception (DSI).
- DisHunkPatch (0 or 1): Disable automatic pushing first code hunk to FAST RAM.
  Default = 0.
- EnStackPatch (0 or 1): Enable if you want the library to push more 68K data to
  68K memory like stack and task structures. **EXPERIMENTAL**
- SetCPUComm (0 or 1): If set will move all requests to MasterControl process and
  are no longer directly handled by the 68K interrupt. Intended for A1200.
  Default = 0. **EXPERIMENTAL** 
- SetCMemDiv (0-5): Sets the speed divider of the L2 Cache memory of a Sonnet card.
  5 = 3, 4 = 2.5, 3 = 2, 2 = 1.5, 1 = 1, 0 = Handled by library. Default = 0.
  For example: A Sonnet with speed 500 MHz and setting 5 will run the L2 cache
  at 166 MHz (500/3). **USE AT OWN RISK!!!**
- Harrier256MB (0 or 1): Enable if you have a Harrier based G4 card with 256MB.
  Default = 0 (128MB) The 128MB card needs a jumper on pin 11/12 of J2.

# Bugs

See CONTRIBUTING.md file.

# Legal status

SonnetAmiga project is licensed under MIT License, with some notable exceptions.

The following components are *not* licensed under MIT:

- Parts of `ppcfunctions.p` contain code reassembled from original WarpOS. This is the only file that contains offending code. Even though Sam Jordan agreed on code reuse, copyright on this code is held by Haage & Partner. This file should be rewritten to avoid potential legal disputes. See issue #2 on GitHub.
- The low level WarpOS debugger and the disassembler vdappc (all files in `wosdb` and `vda` directories) are copyright Frank Wille. The author has granted permission for inclusion in SonnetAmiga project, but anyone willing to further modify or use the code (especially for commercial purposes) should contact the author first.
- The bogomips program by Jeff Tranter is based on a Linux kernel code, therefore we assume it is covered by GNU GPL license.

# Disclaimers

We, the developers, are officially stating that all code interacting with 
Mediator boards was developed without access to the official Mediator SDK.
This project is not endorsed by ELBOX in any way.

We are not responsible for any damages as a result of hardware modifications you performed needed to get
a PCI PPC card working in your system and neither for making your system work with a PPC PCI card. We are
also not responsible for any money loss due to the inflated prices on e.g. AmiBay or EBay.
Buy a PCI PPC card at your own risk!

