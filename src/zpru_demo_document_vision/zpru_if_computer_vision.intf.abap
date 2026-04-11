INTERFACE zpru_if_computer_vision
  PUBLIC .
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

  " context modelling
  TYPES:
    BEGIN OF ts_cmr_create_content,
      message    TYPE string,
      cmrheaders TYPE STANDARD TABLE OF zpru_cmr_header WITH EMPTY KEY,
      cmritems   TYPE STANDARD TABLE OF zpru_cmr_item WITH EMPTY KEY,
    END OF ts_cmr_create_content.
  TYPES: tt_cmr_create_content TYPE STANDARD TABLE OF ts_cmr_create_content WITH EMPTY KEY.

  TYPES:
    BEGIN OF ts_cmr_create_request,
      cmrcreationcontent TYPE string,
    END OF ts_cmr_create_request.
  TYPES: tt_cmr_create_request TYPE STANDARD TABLE OF ts_cmr_create_request WITH EMPTY KEY.

  TYPES:
    BEGIN OF ts_cmr_validate_req,
      cmrheaders         TYPE string,
      cmritems           TYPE string,
      cmrcreationrequest TYPE string,
    END OF ts_cmr_validate_req.

  TYPES:
    tt_cmr_validate_req TYPE STANDARD TABLE OF ts_cmr_validate_req WITH EMPTY KEY.

  TYPES:
    BEGIN OF ts_cmr_classify_req,
      cmrheaders         TYPE string,
      cmritems           TYPE string,
      cmrcreationrequest TYPE string,
    END OF ts_cmr_classify_req,

    tt_cmr_classify_req TYPE STANDARD TABLE OF ts_cmr_classify_req WITH EMPTY KEY.

  TYPES:
    BEGIN OF ts_cmr_overall_status,
      cmruuid       TYPE sysuuid_x16,
      cmrid         TYPE char10,
      overallstatus TYPE string,
    END OF ts_cmr_overall_status,

    tt_cmr_overall_status TYPE STANDARD TABLE OF ts_cmr_overall_status WITH EMPTY KEY.

ENDINTERFACE.
