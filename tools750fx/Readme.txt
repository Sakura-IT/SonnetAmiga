
These are some additional tools for 750FX users to take advantage of some of
the facilities on that chip.


GetSpeed

Will display the current clockspeed of your 750FX chip.  This command reads
the actual clockspeed from the PLL inside the CPU whereas other tools such as
Getinfo and WhichAmiga will read the hardware (ie stock) clockspeed.

GetTemp

Will display the current temparture of your 750FX chip. However, the
temperature measurement capabilities of the 750FX are woeful and can easily be
20C in error!  This is a problem with the design of the 750FX, not GetTemp.
At best, GetTemp will tell you whether the chip is getting hotter or colder
but that's about it.

SetSpeed CLOCKSPEED/N

Changes the clockspeed of the 750FX.  CLOCKSPEED can be set between 300 and
1200 MHz inclusive in 50 MHz increments. Testing has shown that speeds above
about 950MHz are unstable.  And as you increase the clockspeed you increase
the heat of the CPU, potentially shortening its working lifespan or damaging
it completely.  Speeds above 1000 MHz are strongly discouraged!  Any damage
you cause by overclocking is your responsibility - you have been warned.

Speeds below the stock speed are potentially useful to reduce heat build up
inside the case.


Special thanks to Hedeon who made all the magic possible...

Wrangler/August 2018
