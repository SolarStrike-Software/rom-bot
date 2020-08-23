



-- #############################################################################
-- ##                                                                         ##
-- ##  Language     : English (EU /USA)                                       ##
-- ##  Locale       : EN*                                                     ##
-- ##  Origin       : Original default language                               ##
-- ##  Author       : Shardea of Siochain (EN/EU)                             ##
-- ##                                                                         ##
-- #############################################################################

-- General

UMM_TITLE                           = "Ultimate Mail Mod";
UMM_PROMPT                          = "UltimateMailMod";
UMM_LOADED                          = " loaded.";

-- Slash settings

UMM_SLASH_HELP1                     = "Help for commands:";
UMM_SLASH_HELP2                     = "/umm sound : toggles audio warning on/off.";
UMM_SLASH_HELP3                     = "/umm reset : resets the list of own characters.";
UMM_SLASH_AUDIODISABLED             = "Audio warning when receiving new mails is now disabled.";
UMM_SLASH_AUDIOENABLED              = "Audio warning when receiving new mails is now enabled.";
UMM_SLASH_CHARSRESET                = "List of own characters has been reset.";

-- New mail notify

UMM_NOTIFY_NEWMAILARRIVED           = "New mail has arrived";
UMM_NOTIFY_TOOLTIP_TITLE            = TEXT("SYS_NEW_MAIL"); -- New mail
UMM_NOTIFY_TOOLTIP_NEWMAIL          = "You have new mail waiting.";
UMM_NOTIFY_TOOLTIP_NEWMAILS         = "You have %d new mails waiting.";
UMM_NOTIFY_TOOLTIP_MOVETIP          = "Shift+Right-mouse: move this icon.";

-- Menu tabs

UMM_MENU_TAB1                       = MAIL_INBOX; -- Inbox
UMM_MENU_TAB2                       = MAIL_SENTMAIL; -- Compose
UMM_MENU_TAB3                       = "Mass Send Items";

-- Tooltip specific

UMM_TOOLTIP_BOUND                   = TEXT("TOOLTIP_SOULBOUND_ALREADY"); -- Bound

-- Setting

UMM_SETTINGS_AUDIOWARNING           = "Play a sound when I receive new mails.";

-- Inbox

UMM_HELP_INBOX_LINE1                = "You can multi-select mails for :";
UMM_HELP_INBOX_LINE2                = "1) Take items / money /diamonds.";
UMM_HELP_INBOX_LINE3                = "2) Mass return mails.";
UMM_HELP_INBOX_LINE4                = "3) Mass delete mails.";
UMM_HELP_INBOX_LINE5                = "Ctrl + Left-click to tag / untag a mail.";
UMM_HELP_INBOX_RETURNTAGGED         = "Returns all tagged mails.";
UMM_HELP_INBOX_DELETETAGGED         = "Deletes all tagged mails.";

UMM_INBOX_LOADING                   = "Loading inbox - please wait ...";
UMM_INBOX_EMPTY                     = "Your inbox is empty.";

UMM_INBOX_BUTTON_TAGCHARS           = "Chars";
UMM_INBOX_BUTTON_TAGFRIENDS         = "Friends";
UMM_INBOX_BUTTON_TAGGUILDIES        = GUILD; -- Guild
UMM_INBOX_BUTTON_TAGOTHER           = TEXT("ITEM_OTHER"); -- Other
UMM_INBOX_BUTTON_TAGEMPTY           = "Empty";
UMM_INBOX_BUTTON_TAKE               = "Take";
UMM_INBOX_BUTTON_RETURN             = "Return";
UMM_INBOX_BUTTON_DELETE             = C_DEL; -- Delete

UMM_INBOX_OPTION_1                  = "Everything.";
UMM_INBOX_OPTION_2                  = TEXT("CRAFT_TYPELIST_36"); -- Items
UMM_INBOX_OPTION_3                  = TEXT("AC_ITEMTYPENAME_12"); -- Money
UMM_INBOX_OPTION_4                  = TEXT("AC_ITEMTYPENAME_12_1"); -- Diamonds

UMM_INBOX_CHECK_DELETEDONE          = "Delete mails when done taking.";

UMM_INBOX_LABEL_MASSTAG             = "Select mails from:";
UMM_INBOX_LABEL_TOTALMONEY          = "Total money in inbox:";
UMM_INBOX_LABEL_TOTALDIAMONDS       = "Total diamonds in inbox:";
UMM_INBOX_LABEL_MAILCOUNT			= "Mail Count";

UMM_INBOX_STATUS_TAKEALLTAGGED      = "Automatically opening mails - please wait ...";
UMM_INBOX_STATUS_PREPARETAKEDELETE  = "Preparing to delete opened mails - please wait ...";
UMM_INBOX_STATUS_RETURNTAGGED       = "Automatically returning mails - please wait ...";
UMM_INBOX_STATUS_DELETETAGGED       = "Automatically deleting mails - please wait ...";

-- Viewer

UMM_VIEWER_LABEL_FROM               = MAIL_SENDER_COLON; -- Sender:
UMM_VIEWER_LABEL_SUBJECT            = MAIL_SUBJECT_COLON; -- Subject:

UMM_VIEWER_BUTTON_REPLY             = MAIL_REPLY; -- Reply
UMM_VIEWER_BUTTON_RETURN            = "Return";
UMM_VIEWER_BUTTON_DELETE            = C_DEL; -- Delete
UMM_VIEWER_BUTTON_CLOSE             = SYS_CLOSE_MAIL; -- Close

UMM_VIEWER_ATTACHED                 = MAIL_SENTITEM_COLON; -- Attachment:
UMM_VIEWER_ATTACHMENTCOD            = "C.O.D. price:";
UMM_VIEWER_ATTACHMENTACCEPT         = "I accept C.O.D.";
UMM_VIEWER_ATTACHMENT_NOT_ACCEPTED  = "Please check accept the C.O.D. and try again.";

-- Composer

UMM_COMPOSER_ADDRESSEE              = MAIL_ADDRESSEE_COLON; -- To:
UMM_COMPOSER_SUBJECT                = MAIL_SUBJECT_COLON; -- Subject:
UMM_COMPOSER_BUTTON_RESET           = OBJ_RESET; -- Reset
UMM_COMPOSER_BUTTON_SEND            = MAIL_MAILSENT; -- Send
UMM_COMPOSER_ATTACHMENT             = MAIL_SENTITEM_COLON; -- Attachment:
UMM_COMPOSER_AUTOSUBJECT            = TEXT("AC_ITEMTYPENAME_12")..": "; -- Money:
UMM_COMPOSER_SENDGOLD               = MAIL_SENTMONEY; -- Send Cash
UMM_COMPOSER_SENDCOD                = MAIL_COD; -- C.O.D.

UMM_COMPOSER_CONFIRM_TEXT1          = "Are you sure you want to send the amount";
UMM_COMPOSER_CONFIRM_TEXT2          = "shown bellow to %s ?";
UMM_COMPOSER_CONFIRM_YES            = YES; -- Yes
UMM_COMPOSER_CONFIRM_NO             = NO; -- No

UMM_RECIPIENT_OWN                   = "Characters";
UMM_RECIPIENT_FRIEND                = "Friends";
UMM_RECIPIENT_GUILD                 = GUILD; -- Guild

-- Mass Send Items

UMM_MSI_MARKBUTTON1                 = "Runes";
UMM_MSI_MARKBUTTON2                 = "F. Stones";
UMM_MSI_MARKBUTTON3                 = "Jewels";
UMM_MSI_MARKBUTTON4                 = "Ores";
UMM_MSI_MARKBUTTON5                 = "Wood";
UMM_MSI_MARKBUTTON6                 = "Herbs";
UMM_MSI_MARKBUTTON7                 = "R. Mats.";
UMM_MSI_MARKBUTTON8                 = "P. Runes";
UMM_MSI_MARKBUTTON9                 = "Foods";
UMM_MSI_MARKBUTTON10                = "Desserts";
UMM_MSI_MARKBUTTON11                = "Potions";

UMM_MSI_MARK_LABEL                  = "Mark:";
UMM_MSI_MARK_TOOLTIP1               = TEXT("AC_ITEMTYPENAME_5_1"); -- Runes
UMM_MSI_MARK_TOOLTIP2               = TEXT("AC_ITEMTYPENAME_5_2"); -- Fusion Stones
UMM_MSI_MARK_TOOLTIP3               = TEXT("AC_ITEMTYPENAME_5_0"); -- Refining Gems
UMM_MSI_MARK_TOOLTIP4               = TEXT("AC_ITEMTYPENAME_3_0"); -- Ores
UMM_MSI_MARK_TOOLTIP5               = TEXT("AC_ITEMTYPENAME_3_1"); -- Wood
UMM_MSI_MARK_TOOLTIP6               = TEXT("AC_ITEMTYPENAME_3_2"); -- Herbs
UMM_MSI_MARK_TOOLTIP7               = TEXT("AC_ITEMTYPENAME_3_3"); -- Raw Materials
UMM_MSI_MARK_TOOLTIP8               = TEXT("AC_ITEMTYPENAME_3_4"); -- Production Runes
UMM_MSI_MARK_TOOLTIP9               = TEXT("AC_ITEMTYPENAME_2_0"); -- Foods
UMM_MSI_MARK_TOOLTIP10              = TEXT("AC_ITEMTYPENAME_2_1"); -- Desserts
UMM_MSI_MARK_TOOLTIP11              = TEXT("AC_ITEMTYPENAME_2_2"); -- Potions
UMM_MSI_MARK_TOOLTIPCLICK           = "Click to mark all slots of items in this category.";

UMM_MSI_BUTTON_ADDRESSEE            = MAIL_ADDRESSEE_COLON; -- To:
UMM_MSI_BUTTON_RESET                = OBJ_RESET; -- Reset

UMM_MSI_MAILSTOSEND                 = "Mails to send: %d";
UMM_MSI_ADDRESSEE                   = MAIL_ADDRESSEE_COLON; -- To:
UMM_MSI_SUBJECT                     = MAIL_SUBJECT_COLON; -- Subject:
UMM_MSI_COD                         = MAIL_COD; -- C.O.D.
UMM_MSI_STATUS                      = "Status:";
UMM_MSI_STATUS_SENDING              = "Sending...";
UMM_MSI_STATUS_QUEUED               = "Queued.";
UMM_MSI_BUTTON_SEND                 = MAIL_MAILSENT; -- Send
UMM_MSI_BUTTON_COD                  = MAIL_COD; -- C.O.D.
UMM_MSI_BUTTON_CANCEL               = C_CANCEL; -- Cancel
UMM_MSI_SEND_STATUS                 = "Sending %d of %d - please wait ...";
UMM_MSI_SEND_MAILBODY               = "Hi %s\n\nI used Ultimate Mail Mod to send this item to you.\n\nPlease enjoy.\n\nKind regards\n%s\n\n%s";

-- Error messages

UMM_ERROR_CANTSENDSELF              = TEXT("SYS_SENDMAIL_OWNER_ERROR"); -- You can not send mails to yourself!
UMM_ERROR_NOSUBJECT                 = "Please enter a subject for this mail.";
UMM_ERROR_CANTSENDBOUND             = TEXT("SYS_SENDMAIL_SOULBOUND"); -- You can not send soulbound or locked items!";

UMM_ERROR_AUTOMATIONFAILED          = "Automation process failed - process halted.";
UMM_ERROR_NOTHINGTAGGED             = "Please tag one or more mails !";
UMM_ERROR_CANTDELETE                = "Unable to delete mails with attachments !";
UMM_ERROR_CANTRETURN                = "Unable to return mail !";
UMM_ERROR_CANTTAKECOD               = "C.O.D. mails can not be auto-taken !";
UMM_ERROR_CANTTAKE                  = "Tagged mail does not meet required take conditions !";
