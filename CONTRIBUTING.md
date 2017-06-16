# Contributing

**Everyone** is encouraged to help improve this project!

## Reporting bugs and issues

We are using [GitHub Issues](https://github.com/Sakura-IT/SonnetAmiga/issues) to track problems.

When creting a new issue, please include the following information about your hardware:
* The exact Sonnet card model - can be read from the sticker on the back of the card (for example "MG3-500-1-BLT REV A").
* Information about any mods applied to the Sonnet card (for example "installed 3.3V regulator according to instructions from...").
* Information about installed memory on Sonnet along with its physical layout (for example "64MB in form of 2x DIMM 5V 168-pin FPM 2K refresh 32MB, two top slots").
* Amiga model (for example "Amiga 4000T made by Escom, mainboard rev 4").
* Buster chip version (for example "Super Buster 11").
* CPU model (for example "MC68040 25MHz").
* CPU board model (for example "Commodore A3640 rev 3.2").
* Mediator model (for example "Mediator 3/4000T").
* Graphics card model (for example "Radeon 9200 PCI 128MB").

And some information about the software:
* AmigaOS version (for example "Kickstart 3.1, AmigaOS 3.9, BoingBag 2, clean fresh install").
* Implementation of 68040/68060.library (for example "original 68040.library from Commodore").
* Version of Sonnet powerpc.library OR build number if running development snapshot OR source snapshot date if you built it from source yourself (for example "powerpc.library 17.6 obtained from Aminet").
* Version of mmu.library if installed.
* Version of pci.library along with information about any patches to it (for example "pci.library 11.0, modified in the following way...").
* Mediator's `ENVARC:` settings.
* Output of `pciinfo` command.
* Output of `showconfig` command.
* Output of `muscan` command if `mmu.library` is used.
* Output of Sonnet crash window if displayed.

## Sending patches

All code fixes are welcome. GitHub is just a mirror of the development repository. Therefore, please do not use pull requests on GitHub, we can not merge them automatically. Instead just attach an unified diff to the issue (alternatively, upload the diff to gist, link the gist in an issue) or e-mail it to us.

