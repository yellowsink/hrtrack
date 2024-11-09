# HRTrack

A PWA to track HRT.

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
   * data is stored encrypted with your account's secret token,
     so the operator of an instance cannot see your data.
   * data is not shared with anyone.
   * while push notifications unfortunately have to be sent through third parties
     (Mozilla Push Services, Google Firebase Cloud Messaging, and Apple Push),
     this is entirely optional.
     - notifications are not *yet* encrypted during passing through these services
     - I plan to change this in the future.
   * you may download your data or delete your account at any time.

Note that storing data locally is not supported due to issues with storage integrity and due to
notifications being impossible to implement without a server.

## A note on security

I am just some random internet person. And I'm creating a public registration service that tracks people's
*medical data*. That makes me about as uncomfortable as I think it should, so I'm taking an utterly paranoid approach
to building this.

My goal is pretty simple to state: I should not be able to read ANYTHING useful from the database as the site operator.

All authentication methods supported
(currently, just pair of secret tokens, I'm investigating passkeys and other mechanisms) MUST be able to provide a value
that is usable for encryption, and then the server can throw away, and reliably obtain again upon login to decrypt data.

When you create an account, the server generates two random numbers: a user ID, and an encryption key
(I call this the *user data key*).
It then encrypts your initial user data, and stores that encrypted data against the user ID.
The server then randomly generates an *access key*, and encrypts the user data key with it.
The encrypted user data key is stored against the user id, too, and is then promptly thrown away and never seen again.

Finally, the user ID and access key are sent to the client where you store them in your password manager.

On login, you provide the user ID and an access key. The server uses your access key to decrypt the user data key,
which it stores in session storage for the length of your session (at this point your access key is again forgotten).
This user data key can then be used by the server to read and write your data, encrypted, to the database.

Why this two layer approach? Why not simply make the access and user data keys one and the same?
Well, it all comes down to flexibility.
Once you have an account, and are logged in (and thus the server has access to the user data key),
you can also encrypt that key against a *new* access key, and store both access keys.
Now you can have two different access keys. That seems like a weird and unnecessary feature, but this means you can
*change your access key*, which is a major requirement.

It also means that, if I ever get passkey authentication working for example, you can add a passkey to your account
along with an access key and any other method all at once, and I can register both of my Yubikeys simultaneously - a big
deal for hardware keys! Otherwise, if you lost one you'd be locked out *forever*!
This is, of course, not so much of an issue if my passkey is just in, say, Bitwarden.

What about two-factor authentication? Well, the access key on its own is enough to ensure that I,
as the server operator, can never read your data, so my paranoia about handling strangers' medical data is satisfied.
Any support for multifactor authentication (e.g. TOTP, U2F) does nothing extra to protect against *me*,
but it absolutely still can protect against an attacker - if they can provide your access key but not your TOTP code,
the server can still deny them access, even though it can access your data if it really wanted to.

So multifactor authentication still works just as well as it does with any other service, it just doesn't enhance the
"site owner has none of my data" aspect, which most services don't have to worry about anyway!
It's basically equivalent to any other MFA implementation.

Finally, the first of a couple caveats I have to talk about: sessions and session security.
I can't have you log in for every single API request you ever make, nor could I, say, send your Yubikey 50 cryptography
requests on every page load for all the different entities I need to access, so I will have to store your user data
key in the server's RAM.

The way this is done is using a session storage system that associates your user data key (in plain!) against a session
token, that is then given to you as a cookie. These sessions later expire and are deleted from the server.
This being secure relies on two things: nobody ever reading the session store without correct access, and appropriate
session timeouts.

There is a tension here, as lower session timeouts, e.g. 15 minutes are good for security, but not so good when you
come back after 10 days to log your next injection, and you got logged out again.
This may change in future, but for now I have chosen a session timeout of an hour, which should be as much time as you'd
realistically want for a single session, but means you won't get to just arrive after a week, log your stuff,
then leave again.

The other caveat to talk about is me: I am not an expert. I don't do cryptography much, I'm just a woman who wants an
app that's *actually good* at tracking her HRT, and if I'm going to the effort of making it, I want to make it such that
others can benefit from it too, which instils a certain level of paranoia into me.
I want you to be able to trust me, and the best way I can think of is to hardcode it into the system that I can't spy
on you.

All you should have to trust in an ideal world is that I am running the server software I say I am (which I am!),
though realistically you also have to trust that I haven't inadvertently introduced any security flaws,
but it *is* open source!

Currently supported authentication methods:
 - User ID + Access Key

Currently supported MFA methods:
 - None

## Credits

The [vibe.d](https://vibed.org/) framework for handling web and I/O for me.

[RocksDB](https://rocksdb.org/), for being a stupid fast and simple embedded key-value database.

The [SecureD](https://github.com/LightBender/SecureD) library for being absolutely awesome.
It has amazing defaults and handles all the footguns for you, to make adding cryptography to your app properly actually
feasible for a newbie. So many kudos.
