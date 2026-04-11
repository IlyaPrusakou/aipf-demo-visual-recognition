INTERFACE zpru_if_computer_vision
  PUBLIC.
  INTERFACES if_serializable_object.
  INTERFACES zpru_if_decision_provider.
  INTERFACES zpru_if_short_memory_provider.
  INTERFACES zpru_if_long_memory_provider.
  INTERFACES zpru_if_agent_info_provider.
  INTERFACES zpru_if_prompt_provider.
  INTERFACES zpru_if_tool_provider.
  INTERFACES zpru_if_tool_schema_provider.
  INTERFACES zpru_if_tool_info_provider.
  INTERFACES zpru_if_agent_singleton_meth.

  CONSTANTS: BEGIN OF cs_context_field,
               BEGIN OF cmralerts,
                 field_name    TYPE string VALUE `CMRALERTS`,
                 absolute_name TYPE string VALUE `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TT_CMR_ALERT_CONTEXT`,
               END OF cmralerts,
               BEGIN OF cmrheaders,
                 field_name    TYPE string VALUE `CMRHEADERS`,
                 absolute_name TYPE string VALUE `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TT_CMR_HEADER_CONTEXT`,
               END OF cmrheaders,
               BEGIN OF cmritems,
                 field_name    TYPE string VALUE `CMRITEMS`,
                 absolute_name TYPE string VALUE `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TT_CMR_ITEM_CONTEXT`,
               END OF cmritems,
               BEGIN OF cmrcreationcontent,
                 field_name    TYPE string VALUE `CMRCREATIONCONTENT`,
                 absolute_name TYPE string VALUE `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TT_CMR_CREATE_CONTENT`,
               END OF cmrcreationcontent,
               BEGIN OF cmrstatus,
                 field_name    TYPE string VALUE `CMRSTATUS`,
                 absolute_name TYPE string VALUE `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TT_CMR_OVERALL_STATUS`,
               END OF cmrstatus,
               BEGIN OF cmrfinding,
                 field_name    TYPE string VALUE `CMRFINDING`,
                 absolute_name TYPE string VALUE `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TT_CMR_FINDING`,
               END OF cmrfinding,
             END OF cs_context_field.

  CONSTANTS: BEGIN OF cs_input_tool_structure,
               BEGIN OF create_cmr,
                 absolute_name TYPE string VALUE `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TS_CMR_CREATE_REQUEST`,
               END OF create_cmr,
               BEGIN OF classify_danger_goods,
                 absolute_name TYPE string VALUE `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TS_CMR_CLASSIFY_REQ`,
               END OF classify_danger_goods,
               BEGIN OF validate_cmr,
                 absolute_name TYPE string VALUE `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TS_CMR_VALIDATE_REQ`,
               END OF validate_cmr,
             END OF cs_input_tool_structure.

  CONSTANTS: BEGIN OF cs_input_context_fields,
               BEGIN OF create_cmr,
                 cmrcreationcontent TYPE string VALUE `CMRCREATIONCONTENT`,
               END OF create_cmr,
               BEGIN OF classify_danger_goods,
                 cmrheaders         TYPE string VALUE `CMRHEADERS`,
                 cmritems           TYPE string VALUE `CMRITEMS`,
                 cmrcreationcontent TYPE string VALUE `CMRCREATIONCONTENT`,
               END OF classify_danger_goods,
               BEGIN OF validate_cmr,
                 cmrheaders         TYPE string VALUE `CMRHEADERS`,
                 cmritems           TYPE string VALUE `CMRITEMS`,
                 cmrcreationcontent TYPE string VALUE `CMRCREATIONCONTENT`,
               END OF validate_cmr,
             END OF cs_input_context_fields.

  CONSTANTS: BEGIN OF cs_output_context_fields,
               BEGIN OF create_cmr,
                 cmrheaders         TYPE string VALUE `CMRHEADERS`,
                 cmritems           TYPE string VALUE `CMRITEMS`,
                 cmrcreationcontent TYPE string VALUE `CMRCREATIONCONTENT`,
               END OF create_cmr,
               BEGIN OF classify_danger_goods,
                 cmralerts TYPE string VALUE `CMRALERTS`,
               END OF classify_danger_goods,
               BEGIN OF validate_cmr,
                 cmrstatus  TYPE string VALUE `CMRSTATUS`,
                 cmrfinding TYPE string VALUE `CMRFINDING`,
               END OF validate_cmr,
             END OF cs_output_context_fields.

  " CONTEXT
  " TOOL INPUT TYPE
  " 1 INPUT FOR TOOL 'CREATE_CMR'
  TYPES:
    BEGIN OF ts_cmr_create_request,
      cmrcreationcontent TYPE string,
    END OF ts_cmr_create_request,
    tt_cmr_create_request TYPE STANDARD TABLE OF ts_cmr_create_request WITH EMPTY KEY.

  " 2 INPUT FOR TOOL 'CLASSIFY_DANGER_GOODS'
  TYPES:
    BEGIN OF ts_cmr_classify_req,
      cmrheaders         TYPE string,
      cmritems           TYPE string,
      cmrcreationcontent TYPE string,
    END OF ts_cmr_classify_req,
    tt_cmr_classify_req TYPE STANDARD TABLE OF ts_cmr_classify_req WITH EMPTY KEY.

  " 3 INPUT FOR TOOL 'VALIDATE_CMR'
  TYPES:
    BEGIN OF ts_cmr_validate_req,
      cmrheaders         TYPE string,
      cmritems           TYPE string,
      cmrcreationcontent TYPE string,
    END OF ts_cmr_validate_req,
    tt_cmr_validate_req TYPE STANDARD TABLE OF ts_cmr_validate_req WITH EMPTY KEY.

  " CONTEXT FIELDS
  " CONTEXT FIELD 'CMRALERTS'
  TYPES ts_cmr_alert_context  TYPE zpru_cmr_alert.
  TYPES tt_cmr_alert_context  TYPE STANDARD TABLE OF ts_cmr_alert_context WITH EMPTY KEY.

  " CONTEXT FIELD 'CMRHEADERS'
  TYPES ts_cmr_header_context TYPE zpru_cmr_header.
  TYPES tt_cmr_header_context TYPE STANDARD TABLE OF ts_cmr_header_context WITH EMPTY KEY.

  " CONTEXT FIELD 'CMRITEMS'
  TYPES ts_cmr_item_context   TYPE zpru_cmr_item.
  TYPES tt_cmr_item_context   TYPE STANDARD TABLE OF ts_cmr_item_context WITH EMPTY KEY.

  " CONTEXT FIELD 'CMRCREATIONCONTENT'
  TYPES:
    BEGIN OF ts_cmr_create_content,
      message    TYPE string,
      cmrheaders TYPE tt_cmr_header_context,
      cmritems   TYPE tt_cmr_item_context,
    END OF ts_cmr_create_content.
  TYPES tt_cmr_create_content TYPE STANDARD TABLE OF ts_cmr_create_content WITH EMPTY KEY.

  " CONTEXT FIELD 'CMRSTATUS'
  TYPES:
    BEGIN OF ts_cmr_overall_status,
      cmruuid       TYPE sysuuid_x16,
      cmrid         TYPE char10,
      overallstatus TYPE string,
    END OF ts_cmr_overall_status,
    tt_cmr_overall_status TYPE STANDARD TABLE OF ts_cmr_overall_status WITH EMPTY KEY.

  " CONTEXT FIELD 'CMRFINDING'
  TYPES ts_cmr_finding TYPE zpru_cmr_valid.
  TYPES tt_cmr_finding TYPE STANDARD TABLE OF ts_cmr_finding WITH EMPTY KEY.

ENDINTERFACE.
