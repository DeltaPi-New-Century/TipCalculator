/// English fallbacks for every translatable string in the app.
///
/// Single source of truth: [DatabaseData] seeds its offline language data from
/// here, and [TipData.t] falls back to it whenever the remote database has no
/// entry for a key (older database versions, unsupported locale, no network).
///
/// Adding a UI string means adding it here AND to the remote database gist --
/// see resources/tipcalculator_languages.json.
const Map<String, String> kDefaultTranslations = {
  // Existing keys, present in database version 1.0.2c.
  "app_title": "Tip Calculator",
  "amount_title": "Amount",
  "amount_input_text": "Enter value",
  "people_title": "People",
  "people_input_text": "Enter value",
  "tip_title": "Tip",
  "tip_total": "Total",
  "tip_total_per_person": "Per Person",
  "tip_button_text": "Recommended for \$countryName",
  "total_title": "Total",
  "total_amount": "Amount",
  "total_per_person": "Per Person",

  // Shared actions.
  "cancel": "Cancel",
  "save": "Save",
  "add": "Add",
  "undo": "Undo",

  // History.
  "history_title": "History",
  "history_save": "Save",
  "history_saved": "Saved to history",
  "history_nothing_to_save": "Enter an amount first",
  "history_empty": "No saved calculations yet.",
  "history_deleted": "Deleted",
  "history_clear": "Clear",
  "history_clear_title": "Clear history",
  "history_clear_body":
      "This deletes every saved calculation. It cannot be undone.",

  // Split by items.
  "split_title": "Itemized split",
  "split_evenly": "Evenly",
  "split_by_items": "Itemized",
  "split_manage": "Manage people",
  "split_empty": "Add the people sharing this bill.",
  "person": "Person",
  "person_add": "Add person",
  "person_remove": "Remove",
  "person_rename": "Rename",
  "item_add": "Add item",
  "item_label": "Item",
  "item_price": "Price",
  "tip_share": "Tip share",

  // Appearance.
  "theme_title": "Appearance",
  "theme_system": "System",
  "theme_light": "Light",
  "theme_dark": "Dark",

  // History date grouping.
  "history_today": "Today",
  "history_yesterday": "Yesterday",

  // Sharing.
  "share": "Share",
  "share_as_text": "Share as text",
  "share_as_text_hint": "Plain text, works everywhere",
  "share_as_image": "Share as image",
  "share_as_image_hint": "A receipt card for chats and stories",
  "share_failed": "Could not share the summary",
  "share_bill": "Bill",

  // Shared live session.
  "session_title": "Shared session",
  "session_subtitle": "Everyone adds their own items",
  "session_create": "Create session",
  "session_join": "Join session",
  "session_code": "Code",
  "session_code_hint": "Read this out to the table",
  "session_enter_code": "Enter the code",
  "session_your_name": "Your name",
  "session_members": "At the table",
  "session_host": "Host",
  "session_you": "You",
  "session_leave": "Leave",
  "session_close": "Close session",
  "session_close_body":
      "This ends the session for everyone. Each person keeps their own copy.",
  "session_closed": "Session closed",
  "session_save_copy": "Save to history",
  "session_finish": "Done",
  "session_waiting": "Waiting for others to join",
  "session_tip_locked": "The host sets the tip",
  "session_error_not_found": "No session with that code",
  "session_error_expired": "That session has expired",
  "session_error_closed": "That session is already closed",
  "session_error_invalid_code": "Check the code and try again",
  "session_error_not_owner": "Only the host can close the session",
  "session_error_limit": "Too many sessions right now, try again shortly",
  "session_error_denied": "The session refused this device",
  "session_error_network": "No connection to the session",
  "session_error_signin": "Shared sessions are unavailable right now",
};
