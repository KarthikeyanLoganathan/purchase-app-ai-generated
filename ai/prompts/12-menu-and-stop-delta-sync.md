settings screen should also give ... (over flow menu) menu like all other screens with items
- "Sync with Google Sheets" - conditional only when Developer Mode is on
- "View Sync Log" - conditional only when Developer Mode is on
- "Prepare Condensed Log" - conditional only when Developer Mode is on
- Data Browser

At the same time, "Prepare Condensed Log" to be renamed as "Prepared Condensed Change Log" across all screens.

Note, in Home screen, "Sync with Google Sheets" gives busy cursor when sync is already running to avoid running sync second time.  This behaviour is expected in all screns.  

Anytime, when sync is attempted from anywhere, it should check whether sync is already running, avoid re-run.

In all screens, we need additional feature
- "Stop Sync with Google Sheets" - conditional only when Developer Mode is on - conditionally enabled when sync is running.  Accordingly enable this feature in delta sync logic to stop running sync.