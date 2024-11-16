## Done
 - user id + access key authentication
 - encrypted storage helper apis
 - account creation flow
 - login and logout apis
 - session expiration
 - full API documentation for my own reference
 - full database format and entity documentation (again for my reference)
 - frontend:
   * account creation, login flows

## In Progress
 - frontend:
   * user settings page
     - full access key management API
 - user setup stuff:
   * medications
 - fully mock up stored data and UI

## To-Do (high priority)
 - user setup stuff:
   * dosages & schedules
   * notifications
   * supplies
   * injection sites
 - account deletion (this and export both require recursively finding the user's owned objects)
 - bloodwork scheduling / reminders
   * remind you to get liver tests if your dosages includes bica
 - actually store medicate events
   * multiple medication types from the start
 - store and auto update current stocks
 - account export

## To-Do (later)
 - stats and trends
 - bloodwork support
 - push notifications
 - milestones
 - injection site suggestion
 - rewrite sessions to be encrypted
 - body measurements
 - HRT effects journal
 - data import (useful for migrating instances, should only be possible at account creation time)
 - TOTP
 - allow the PWA to save credentials (warn of security implications)
   * this allows it to renew expired sessions automatically

## unsure if will include or not (feels like scope creep)
 - period tracking capabilities (use Euki?)
 - storing selfies etc over time (idk have a folder or something)
