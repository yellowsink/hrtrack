# HRTrack

A simple, specialized PWA to track HRT.

Goals:
 - remind you to take your HRT (push notifications optional)
 - track each time you do take it
 - track your dosage over time
 - track your stocks of supplies e.g. needles, alcohol swabs
 - track your stocks of medication
 - automatically adjust your schedule: if you take it a day late,
   move your future reminders a day later (optional)
 - complete privacy:
   * data is stored encrypted with your account's passkey,
     so the operator of an instance cannot see your data.
   * passkeys are used as they are the most secure way to manage accounts,
     and you can delete your account at any time.
   * data is not shared with anyone.
   * while push notifications unfortunately have to be sent through third parties
     (Mozilla Push Services, Google Firebase Cloud Messaging, and Apple Push),
     this is entirely optional.
     - notifications are not *yet* encrypted during passing through these services
     - I plan to change this in the future.
   * you may download your data or delete your account at any time.

Note that storing data locally is not supported due to issues with storage integrity and due to
notifications being impossible to implement without a server.