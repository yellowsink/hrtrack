# HRTrack API Notes

You don't necessarily need a browser, but you do need to speak HTTP and to *correctly receive, store, and send cookies*.

The session, stored on the server, can store any combination of the following data:
 - authenticated user session
 - provisional account creation credentials (user id and access key)

When arguments are expected, they must be EITHER in request query (`/?key=value&key2=value2`), or in a form POST body.
Both `multipart/form-data` and `application/x-www-form-urlencoded` are allowed.

Note that entity IDs and encryption keys are encoded as unpadded url-safe base64
when in transit over the API.

## Endpoints

### `GET /`

Response: HTML

### `GET /dashboard`

Expected request:
 - user is logged in
 - optional `onboard` argument that will tell the client to show the onboarding flow.

Response:
 - `200` HTML
 - `401` with delayed automatic redirect to `/`

Redirects you back to `/` if you are not logged in.

### `GET /account_preflight`

Response: HTML

Step 1 of the account creation flow.
Generates provisional credentials, stores them in the session, and returns the first step of that flow to you.

### `POST /create_account`

Expected request:
 - has provisional credentials in the session
 - has `id` and `accessKey` arguments matching the provisional credentials

Responses:
 - `401` You must access /provisional_creds before attempting to create an account
 - `401` You must return the same credentials as previously provided to you
 - `303 /dashboard?onboard`

Step 2 of the account creation flow.

When given back account credentials matching the provisional ones in the session,
removes the provisional credentials from the session, creates an account, and
sets the authenticated user session (so that at this point you are now logged in).

It then sends you to the dashboard.

### `POST /login`

Expected request:
 - has `id` and `accessKey` arguments

Responses:
 - `401` incorrect user ID or access key
 - `303 /dashboard`

### `POST /logout`

Expected request:
 - has authenticated user session

Responses:
 - `400` You are not logged in
 - `303 /`

Logs you out, by removing the authenticated user session.
This prevents you from accessing authenticated endpoints with your session,
and also clears your user data key from the server's memory,
making your data 100% inaccessible until login.
