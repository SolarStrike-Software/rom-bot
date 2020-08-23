
-- #############################################################################
-- ##                                                                         ##
-- ##  Language     : Japanese (Japan)                                        ##
-- ##  Locale       : JP                                                      ##
-- ##  Last updated : 7 Dec 2009                                              ##
-- ##  Origin       : Translated                                              ##
-- ##  Author       : TBDjp at Curse                                          ##
-- ##                                                                         ##
-- ##  Thanks very much for the help.                                         ##
-- ##                                                                         ##
-- #############################################################################

-- General

UMM_TITLE                           = "究極め～るR (Ultimate Mail Mod日本語版)";
UMM_PROMPT                          = "究極め～るR";
UMM_LOADED                          = "ロード完了";

-- Slash settings

UMM_SLASH_HELP1                     = "コマンド一覧:";
UMM_SLASH_HELP2                     = "/umm sound : 着信通知音のオン・オフ";
UMM_SLASH_HELP3                     = "/umm reset : 自キャラのリストをクリア";
UMM_SLASH_AUDIODISABLED             = "新着メールの着信通知音はオフになりました";
UMM_SLASH_AUDIOENABLED              = "新着メールの着信通知音をオンにします";
UMM_SLASH_CHARSRESET                = "自キャラリストをリセットしました";

-- New mail notify

UMM_NOTIFY_NEWMAILARRIVED           = "新しいメールを受信しました";
UMM_NOTIFY_TOOLTIP_TITLE            = "新着メール";
UMM_NOTIFY_TOOLTIP_NEWMAIL          = "新着メールがあります";
UMM_NOTIFY_TOOLTIP_NEWMAILS         = "新着メールが %d 通あります";
UMM_NOTIFY_TOOLTIP_MOVETIP          = "シフト＋右クリック＝アイコン移動";

-- Menu tabs

UMM_MENU_TAB1                       = "受信";
UMM_MENU_TAB2                       = "メール送信";
UMM_MENU_TAB3                       = "一括送付";

-- Tooltip specific

UMM_TOOLTIP_BOUND                   = "バインド済み";

-- Setting

UMM_SETTINGS_AUDIOWARNING           = "メール新着時にサウンドを鳴らす";

-- Inbox

UMM_HELP_INBOX_LINE1                = "CTRL+左クリックでメールを選択/選択解除出来ます。";
UMM_HELP_INBOX_LINE2                = "選択したメールに対して、以下の処理を一括で行います";
UMM_HELP_INBOX_LINE3                = "1)一括受け取り(アイテム/ゴールド/BC)";
UMM_HELP_INBOX_LINE4                = "2)一括受領拒否";
UMM_HELP_INBOX_LINE5                = "3)一括消去";
UMM_HELP_INBOX_RETURNTAGGED         = "選択したメールを一括で受領拒否します";
UMM_HELP_INBOX_DELETETAGGED         = "選択したメールを一括で消去します";

UMM_INBOX_LOADING                   = "受信窓更新中-しばらくお待ち下さい";
UMM_INBOX_EMPTY                     = "受信メールはありません";

UMM_INBOX_BUTTON_TAGCHARS           = "自キャラ";
UMM_INBOX_BUTTON_TAGFRIENDS         = "友人";
UMM_INBOX_BUTTON_TAGGUILDIES        = "ギルメン";
UMM_INBOX_BUTTON_TAGOTHER           = "そのほか";
UMM_INBOX_BUTTON_TAGEMPTY           = "空";
UMM_INBOX_BUTTON_TAKE               = "一括受領";
UMM_INBOX_BUTTON_RETURN             = "一括拒否";
UMM_INBOX_BUTTON_DELETE             = "一括消去";

UMM_INBOX_OPTION_1                  = "すべて";
UMM_INBOX_OPTION_2                  = "装備のみ";
UMM_INBOX_OPTION_3                  = "ゴールドのみ";
UMM_INBOX_OPTION_4                  = "BCのみ";

UMM_INBOX_CHECK_DELETEDONE          = "添付物を受領後メールを自動消去";

UMM_INBOX_LABEL_MASSTAG             = "タグ総数:";
UMM_INBOX_LABEL_TOTALMONEY          = "受信ゴールド総計:";
UMM_INBOX_LABEL_TOTALDIAMONDS       = "受信BC総計:";
UMM_INBOX_LABEL_MAILCOUNT			= "Mail Count"; -- TRANSLATE

UMM_INBOX_STATUS_TAKEALLTAGGED      = "メール開封処理中 - しばらくお待ち下さい";
UMM_INBOX_STATUS_PREPARETAKEDELETE  = "開封済みメール消去処理中 - しばらくお待ち下さい";
UMM_INBOX_STATUS_RETURNTAGGED       = "一括拒否処理中 - しばらくお待ち下さい";
UMM_INBOX_STATUS_DELETETAGGED       = "一括削除中 - しばらくお待ち下さい";

-- Viewer

UMM_VIEWER_LABEL_FROM               = "送信者:";
UMM_VIEWER_LABEL_SUBJECT            = "件　名:";

UMM_VIEWER_BUTTON_REPLY             = "返信";
UMM_VIEWER_BUTTON_RETURN            = "拒否";
UMM_VIEWER_BUTTON_DELETE            = "削除";
UMM_VIEWER_BUTTON_CLOSE             = "閉じる";

UMM_VIEWER_ATTACHED                 = "添付:";
UMM_VIEWER_ATTACHMENTCOD            = "着払い金額:";
UMM_VIEWER_ATTACHMENTACCEPT         = "購入";
UMM_VIEWER_ATTACHMENT_NOT_ACCEPTED  = "購入しなければ受け取れません";

-- Composer

UMM_COMPOSER_ADDRESSEE              = "受信者：";
UMM_COMPOSER_SUBJECT                = "件名：";
UMM_COMPOSER_BUTTON_RESET           = "リセット";
UMM_COMPOSER_BUTTON_SEND            = "送る";
UMM_COMPOSER_ATTACHMENT             = "メール送信：";
UMM_COMPOSER_AUTOSUBJECT            = "ゴールド: ";
UMM_COMPOSER_SENDGOLD               = "ゴールド送付";
UMM_COMPOSER_SENDCOD                = "着払い";

UMM_RECIPIENT_OWN                   = "自キャラ";
UMM_RECIPIENT_FRIEND                = "フレンド";
UMM_RECIPIENT_GUILD                 = "ギルメン";

-- Mass Send Items

UMM_MSI_MARKBUTTON1                 = "ルーン";
UMM_MSI_MARKBUTTON2                 = "溶解石";
UMM_MSI_MARKBUTTON3                 = "宝石";
UMM_MSI_MARKBUTTON4                 = "鉱石";
UMM_MSI_MARKBUTTON5                 = "木材";
UMM_MSI_MARKBUTTON6                 = "ハーブ";
UMM_MSI_MARKBUTTON7                 = "原材料";
UMM_MSI_MARKBUTTON8                 = "生産ルーン";
UMM_MSI_MARKBUTTON9                 = "食べ物";
UMM_MSI_MARKBUTTON10                = "甘い食物";
UMM_MSI_MARKBUTTON11                = "ポーション";

UMM_MSI_MARK_LABEL                  = "選択:";
UMM_MSI_MARK_TOOLTIP1               = "ルーン";
UMM_MSI_MARK_TOOLTIP2               = "溶解石";
UMM_MSI_MARK_TOOLTIP3               = "宝石";
UMM_MSI_MARK_TOOLTIP4               = "鉱石";
UMM_MSI_MARK_TOOLTIP5               = "木材";
UMM_MSI_MARK_TOOLTIP6               = "ハーブ";
UMM_MSI_MARK_TOOLTIP7               = "原材料";
UMM_MSI_MARK_TOOLTIP8               = "生産ルーン";
UMM_MSI_MARK_TOOLTIP9               = "食べ物";
UMM_MSI_MARK_TOOLTIP10              = "甘い食物";
UMM_MSI_MARK_TOOLTIP11              = "ポーション";
UMM_MSI_MARK_TOOLTIPCLICK           = "クリックすると、この種別のアイテムが一括選択されます";

UMM_MSI_BUTTON_ADDRESSEE            = "受信者：";
UMM_MSI_BUTTON_RESET                = "リセット";

UMM_MSI_MAILSTOSEND                 = "送付メール数: %d";
UMM_MSI_ADDRESSEE                   = "受信者：";
UMM_MSI_SUBJECT                     = "件名：";
UMM_MSI_COD                         = "着払い";
UMM_MSI_STATUS                      = "状態:";
UMM_MSI_STATUS_SENDING              = "送付処理中";
UMM_MSI_STATUS_QUEUED               = "送付準備中";
UMM_MSI_BUTTON_SEND                 = "送る";
UMM_MSI_BUTTON_COD                  = "着払い";
UMM_MSI_BUTTON_CANCEL               = "キャンセル";
UMM_MSI_SEND_STATUS                 = "%d通目のメールを送付中(全%d通) - しばらくお待ち下さい";
UMM_MSI_SEND_MAILBODY               = "前略%sさま\n\n究極め～るR (UltimateMailMod日本語版)による自動送信メールで失礼いたします。\n\n首記の品を送付いたします。ご査収の程よろしくお願い申し上げます。\n\n草々\n\n%s拝\n\n%s";

-- Error messages

UMM_ERROR_CANTSENDSELF              = "自分自身にメールすることは出来ません";
UMM_ERROR_NOSUBJECT                 = "件名が未記入です";
UMM_ERROR_CANTSENDBOUND             = "バインド品を添付することは出来ません";

UMM_ERROR_AUTOMATIONFAILED          = "自動処理中にエラーが発生し処理を中止しました";
UMM_ERROR_NOTHINGTAGGED             = "1通も選択されていません";
UMM_ERROR_CANTDELETE                = "添付物があるので消去できません";
UMM_ERROR_CANTRETURN                = "拒否できません";
UMM_ERROR_CANTTAKECOD               = "着払いメールなので自動取得できません";
UMM_ERROR_CANTTAKE                  = "選択された中には処理対象となるメールが存在しませんでした";
