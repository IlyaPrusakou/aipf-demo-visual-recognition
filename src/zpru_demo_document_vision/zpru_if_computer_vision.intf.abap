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
      cmrcreationrequest TYPE string,
    END OF ts_cmr_classify_req,
    tt_cmr_classify_req TYPE STANDARD TABLE OF ts_cmr_classify_req WITH EMPTY KEY.

  " 3 INPUT FOR TOOL 'VALIDATE_CMR'
  TYPES:
    BEGIN OF ts_cmr_validate_req,
      cmrheaders         TYPE string,
      cmritems           TYPE string,
      cmrcreationrequest TYPE string,
    END OF ts_cmr_validate_req,
    tt_cmr_validate_req TYPE STANDARD TABLE OF ts_cmr_validate_req WITH EMPTY KEY.

  " CONTEXT FIELDS
  " CONTEXT FIELD 'CMRALERTS'
  TYPES: ts_cmr_alert_context TYPE zpru_cmr_alert.
  TYPES: tt_cmr_alert_context TYPE STANDARD TABLE OF ts_cmr_alert_context WITH EMPTY KEY.

  " CONTEXT FIELD 'CMRHEADERS'
  TYPES tS_cmr_header_context TYPE zpru_cmr_header.
  TYPES tt_cmr_header_context TYPE STANDARD TABLE OF tS_cmr_header_context WITH EMPTY KEY.

  " CONTEXT FIELD 'CMRITEMS'
  TYPES tS_cmr_item_context   TYPE zpru_cmr_item.
  TYPES tt_cmr_item_context   TYPE STANDARD TABLE OF tS_cmr_item_context WITH EMPTY KEY.

  TYPES:
    BEGIN OF ts_cmr_overall_status,
      cmruuid       TYPE sysuuid_x16,
      cmrid         TYPE char10,
      overallstatus TYPE string,
    END OF ts_cmr_overall_status,
    tt_cmr_overall_status TYPE STANDARD TABLE OF ts_cmr_overall_status WITH EMPTY KEY.

  TYPES:
    BEGIN OF ts_cmr_create_content,
      message    TYPE string,
      cmrheaders TYPE STANDARD TABLE OF zpru_cmr_header WITH EMPTY KEY,
      cmritems   TYPE STANDARD TABLE OF zpru_cmr_item WITH EMPTY KEY,
    END OF ts_cmr_create_content.
  TYPES tt_cmr_create_content TYPE STANDARD TABLE OF ts_cmr_create_content WITH EMPTY KEY.

ENDINTERFACE.
