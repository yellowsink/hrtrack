# HRTrack

[![wakatime](https://wakatime.com/badge/github/yellowsink/hrtrack.svg)](https://wakatime.com/badge/github/yellowsink/hrtrack)

A PWA to track your HRT.

HRTrack is very work-in-progress at the time of writing,
please see the roadmap for info on current status of development.

Goals:
 - remind you to take your HRT (push notifications optional)
 - track each time you do take it
 - track your dosage over time
 - track your stocks of supplies e.g. needles, alcohol swabs
 - track your stocks of medication
 - track your blood test results over time
 - support anti-androgens, testosterone, etc.
 - track body measurements
 - have fun stats and graphs
 - automatically find milestones :D
 - authoritative stock-takes that correct automatic tracking if it falls out of sync.
 - learn how you like to rotate your injection sites, and tell you which one to use next (this does NOT use neural networks, just basic statistics.)
 - automatically adjust your schedule: if you take it a day late,
   move your future reminders a day later (optional)
 - complete privacy:
   * the database is encrypted with your account's secret token,
     so the operator of an instance cannot see your data.
   * data is not shared with anyone.
   * while push notifications unfortunately have to be sent through third parties
     (Mozilla Push Services, Google Firebase Cloud Messaging, and Apple Push),
     this is entirely optional.
     - notifications are not *yet* encrypted during passing through these services
     - I plan to change this in the future.
   * you may download your data or delete your account at any time, and move to a different instance.

Note that storing data locally is not supported due to issues with storage integrity and due to
notifications being impossible to implement without a server.

## Credits

The [vibe.d](https://vibed.org/) framework for handling web and I/O for me.

[RocksDB](https://rocksdb.org/), for being a stupid fast and simple embedded key-value database.

The [SecureD](https://github.com/LightBender/SecureD) library for being absolutely awesome.
It has amazing defaults and handles all the footguns for you, to make adding cryptography to your app properly actually
feasible for a newbie. So many kudos.
