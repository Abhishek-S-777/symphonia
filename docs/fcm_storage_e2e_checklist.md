# FCM + Storage E2E Checklist

## Scope

This checklist verifies:

- Voice-note uploads against Firebase Storage rules
- `request_location`, `ring_phone`, and `stop_ring` push flows end-to-end

## Preconditions

- Two physical devices signed into different users in the same couple
- Latest app installed on both devices
- Cloud Functions deployed from `symphonia-functions`
- Firebase Storage rules deployed from this repo (`storage.rules`)

## 1) Voice Note Storage Rules

1. On Device A, record and send a voice note.
2. Confirm Firestore doc appears under `couples/{coupleId}/voiceNotes/{voiceNoteId}`.
3. Confirm Storage object appears under `couples/{coupleId}/voice_notes/{fileName}`.
4. Confirm Device B can play the note.
5. Negative test: sign in with a user from another couple and try to read the URL/object path. Access should fail.

## 2) Location Request Flow

1. Keep Device B in foreground, open app.
2. On Device A, tap "Request Location".
3. On Device B, verify:
   - Notification shown on `location_channel`
   - Location written to `couples/{coupleId}/locations/{userId}`
4. Repeat with Device B backgrounded:
   - Notification still appears
   - Location write still occurs (if OS allows background location APIs)

## 3) Ring Flow

1. On Device A, tap "Ring Phone".
2. On Device B, verify:
   - Alarm/vibration starts
   - Notification shown on `ring_channel`
3. On Device A, tap "Stop".
4. On Device B, verify ringtone and vibration stop.

## 4) Logs to Watch

- App logs containing:
  - `FCM Foreground message received`
  - `Location auto-shared successfully`
  - `Background: Ring phone request received`
- Cloud Function logs for `location_requests` and `ring_requests` triggers.

## 5) Expected Pass Criteria

- No permission errors for legitimate couple members
- Non-couple users cannot access protected Storage paths
- Location and ring actions work in foreground and background states
