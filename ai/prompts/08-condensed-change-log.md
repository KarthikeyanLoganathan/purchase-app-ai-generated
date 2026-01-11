Change Log Behaviour.

In Flutter App, in general change_log should behave as follows.

DML on Application DB Table (e.g. manufacturer_materials) | change_log.uuid | change_log.table_index | change_log.table_key_uuid | change_log.change_mode | change_log.updated_at
--|--|--|--|--|--
Insert with key mm-uuid1 | cl-uuid1 | 4 | mm-uuid1 | I | current time
Update on key mm-uuid1 | cl-uuid2 | 4 | mm-uuid1 | U | current time
Update on key mm-uuid1 | cl-uuid3 | 4 | mm-uuid1 | U | current time
Delete on key mm-uuid1 | cl-uuid4 | 4 | mm-uuid1 | D | current time


add additional SQLite table condensed_change_log

Just before Delta Sync, there has to be a condense change log operation like [backend function prepareCondensedChangeLogFromChangeLog()](../backend/google-app-script-code/changeLogUtils.js#075)

Implement this logic in Flutter App in delta sync.

This can avoid sending duplicate records to backend.

Remember that the delta sync logic sends data in small batches to avoid server timeout in backend.