//
//  CleanerCantant.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#ifndef CleanerCantant_h
#define CleanerCantant_h

#define KB_SIZE 1000
#define MB_SIZE 1000 * 1000

//qmgarbage.xml中相关的枚举 -- 为了防止后面假如大的改动，导致程序中的id和配置文件中的id无法一一对应
typedef NS_ENUM(NSUInteger, CategoryIdType) {
    CategoryIdTypeSystem = 1,
    CategoryIdTypeApplication,
    CategoryIdTypeSysBrowser,
};

typedef NS_ENUM(NSUInteger, SysSubcategoryIdType) {
    SubcategoryIdTypeSysCache = 1001,
    SubcategoryIdTypeLog,
    SubcategoryIdTypeLanguage,
    SubcategoryIdTypeIosPicCache,
    SubcategoryIdTypeIosUpdateCache,
    SubcategoryIdTypeRubbish,
};

//进程间通知
#define MAIN_CLENER_CLEAN_SUCCESS @"com.tencent.lemon.main_cleaner_clean_success"

//进程内通知
#define SHOW_OR_CLOSE_TOOL_VIEW @"show_or_close_view"
#define OPEN_TOOL_VIEW @"open_tool_view"
#define CLOSE_TOOL_VIEW @"close_tool_view"
#define SHOW_OR_CLOSE_BIG_CLEAN_VIEW @"show_or_close_big_clean_view"
#define OPEN_BIG_CLEAN_VIEW @"open_big_clean_view"
#define CLOSE_BIG_CLEAN_VIEW @"close_big_clean_view"
#define OPEN_BIG_RESULT_VIEW @"open_big_result_view"
#define CLOSE_BIG_RESULT_VIEW @"close_big_result_view"
#define BIG_RESULT_VIEW_TOTAl_SIZE @"big_result_view_total_size"
#define BIG_RESULT_VIEW_FILE_SIZE @"big_result_view_file_size"
#define BIG_RESULT_VIEW_FILE_NUMS @"big_result_view_file_nums"
#define BIG_RESULT_VIEW_TIME @"big_result_view_time"
#define BIG_CLEAN_VIEW_TYPE @"big_clean_view_type"
#define CLEAN_VIEW_TYPE_SCANNING @"clean_view_type_scanning"
#define CLEAN_VIEW_TYPE_CLEANNING @"clean_view_type_cleanning"
#define CLEAN_VIEW_TYPE_RESULT @"clean_view_type_result"
#define CLEAN_VIEW_TYPE_NORESULT @"clean_view_type_noresult"
#define BIG_CLEAN_VIEW_FILE_SIZE @"big_clean_view_file_size"
#define BIG_CLEAN_VIEW_FILE_NUMS @"big_clean_view_file_nums"
#define BIG_CLEAN_VIEW_TIME @"big_clean_view_time"
#define START_TO_SCAN @"start_to_scan"
#define START_TO_SHOW_FULL_DISK_PRIVACY_SETTING @"start_to_full_disk_privacy_setting"

#define SHOW_EXPERIENCE_TOOL @"show_experience_tool"
#define EXPERIENCE_TOOL_CLASS_NAME  @"experience_tool_class_name"

#define REFRESH_SELECT_SIZE @"refresh_select_size"
#define START_SMALL_CLEAN @"start_small_clean"
#define START_JUMP_MAINPAGE @"start_jump_mainpage"
#define REPARSE_CLEAN_XML @"reparse_clean_xml"
#define NEED_DISPLAY_BIG_VIEW_CLEANING @"need_display_big_view_cleanning"
#define SHOW_GET_DIR_ACCESS @"show_get_dir_access"

#define SCAN_DID_END @"scan_did_end"

///更新展示小工具界面展开按钮的状态
#define UPDATE_SHOW_TOOL_VIEW_BTN_STATE @"update_show_tool_view_btn_state"
#define K_SHOW_TOOL_VIEW_BTN_STATE @"show_tool_view_btn_state"


#pragma mark ---- outlineview indentifier
#define CATEGORY_CELLVIEW_INDENTIFIER @"CategoryCellView"
#define SUB_CATEGORY_CELLVIEW_INDENTIFIER @"SubCategoryCellView"
#define ACTION_CELLVIEW_INDETIFIER @"ActionCellView"
#define RESULT_CELLVIEW_INDENTIFIER @"ResultCellView"


//share preference key
#define GUIDE_HAS_SHOWN @"guide_has_shown"

#define IS_SHOW_BIG_VIEW @"is_show_big_view" //打开主界面后，是否展示大界面

// alert 标识符
#define LMCLEAN_DOWNLOAD_SELECT_ALL_ALERT_SHOWED @"LMCLEAN_DOWNLOAD_SELECT_ALL_ALERT_SHOWED"

#endif /* CleanerCantant_h */
