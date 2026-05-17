CLASS lcl_adf_decision_provider DEFINITION INHERITING FROM zpru_cl_decision_provider CREATE PUBLIC.
  PROTECTED SECTION.
    " Gemini request types
    TYPES: BEGIN OF ts_inline_data,
             mime_type TYPE string,
             data      TYPE string,
           END OF ts_inline_data.
    TYPES: BEGIN OF ts_part,
             text        TYPE string,
             inline_data TYPE ts_inline_data,
           END OF ts_part,
           tt_parts TYPE STANDARD TABLE OF ts_part WITH EMPTY KEY.
    TYPES: BEGIN OF ts_content,
             parts TYPE tt_parts,
           END OF ts_content,
           tt_contents TYPE STANDARD TABLE OF ts_content WITH EMPTY KEY.
    TYPES: BEGIN OF ts_gemini_request,
             contents TYPE tt_contents,
           END OF ts_gemini_request.
    " Gemini response types
    TYPES: BEGIN OF ts_res_part,
             text TYPE string,
           END OF ts_res_part,
           tt_res_parts TYPE STANDARD TABLE OF ts_res_part WITH EMPTY KEY.
    TYPES: BEGIN OF ts_res_content,
             parts TYPE tt_res_parts,
             role  TYPE string,
           END OF ts_res_content.
    TYPES: BEGIN OF ts_candidate,
             content       TYPE ts_res_content,
             finish_reason TYPE string,
           END OF ts_candidate,
           tt_candidates TYPE STANDARD TABLE OF ts_candidate WITH EMPTY KEY.
    TYPES: BEGIN OF ts_gemini_response,
             candidates TYPE tt_candidates,
           END OF ts_gemini_response.
    " CMR response parsing types
    TYPES: BEGIN OF ts_parse_item,
             itemposition       TYPE n LENGTH 4,
             marksnumbers       TYPE char100,
             packagecount       TYPE int4,
             packingmethod      TYPE char100,
             natureofgoods      TYPE char100,
             statisticalnumber  TYPE char20,
             weightunitfield    TYPE msehi,
             volumeunitfield    TYPE msehi,
             grossweight        TYPE p LENGTH 7 DECIMALS 3,
             volume             TYPE p LENGTH 7 DECIMALS 3,
             unitednationnumber TYPE char10,
             hazardclass        TYPE char5,
             packinggroup       TYPE char10,
           END OF ts_parse_item,
           tt_parse_items TYPE STANDARD TABLE OF ts_parse_item WITH EMPTY KEY.
    TYPES: BEGIN OF ts_parse_header,
             cmrid             TYPE char10,
             senderinfo        TYPE char255,
             consigneeinfo     TYPE char255,
             deliveryplace     TYPE char100,
             takingoverplace   TYPE char100,
             takingoverdate    TYPE dats,
             carrierinfo       TYPE char255,
             successivecarrier TYPE char255,
             carrierreservice  TYPE char255,
             senderinstruction TYPE char255,
             cashondelivery    TYPE p LENGTH 8 DECIMALS 2,
             currency          TYPE waers_curc,
             establishedplace  TYPE char100,
             establisheddate   TYPE dats,
             createdby         TYPE char12,
             createdat         TYPE timestampl,
             lastchangedby     TYPE char12,
             lastchangedat     TYPE timestampl,
             cmritems          TYPE tt_parse_items,
           END OF ts_parse_header,
           tt_parse_headers TYPE STANDARD TABLE OF ts_parse_header WITH EMPTY KEY.
    TYPES: BEGIN OF ts_parse_attachment,
             cmrheaders TYPE tt_parse_headers,
           END OF ts_parse_attachment,
           tt_parse_attachments TYPE STANDARD TABLE OF ts_parse_attachment WITH EMPTY KEY.
    TYPES: BEGIN OF ts_parse_response,
             messageid   TYPE char32,
             attachments TYPE tt_parse_attachments,
           END OF ts_parse_response,
           tt_parse_response_root TYPE STANDARD TABLE OF ts_parse_response WITH EMPTY KEY.

    METHODS create_gemini_http_client
      RETURNING VALUE(ro_http_client) TYPE REF TO if_web_http_client
      RAISING   zpru_cx_agent_core.

    METHODS set_http_headers
      IMPORTING io_http_request TYPE REF TO if_web_http_request.

    METHODS deserialize_input_to_payload
      IMPORTING is_input_prompt   TYPE zpru_s_prompt
      RETURNING VALUE(ro_payload) TYPE REF TO data
      RAISING   zpru_cx_agent_core.

    METHODS build_cmr_json_schema
      RETURNING VALUE(rv_schema) TYPE string.

    METHODS build_gemini_request_payload
      IMPORTING io_input_payload     TYPE REF TO data
                iv_json_schema       TYPE string
      RETURNING VALUE(ro_gemini_req) TYPE REF TO ts_gemini_request
      RAISING   zpru_cx_agent_core.

    METHODS add_system_instructions
      IMPORTING iv_json_schema TYPE string
      CHANGING  cs_part        TYPE ts_part.

    METHODS add_attachment_images
      IMPORTING io_input_payload TYPE REF TO data
      CHANGING  cs_content       TYPE ts_content.

    METHODS serialize_payload_to_json
      IMPORTING is_payload     TYPE ts_gemini_request
      RETURNING VALUE(rv_json) TYPE string.

    METHODS execute_llm
      IMPORTING io_http_client  TYPE REF TO if_web_http_client
                iv_json_payload TYPE string
       RAISING zpru_cx_agent_core.

    METHODS get_mock_test_response
      RETURNING VALUE(rv_response) TYPE string.

    METHODS strip_markdown_wrappers
      CHANGING cv_response TYPE string.

    METHODS add_execution_plan_step
      IMPORTING iv_agentuuid TYPE sysuuid_x16
                iv_sequence  TYPE int4
                iv_toolname  TYPE string
      CHANGING  ct_plan      TYPE zpru_if_decision_provider=>tt_execution_plan.

    METHODS parse_think_output_2_cmr_resp
      IMPORTING iv_thinking_output TYPE string
      RETURNING VALUE(rt_response) TYPE tt_parse_response_root.

    METHODS map_response_2_creat_content
      IMPORTING it_response       TYPE tt_parse_response_root
      RETURNING VALUE(rt_content) TYPE zpru_if_computer_vision=>tt_cmr_create_content.

    METHODS get_axc_service_instance
      RETURNING VALUE(ro_axc_service) TYPE REF TO zpru_if_axc_service
      RAISING   zpru_cx_agent_core.

    METHODS read_execution_data
      IMPORTING iv_run_uuid    TYPE sysuuid_x16
                iv_query_uuid  TYPE sysuuid_x16
                io_axc_service TYPE REF TO zpru_if_axc_service
      EXPORTING et_axc_head    TYPE zpru_if_axc_type_and_constant=>tt_axc_head
                et_axc_query   TYPE zpru_if_axc_type_and_constant=>tt_axc_query
                et_axc_steps   TYPE zpru_if_axc_type_and_constant=>tt_axc_step.

    METHODS assign_runtime_to_messages
      IMPORTING io_controller         TYPE REF TO zpru_if_agent_controller
                it_axc_head           TYPE zpru_if_axc_type_and_constant=>tt_axc_head
                it_axc_query          TYPE zpru_if_axc_type_and_constant=>tt_axc_query
                it_axc_steps          TYPE zpru_if_axc_type_and_constant=>tt_axc_step
      CHANGING  cs_recognition_output TYPE zbp_r_pru_message=>ts_recognition_output.

    METHODS append_freshest_context
      IMPORTING io_controller TYPE REF TO zpru_if_agent_controller
      CHANGING  cs_final_body TYPE zpru_s_final_response_body.

    METHODS check_authorizations        REDEFINITION.
    METHODS recall_memory               REDEFINITION.
    METHODS read_data_4_thinking        REDEFINITION.
    METHODS process_thinking            REDEFINITION.
    METHODS prepare_first_tool_input    REDEFINITION.
    METHODS set_model_id                REDEFINITION.
    METHODS set_result_comment          REDEFINITION.
    METHODS set_final_response_content  REDEFINITION.
    METHODS set_final_response_metadata REDEFINITION.
ENDCLASS.


CLASS lcl_adf_short_memory_provider DEFINITION INHERITING FROM zpru_cl_short_memory_base CREATE PUBLIC.
  PUBLIC SECTION.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.


CLASS lcl_adf_long_memory_provider DEFINITION INHERITING FROM zpru_cl_long_memory_base CREATE PUBLIC.
  PUBLIC SECTION.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.


CLASS lcl_adf_agent_info_provider DEFINITION INHERITING FROM zpru_cl_agent_info_provider CREATE PUBLIC.
  PROTECTED SECTION.
    METHODS get_agent_main_info    REDEFINITION.
    METHODS set_agent_goals        REDEFINITION.
    METHODS prepare_agent_domains  REDEFINITION.
    METHODS set_agent_restrictions REDEFINITION.
    METHODS set_tool_metadata      REDEFINITION.
    METHODS get_free_text          REDEFINITION.
ENDCLASS.


CLASS lcl_adf_syst_prompt_provider DEFINITION INHERITING FROM zpru_cl_syst_prmpt_prvdr_base CREATE PUBLIC.
  PROTECTED SECTION.
    METHODS set_primary_session_task REDEFINITION.
    METHODS set_technical_rules      REDEFINITION.
    METHODS set_business_rules       REDEFINITION.
    METHODS set_format_guidelines    REDEFINITION.
    METHODS set_reasoning_step       REDEFINITION.
    METHODS set_prompt_restrictions  REDEFINITION.
    METHODS set_arbitrary_text       REDEFINITION.
ENDCLASS.


CLASS lcl_adf_agent_mapper DEFINITION INHERITING FROM zpru_cl_agent_mapper CREATE PUBLIC.
  PROTECTED SECTION.
ENDCLASS.


CLASS lcl_adf_create_cmr DEFINITION INHERITING FROM zpru_cl_abap_executor CREATE PUBLIC.
  PROTECTED SECTION.
    TYPES tt_pru_cmrheader TYPE TABLE FOR CREATE zr_pru_cmr_header\\zrprucmrheader.
    TYPES tt_pru_cmritem   TYPE TABLE FOR CREATE zr_pru_cmr_header\\zrprucmrheader\_cmritems.

    METHODS execute_code_int REDEFINITION.

    METHODS deserialize_cmr_creation_input
      IMPORTING is_input           TYPE REF TO data
      RETURNING VALUE(rt_creation) TYPE zpru_if_computer_vision=>tt_cmr_create_content
      RAISING   zpru_cx_agent_core.

    METHODS assign_cmr_ids
      CHANGING ct_headers TYPE zpru_if_computer_vision=>tt_cmr_header_context
               ct_items   TYPE zpru_if_computer_vision=>tt_cmr_item_context.

    METHODS prepare_header_rap_entities
      IMPORTING it_headers       TYPE zpru_if_computer_vision=>tt_cmr_header_context
      RETURNING VALUE(rt_create) TYPE tt_pru_cmrheader.

    METHODS prepare_item_rap_entities
      IMPORTING it_headers_create type lcl_adf_create_cmr=>tt_pru_cmrheader
                it_items         TYPE zpru_if_computer_vision=>tt_cmr_item_context
      RETURNING VALUE(rt_create) TYPE tt_pru_cmritem.

    METHODS persist_cmr_via_rap
      IMPORTING it_create_header TYPE tt_pru_cmrheader
                it_create_item   TYPE tt_pru_cmritem
      EXPORTING et_mapped_header TYPE zpru_if_computer_vision=>tt_cmr_header_context
                et_mapped_item   TYPE zpru_if_computer_vision=>tt_cmr_item_context
      CHANGING  ev_error_flag    TYPE abap_bool.

    METHODS append_cmr_output_pairs
      IMPORTING it_cmr_headers      TYPE zpru_if_computer_vision=>tt_cmr_header_context
                it_cmr_items        TYPE zpru_if_computer_vision=>tt_cmr_item_context
                it_creation_content TYPE zpru_if_computer_vision=>tt_cmr_create_content
      CHANGING  ct_key_value_pairs  TYPE zpru_tt_key_value.
ENDCLASS.


CLASS lcl_adf_classify_danger_goods DEFINITION
  INHERITING FROM zpru_cl_abap_executor
  CREATE PUBLIC.

  PROTECTED SECTION.
    TYPES tt_cmralert_create TYPE TABLE FOR CREATE zr_pru_cmr_alert\\zrprucmralert.
    TYPES ts_cmralert_create TYPE STRUCTURE FOR CREATE zr_pru_cmr_alert\\zrprucmralert.

    METHODS execute_code_int REDEFINITION.

    METHODS deserialize_classify_input
      IMPORTING is_input        TYPE REF TO data
      RETURNING VALUE(rt_items) TYPE zpru_if_computer_vision=>tt_cmr_item_context
      RAISING   zpru_cx_agent_core.

    METHODS check_danger_by_hazard_class
      IMPORTING iv_hazardclass   TYPE char5
      RETURNING VALUE(rv_reason) TYPE string.

    METHODS check_danger_by_un_number
      IMPORTING iv_un_number     TYPE char10
      RETURNING VALUE(rv_reason) TYPE string.

    METHODS check_explosive
      IMPORTING iv_nature_up     TYPE string
      RETURNING VALUE(rv_reason) TYPE string.

    METHODS check_flammable_gas
      IMPORTING iv_nature_up     TYPE string
      RETURNING VALUE(rv_reason) TYPE string.

    METHODS check_flammable_liquid
      IMPORTING iv_nature_up     TYPE string
      RETURNING VALUE(rv_reason) TYPE string.

    METHODS check_flammable_solid
      IMPORTING iv_nature_up     TYPE string
      RETURNING VALUE(rv_reason) TYPE string.

    METHODS check_oxidiser
      IMPORTING iv_nature_up     TYPE string
      RETURNING VALUE(rv_reason) TYPE string.

    METHODS check_toxic
      IMPORTING iv_nature_up     TYPE string
      RETURNING VALUE(rv_reason) TYPE string.

    METHODS check_infectious
      IMPORTING iv_nature_up     TYPE string
      RETURNING VALUE(rv_reason) TYPE string.

    METHODS check_radioactive
      IMPORTING iv_nature_up     TYPE string
      RETURNING VALUE(rv_reason) TYPE string.

    METHODS check_corrosive
      IMPORTING iv_nature_up     TYPE string
      RETURNING VALUE(rv_reason) TYPE string.

    METHODS check_hazardous_other
      IMPORTING iv_nature_up     TYPE string
      RETURNING VALUE(rv_reason) TYPE string.

    METHODS classify_single_item
      IMPORTING is_item      TYPE zpru_if_computer_vision=>ts_cmr_item_context
      EXPORTING ev_is_danger TYPE abap_bool
                ev_reason    TYPE string.

    METHODS create_alert_entity
      IMPORTING is_item         TYPE zpru_if_computer_vision=>ts_cmr_item_context
                iv_reason       TYPE string
                iv_alert_seq    TYPE i
      RETURNING VALUE(rs_alert) TYPE ts_cmralert_create.

    METHODS persist_alerts_via_rap
      IMPORTING it_alerts     TYPE tt_cmralert_create
      EXPORTING et_alerts     TYPE zpru_if_computer_vision=>tt_cmr_alert_context
      CHANGING  ev_error_flag TYPE abap_bool.

    METHODS append_alert_output
      IMPORTING it_alerts          TYPE zpru_if_computer_vision=>tt_cmr_alert_context
      CHANGING  ct_key_value_pairs TYPE zpru_tt_key_value.
ENDCLASS.


CLASS lcl_adf_validate_cmr DEFINITION
  INHERITING FROM zpru_cl_abap_executor
  CREATE PUBLIC.

  PROTECTED SECTION.
    TYPES tt_pru_cmrvalid TYPE TABLE FOR CREATE zr_pru_cmr_valid\\zrprucmrvalid.

    METHODS execute_code_int REDEFINITION.

    METHODS deserialize_validation_input
      IMPORTING is_input   TYPE REF TO data
      EXPORTING et_headers TYPE zpru_if_computer_vision=>tt_cmr_header_context
                et_items   TYPE zpru_if_computer_vision=>tt_cmr_item_context
      RAISING   zpru_cx_agent_core.

    METHODS validate_header_senderinfo
      IMPORTING is_header       TYPE zpru_if_computer_vision=>ts_cmr_header_context
      CHANGING  ct_findings     TYPE zpru_if_computer_vision=>tt_cmr_finding
                ct_findings_rap TYPE tt_pru_cmrvalid
                cv_cid_counter  TYPE i.

    METHODS validate_header_consigneeinfo
      IMPORTING is_header       TYPE zpru_if_computer_vision=>ts_cmr_header_context
      CHANGING  ct_findings     TYPE zpru_if_computer_vision=>tt_cmr_finding
                ct_findings_rap TYPE tt_pru_cmrvalid
                cv_cid_counter  TYPE i.

    METHODS validate_header_carrierinfo
      IMPORTING is_header       TYPE zpru_if_computer_vision=>ts_cmr_header_context
      CHANGING  ct_findings     TYPE zpru_if_computer_vision=>tt_cmr_finding
                ct_findings_rap TYPE tt_pru_cmrvalid
                cv_cid_counter  TYPE i.

    METHODS validate_head_takingoverplace
      IMPORTING is_header       TYPE zpru_if_computer_vision=>ts_cmr_header_context
      CHANGING  ct_findings     TYPE zpru_if_computer_vision=>tt_cmr_finding
                ct_findings_rap TYPE tt_pru_cmrvalid
                cv_cid_counter  TYPE i.

    METHODS validate_header_deliveryplace
      IMPORTING is_header       TYPE zpru_if_computer_vision=>ts_cmr_header_context
      CHANGING  ct_findings     TYPE zpru_if_computer_vision=>tt_cmr_finding
                ct_findings_rap TYPE tt_pru_cmrvalid
                cv_cid_counter  TYPE i.

    METHODS validate_header_takingoverdate
      IMPORTING is_header       TYPE zpru_if_computer_vision=>ts_cmr_header_context
      CHANGING  ct_findings     TYPE zpru_if_computer_vision=>tt_cmr_finding
                ct_findings_rap TYPE tt_pru_cmrvalid
                cv_cid_counter  TYPE i.

    METHODS validate_header_currency
      IMPORTING is_header       TYPE zpru_if_computer_vision=>ts_cmr_header_context
      CHANGING  ct_findings     TYPE zpru_if_computer_vision=>tt_cmr_finding
                ct_findings_rap TYPE tt_pru_cmrvalid
                cv_cid_counter  TYPE i.

    METHODS validate_item_count
      IMPORTING is_header       TYPE zpru_if_computer_vision=>ts_cmr_header_context
                it_items        TYPE zpru_if_computer_vision=>tt_cmr_item_context
      CHANGING  ct_findings     TYPE zpru_if_computer_vision=>tt_cmr_finding
                ct_findings_rap TYPE tt_pru_cmrvalid
                cv_cid_counter  TYPE i.

    METHODS validate_item_natureofgoods
      IMPORTING is_header       TYPE zpru_if_computer_vision=>ts_cmr_header_context
                is_item         TYPE zpru_if_computer_vision=>ts_cmr_item_context
      CHANGING  ct_findings     TYPE zpru_if_computer_vision=>tt_cmr_finding
                ct_findings_rap TYPE tt_pru_cmrvalid
                cv_cid_counter  TYPE i.

    METHODS validate_item_grossweight
      IMPORTING is_header       TYPE zpru_if_computer_vision=>ts_cmr_header_context
                is_item         TYPE zpru_if_computer_vision=>ts_cmr_item_context
      CHANGING  ct_findings     TYPE zpru_if_computer_vision=>tt_cmr_finding
                ct_findings_rap TYPE tt_pru_cmrvalid
                cv_cid_counter  TYPE i.

    METHODS validate_item_weightunit
      IMPORTING is_header       TYPE zpru_if_computer_vision=>ts_cmr_header_context
                is_item         TYPE zpru_if_computer_vision=>ts_cmr_item_context
      CHANGING  ct_findings     TYPE zpru_if_computer_vision=>tt_cmr_finding
                ct_findings_rap TYPE tt_pru_cmrvalid
                cv_cid_counter  TYPE i.

    METHODS validate_item_dg_fields
      IMPORTING is_header       TYPE zpru_if_computer_vision=>ts_cmr_header_context
                is_item         TYPE zpru_if_computer_vision=>ts_cmr_item_context
      CHANGING  ct_findings     TYPE zpru_if_computer_vision=>tt_cmr_finding
                ct_findings_rap TYPE tt_pru_cmrvalid
                cv_cid_counter  TYPE i.

    METHODS add_finding_to_output
      IMPORTING is_finding_rap TYPE  zpru_if_computer_vision=>ts_cmr_finding
      CHANGING  ct_findings    TYPE zpru_if_computer_vision=>tt_cmr_finding.

    METHODS calculate_cmr_status
      IMPORTING is_header   TYPE zpru_if_computer_vision=>ts_cmr_header_context
                it_findings TYPE zpru_if_computer_vision=>tt_cmr_finding
      CHANGING  ct_status   TYPE zpru_if_computer_vision=>tt_cmr_overall_status.

    METHODS persist_validation_findings
      IMPORTING it_findings_rap TYPE tt_pru_cmrvalid
      CHANGING  ev_error_flag   TYPE abap_bool.

    METHODS append_validation_output
      IMPORTING it_cmr_status      TYPE zpru_if_computer_vision=>tt_cmr_overall_status
                it_cmr_findings    TYPE zpru_if_computer_vision=>tt_cmr_finding
      CHANGING  ct_key_value_pairs TYPE zpru_tt_key_value.
ENDCLASS.


CLASS lcl_adf_create_inb_delivery DEFINITION
  INHERITING FROM zpru_cl_abap_executor
  CREATE PUBLIC.

  PROTECTED SECTION.
    TYPES tt_inb_delivery_header TYPE TABLE FOR CREATE zprur_inbhdr\\inbhdr.
    TYPES tt_inb_delivery_item   TYPE TABLE FOR CREATE zprur_inbhdr\\inbhdr\_inbitm.

    METHODS execute_code_int REDEFINITION.

    METHODS deserialize_inb_delivery_input
      IMPORTING is_input      TYPE REF TO data
      EXPORTING et_cmr_header TYPE zpru_if_computer_vision=>tt_cmr_header_context
                et_cmr_item   TYPE zpru_if_computer_vision=>tt_cmr_item_context
      RAISING   zpru_cx_agent_core.

    METHODS map_cmr_to_delivery_content
      IMPORTING it_cmr_header  TYPE zpru_if_computer_vision=>tt_cmr_header_context
                it_cmr_item    TYPE zpru_if_computer_vision=>tt_cmr_item_context
      EXPORTING et_headers_all TYPE zpru_if_computer_vision=>tt_inb_delivery_header_context
                et_items_all   TYPE zpru_if_computer_vision=>tt_inb_delivery_item_context.

    METHODS prepare_delivery_head_entities
      IMPORTING it_headers       TYPE zpru_if_computer_vision=>tt_inb_delivery_header_context
      RETURNING VALUE(rt_create) TYPE tt_inb_delivery_header.

    METHODS prepare_delivery_item_entities
      IMPORTING it_headers_create  type tt_inb_delivery_header
                it_items         TYPE zpru_if_computer_vision=>tt_inb_delivery_item_context
      RETURNING VALUE(rt_create) TYPE tt_inb_delivery_item.

    METHODS persist_inb_delivery_via_rap
      IMPORTING it_create_header TYPE tt_inb_delivery_header
                it_create_item   TYPE tt_inb_delivery_item
      EXPORTING et_mapped_header TYPE zpru_if_computer_vision=>tt_inb_delivery_header_context
                et_mapped_item   TYPE zpru_if_computer_vision=>tt_inb_delivery_item_context
      CHANGING  ev_error_flag    TYPE abap_bool.

    METHODS append_inb_delivery_output
      IMPORTING it_delivery_headers TYPE zpru_if_computer_vision=>tt_inb_delivery_header_context
                it_delivery_items   TYPE zpru_if_computer_vision=>tt_inb_delivery_item_context
      CHANGING  ct_key_value_pairs  TYPE zpru_tt_key_value.
ENDCLASS.


CLASS lcl_adf_find_storage_bin DEFINITION
  INHERITING FROM zpru_cl_abap_executor
  CREATE PUBLIC.

  PROTECTED SECTION.
    METHODS execute_code_int REDEFINITION.

    METHODS query_available_bins
      RETURNING VALUE(rt_bins) TYPE zpru_if_computer_vision=>tt_storage_bin_context.

    METHODS append_storage_bin_output
      IMPORTING it_bins            TYPE zpru_if_computer_vision=>tt_storage_bin_context
      CHANGING  ct_key_value_pairs TYPE zpru_tt_key_value.
ENDCLASS.


CLASS lcl_adf_create_warehouse_task DEFINITION
  INHERITING FROM zpru_cl_abap_executor
  CREATE PUBLIC.

  PROTECTED SECTION.
    TYPES tt_warehouse_task TYPE TABLE FOR CREATE zprur_task\\task.

    METHODS execute_code_int REDEFINITION.

    METHODS deserialize_wh_task_input
      IMPORTING is_input        TYPE REF TO data
      EXPORTING et_inb_headers  TYPE zpru_if_computer_vision=>tt_inb_delivery_header_context
                et_inb_items    TYPE zpru_if_computer_vision=>tt_inb_delivery_item_context
                et_storage_bins TYPE zpru_if_computer_vision=>tt_storage_bin_context
      RAISING   zpru_cx_agent_core.

    METHODS get_next_task_number
      RETURNING VALUE(rv_next_tanum) TYPE i.

    METHODS build_warehouse_task_entities
      IMPORTING it_inb_headers  TYPE zpru_if_computer_vision=>tt_inb_delivery_header_context
                it_inb_items    TYPE zpru_if_computer_vision=>tt_inb_delivery_item_context
                it_storage_bins TYPE zpru_if_computer_vision=>tt_storage_bin_context
      RETURNING VALUE(rt_tasks) TYPE tt_warehouse_task.

    METHODS persist_tasks_via_rap
      IMPORTING it_tasks      TYPE tt_warehouse_task
      EXPORTING et_tasks      TYPE zpru_if_computer_vision=>tt_warehouse_task_context
      CHANGING  ev_error_flag TYPE abap_bool.

    METHODS append_wh_task_output
      IMPORTING it_tasks           TYPE zpru_if_computer_vision=>tt_warehouse_task_context
      CHANGING  ct_key_value_pairs TYPE zpru_tt_key_value.
ENDCLASS.


CLASS lcl_adf_tool_provider DEFINITION INHERITING FROM zpru_cl_tool_provider CREATE PUBLIC.
  PROTECTED SECTION.
    METHODS provide_tool_instance REDEFINITION.
ENDCLASS.


CLASS lcl_adf_tool_info_provider DEFINITION INHERITING FROM zpru_cl_tool_info_provider CREATE PUBLIC.
  PROTECTED SECTION.
    METHODS get_main_tool_info  REDEFINITION.
    METHODS set_tool_properties REDEFINITION.
    METHODS set_tool_parameters REDEFINITION.
ENDCLASS.


CLASS lcl_adf_schema_provider DEFINITION INHERITING FROM zpru_cl_tool_schema_provider CREATE PUBLIC.
  PROTECTED SECTION.
    METHODS get_input_abap_type   REDEFINITION.
    METHODS get_input_json_schema REDEFINITION.

    METHODS get_cmr_create
      RETURNING VALUE(rv_schema) TYPE string.

    METHODS get_classify_danger_goods
      RETURNING VALUE(rv_schema) TYPE string.

    METHODS get_validate_cmr
      RETURNING VALUE(rv_schema) TYPE string.

    METHODS get_create_inb_delivery
      RETURNING VALUE(rv_schema) TYPE string.

    METHODS get_find_storage_bin
      RETURNING VALUE(rv_schema) TYPE string.

    METHODS get_create_warehouse_task
      RETURNING VALUE(rv_schema) TYPE string.

    METHODS fill_cmr_create_schm
      RETURNING VALUE(rs_schema) TYPE zpru_s_json_schema.

    METHODS fill_class_dgr_schm
      RETURNING VALUE(rs_schema) TYPE zpru_s_json_schema.

    METHODS fill_val_cmr_schm
      RETURNING VALUE(rs_schema) TYPE zpru_s_json_schema.

    METHODS fill_inb_del_schm
      RETURNING VALUE(rs_schema) TYPE zpru_s_json_schema.

    METHODS fill_find_bin_schm
      RETURNING VALUE(rs_schema) TYPE zpru_s_json_schema.

    METHODS fill_wh_task_schm
      RETURNING VALUE(rs_schema) TYPE zpru_s_json_schema.
ENDCLASS.


