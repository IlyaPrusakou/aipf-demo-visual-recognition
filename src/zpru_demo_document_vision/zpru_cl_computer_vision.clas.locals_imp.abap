CLASS lcl_adf_decision_provider IMPLEMENTATION.
  METHOD check_authorizations.
    ev_allowed = abap_true.
    RETURN.
  ENDMETHOD.

  METHOD process_thinking.
    " gemini input
    TYPES: BEGIN OF ts_inline_data,
             mime_type TYPE string,
             data      TYPE string, " Base64 string
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

    " gemini output
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

    DATA lv_gemini_url       TYPE string.
    DATA lo_http_destination TYPE REF TO if_http_destination.
    DATA lo_http_client      TYPE REF TO if_web_http_client.
    DATA ls_abap_payload     TYPE REF TO ts_gemini_request.
    DATA lv_string_payload   TYPE string.
*    DATA ls_llm_output       TYPE ts_gemini_response.
    DATA lr_payload          TYPE REF TO data.

    FIELD-SYMBOLS <ls_payload> TYPE zbp_r_pru_message=>ts_doc_recognition.

    lv_gemini_url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`.
    TRY.
        lo_http_destination = cl_http_destination_provider=>create_by_url( i_url = lv_gemini_url ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = lo_http_destination ).
      CATCH cx_http_dest_provider_error
            cx_web_http_client_error.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDTRY.

    DATA(lo_http_request) = lo_http_client->get_http_request( ).

    lo_http_request->set_header_field( i_name  = 'Content-Type'
                                       i_value = 'application/json' ).
    lo_http_request->set_header_field( i_name  = 'x-goog-api-key'
                                       i_value = 'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm' ).

    CREATE DATA lr_payload TYPE (is_input_prompt-type).

    ASSIGN lr_payload->* TO <ls_payload>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    /ui2/cl_json=>deserialize( EXPORTING json = is_input_prompt-string_content
                                         hex_as_base64 = abap_false
                               CHANGING  data = <ls_payload> ).

    CREATE DATA ls_abap_payload.

    ASSIGN ls_abap_payload->* TO FIELD-SYMBOL(<ls_abap_payload>).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    DATA(lv_json_schema) =
      |\{| &&
      |  "type": "array",| &&
      |  "items": \{| &&
      |    "type": "object",| &&
      |    "properties": \{| &&
      |      "messageid": \{ "type": "string" \},| &&
      |      "attachments": \{| &&
      |        "type": "array",| &&
      |        "items": \{| &&
      |          "type": "object",| &&
      |          "properties": \{| &&
      |            "cmrheaders": \{| &&
      |              "type": "array",| &&
      |              "items": \{| &&
      |                "type": "object",| &&
      |                "properties": \{| &&
      |                  "cmrid": \{ "type": "string" \},| &&
      |                  "senderinfo": \{ "type": "string" \},| &&
      |                  "consigneeinfo": \{ "type": "string" \},| &&
      |                  "deliveryplace": \{ "type": "string" \},| &&
      |                  "takingoverplace": \{ "type": "string" \},| &&
      |                  "takingoverdate": \{ "type": "string" \},| &&
      |                  "carrierinfo": \{ "type": "string" \},| &&
      |                  "successivecarrier": \{ "type": "string" \},| &&
      |                  "carrierreservice": \{ "type": "string" \},| &&
      |                  "senderinstruction": \{ "type": "string" \},| &&
      |                  "cashondelivery": \{ "type": "number" \},| &&
      |                  "currency": \{ "type": "string" \},| &&
      |                  "establishedplace": \{ "type": "string" \},| &&
      |                  "establisheddate": \{ "type": "string" \},| &&
      |                  "createdby": \{ "type": "string" \},| &&
      |                  "createdat": \{ "type": "string" \},| &&
      |                  "lastchangedby": \{ "type": "string" \},| &&
      |                  "lastchangedat": \{ "type": "string" \},| &&
      |                  "cmritems": \{| &&
      |                    "type": "array",| &&
      |                    "items": \{| &&
      |                      "type": "object",| &&
      |                      "properties": \{| &&
      |                        "itemposition": \{ "type": "string" \},| &&
      |                        "marksnumbers": \{ "type": "string" \},| &&
      |                        "packagecount": \{ "type": "integer" \},| &&
      |                        "packingmethod": \{ "type": "string" \},| &&
      |                        "natureofgoods": \{ "type": "string" \},| &&
      |                        "statisticalnumber": \{ "type": "string" \},| &&
      |                        "weightunitfield": \{ "type": "string" \},| &&
      |                        "volumeunitfield": \{ "type": "string" \},| &&
      |                        "grossweight": \{ "type": "number" \},| &&
      |                        "volume": \{ "type": "number" \},| &&
      |                        "unitednationnumber": \{ "type": "string" \},| &&
      |                        "hazardclass": \{ "type": "string" \},| &&
      |                        "packinggroup": \{ "type": "string" \}| &&
      |                      \},| &&
      |                      "required": ["itemposition", "natureofgoods"]| &&
      |                    \}| &&
      |                  \}| &&
      |                \},| &&
      |                "required": ["cmrid", "cmritems"]| &&
      |              \}| &&
      |            \}| &&
      |          \},| &&
      |          "required": ["cmrheaders"]| &&
      |        \}| &&
      |      \}| &&
      |    \},| &&
      |    "required": ["messageid", "attachments"]| &&
      |  \}| &&
      |\}|.

    APPEND INITIAL LINE TO <ls_abap_payload>-contents ASSIGNING FIELD-SYMBOL(<ls_contnent>).
    APPEND INITIAL LINE TO <ls_contnent>-parts ASSIGNING FIELD-SYMBOL(<ls_part>).

    LOOP AT <ls_payload>-message ASSIGNING FIELD-SYMBOL(<ls_message>).

      <ls_part>-text = |{ <ls_part>-text } always use USD as currency, KG as weight and M3 as volume.{ cl_abap_char_utilities=>newline }|.
      <ls_part>-text = |{ <ls_part>-text } always give me output as json according the schema.{ cl_abap_char_utilities=>newline }|.
      <ls_part>-text = |{ <ls_part>-text } For output use this schema: { lv_json_schema }{ cl_abap_char_utilities=>newline }|.

      LOOP AT <ls_payload>-attachment ASSIGNING FIELD-SYMBOL(<ls_attachment>)
           WHERE messageid = <ls_message>-messageid.
        DATA(lv_image_base64) = cl_web_http_utility=>encode_x_base64( unencoded = <ls_attachment>-attachment ).

        APPEND INITIAL LINE TO <ls_contnent>-parts ASSIGNING <ls_part>.
        <ls_part>-inline_data-mime_type = 'image/jpeg'.
        <ls_part>-inline_data-data      = lv_image_base64.
      ENDLOOP.
    ENDLOOP.

    lv_string_payload = /ui2/cl_json=>serialize( data        = ls_abap_payload
                                                 hex_as_base64 = abap_false
                                                 pretty_name = /ui2/cl_json=>pretty_mode-low_case
                                                 compress    = abap_true ).

    IF lv_string_payload IS INITIAL.
      RETURN.
    ENDIF.

    lo_http_request->set_text( i_text = lv_string_payload ).

*    TRY.
*        DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>post ).
*      CATCH cx_web_http_client_error.
*        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
*    ENDTRY.
*
*    IF lo_response->get_status( )-code <> `200`.
*      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
*    ENDIF.
*
*    DATA(lv_gemini_output) = lo_response->get_text( ).
*
*    /ui2/cl_json=>deserialize( EXPORTING json = lv_gemini_output
*                                hex_as_base64 = abap_false
*                               CHANGING  data = ls_llm_output ).
*
*    DATA(lv_raw_response) = VALUE #( ls_llm_output-candidates[ 1 ]-content-parts[ 1 ]-text OPTIONAL ).

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""" testing

    DATA(lv_raw_response) = |[| &&
    |  \{| &&
    |    "messageid": "CMR-20260314-001",| &&
    |    "attachments": [| &&
    |      \{| &&
    |        "cmrheaders": [| &&
    |          \{| &&
    |            "cmrid": "",| &&
    |            "senderinfo": "Sender LTD",| &&
    |            "consigneeinfo": "Biedronka LTD",| &&
    |            "deliveryplace": "Wrocław",| &&
    |            "takingoverplace": "Warsaw",| &&
    |            "takingoverdate": "14/03/2026",| &&
    |            "carrierinfo": "DPD Polska",| &&
    |            "successivecarrier": "Biedronka Express",| &&
    |            "carrierreservice": null,| &&
    |            "senderinstruction": "spread into markets ASAP",| &&
    |            "cashondelivery": 1344,| &&
    |            "currency": "USD",| &&
    |            "establishedplace": "Wrocław, Biskupin",| &&
    |            "establisheddate": "31/03/2026",| &&
    |            "createdby": null,| &&
    |            "createdat": null,| &&
    |            "lastchangedby": null,| &&
    |            "lastchangedat": null,| &&
    |            "cmritems": [| &&
    |              \{| &&
    |                "itemposition": "prod1",| &&
    |                "marksnumbers": "prod1",| &&
    |                "packagecount": 14,| &&
    |                "packingmethod": "box",| &&
    |                "natureofgoods": "pencils",| &&
    |                "statisticalnumber": "st-14nr",| &&
    |                "weightunitfield": "KG",| &&
    |                "volumeunitfield": "M3",| &&
    |                "grossweight": 16,| &&
    |                "volume": 1,| &&
    |                "unitednationnumber": null,| &&
    |                "hazardclass": "FLAM",| &&  " QQQ FLAMABLE trigger on hazard class"
    |                "packinggroup": null| &&
    |              \},| &&
    |              \{| &&
    |                "itemposition": "prod2",| &&
    |                "marksnumbers": "prod2",| &&
    |                "packagecount": 8,| &&
    |                "packingmethod": "pallet",| &&
    |                "natureofgoods": "EXPLOS bananas",| && " QQQ EPLOSIVE trigger on nature of goods"
    |                "statisticalnumber": "st-888nr",| &&
    |                "weightunitfield": "KG",| &&
    |                "volumeunitfield": "M3",| &&
    |                "grossweight": 55,| &&
    |                "volume": 5,| &&
    |                "unitednationnumber": null,| &&
    |                "hazardclass": null,| &&
    |                "packinggroup": null| &&
    |              \}| &&
    |            ]| &&
    |          \}| &&
    |        ]| &&
    |      \}| &&
    |    ]| &&
    |  \}| &&
    |]|.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" testing
    REPLACE FIRST OCCURRENCE OF '```json' IN lv_raw_response WITH ''.
    REPLACE ALL OCCURRENCES OF '```' IN lv_raw_response WITH ''.

    IF lv_raw_response IS INITIAL.
      RETURN.
    ENDIF.

    ev_thinking_output = lv_raw_response.

    APPEND INITIAL LINE TO et_execution_plan ASSIGNING FIELD-SYMBOL(<ls_execution_plan>).
    <ls_execution_plan>-agentuuid = is_agent-agentuuid.
    <ls_execution_plan>-sequence  = 1.
    <ls_execution_plan>-toolname  = zpru_if_computer_vision=>cs_tools-create_cmr.

    APPEND INITIAL LINE TO et_execution_plan ASSIGNING <ls_execution_plan>.
    <ls_execution_plan>-agentuuid = is_agent-agentuuid.
    <ls_execution_plan>-sequence  = 2.
    <ls_execution_plan>-toolname  = zpru_if_computer_vision=>cs_tools-classify_danger_goods.

    APPEND INITIAL LINE TO et_execution_plan ASSIGNING <ls_execution_plan>.
    <ls_execution_plan>-agentuuid = is_agent-agentuuid.
    <ls_execution_plan>-sequence  = 3.
    <ls_execution_plan>-toolname  = zpru_if_computer_vision=>cs_tools-validate_cmr.

    APPEND INITIAL LINE TO et_execution_plan ASSIGNING <ls_execution_plan>.
    <ls_execution_plan>-agentuuid = is_agent-agentuuid.
    <ls_execution_plan>-sequence  = 4.
    <ls_execution_plan>-toolname  = zpru_if_computer_vision=>cs_tools-create_inb_delivery.

    APPEND INITIAL LINE TO et_execution_plan ASSIGNING <ls_execution_plan>.
    <ls_execution_plan>-agentuuid = is_agent-agentuuid.
    <ls_execution_plan>-sequence  = 5.
    <ls_execution_plan>-toolname  = zpru_if_computer_vision=>cs_tools-find_storage_bin.

    APPEND INITIAL LINE TO et_execution_plan ASSIGNING <ls_execution_plan>.
    <ls_execution_plan>-agentuuid = is_agent-agentuuid.
    <ls_execution_plan>-sequence  = 6.
    <ls_execution_plan>-toolname  = zpru_if_computer_vision=>cs_tools-create_warehouse_task.

    ev_langu = sy-langu.
  ENDMETHOD.

  METHOD prepare_first_tool_input.
    TYPES: BEGIN OF ts_items,
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
           END OF ts_items,

           tt_items TYPE STANDARD TABLE OF ts_items WITH EMPTY KEY.

    TYPES: BEGIN OF ts_headers,
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
             cmritems          TYPE tt_items,
           END OF ts_headers,

           tt_headers TYPE STANDARD TABLE OF ts_headers WITH EMPTY KEY.

    TYPES: BEGIN OF ts_attachment,
             cmrheaders TYPE tt_headers,
           END OF ts_attachment,

           tt_attachments TYPE STANDARD TABLE OF ts_attachment WITH EMPTY KEY.

    TYPES: BEGIN OF ts_response,
             messageid   TYPE char32,
             attachments TYPE tt_attachments,
           END OF ts_response,

           tt_response_root TYPE STANDARD TABLE OF ts_response WITH EMPTY KEY.

    DATA lt_raw_response       TYPE tt_response_root.
    DATA ls_cmr_create_request TYPE zpru_if_computer_vision=>ts_cmr_create_request.
    DATA lt_header             TYPE STANDARD TABLE OF zpru_cmr_header WITH EMPTY KEY.
    DATA lt_items              TYPE STANDARD TABLE OF zpru_cmr_item WITH EMPTY KEY.
    DATA lt_creation_content   TYPE zpru_if_computer_vision=>tt_cmr_create_content.

    /ui2/cl_json=>deserialize( EXPORTING json = iv_thinking_output
                                         hex_as_base64 = abap_false
                               CHANGING  data = lt_raw_response ). " qqq check how dates transformed

    IF lt_raw_response IS INITIAL.
      RETURN.
    ENDIF.

    CASE is_first_tool-toolname.
      WHEN `CREATE_CMR`.

        LOOP AT lt_raw_response ASSIGNING FIELD-SYMBOL(<ls_message>).

          APPEND INITIAL LINE TO lt_creation_content ASSIGNING FIELD-SYMBOL(<ls_cmrcreationrequest>).
          <ls_cmrcreationrequest>-message = <ls_message>-messageid.

          LOOP AT <ls_message>-attachments ASSIGNING FIELD-SYMBOL(<ls_attachment>).
            LOOP AT <ls_attachment>-cmrheaders ASSIGNING FIELD-SYMBOL(<ls_raw_header>).
              APPEND INITIAL LINE TO lt_header ASSIGNING FIELD-SYMBOL(<ls_header>).
              <ls_header> = CORRESPONDING #( <ls_raw_header> ).
              TRY.
                  <ls_header>-cmruuid = cl_system_uuid=>create_uuid_x16_static( ).
                CATCH cx_uuid_error.
                  ASSERT 1 = 2.
              ENDTRY.

              LOOP AT <ls_raw_header>-cmritems ASSIGNING FIELD-SYMBOL(<ls_raw_item>).
                APPEND INITIAL LINE TO lt_items ASSIGNING FIELD-SYMBOL(<ls_item>).
                <ls_item> = CORRESPONDING #( <ls_raw_item> ).
                <ls_item>-cmruuid = <ls_header>-cmruuid.
              ENDLOOP.
            ENDLOOP.
          ENDLOOP.
          <ls_cmrcreationrequest>-cmrheaders = lt_header.
          <ls_cmrcreationrequest>-cmritems   = lt_items.

        ENDLOOP.

        ls_cmr_create_request-cmrcreationcontent = /ui2/cl_json=>serialize( data = lt_creation_content
                                                                            hex_as_base64 = abap_false ).

        er_first_tool_input = NEW zpru_if_computer_vision=>ts_cmr_create_request( ls_cmr_create_request ).
      WHEN OTHERS.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDCASE.
  ENDMETHOD.

  METHOD read_data_4_thinking.
*   " Example: Provide RAG data for the LLM decision engine
*   " For document recognition, we pass the input prompt content as context
    APPEND INITIAL LINE TO cs_decision_log-thinkingsteps ASSIGNING FIELD-SYMBOL(<ls_thinking_step>).
    <ls_thinking_step>-thinkingstepnumber   = get_last_thinkingstepnumber( cs_decision_log-thinkingsteps ).
    <ls_thinking_step>-thinkingstepdatetime = get_timestamp( ).
    <ls_thinking_step>-thinkingstepcontent  = `RAG data prepared for thinking`.
  ENDMETHOD.

  METHOD recall_memory.
*   " Example: Retrieve relevant context from short/long-term memory
*   " For document recognition, we typically use fresh input data
    APPEND INITIAL LINE TO cs_decision_log-thinkingsteps ASSIGNING FIELD-SYMBOL(<ls_thinking_step>).
    <ls_thinking_step>-thinkingstepnumber   = get_last_thinkingstepnumber( cs_decision_log-thinkingsteps ).
    <ls_thinking_step>-thinkingstepdatetime = get_timestamp( ).
    <ls_thinking_step>-thinkingstepcontent  = `Memory recall completed`.
  ENDMETHOD.

  METHOD set_final_response_content.
    DATA lo_axc_service        TYPE REF TO zpru_if_axc_service.
    DATA lt_axc_head           TYPE zpru_if_axc_type_and_constant=>tt_axc_head.
    DATA lt_axc_query          TYPE zpru_if_axc_type_and_constant=>tt_axc_query.
    DATA lt_axc_steps          TYPE zpru_if_axc_type_and_constant=>tt_axc_step.
    DATA ls_doc_recognition    TYPE zbp_r_pru_message=>ts_doc_recognition.
    DATA ls_recognition_output TYPE zbp_r_pru_message=>ts_recognition_output.

    lo_axc_service ?= zpru_cl_agent_service_mngr=>get_service( iv_service = `ZPRU_IF_AXC_SERVICE`
                                                               iv_context = zpru_if_agent_frw=>cs_context-standard ).

    " Read run head by run UUID
    lo_axc_service->read_header(
      EXPORTING it_head_read_k = VALUE #( ( runuuid = iv_run_uuid
                                            control = VALUE #( runuuid          = abap_true
                                                               runid            = abap_true
                                                               agentuuid        = abap_true
                                                               userid           = abap_true
                                                               runstartdatetime = abap_true
                                                               runenddatetime   = abap_true ) ) )
      IMPORTING et_axc_head    = lt_axc_head ).

    " Read specific query by query UUID
    lo_axc_service->read_query(
      EXPORTING it_query_read_k = VALUE #( ( queryuuid = iv_query_uuid
                                             control   = VALUE #( runuuid             = abap_true
                                                                  querynumber         = abap_true
                                                                  queryuuid           = abap_true
                                                                  querylanguage       = abap_true
                                                                  querystatus         = abap_true
                                                                  querystartdatetime  = abap_true
                                                                  queryenddatetime    = abap_true
                                                                  queryinputprompt    = abap_true
                                                                  querydecisionlog    = abap_true
                                                                  queryoutputresponse = abap_true ) ) )
      IMPORTING et_axc_query    = lt_axc_query ).

    " Read steps by query UUID (read by association)
    lo_axc_service->rba_step(
      EXPORTING it_rba_step_k = VALUE #( ( queryuuid = iv_query_uuid
                                           control   = VALUE #( stepuuid           = abap_true
                                                                stepnumber         = abap_true
                                                                queryuuid          = abap_true
                                                                runuuid            = abap_true
                                                                tooluuid           = abap_true
                                                                stepsequence       = abap_true
                                                                stepstatus         = abap_true
                                                                stepstartdatetime  = abap_true
                                                                stependdatetime    = abap_true
                                                                stepinputprompt    = abap_true
                                                                stepoutputresponse = abap_true ) ) )
      IMPORTING et_axc_step   = lt_axc_steps ).

    " Get message from first input prompt
    SORT io_controller->mt_input_output BY number ASCENDING.
    DATA(ls_input_prompt) = VALUE #( io_controller->mt_input_output[ 1 ]-input_prompt OPTIONAL ).
    /ui2/cl_json=>deserialize( EXPORTING json = ls_input_prompt-string_content
                                         hex_as_base64 = abap_false
                               CHANGING  data = ls_doc_recognition ).

    " Build one runtime entry per message
    LOOP AT ls_doc_recognition-message ASSIGNING FIELD-SYMBOL(<ls_message>).
      APPEND INITIAL LINE TO ls_recognition_output-agent_execution_runtime ASSIGNING FIELD-SYMBOL(<ls_runtime>).
      <ls_runtime>-message = <ls_message>.
      <ls_runtime>-run     = CORRESPONDING #( lt_axc_head ).
      <ls_runtime>-query   = CORRESPONDING #( lt_axc_query ).
      <ls_runtime>-steps   = CORRESPONDING #( lt_axc_steps ).
    ENDLOOP.

    cs_final_response_body-responsecontent = /ui2/cl_json=>serialize( data = ls_recognition_output
                                                                      hex_as_base64 = abap_false ).

    cs_final_response_body-type            = `\CLASS=ZBP_R_PRU_MESSAGE\TYPE=TS_RECOGNITION_OUTPUT`.

    SORT io_controller->mt_input_output BY number DESCENDING.
    DATA(lt_freshest_context) = VALUE #( io_controller->mt_input_output[ 1 ]-key_value_pairs OPTIONAL ).

    LOOP AT lt_freshest_context ASSIGNING FIELD-SYMBOL(<ls_context>).
      APPEND INITIAL LINE TO cs_final_response_body-structureddata ASSIGNING FIELD-SYMBOL(<ls_structureddata>).
      <ls_structureddata>-name  = <ls_context>-name.
      <ls_structureddata>-value = <ls_context>-value.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_final_response_metadata.
*   " Set reasoning trace metadata for the final response
    cs_reasoning_trace-rationalsummary = 'Document Visual Recognition completed. CMR data extracted, validated, and processed through the warehouse workflow.'.
    cs_reasoning_trace-confidencescore = `90.00`.
  ENDMETHOD.

  METHOD set_model_id.
*   " Set the LLM model ID for the document recognition
*   " Replace with actual model endpoint when available
    rv_model_id = `GEMINI_2.5_FLASH`.
  ENDMETHOD.

  METHOD set_result_comment.
    rv_result_comment = `Document Visual Recognition processing finished`.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_short_memory_provider IMPLEMENTATION.
ENDCLASS.


CLASS lcl_adf_long_memory_provider IMPLEMENTATION.

ENDCLASS.


CLASS lcl_adf_agent_info_provider IMPLEMENTATION.
  METHOD get_agent_main_info.
    ev_agentname    = `Document Visual Recognition Agent`.
    ev_agentversion = `Version 1.0.0`.
    ev_agentrole    = `Extracts structured data from delivery documents (CMR), detects dangerous goods, creates CMR and inbound delivery records, validates and raises alerts, and suggests warehouse tasks.`.
  ENDMETHOD.

  METHOD get_free_text.
    ev_freetextcontent = |This agent is specialized in processing CMR (Convention relative au contrat de transport international de Marchandises par Route) documents. | &&
               |It uses multimodal AI to extract structured data from scanned documents, classifies dangerous goods, | &&
               |validates mandatory fields, creates inbound delivery records, finds available storage bins, | &&
               |and generates warehouse tasks for putaway.|.
  ENDMETHOD.

  METHOD prepare_agent_domains.
    rs_agent_domains-agentdomainname    = `Document Visual Recognition`.
    rs_agent_domains-agentdomaincontent = |Extract structured data from delivery documents (CMR), classify dangerous goods, create inbound delivery records, and orchestrate basic warehouse tasks.|.

    APPEND INITIAL LINE TO rs_agent_domains-agentsubdomains ASSIGNING FIELD-SYMBOL(<ls_sub_domains>).
    <ls_sub_domains>-agentsubdomainname    = `Document OCR & Data Extraction`.
    <ls_sub_domains>-agentsubdomaincontent = `Recognize text and structured fields from scanned delivery documents (CMR) and return JSON-ready header/item structures.`.

    APPEND INITIAL LINE TO rs_agent_domains-agentsubdomains ASSIGNING <ls_sub_domains>.
    <ls_sub_domains>-agentsubdomainname    = `Dangerous Goods Classification`.
    <ls_sub_domains>-agentsubdomaincontent = `Detect hazardous goods using explicit fields (hazard class, UN number) and free-text indicators; emit alerts and DG metadata.`.

    APPEND INITIAL LINE TO rs_agent_domains-agentsubdomains ASSIGNING <ls_sub_domains>.
    <ls_sub_domains>-agentsubdomainname    = `Inbound Delivery Automation`.
    <ls_sub_domains>-agentsubdomaincontent = `Map extracted CMR data to inbound delivery entities, generate delivery IDs, and persist inbound headers/items via RAP.`.

    APPEND INITIAL LINE TO rs_agent_domains-agentsubdomains ASSIGNING <ls_sub_domains>.
    <ls_sub_domains>-agentsubdomainname    = `Warehouse Tasking & Storage`.
    <ls_sub_domains>-agentsubdomaincontent = `Find available storage bins and generate warehouse tasks for received items, integrating basic allocation heuristics.`.

    APPEND INITIAL LINE TO rs_agent_domains-agentsubdomains ASSIGNING <ls_sub_domains>.
    <ls_sub_domains>-agentsubdomainname    = `Validation & Compliance`.
    <ls_sub_domains>-agentsubdomaincontent = `Validate mandatory fields, weights, and dates; record findings and provide actionable remediation suggestions.`.
  ENDMETHOD.

  METHOD set_agent_goals.
    APPEND INITIAL LINE TO rt_agent_goals ASSIGNING FIELD-SYMBOL(<ls_agent_goal>).
    <ls_agent_goal>-agentgoalid              = 1.
    <ls_agent_goal>-agentgoaldescription     = `Accurate Document Extraction`.
    <ls_agent_goal>-agentgoalpriority        = 1.
    <ls_agent_goal>-agentgoalcontent         = `Extract structured header and item data from delivery documents (CMR) with high accuracy and return JSON matching the expected schema.`.
    <ls_agent_goal>-agentgoalsuccesscriteria = `Extracted JSON validates against schema and contains required header and item fields`.

    APPEND INITIAL LINE TO rt_agent_goals ASSIGNING <ls_agent_goal>.
    <ls_agent_goal>-agentgoalid              = 2.
    <ls_agent_goal>-agentgoaldescription     = `Dangerous Goods Detection`.
    <ls_agent_goal>-agentgoalpriority        = 1.
    <ls_agent_goal>-agentgoalcontent         = `Detect hazardous goods using explicit fields (hazard class, UN number) and free-text indicators; raise alerts for suspect items.`.
    <ls_agent_goal>-agentgoalsuccesscriteria = `All dangerous items are flagged and alerts persisted in the system`.

    APPEND INITIAL LINE TO rt_agent_goals ASSIGNING <ls_agent_goal>.
    <ls_agent_goal>-agentgoalid              = 3.
    <ls_agent_goal>-agentgoaldescription     = `Inbound Delivery Creation`.
    <ls_agent_goal>-agentgoalpriority        = 2.
    <ls_agent_goal>-agentgoalcontent         = `Map extracted CMR data to inbound delivery entities and persist headers and items via RAP; generate delivery IDs.`.
    <ls_agent_goal>-agentgoalsuccesscriteria = `Inbound header and item records are created and returned in the execution context`.

    APPEND INITIAL LINE TO rt_agent_goals ASSIGNING <ls_agent_goal>.
    <ls_agent_goal>-agentgoalid              = 4.
    <ls_agent_goal>-agentgoaldescription     = `Validation and Remediation Guidance`.
    <ls_agent_goal>-agentgoalpriority        = 2.
    <ls_agent_goal>-agentgoalcontent         = `Validate mandatory fields, weights, units and dates; record findings and provide actionable remediation steps for operators.`.
    <ls_agent_goal>-agentgoalsuccesscriteria = `Findings are recorded for invalid or incomplete data and suggested fixes are provided`.
  ENDMETHOD.

  METHOD set_agent_restrictions.
    APPEND INITIAL LINE TO rt_agent_restrictions ASSIGNING FIELD-SYMBOL(<ls_restriction>).
    <ls_restriction>-agentrestrictionname       = `READ_ONLY_ACCESS`.
    <ls_restriction>-agentrestriction = `This agent only creates and reads CMR, inbound delivery, and warehouse data. It cannot modify or delete past records.`.
    APPEND INITIAL LINE TO rt_agent_restrictions ASSIGNING <ls_restriction>.
    <ls_restriction>-agentrestrictionname       = `NO_FINANCIAL_TRANSACTIONS`.
    <ls_restriction>-agentrestriction = `The agent does not process payments, invoices, or financial transactions.`.
  ENDMETHOD.

  METHOD set_tool_metadata.
    APPEND INITIAL LINE TO rt_tool_metadata ASSIGNING FIELD-SYMBOL(<ls_tool>).
    <ls_tool>-toolname        = `CREATE_CMR`.
    <ls_tool>-tooldesciption  = `Create CMR`.
    <ls_tool>-toolexplanation = `Parse extracted CMR JSON and persist header/items (RAP).`.
    <ls_tool>-tooltype        = zpru_if_adf_type_and_constant=>cs_step_type-abap_code.

    APPEND INITIAL LINE TO rt_tool_metadata ASSIGNING <ls_tool>.
    <ls_tool>-toolname        = `CLASSIFY_DANGER_GOODS`.
    <ls_tool>-tooldesciption  = `Dangerous goods classification`.
    <ls_tool>-toolexplanation = `Detect hazardous goods by fields (hazard class/UN) and free-text heuristics.`.
    <ls_tool>-tooltype        = zpru_if_adf_type_and_constant=>cs_step_type-abap_code.

    APPEND INITIAL LINE TO rt_tool_metadata ASSIGNING <ls_tool>.
    <ls_tool>-toolname        = `VALIDATE_CMR`.
    <ls_tool>-tooldesciption  = `Validate CMR`.
    <ls_tool>-toolexplanation = `Run mandatory field checks, weight/date validations and emit findings.`.
    <ls_tool>-tooltype        = zpru_if_adf_type_and_constant=>cs_step_type-abap_code.

    APPEND INITIAL LINE TO rt_tool_metadata ASSIGNING <ls_tool>.
    <ls_tool>-toolname        = `CREATE_INB_DELIVERY`.
    <ls_tool>-tooldesciption  = `Create Inbound Delivery`.
    <ls_tool>-toolexplanation = `Map CMR headers/items to inbound delivery entities and persist via RAP.`.
    <ls_tool>-tooltype        = zpru_if_adf_type_and_constant=>cs_step_type-abap_code.

    APPEND INITIAL LINE TO rt_tool_metadata ASSIGNING <ls_tool>.
    <ls_tool>-toolname        = `FIND_STORAGE_BIN`.
    <ls_tool>-tooldesciption  = `Find Storage Bin`.
    <ls_tool>-toolexplanation = `Locate suitable storage bins for received items using simple heuristics.`.
    <ls_tool>-tooltype        = zpru_if_adf_type_and_constant=>cs_step_type-abap_code.

    APPEND INITIAL LINE TO rt_tool_metadata ASSIGNING <ls_tool>.
    <ls_tool>-toolname        = `CREATE_WAREHOUSE_TASK`.
    <ls_tool>-tooldesciption  = `Create Warehouse Task`.
    <ls_tool>-toolexplanation = `Generate warehouse tasks (putaway/picking) for inbound items.`.
    <ls_tool>-tooltype        = zpru_if_adf_type_and_constant=>cs_step_type-abap_code.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_syst_prompt_provider IMPLEMENTATION.
  METHOD set_primary_session_task.
    ev_primary_session_task = `Extract structured CMR document data from scanned images and orchestrate the full warehouse workflow: classify dangerous goods, validate fields, create inbound deliveries, find storage bins, and generate warehouse tasks.`.
  ENDMETHOD.

  METHOD set_business_rules.
    APPEND INITIAL LINE TO rt_business_rules ASSIGNING FIELD-SYMBOL(<ls_rule>).
    <ls_rule>-businessrulesname    = `CURRENCY_RULE`.
    <ls_rule>-businessrule = `Always use USD as currency for cash on delivery amounts.`.
    APPEND INITIAL LINE TO rt_business_rules ASSIGNING <ls_rule>.
    <ls_rule>-businessrulesname    = `WEIGHT_UNIT_RULE`.
    <ls_rule>-businessrule = `Use KG as default weight unit and M3 as default volume unit for item dimensions.`.
    APPEND INITIAL LINE TO rt_business_rules ASSIGNING <ls_rule>.
    <ls_rule>-businessrulesname    = `MANDATORY_FIELDS_RULE`.
    <ls_rule>-businessrule = `Sender info, consignee info, carrier info, taking-over place, delivery place, and taking-over date are mandatory for each CMR header. Nature of goods is mandatory for each item.`.
    APPEND INITIAL LINE TO rt_business_rules ASSIGNING <ls_rule>.
    <ls_rule>-businessrulesname    = `DG_COMPLIANCE_RULE`.
    <ls_rule>-businessrule = `Dangerous goods items must have UN number, hazard class, and packing group filled; otherwise flag as finding.`.
  ENDMETHOD.

  METHOD set_format_guidelines.
    APPEND INITIAL LINE TO rt_format_guidelines ASSIGNING FIELD-SYMBOL(<ls_format_guidelines>).
    <ls_format_guidelines>-formatguidelinename = `NO_MARKDOWN_WRAPPERS`.
    <ls_format_guidelines>-formatguideline     = `Return raw JSON or ABAP structures only. Do not include triple backticks, fenced codeblocks, or explanatory text.`.

    APPEND INITIAL LINE TO rt_format_guidelines ASSIGNING <ls_format_guidelines>.
    <ls_format_guidelines>-formatguidelinename = `VALID_JSON_ONLY`.
    <ls_format_guidelines>-formatguideline     = `When JSON is requested, return strictly valid JSON. If you cannot produce valid JSON that matches the schema, return a single-key error object: {"__error__":"reason"}.`.

    APPEND INITIAL LINE TO rt_format_guidelines ASSIGNING <ls_format_guidelines>.
    <ls_format_guidelines>-formatguidelinename = `STRICT_SCHEMA_ADHERENCE`.
    <ls_format_guidelines>-formatguideline     = `Do not add fields not defined in the provided schema. Use the exact field names and types required by the schema.`.

    APPEND INITIAL LINE TO rt_format_guidelines ASSIGNING <ls_format_guidelines>.
    <ls_format_guidelines>-formatguidelinename = `NO_CONVERSATIONAL_TEXT`.
    <ls_format_guidelines>-formatguideline     = `Do not prepend or append conversational phrases ("Here is...", "I think", apologies, or guidance). Output must be the data only.`.

    APPEND INITIAL LINE TO rt_format_guidelines ASSIGNING <ls_format_guidelines>.
    <ls_format_guidelines>-formatguidelinename = `UNITS_AND_NORMALIZATION`.
    <ls_format_guidelines>-formatguideline     = `Use canonical units: currency = USD, weight unit = KG, volume unit = M3. Normalize numeric formats (no thousands separators).`.

    APPEND INITIAL LINE TO rt_format_guidelines ASSIGNING <ls_format_guidelines>.
    <ls_format_guidelines>-formatguidelinename = `MASK_SENSITIVE`.
    <ls_format_guidelines>-formatguideline     = `Mask or omit any sensitive personal data (tax ids, bank account numbers) unless explicit permission is given.`.

    APPEND INITIAL LINE TO rt_format_guidelines ASSIGNING <ls_format_guidelines>.
    <ls_format_guidelines>-formatguidelinename = `ERROR_FORMAT`.
    <ls_format_guidelines>-formatguideline     = `On validation or extraction errors, return a concise machine-readable summary under key \"__error__\" and optionally a \"__details__\" array with field-level issues.`.

    APPEND INITIAL LINE TO rt_format_guidelines ASSIGNING <ls_format_guidelines>.
    <ls_format_guidelines>-formatguidelinename = `LITERAL_FIELD_VALUES`.
    <ls_format_guidelines>-formatguideline     = `When a schema field expects a string, return string values (no null unless allowed). For date fields use YYYY-MM-DD if schema accepts ISO dates.`.
  ENDMETHOD.

  METHOD set_prompt_restrictions.
    APPEND INITIAL LINE TO rt_prompt_restrictions ASSIGNING FIELD-SYMBOL(<ls_restriction>).
    <ls_restriction>-promptrestrictionname    = `NO_HALLUCINATION`.
    <ls_restriction>-promptrestriction = `Do not invent or hallucinate data. If a field cannot be extracted from the document, leave it null or empty.`.
    APPEND INITIAL LINE TO rt_prompt_restrictions ASSIGNING <ls_restriction>.
    <ls_restriction>-promptrestrictionname    = `NO_EXECUTION`.
    <ls_restriction>-promptrestriction = `Do not execute code, make changes, or perform any action outside of the tools provided to you.`.
    APPEND INITIAL LINE TO rt_prompt_restrictions ASSIGNING <ls_restriction>.
    <ls_restriction>-promptrestrictionname    = `ONLY_STRUCTURED_OUTPUT`.
    <ls_restriction>-promptrestriction = `Return only the requested structured data. Do not add any conversational or explanatory text.`.
  ENDMETHOD.

  METHOD set_reasoning_step.
    APPEND INITIAL LINE TO rt_reasoning_step ASSIGNING FIELD-SYMBOL(<ls_step>).
    <ls_step>-reasoningstepname        = `EXTRACT_STRUCTURED_FIELDS`.
    <ls_step>-reasoningstepquestion    = `Can the document be parsed into header and item structures matching the CMR schema?`.
    <ls_step>-reasoninginstruction     = `Identify header blocks and item lines using OCR output; normalize dates to YYYY-MM-DD and units to USD/KG/M3. If fields are ambiguous, mark them as null and continue.`.
    <ls_step>-reasoningstepismandatory = abap_true.

    APPEND INITIAL LINE TO rt_reasoning_step ASSIGNING <ls_step>.
    <ls_step>-reasoningstepname        = `NORMALIZE_UNITS_AND_NUMBERS`.
    <ls_step>-reasoningstepquestion    = `Are currency, weight and volume values present and normalized to canonical units?`.
    <ls_step>-reasoninginstruction     = `Convert currency to USD, weights to KG, volume to M3. Remove thousands separators and ensure numeric fields are numeric; if conversion impossible, flag as finding.`.
    <ls_step>-reasoningstepismandatory = abap_true.

    APPEND INITIAL LINE TO rt_reasoning_step ASSIGNING <ls_step>.
    <ls_step>-reasoningstepname        = `CLASSIFY_DANGEROUS_GOODS`.
    <ls_step>-reasoningstepquestion    = `Do any items indicate dangerous goods via hazard class, UN number, or free-text heuristics?`.
    <ls_step>-reasoninginstruction     = `Check explicit hazard class/UN fields first; then apply text heuristics (e.g., FLAMM, EXPLOS, POISON). Emit alerts for any suspect items.`.
    <ls_step>-reasoningstepismandatory = abap_true.

    APPEND INITIAL LINE TO rt_reasoning_step ASSIGNING <ls_step>.
    <ls_step>-reasoningstepname        = `VALIDATE_MANDATORY_FIELDS`.
    <ls_step>-reasoningstepquestion    = `Are mandatory header fields present (sender, consignee, takingoverdate, deliveryplace)?`.
    <ls_step>-reasoninginstruction     = `Verify presence and format of required fields; create findings entries for missing or malformed values and include remediation suggestions.`.
    <ls_step>-reasoningstepismandatory = abap_true.

    APPEND INITIAL LINE TO rt_reasoning_step ASSIGNING <ls_step>.
    <ls_step>-reasoningstepname        = `OUTPUT_JSON_SCHEMA_CHECK`.
    <ls_step>-reasoningstepquestion    = `Does the final JSON match the provided schema and remain strictly valid JSON?`.
    <ls_step>-reasoninginstruction     = `Ensure output adheres to schema: required arrays/objects exist, types match, and no extra fields are added. If validation fails, return {"__error__":"reason"}.`.
    <ls_step>-reasoningstepismandatory = abap_true.
  ENDMETHOD.

  METHOD set_technical_rules.
    APPEND INITIAL LINE TO rt_tech_rules ASSIGNING FIELD-SYMBOL(<ls_tech_rule>).
    <ls_tech_rule>-technicalrulesname       = `API_TIMEOUT`.
    <ls_tech_rule>-technicalrule = `The Gemini API call may take up to 30 seconds. Handle timeout gracefully.`.
    APPEND INITIAL LINE TO rt_tech_rules ASSIGNING <ls_tech_rule>.
    <ls_tech_rule>-technicalrulesname       = `BASE64_ENCODING`.
    <ls_tech_rule>-technicalrule = `Images must be Base64-encoded before being sent to Gemini API. Use JPEG format.`.
    APPEND INITIAL LINE TO rt_tech_rules ASSIGNING <ls_tech_rule>.
    <ls_tech_rule>-technicalrulesname       = `MAX_IMAGE_SIZE`.
    <ls_tech_rule>-technicalrule = `Each image should not exceed 20 MB after Base64 encoding.`.
  ENDMETHOD.

  METHOD set_arbitrary_text.
    ev_arbitrarytexttitle   = `AGENT_ORIGIN`.
    ev_arbitrarytext = `Developed for SAP S/4HANA warehouse automation scenarios.`.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_create_cmr IMPLEMENTATION.
  METHOD execute_code_int.
    DATA lt_headers_all        TYPE zpru_if_computer_vision=>tt_cmr_header_context.
    DATA lt_items_all          TYPE zpru_if_computer_vision=>tt_cmr_item_context.
    DATA lt_cmr_create_head    TYPE TABLE FOR CREATE zr_pru_cmr_header\\zrprucmrheader.
    DATA lt_cmr_create_item    TYPE TABLE FOR CREATE zr_pru_cmr_header\\zrprucmrheader\_cmritems.
    DATA lt_cmr_header_context TYPE zpru_if_computer_vision=>tt_cmr_header_context.
    DATA lt_cmr_item_context   TYPE zpru_if_computer_vision=>tt_cmr_item_context.
    DATA lt_creation_content   TYPE zpru_if_computer_vision=>tt_cmr_create_content.

    FIELD-SYMBOLS <ls_cmr_create> TYPE zpru_if_computer_vision=>ts_cmr_create_request.

    ASSIGN is_input->* TO <ls_cmr_create>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.
    /ui2/cl_json=>deserialize( EXPORTING json = <ls_cmr_create>-cmrcreationcontent
                                         hex_as_base64 = abap_false
                               CHANGING  data = lt_creation_content ).

    LOOP AT lt_creation_content ASSIGNING FIELD-SYMBOL(<ls_cmrcreationcontent>).
      lt_headers_all = CORRESPONDING #( BASE ( lt_headers_all ) <ls_cmrcreationcontent>-cmrheaders ).
      lt_items_all = CORRESPONDING #( BASE ( lt_items_all ) <ls_cmrcreationcontent>-cmritems ).
    ENDLOOP.

    SELECT MAX( cmrid ) FROM zr_pru_cmr_header
      INTO @DATA(lv_max_cmrid).

    DATA(lv_next_cmrid_num) = CONV i( lv_max_cmrid ) + 1.

    LOOP AT lt_headers_all ASSIGNING FIELD-SYMBOL(<ls_header_cmrid>).
      <ls_header_cmrid>-cmrid = lv_next_cmrid_num.

      LOOP AT lt_items_all ASSIGNING FIELD-SYMBOL(<ls_item_cmrid>)
           WHERE cmruuid = <ls_header_cmrid>-cmruuid. " qqq cmruuid is empty
        <ls_item_cmrid>-cmrid = <ls_header_cmrid>-cmrid.
      ENDLOOP.

      lv_next_cmrid_num += 1.
    ENDLOOP.

    DATA(lv_item_cid) = 1.
    LOOP AT lt_headers_all ASSIGNING FIELD-SYMBOL(<ls_header>).

      APPEND INITIAL LINE TO lt_cmr_create_head ASSIGNING FIELD-SYMBOL(<ls_cmr_create_head>).
      <ls_cmr_create_head> = CORRESPONDING #( <ls_header> MAPPING TO ENTITY CHANGING CONTROL ).
      <ls_cmr_create_head>-%cid = '1'.
      CLEAR: <ls_cmr_create_head>-cmruuid,
             <ls_cmr_create_head>-%control-cmruuid.
      LOOP AT lt_items_all ASSIGNING FIELD-SYMBOL(<ls_item>)
           WHERE cmruuid = <ls_header>-cmruuid.
        APPEND INITIAL LINE TO lt_cmr_create_item ASSIGNING FIELD-SYMBOL(<ls_cmr_create_item>).
        <ls_cmr_create_item>-%cid_ref = '1'.
        APPEND INITIAL LINE TO <ls_cmr_create_item>-%target ASSIGNING FIELD-SYMBOL(<ls_cmr_item_target>).
        <ls_cmr_item_target> = CORRESPONDING #( <ls_item> MAPPING TO ENTITY CHANGING CONTROL ).
        <ls_cmr_item_target>-%cid = lv_item_cid.
        CLEAR: <ls_cmr_item_target>-cmruuid,
               <ls_cmr_item_target>-%control-cmruuid.

        lv_item_cid += 1.
      ENDLOOP.
    ENDLOOP.

    IF lt_cmr_create_head IS INITIAL.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    MODIFY ENTITIES OF zr_pru_cmr_header
           ENTITY zrprucmrheader
           CREATE FROM lt_cmr_create_head
           ENTITY zrprucmrheader
           CREATE BY \_cmritems
           FROM lt_cmr_create_item
           MAPPED DATA(ls_mapped)
           FAILED DATA(ls_failed)
           " TODO: variable is assigned but never used (ABAP cleaner)
           REPORTED DATA(ls_reported).

    IF ls_failed IS NOT INITIAL.
      ev_error_flag = abap_true.
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_cmr_header
         ENTITY zrprucmrheader
         ALL FIELDS WITH CORRESPONDING #( ls_mapped-zrprucmrheader )
         RESULT DATA(lt_new_cmr_headers).

    READ ENTITIES OF zr_pru_cmr_header
         ENTITY zrprucmritem
         ALL FIELDS WITH CORRESPONDING #( ls_mapped-zrprucmritem )
         RESULT DATA(lt_new_cmr_items).

    lt_cmr_header_context = CORRESPONDING #( lt_new_cmr_headers MAPPING FROM ENTITY ).
    lt_cmr_item_context = CORRESPONDING #( lt_new_cmr_items MAPPING FROM ENTITY ).

    APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_key_value>).
    <ls_key_value>-name  = zpru_if_computer_vision=>cs_context_field-cmrheaders-field_name.
    <ls_key_value>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_key_value>-value = /ui2/cl_json=>serialize( data          = lt_cmr_header_context
                                                    hex_as_base64 = abap_false
                                                    compress      = abap_true ).

    APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING <ls_key_value>.
    <ls_key_value>-name  = zpru_if_computer_vision=>cs_context_field-cmritems-field_name.
    <ls_key_value>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_key_value>-value = /ui2/cl_json=>serialize( data          = lt_cmr_item_context
                                                    hex_as_base64 = abap_false
                                                    compress      = abap_true ).

    APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING <ls_key_value>.
    <ls_key_value>-name  = zpru_if_computer_vision=>cs_context_field-cmrcreationcontent-field_name.
    <ls_key_value>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_key_value>-value = /ui2/cl_json=>serialize( data          = lt_creation_content
                                                    hex_as_base64 = abap_false
                                                    compress      = abap_true ).

    es_output = NEW zpru_tt_key_value( et_key_value_pairs ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_classify_danger_goods IMPLEMENTATION.
  METHOD execute_code_int.
    DATA lv_nature_up         TYPE string.
    DATA lv_is_danger         TYPE abap_bool.
    DATA lv_reason            TYPE string.
    DATA lt_alert_rap         TYPE TABLE FOR CREATE zr_pru_cmr_alert\\zrprucmralert.
    DATA lt_cmr_item_context  TYPE zpru_if_computer_vision=>tt_cmr_item_context.
    DATA lt_cmr_alert_context TYPE STANDARD TABLE OF zpru_cmr_alert WITH EMPTY KEY.

    FIELD-SYMBOLS <ls_input> TYPE zpru_if_computer_vision=>ts_cmr_classify_req.

    ASSIGN is_input->* TO <ls_input>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-cmritems
                                         hex_as_base64 = abap_false
                               CHANGING  data          = lt_cmr_item_context ).

    IF lt_cmr_item_context IS INITIAL.
      APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv_empty>).
      <ls_kv_empty>-name  = zpru_if_computer_vision=>cs_context_field-cmralerts-field_name.
      <ls_kv_empty>-value = ``.
      RETURN.
    ENDIF.

    DATA(lv_count) = 0.
    LOOP AT lt_cmr_item_context ASSIGNING FIELD-SYMBOL(<ls_item>).
      CLEAR: lv_is_danger,
             lv_reason.

      lv_count += 1.

      IF <ls_item>-hazardclass IS NOT INITIAL.
        lv_is_danger = abap_true.
        lv_reason = |Hazard class { <ls_item>-hazardclass } detected|.
      ENDIF.
      IF lv_is_danger = abap_false AND <ls_item>-unitednationnumber IS NOT INITIAL.
        lv_is_danger = abap_true.
        lv_reason = |UN number { <ls_item>-unitednationnumber } present|.
      ENDIF.

      IF lv_is_danger = abap_false.
        lv_nature_up = to_upper( <ls_item>-natureofgoods ).

        IF lv_nature_up CS 'EXPLOS'.
          lv_is_danger = abap_true.
          lv_reason = 'Explosive material detected in nature of goods'.
        ENDIF.

        IF lv_is_danger = abap_false AND (    lv_nature_up CS 'FLAMMABLE GAS'
                                           OR lv_nature_up CS 'INFLAMMABLE GAS'
                                           OR lv_nature_up CS 'LPG'
                                           OR lv_nature_up CS 'LNG'
                                           OR lv_nature_up CS 'COMPRESSED GAS'
                                           OR lv_nature_up CS 'PROPANE'
                                           OR lv_nature_up CS 'BUTANE'
                                           OR lv_nature_up CS 'ACETYLENE'
                                           OR lv_nature_up CS 'HYDROGEN' ).
          lv_is_danger = abap_true.
          lv_reason = 'Flammable gas detected in nature of goods'.
        ENDIF.

        IF lv_is_danger = abap_false AND (    lv_nature_up CS 'FLAMMABLE LIQUID'
                                           OR lv_nature_up CS 'INFLAMMABLE LIQUID'
                                           OR lv_nature_up CS 'PETROL'
                                           OR lv_nature_up CS 'GASOLINE'
                                           OR lv_nature_up CS 'DIESEL'
                                           OR lv_nature_up CS 'KEROSENE'
                                           OR lv_nature_up CS 'ETHANOL'
                                           OR lv_nature_up CS 'METHANOL'
                                           OR lv_nature_up CS 'ACETONE'
                                           OR lv_nature_up CS 'BENZENE'
                                           OR lv_nature_up CS 'TOLUENE'
                                           OR lv_nature_up CS 'FUEL OIL' ).
          lv_is_danger = abap_true.
          lv_reason = 'Flammable liquid detected in nature of goods'.
        ENDIF.

        IF lv_is_danger = abap_false AND (    lv_nature_up CS 'FLAMMABLE SOLID'
                                           OR lv_nature_up CS 'INFLAMMABLE SOLID'
                                           OR lv_nature_up CS 'PHOSPHORUS'
                                           OR lv_nature_up CS 'SULPHUR'
                                           OR lv_nature_up CS 'SULFUR'
                                           OR lv_nature_up CS 'MAGNESIUM'
                                           OR lv_nature_up CS 'ALUMINIUM POWDER'
                                           OR lv_nature_up CS 'ALUMINUM POWDER' ).
          lv_is_danger = abap_true.
          lv_reason = 'Flammable solid detected in nature of goods'.
        ENDIF.

        IF lv_is_danger = abap_false AND (    lv_nature_up CS 'OXIDIS'
                                           OR lv_nature_up CS 'OXIDIZ'
                                           OR lv_nature_up CS 'PEROXIDE'
                                           OR lv_nature_up CS 'PERMANGANATE'
                                           OR lv_nature_up CS 'CHLORATE'
                                           OR lv_nature_up CS 'NITRATE'
                                           OR lv_nature_up CS 'PERCHLORATE' ).
          lv_is_danger = abap_true.
          lv_reason = 'Oxidiser/organic peroxide detected in nature of goods'.
        ENDIF.

        IF lv_is_danger = abap_false AND (    lv_nature_up CS 'TOXIC'
                                           OR lv_nature_up CS 'POISON'
                                           OR lv_nature_up CS 'PESTICIDE'
                                           OR lv_nature_up CS 'HERBICIDE'
                                           OR lv_nature_up CS 'INSECTICIDE'
                                           OR lv_nature_up CS 'CYANIDE'
                                           OR lv_nature_up CS 'ARSENIC'
                                           OR lv_nature_up CS 'MERCURY'
                                           OR lv_nature_up CS 'CHLORINE'
                                           OR lv_nature_up CS 'AMMONIA'
                                           OR lv_nature_up CS 'FORMALDEHYDE' ).
          lv_is_danger = abap_true.
          lv_reason = 'Toxic substance detected in nature of goods'.
        ENDIF.

        IF lv_is_danger = abap_false AND (    lv_nature_up CS 'INFECTIOUS'
                                           OR lv_nature_up CS 'PATHOGEN'
                                           OR lv_nature_up CS 'CLINICAL WASTE'
                                           OR lv_nature_up CS 'MEDICAL WASTE' ).
          lv_is_danger = abap_true.
          lv_reason = 'Infectious substance detected in nature of goods'.
        ENDIF.

        IF lv_is_danger = abap_false AND (    lv_nature_up CS 'RADIOACT'
                                           OR lv_nature_up CS 'NUCLEAR'
                                           OR lv_nature_up CS 'URANIUM'
                                           OR lv_nature_up CS 'PLUTONIUM'
                                           OR lv_nature_up CS 'ISOTOPE' ).
          lv_is_danger = abap_true.
          lv_reason = 'Radioactive material detected in nature of goods'.
        ENDIF.

        IF lv_is_danger = abap_false AND (    lv_nature_up CS 'CORROSIVE'
                                           OR lv_nature_up CS 'ACID'
                                           OR lv_nature_up CS 'CAUSTIC'
                                           OR lv_nature_up CS 'SULPHURIC'
                                           OR lv_nature_up CS 'SULFURIC'
                                           OR lv_nature_up CS 'HYDROCHLORIC'
                                           OR lv_nature_up CS 'SODIUM HYDROXIDE'
                                           OR lv_nature_up CS 'POTASSIUM HYDROXIDE'
                                           OR lv_nature_up CS 'BLEACH' ).
          lv_is_danger = abap_true.
          lv_reason = 'Corrosive substance detected in nature of goods'.
        ENDIF.

        IF lv_is_danger = abap_false AND (    lv_nature_up CS 'DANGEROUS GOODS'
                                           OR lv_nature_up CS 'HAZARDOUS'
                                           OR lv_nature_up CS 'LITHIUM BATTER'
                                           OR lv_nature_up CS 'DRY ICE'
                                           OR lv_nature_up CS 'MAGNETIS' ).
          lv_is_danger = abap_true.
          lv_reason = 'Hazardous material detected in nature of goods'.
        ENDIF.
      ENDIF.

      IF lv_is_danger = abap_true.
        APPEND INITIAL LINE TO lt_alert_rap ASSIGNING FIELD-SYMBOL(<ls_alert_rap>).
        TRY.
            <ls_alert_rap>-alertuuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.

        <ls_alert_rap>-%cid          = |ALERT{ lv_count }|.
        <ls_alert_rap>-cmruuid       = <ls_item>-cmruuid.
        <ls_alert_rap>-cmrid         = <ls_item>-cmrid.
        <ls_alert_rap>-cmritemuuid   = <ls_item>-cmritemuuid.
        <ls_alert_rap>-itemposition  = <ls_item>-itemposition.
        <ls_alert_rap>-natureofgoods = <ls_item>-natureofgoods.
        <ls_alert_rap>-alerttype     = 'DANGER_GOODS'.
        <ls_alert_rap>-alertmessage  = lv_reason.

        <ls_alert_rap>-%control      = VALUE #( alertuuid     = if_abap_behv=>mk-on
                                                cmruuid       = if_abap_behv=>mk-on
                                                cmrid         = if_abap_behv=>mk-on
                                                cmritemuuid   = if_abap_behv=>mk-on
                                                itemposition  = if_abap_behv=>mk-on
                                                natureofgoods = if_abap_behv=>mk-on
                                                alerttype     = if_abap_behv=>mk-on
                                                alertmessage  = if_abap_behv=>mk-on ).

      ENDIF.
    ENDLOOP.

    IF lt_alert_rap IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_pru_cmr_alert
           ENTITY zrprucmralert
           CREATE FROM lt_alert_rap
           MAPPED DATA(ls_mapped_alert)
           FAILED DATA(ls_failed_alert).

    IF ls_failed_alert-zrprucmralert IS NOT INITIAL.
      ev_error_flag = abap_true.
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_cmr_alert
         ENTITY zrprucmralert
         ALL FIELDS WITH CORRESPONDING #( ls_mapped_alert-zrprucmralert )
         RESULT DATA(lt_alert_create).

    lt_cmr_alert_context = CORRESPONDING #( lt_alert_create MAPPING FROM ENTITY ).

    APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv>).
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-cmralerts-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = lt_cmr_alert_context
                                             hex_as_base64 = abap_false
                                             compress      = abap_true ).

    es_output = NEW zpru_tt_key_value( et_key_value_pairs ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_validate_cmr IMPLEMENTATION.
  METHOD execute_code_int.
    DATA lt_headers      TYPE zpru_if_computer_vision=>tt_cmr_header_context.
    DATA lt_items        TYPE zpru_if_computer_vision=>tt_cmr_item_context.
    DATA lt_alerts       TYPE zpru_if_computer_vision=>tt_cmr_alert_context.
    DATA lt_findings_rap TYPE TABLE FOR CREATE zr_pru_cmr_valid\\zrprucmrvalid.
    DATA lt_findings_out TYPE zpru_if_computer_vision=>tt_cmr_finding.
    DATA lt_cmr_status   TYPE zpru_if_computer_vision=>tt_cmr_overall_status.
    DATA ls_finding_out  TYPE zpru_if_computer_vision=>ts_cmr_finding.
    DATA lv_cid_counter  TYPE i VALUE 1.

    FIELD-SYMBOLS <ls_input> TYPE zpru_if_computer_vision=>ts_cmr_validate_req.

    ASSIGN is_input->* TO <ls_input>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-cmrheaders
                                         hex_as_base64 = abap_false
                               CHANGING  data          = lt_headers ).
    /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-cmritems
                                         hex_as_base64 = abap_false
                               CHANGING  data          = lt_items ).

    LOOP AT lt_headers ASSIGNING FIELD-SYMBOL(<ls_hdr>).

      IF <ls_hdr>-senderinfo IS INITIAL.
        CLEAR ls_finding_out.
        APPEND INITIAL LINE TO lt_findings_rap ASSIGNING FIELD-SYMBOL(<ls_finding_rap>).

        TRY.
            <ls_finding_rap>-findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.

        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
        <ls_finding_rap>-findingtype   = 'MANDATORY_FIELD'.
        <ls_finding_rap>-fieldname     = 'SENDERINFO'.
        <ls_finding_rap>-findingmsg    = 'Sender information is missing'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid     = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                             cmruuid       = if_abap_behv=>mk-on
                                             cmrid         = if_abap_behv=>mk-on
                                             findingstatus = if_abap_behv=>mk-on
                                             findingtype   = if_abap_behv=>mk-on
                                             fieldname     = if_abap_behv=>mk-on
                                             findingmsg    = if_abap_behv=>mk-on
                                             createdby     = if_abap_behv=>mk-on
                                             createdat     = if_abap_behv=>mk-on ).
        lv_cid_counter += 1.
        MOVE-CORRESPONDING <ls_finding_rap> TO ls_finding_out.
        APPEND ls_finding_out TO lt_findings_out.
      ENDIF.

      IF <ls_hdr>-consigneeinfo IS INITIAL.
        CLEAR ls_finding_out.
        APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
        TRY.
            <ls_finding_rap>-findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.
        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
        <ls_finding_rap>-findingtype   = 'MANDATORY_FIELD'.
        <ls_finding_rap>-fieldname     = 'CONSIGNEEINFO'.
        <ls_finding_rap>-findingmsg    = 'Consignee information is missing'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid     = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                             cmruuid       = if_abap_behv=>mk-on
                                             cmrid         = if_abap_behv=>mk-on
                                             findingstatus = if_abap_behv=>mk-on
                                             findingtype   = if_abap_behv=>mk-on
                                             fieldname     = if_abap_behv=>mk-on
                                             findingmsg    = if_abap_behv=>mk-on
                                             createdby     = if_abap_behv=>mk-on
                                             createdat     = if_abap_behv=>mk-on ).
        lv_cid_counter += 1.
        MOVE-CORRESPONDING <ls_finding_rap> TO ls_finding_out.
        APPEND ls_finding_out TO lt_findings_out.
      ENDIF.

      IF <ls_hdr>-carrierinfo IS INITIAL.
        CLEAR ls_finding_out.
        APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
        TRY.
            <ls_finding_rap>-findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.
        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
        <ls_finding_rap>-findingtype   = 'MANDATORY_FIELD'.
        <ls_finding_rap>-fieldname     = 'CARRIERINFO'.
        <ls_finding_rap>-findingmsg    = 'Carrier information is missing'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid     = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                             cmruuid       = if_abap_behv=>mk-on
                                             cmrid         = if_abap_behv=>mk-on
                                             findingstatus = if_abap_behv=>mk-on
                                             findingtype   = if_abap_behv=>mk-on
                                             fieldname     = if_abap_behv=>mk-on
                                             findingmsg    = if_abap_behv=>mk-on
                                             createdby     = if_abap_behv=>mk-on
                                             createdat     = if_abap_behv=>mk-on ).
        lv_cid_counter += 1.
        MOVE-CORRESPONDING <ls_finding_rap> TO ls_finding_out.
        APPEND ls_finding_out TO lt_findings_out.
      ENDIF.

      IF <ls_hdr>-takingoverplace IS INITIAL.
        CLEAR ls_finding_out.
        APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
        TRY.
            <ls_finding_rap>-findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.
        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
        <ls_finding_rap>-findingtype   = 'MANDATORY_FIELD'.
        <ls_finding_rap>-fieldname     = 'TAKINGOVERPLACE'.
        <ls_finding_rap>-findingmsg    = 'Taking-over place is missing'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid     = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                             cmruuid       = if_abap_behv=>mk-on
                                             cmrid         = if_abap_behv=>mk-on
                                             findingstatus = if_abap_behv=>mk-on
                                             findingtype   = if_abap_behv=>mk-on
                                             fieldname     = if_abap_behv=>mk-on
                                             findingmsg    = if_abap_behv=>mk-on
                                             createdby     = if_abap_behv=>mk-on
                                             createdat     = if_abap_behv=>mk-on ).
        lv_cid_counter += 1.
        MOVE-CORRESPONDING <ls_finding_rap> TO ls_finding_out.
        APPEND ls_finding_out TO lt_findings_out.
      ENDIF.

      IF <ls_hdr>-deliveryplace IS INITIAL.
        CLEAR ls_finding_out.
        APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
        TRY.
            <ls_finding_rap>-findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.
        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
        <ls_finding_rap>-findingtype   = 'MANDATORY_FIELD'.
        <ls_finding_rap>-fieldname     = 'DELIVERYPLACE'.
        <ls_finding_rap>-findingmsg    = 'Delivery place is missing'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid     = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                             cmruuid       = if_abap_behv=>mk-on
                                             cmrid         = if_abap_behv=>mk-on
                                             findingstatus = if_abap_behv=>mk-on
                                             findingtype   = if_abap_behv=>mk-on
                                             fieldname     = if_abap_behv=>mk-on
                                             findingmsg    = if_abap_behv=>mk-on
                                             createdby     = if_abap_behv=>mk-on
                                             createdat     = if_abap_behv=>mk-on ).
        lv_cid_counter += 1.
        MOVE-CORRESPONDING <ls_finding_rap> TO ls_finding_out.
        APPEND ls_finding_out TO lt_findings_out.
      ENDIF.

      IF <ls_hdr>-takingoverdate IS INITIAL OR <ls_hdr>-takingoverdate = '00000000'.
        CLEAR ls_finding_out.
        APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
        TRY.
            <ls_finding_rap>-findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.
        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
        <ls_finding_rap>-findingtype   = 'DATE_CHECK'.
        <ls_finding_rap>-fieldname     = 'TAKINGOVERDATE'.
        <ls_finding_rap>-findingmsg    = 'Taking-over date is missing'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid     = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                             cmruuid       = if_abap_behv=>mk-on
                                             cmrid         = if_abap_behv=>mk-on
                                             findingstatus = if_abap_behv=>mk-on
                                             findingtype   = if_abap_behv=>mk-on
                                             fieldname     = if_abap_behv=>mk-on
                                             findingmsg    = if_abap_behv=>mk-on
                                             createdby     = if_abap_behv=>mk-on
                                             createdat     = if_abap_behv=>mk-on ).
        lv_cid_counter += 1.
        MOVE-CORRESPONDING <ls_finding_rap> TO ls_finding_out.
        APPEND ls_finding_out TO lt_findings_out.
      ENDIF.

      IF <ls_hdr>-cashondelivery > 0 AND <ls_hdr>-currency IS INITIAL.
        CLEAR ls_finding_out.
        APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
        TRY.
            <ls_finding_rap>-findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.
        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
        <ls_finding_rap>-findingtype   = 'MANDATORY_FIELD'.
        <ls_finding_rap>-fieldname     = 'CURRENCY'.
        <ls_finding_rap>-findingmsg    = 'Currency required when cash on delivery is set'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid     = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                             cmruuid       = if_abap_behv=>mk-on
                                             cmrid         = if_abap_behv=>mk-on
                                             findingstatus = if_abap_behv=>mk-on
                                             findingtype   = if_abap_behv=>mk-on
                                             fieldname     = if_abap_behv=>mk-on
                                             findingmsg    = if_abap_behv=>mk-on
                                             createdby     = if_abap_behv=>mk-on
                                             createdat     = if_abap_behv=>mk-on ).
        lv_cid_counter += 1.
        MOVE-CORRESPONDING <ls_finding_rap> TO ls_finding_out.
        APPEND ls_finding_out TO lt_findings_out.
      ENDIF.

      DATA(lv_item_count) = REDUCE i( INIT n = 0
                                      FOR <it> IN lt_items
                                      WHERE ( cmruuid = <ls_hdr>-cmruuid )
                                      NEXT n = n + 1 ).
      IF lv_item_count = 0.
        CLEAR ls_finding_out.
        APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
        TRY.
            <ls_finding_rap>-findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.
        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INVALID'.
        <ls_finding_rap>-findingtype   = 'ITEM_COUNT'.
        <ls_finding_rap>-fieldname     = ''.
        <ls_finding_rap>-findingmsg    = 'No items found for CMR'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid     = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                             cmruuid       = if_abap_behv=>mk-on
                                             cmrid         = if_abap_behv=>mk-on
                                             findingstatus = if_abap_behv=>mk-on
                                             findingtype   = if_abap_behv=>mk-on
                                             fieldname     = if_abap_behv=>mk-on
                                             findingmsg    = if_abap_behv=>mk-on
                                             createdby     = if_abap_behv=>mk-on
                                             createdat     = if_abap_behv=>mk-on ).
        lv_cid_counter += 1.
        MOVE-CORRESPONDING <ls_finding_rap> TO ls_finding_out.
        APPEND ls_finding_out TO lt_findings_out.
      ENDIF.

      LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_item>)
           WHERE cmruuid = <ls_hdr>-cmruuid.

        IF <ls_item>-natureofgoods IS INITIAL.
          CLEAR ls_finding_out.
          APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
          TRY.
              <ls_finding_rap>-findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
            CATCH cx_uuid_error.
          ENDTRY.
          <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
          <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
          <ls_finding_rap>-cmritemuuid   = <ls_item>-cmritemuuid.
          <ls_finding_rap>-itemposition  = <ls_item>-itemposition.
          <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
          <ls_finding_rap>-findingtype   = 'MANDATORY_FIELD'.
          <ls_finding_rap>-fieldname     = 'NATUREOFGOODS'.
          <ls_finding_rap>-findingmsg    = |Nature of goods is missing for item { <ls_item>-itemposition }|.
          <ls_finding_rap>-createdby     = sy-uname.
          GET TIME STAMP FIELD <ls_finding_rap>-createdat.
          <ls_finding_rap>-%cid     = |FIND{ lv_cid_counter }|.
          <ls_finding_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                               cmruuid       = if_abap_behv=>mk-on
                                               cmrid         = if_abap_behv=>mk-on
                                               cmritemuuid   = if_abap_behv=>mk-on
                                               itemposition  = if_abap_behv=>mk-on
                                               findingstatus = if_abap_behv=>mk-on
                                               findingtype   = if_abap_behv=>mk-on
                                               fieldname     = if_abap_behv=>mk-on
                                               findingmsg    = if_abap_behv=>mk-on
                                               createdby     = if_abap_behv=>mk-on
                                               createdat     = if_abap_behv=>mk-on ).
          lv_cid_counter += 1.
          MOVE-CORRESPONDING <ls_finding_rap> TO ls_finding_out.
          APPEND ls_finding_out TO lt_findings_out.
        ENDIF.

        IF <ls_item>-grossweight <= 0.
          CLEAR ls_finding_out.
          APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
          TRY.
              <ls_finding_rap>-findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
            CATCH cx_uuid_error.
          ENDTRY.
          <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
          <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
          <ls_finding_rap>-cmritemuuid   = <ls_item>-cmritemuuid.
          <ls_finding_rap>-itemposition  = <ls_item>-itemposition.
          <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
          <ls_finding_rap>-findingtype   = 'WEIGHT_CHECK'.
          <ls_finding_rap>-fieldname     = 'GROSSWEIGHT'.
          <ls_finding_rap>-findingmsg    = |Gross weight must be greater than zero for item { <ls_item>-itemposition }|.
          <ls_finding_rap>-createdby     = sy-uname.
          GET TIME STAMP FIELD <ls_finding_rap>-createdat.
          <ls_finding_rap>-%cid     = |FIND{ lv_cid_counter }|.
          <ls_finding_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                               cmruuid       = if_abap_behv=>mk-on
                                               cmrid         = if_abap_behv=>mk-on
                                               cmritemuuid   = if_abap_behv=>mk-on
                                               itemposition  = if_abap_behv=>mk-on
                                               findingstatus = if_abap_behv=>mk-on
                                               findingtype   = if_abap_behv=>mk-on
                                               fieldname     = if_abap_behv=>mk-on
                                               findingmsg    = if_abap_behv=>mk-on
                                               createdby     = if_abap_behv=>mk-on
                                               createdat     = if_abap_behv=>mk-on ).
          lv_cid_counter += 1.
          MOVE-CORRESPONDING <ls_finding_rap> TO ls_finding_out.
          APPEND ls_finding_out TO lt_findings_out.
        ENDIF.

        IF <ls_item>-weightunitfield IS INITIAL.
          CLEAR ls_finding_out.
          APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
          TRY.
              <ls_finding_rap>-findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
            CATCH cx_uuid_error.
          ENDTRY.
          <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
          <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
          <ls_finding_rap>-cmritemuuid   = <ls_item>-cmritemuuid.
          <ls_finding_rap>-itemposition  = <ls_item>-itemposition.
          <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
          <ls_finding_rap>-findingtype   = 'MANDATORY_FIELD'.
          <ls_finding_rap>-fieldname     = 'WEIGHTUNITFIELD'.
          <ls_finding_rap>-findingmsg    = |Weight unit is missing for item { <ls_item>-itemposition }|.
          <ls_finding_rap>-createdby     = sy-uname.
          GET TIME STAMP FIELD <ls_finding_rap>-createdat.
          <ls_finding_rap>-%cid     = |FIND{ lv_cid_counter }|.
          <ls_finding_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                               cmruuid       = if_abap_behv=>mk-on
                                               cmrid         = if_abap_behv=>mk-on
                                               cmritemuuid   = if_abap_behv=>mk-on
                                               itemposition  = if_abap_behv=>mk-on
                                               findingstatus = if_abap_behv=>mk-on
                                               findingtype   = if_abap_behv=>mk-on
                                               fieldname     = if_abap_behv=>mk-on
                                               findingmsg    = if_abap_behv=>mk-on
                                               createdby     = if_abap_behv=>mk-on
                                               createdat     = if_abap_behv=>mk-on ).
          lv_cid_counter += 1.
          MOVE-CORRESPONDING <ls_finding_rap> TO ls_finding_out.
          APPEND ls_finding_out TO lt_findings_out.
        ENDIF.

        IF line_exists( lt_alerts[ cmritemuuid = <ls_item>-cmritemuuid ] ).
          IF <ls_item>-unitednationnumber IS INITIAL.
            CLEAR ls_finding_out.
            APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
            TRY.
                <ls_finding_rap>-findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
              CATCH cx_uuid_error.
            ENDTRY.
            <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
            <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
            <ls_finding_rap>-cmritemuuid   = <ls_item>-cmritemuuid.
            <ls_finding_rap>-itemposition  = <ls_item>-itemposition.
            <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
            <ls_finding_rap>-findingtype   = 'DG_FIELDS'.
            <ls_finding_rap>-fieldname     = 'UNITEDNATIONNUMBER'.
            <ls_finding_rap>-findingmsg    = |UN number required for dangerous goods item { <ls_item>-itemposition }|.
            <ls_finding_rap>-createdby     = sy-uname.
            GET TIME STAMP FIELD <ls_finding_rap>-createdat.
            <ls_finding_rap>-%cid     = |FIND{ lv_cid_counter }|.
            <ls_finding_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                                 cmruuid       = if_abap_behv=>mk-on
                                                 cmrid         = if_abap_behv=>mk-on
                                                 cmritemuuid   = if_abap_behv=>mk-on
                                                 itemposition  = if_abap_behv=>mk-on
                                                 findingstatus = if_abap_behv=>mk-on
                                                 findingtype   = if_abap_behv=>mk-on
                                                 fieldname     = if_abap_behv=>mk-on
                                                 findingmsg    = if_abap_behv=>mk-on
                                                 createdby     = if_abap_behv=>mk-on
                                                 createdat     = if_abap_behv=>mk-on ).
            lv_cid_counter += 1.
            MOVE-CORRESPONDING <ls_finding_rap> TO ls_finding_out.
            APPEND ls_finding_out TO lt_findings_out.
          ENDIF.

          IF <ls_item>-hazardclass IS INITIAL.
            CLEAR ls_finding_out.
            APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
            TRY.
                <ls_finding_rap>-findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
              CATCH cx_uuid_error.
            ENDTRY.
            <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
            <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
            <ls_finding_rap>-cmritemuuid   = <ls_item>-cmritemuuid.
            <ls_finding_rap>-itemposition  = <ls_item>-itemposition.
            <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
            <ls_finding_rap>-findingtype   = 'DG_FIELDS'.
            <ls_finding_rap>-fieldname     = 'HAZARDCLASS'.
            <ls_finding_rap>-findingmsg    = |Hazard class required for dangerous goods item { <ls_item>-itemposition }|.
            <ls_finding_rap>-createdby     = sy-uname.
            GET TIME STAMP FIELD <ls_finding_rap>-createdat.
            <ls_finding_rap>-%cid     = |FIND{ lv_cid_counter }|.
            <ls_finding_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                                 cmruuid       = if_abap_behv=>mk-on
                                                 cmrid         = if_abap_behv=>mk-on
                                                 cmritemuuid   = if_abap_behv=>mk-on
                                                 itemposition  = if_abap_behv=>mk-on
                                                 findingstatus = if_abap_behv=>mk-on
                                                 findingtype   = if_abap_behv=>mk-on
                                                 fieldname     = if_abap_behv=>mk-on
                                                 findingmsg    = if_abap_behv=>mk-on
                                                 createdby     = if_abap_behv=>mk-on
                                                 createdat     = if_abap_behv=>mk-on ).
            lv_cid_counter += 1.
            MOVE-CORRESPONDING <ls_finding_rap> TO ls_finding_out.
            APPEND ls_finding_out TO lt_findings_out.
          ENDIF.

          IF <ls_item>-packinggroup IS INITIAL.
            CLEAR ls_finding_out.
            APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
            TRY.
                <ls_finding_rap>-findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
              CATCH cx_uuid_error.
            ENDTRY.
            <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
            <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
            <ls_finding_rap>-cmritemuuid   = <ls_item>-cmritemuuid.
            <ls_finding_rap>-itemposition  = <ls_item>-itemposition.
            <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
            <ls_finding_rap>-findingtype   = 'DG_FIELDS'.
            <ls_finding_rap>-fieldname     = 'PACKINGGROUP'.
            <ls_finding_rap>-findingmsg    = |Packing group required for dangerous goods item { <ls_item>-itemposition }|.
            <ls_finding_rap>-createdby     = sy-uname.
            GET TIME STAMP FIELD <ls_finding_rap>-createdat.
            <ls_finding_rap>-%cid     = |FIND{ lv_cid_counter }|.
            <ls_finding_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                                 cmruuid       = if_abap_behv=>mk-on
                                                 cmrid         = if_abap_behv=>mk-on
                                                 cmritemuuid   = if_abap_behv=>mk-on
                                                 itemposition  = if_abap_behv=>mk-on
                                                 findingstatus = if_abap_behv=>mk-on
                                                 findingtype   = if_abap_behv=>mk-on
                                                 fieldname     = if_abap_behv=>mk-on
                                                 findingmsg    = if_abap_behv=>mk-on
                                                 createdby     = if_abap_behv=>mk-on
                                                 createdat     = if_abap_behv=>mk-on ).
            lv_cid_counter += 1.
            MOVE-CORRESPONDING <ls_finding_rap> TO ls_finding_out.
            APPEND ls_finding_out TO lt_findings_out.
          ENDIF.
        ENDIF.

      ENDLOOP.

      APPEND INITIAL LINE TO lt_cmr_status ASSIGNING FIELD-SYMBOL(<ls_status>).
      <ls_status>-cmruuid = <ls_hdr>-cmruuid.
      <ls_status>-cmrid   = <ls_hdr>-cmrid.

      IF line_exists( lt_findings_out[ cmruuid       = <ls_hdr>-cmruuid
                                       findingstatus = 'INVALID' ] ).
        <ls_status>-overallstatus = 'INVALID'.
      ELSE.
        IF line_exists( lt_findings_out[ cmruuid = <ls_hdr>-cmruuid ] ).
          <ls_status>-overallstatus = 'INCOMPLETE'.
        ELSE.
          <ls_status>-overallstatus = 'VALID'.
        ENDIF.
      ENDIF.

    ENDLOOP.

    IF lt_findings_rap IS NOT INITIAL.
      MODIFY ENTITIES OF zr_pru_cmr_valid
             ENTITY zrprucmrvalid
             CREATE FROM lt_findings_rap
             " TODO: variable is assigned but never used (ABAP cleaner)
             MAPPED DATA(ls_mapped)
             FAILED DATA(ls_failed).
      IF ls_failed IS NOT INITIAL.
        ev_error_flag = abap_true.
        RETURN.
      ENDIF.
    ENDIF.

    APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv>).
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-cmrstatus-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = lt_cmr_status
                                             hex_as_base64 = abap_false
                                             compress      = abap_true ).

    APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING <ls_kv>.
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-cmrfinding-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = lt_findings_out
                                             hex_as_base64 = abap_false
                                             compress      = abap_true ).

    es_output = NEW zpru_tt_key_value( et_key_value_pairs ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_create_inb_delivery IMPLEMENTATION.
  METHOD execute_code_int.
    DATA lt_headers_all              TYPE zpru_if_computer_vision=>tt_inb_delivery_header_context.
    DATA lt_items_all                TYPE zpru_if_computer_vision=>tt_inb_delivery_item_context.
    DATA lt_inb_delivery_create_head TYPE TABLE FOR CREATE zprur_inbhdr\\inbhdr.
    DATA lt_inb_delivery_create_item TYPE TABLE FOR CREATE zprur_inbhdr\\inbhdr\_inbitm.
    DATA lt_inb_delivery_header_ctx  TYPE zpru_if_computer_vision=>tt_inb_delivery_header_context.
    DATA lt_inb_delivery_item_ctx    TYPE zpru_if_computer_vision=>tt_inb_delivery_item_context.
    DATA lt_cmr_header               TYPE zpru_if_computer_vision=>tt_cmr_header_context.
    DATA lt_cmr_item                 TYPE zpru_if_computer_vision=>tt_cmr_item_context.

    FIELD-SYMBOLS <ls_inb_delivery_create> TYPE zpru_if_computer_vision=>ts_inb_delivery_create_request.
    FIELD-SYMBOLS <ls_cmr>                 TYPE LINE OF zpru_if_computer_vision=>tt_cmr_header_context.
    FIELD-SYMBOLS <ls_hdr_out>             TYPE LINE OF zpru_if_computer_vision=>tt_inb_delivery_header_context.
    FIELD-SYMBOLS <ls_cmr_item>            TYPE LINE OF zpru_if_computer_vision=>tt_cmr_item_context.
    FIELD-SYMBOLS <ls_item_out>            TYPE LINE OF zpru_if_computer_vision=>tt_inb_delivery_item_context.

    ASSIGN is_input->* TO <ls_inb_delivery_create>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.
    /ui2/cl_json=>deserialize( EXPORTING json = <ls_inb_delivery_create>-cmrheaders
                                         hex_as_base64 = abap_false
                               CHANGING  data = lt_cmr_header ).

    /ui2/cl_json=>deserialize( EXPORTING json = <ls_inb_delivery_create>-cmritems
                                         hex_as_base64 = abap_false
                               CHANGING  data = lt_cmr_item ).

    SELECT MAX( deliveryid ) FROM zprur_inbhdr
      INTO @DATA(lv_max_deliveryid).

    DATA(lv_next_deliveryid_num) = CONV i( lv_max_deliveryid ).

    LOOP AT lt_cmr_header ASSIGNING <ls_cmr>.

      lv_next_deliveryid_num += 1.
      APPEND INITIAL LINE TO lt_headers_all ASSIGNING <ls_hdr_out>.
      <ls_hdr_out>-deliveryid   = lv_next_deliveryid_num.
      <ls_hdr_out>-cmrreference = <ls_cmr>-cmrid.
      <ls_hdr_out>-vendor       = <ls_cmr>-senderinfo.
      <ls_hdr_out>-consignee    = <ls_cmr>-consigneeinfo.
      <ls_hdr_out>-arrivalplace = <ls_cmr>-deliveryplace.
      <ls_hdr_out>-deliverydate = <ls_cmr>-takingoverdate.

      LOOP AT lt_cmr_item ASSIGNING <ls_cmr_item>.
        APPEND INITIAL LINE TO lt_items_all ASSIGNING <ls_item_out>.
        <ls_item_out>-deliveryid   = <ls_hdr_out>-deliveryid.
        <ls_item_out>-itempos      = <ls_cmr_item>-itemposition.
        <ls_item_out>-materialdesc = <ls_cmr_item>-natureofgoods.
        <ls_item_out>-quantity     = <ls_cmr_item>-packagecount.
        <ls_item_out>-unit         = <ls_cmr_item>-weightunitfield.
        <ls_item_out>-grossweight  = <ls_cmr_item>-grossweight.
        <ls_item_out>-weightunit   = <ls_cmr_item>-weightunitfield.
        <ls_item_out>-hazardclass  = <ls_cmr_item>-hazardclass.
      ENDLOOP.
    ENDLOOP.

    DATA(lv_item_cid) = 1.
    LOOP AT lt_headers_all ASSIGNING FIELD-SYMBOL(<ls_header_entity>).

      APPEND INITIAL LINE TO lt_inb_delivery_create_head ASSIGNING FIELD-SYMBOL(<ls_create_head>).
      <ls_create_head>-%cid         = '1'.
      <ls_create_head>-deliveryid   = <ls_header_entity>-deliveryid.
      <ls_create_head>-vendor       = <ls_header_entity>-vendor.
      <ls_create_head>-consignee    = <ls_header_entity>-consignee.
      <ls_create_head>-arrivalplace = <ls_header_entity>-arrivalplace.
      <ls_create_head>-deliverydate = <ls_header_entity>-deliverydate.
      <ls_create_head>-cmrreference = <ls_header_entity>-cmrreference.
      <ls_create_head>-%control-deliveryid   = if_abap_behv=>mk-on.
      <ls_create_head>-%control-vendor       = if_abap_behv=>mk-on.
      <ls_create_head>-%control-consignee    = if_abap_behv=>mk-on.
      <ls_create_head>-%control-arrivalplace = if_abap_behv=>mk-on.
      <ls_create_head>-%control-deliverydate = if_abap_behv=>mk-on.
      <ls_create_head>-%control-cmrreference = if_abap_behv=>mk-on.

      LOOP AT lt_items_all ASSIGNING FIELD-SYMBOL(<ls_item_entity>)
           WHERE deliveryid = <ls_header_entity>-deliveryid.
        APPEND INITIAL LINE TO lt_inb_delivery_create_item ASSIGNING FIELD-SYMBOL(<ls_create_item>).
        <ls_create_item>-%cid_ref = '1'.
        APPEND INITIAL LINE TO <ls_create_item>-%target ASSIGNING FIELD-SYMBOL(<ls_item_target>).
        <ls_item_target>-deliveryid   = <ls_item_entity>-deliveryid.
        <ls_item_target>-itempos      = <ls_item_entity>-itempos.
        <ls_item_target>-materialdesc = <ls_item_entity>-materialdesc.
        <ls_item_target>-quantity     = <ls_item_entity>-quantity.
        <ls_item_target>-unit         = <ls_item_entity>-unit.
        <ls_item_target>-grossweight  = <ls_item_entity>-grossweight.
        <ls_item_target>-weightunit   = <ls_item_entity>-weightunit.
        <ls_item_target>-hazardclass  = <ls_item_entity>-hazardclass.
        <ls_item_target>-%cid         = lv_item_cid.

        <ls_item_target>-%control-deliveryid   = if_abap_behv=>mk-on.
        <ls_item_target>-%control-itempos      = if_abap_behv=>mk-on.
        <ls_item_target>-%control-materialdesc = if_abap_behv=>mk-on.
        <ls_item_target>-%control-quantity     = if_abap_behv=>mk-on.
        <ls_item_target>-%control-unit         = if_abap_behv=>mk-on.
        <ls_item_target>-%control-grossweight  = if_abap_behv=>mk-on.
        <ls_item_target>-%control-weightunit   = if_abap_behv=>mk-on.
        <ls_item_target>-%control-hazardclass  = if_abap_behv=>mk-on.

        lv_item_cid += 1.
      ENDLOOP.
    ENDLOOP.

    IF lt_inb_delivery_create_head IS INITIAL.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    MODIFY ENTITIES OF zprur_inbhdr
           ENTITY inbhdr
           CREATE FROM lt_inb_delivery_create_head
           ENTITY inbhdr
           CREATE BY \_inbitm
           FROM lt_inb_delivery_create_item
           MAPPED DATA(ls_mapped)
           FAILED DATA(ls_failed)
           " TODO: variable is assigned but never used (ABAP cleaner)
           REPORTED DATA(ls_reported).

    IF ls_failed IS NOT INITIAL.
      ev_error_flag = abap_true.
      RETURN.
    ENDIF.

    READ ENTITIES OF zprur_inbhdr
         ENTITY inbhdr
         ALL FIELDS WITH CORRESPONDING #( ls_mapped-inbhdr )
         RESULT DATA(lt_new_inb_headers).

    READ ENTITIES OF zprur_inbhdr
         ENTITY inbitm
         ALL FIELDS WITH CORRESPONDING #( ls_mapped-inbitm )
         RESULT DATA(lt_new_inb_items).

    lt_inb_delivery_header_ctx = CORRESPONDING #( lt_new_inb_headers MAPPING FROM ENTITY ).
    lt_inb_delivery_item_ctx = CORRESPONDING #( lt_new_inb_items MAPPING FROM ENTITY ).

    APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_key_value>).
    <ls_key_value>-name  = zpru_if_computer_vision=>cs_context_field-inbdeliveryheaders-field_name.
    <ls_key_value>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_key_value>-value = /ui2/cl_json=>serialize( data          = lt_inb_delivery_header_ctx
                                                    hex_as_base64 = abap_false
                                                    compress      = abap_true ).

    APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING <ls_key_value>.
    <ls_key_value>-name  = zpru_if_computer_vision=>cs_context_field-inbdeliveryitems-field_name.
    <ls_key_value>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_key_value>-value = /ui2/cl_json=>serialize( data          = lt_inb_delivery_item_ctx
                                                    hex_as_base64 = abap_false
                                                    compress      = abap_true ).

    es_output = NEW zpru_tt_key_value( et_key_value_pairs ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_find_storage_bin IMPLEMENTATION.
  METHOD execute_code_int.
    DATA lt_cmr_headers      TYPE zpru_if_computer_vision=>tt_cmr_header_context.
    DATA lt_cmr_items        TYPE zpru_if_computer_vision=>tt_cmr_item_context.
    DATA lt_inb_headers      TYPE zpru_if_computer_vision=>tt_inb_delivery_header_context.
    DATA lt_inb_items        TYPE zpru_if_computer_vision=>tt_inb_delivery_item_context.
    DATA lt_storage_bins     TYPE zpru_if_computer_vision=>tt_storage_bin_context.
    DATA lt_storage_bins_out TYPE zpru_if_computer_vision=>tt_storage_bin_context.

    FIELD-SYMBOLS <ls_input> TYPE zpru_if_computer_vision=>ts_find_storage_bin_request.

    ASSIGN is_input->* TO <ls_input>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    IF <ls_input>-cmrheaders IS NOT INITIAL.
      /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-cmrheaders
                                           hex_as_base64 = abap_false
                                 CHANGING  data          = lt_cmr_headers ).
    ENDIF.

    IF <ls_input>-cmritems IS NOT INITIAL.
      /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-cmritems
                                           hex_as_base64 = abap_false
                                 CHANGING  data          = lt_cmr_items ).
    ENDIF.

    IF <ls_input>-inbdeliveryheaders IS NOT INITIAL.
      /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-inbdeliveryheaders
                                           hex_as_base64 = abap_false
                                 CHANGING  data          = lt_inb_headers ).
    ENDIF.

    IF <ls_input>-inbdeliveryitems IS NOT INITIAL.
      /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-inbdeliveryitems
                                           hex_as_base64 = abap_false
                                 CHANGING  data          = lt_inb_items ).
    ENDIF.

    SELECT * FROM zprustorbin
      WHERE is_blocked = @abap_false
      ORDER BY bin_id
      INTO CORRESPONDING FIELDS OF TABLE @lt_storage_bins.
    IF sy-subrc = 0.
      lt_storage_bins_out = lt_storage_bins.
    ELSE.
      CLEAR lt_storage_bins_out.
    ENDIF.

    APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv>).
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-storagebins-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = lt_storage_bins_out
                                             hex_as_base64 = abap_false
                                             compress      = abap_true ).

    es_output = NEW zpru_tt_key_value( et_key_value_pairs ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_create_warehouse_task IMPLEMENTATION.
  METHOD execute_code_int.
    DATA lt_inb_headers         TYPE zpru_if_computer_vision=>tt_inb_delivery_header_context.
    DATA lt_inb_items           TYPE zpru_if_computer_vision=>tt_inb_delivery_item_context.
    DATA lt_storage_bins        TYPE zpru_if_computer_vision=>tt_storage_bin_context.
    DATA lt_warehouse_tasks_rap TYPE TABLE FOR CREATE zprur_task\\task.
    DATA lt_warehouse_tasks_out TYPE zpru_if_computer_vision=>tt_warehouse_task_context.
    DATA lv_task_counter        TYPE i VALUE 1.
    DATA lv_max_tanum           TYPE char10.
    DATA lv_storage_bin         TYPE string.

    FIELD-SYMBOLS <ls_input> TYPE zpru_if_computer_vision=>ts_create_whse_task_request.

    ASSIGN is_input->* TO <ls_input>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    IF <ls_input>-inbdeliveryheaders IS NOT INITIAL.
      /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-inbdeliveryheaders
                                           hex_as_base64 = abap_false
                                 CHANGING  data          = lt_inb_headers ).
    ENDIF.

    IF <ls_input>-inbdeliveryitems IS NOT INITIAL.
      /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-inbdeliveryitems
                                           hex_as_base64 = abap_false
                                 CHANGING  data          = lt_inb_items ).
    ENDIF.

    IF <ls_input>-storagebins IS NOT INITIAL.
      /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-storagebins
                                           hex_as_base64 = abap_false
                                 CHANGING  data          = lt_storage_bins ).
    ENDIF.

    " Get next task number
    SELECT MAX( tanum ) FROM zprur_task
      INTO @lv_max_tanum.
    DATA(lv_next_tanum_num) = CONV i( lv_max_tanum ) + 1.

    LOOP AT lt_inb_items ASSIGNING FIELD-SYMBOL(<ls_inb_item>).
      ASSIGN lt_inb_headers[ uuid = <ls_inb_item>-parent_uuid ] TO FIELD-SYMBOL(<ls_inb_header>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      ASSIGN lt_storage_bins[ is_blocked = abap_false ] TO FIELD-SYMBOL(<ls_storage_bin>).
      IF sy-subrc <> 0.
        lv_storage_bin = `CLEAR`.
      ELSE.
        lv_storage_bin = <ls_storage_bin>-bin_id.
      ENDIF.

      APPEND INITIAL LINE TO lt_warehouse_tasks_rap ASSIGNING FIELD-SYMBOL(<ls_task_rap>).
      <ls_task_rap>-%cid       = |TASK{ lv_task_counter }|.
      <ls_task_rap>-tanum      = lv_next_tanum_num.
      <ls_task_rap>-deliveryid = <ls_inb_header>-deliveryid.
      <ls_task_rap>-itempos    = <ls_inb_item>-itempos.
      <ls_task_rap>-material   = <ls_inb_item>-materialdesc.
      <ls_task_rap>-quantity   = <ls_inb_item>-quantity.
      <ls_task_rap>-unit       = <ls_inb_item>-unit.
      <ls_task_rap>-sourcebin  = 'RECEIVING'.
      <ls_task_rap>-destbin    = lv_storage_bin.
      <ls_task_rap>-confstatus = 'O'.
      <ls_task_rap>-%control   = VALUE #( tanum      = if_abap_behv=>mk-on
                                          deliveryid = if_abap_behv=>mk-on
                                          itempos    = if_abap_behv=>mk-on
                                          material   = if_abap_behv=>mk-on
                                          quantity   = if_abap_behv=>mk-on
                                          unit       = if_abap_behv=>mk-on
                                          sourcebin  = if_abap_behv=>mk-on
                                          destbin    = if_abap_behv=>mk-on
                                          confstatus = if_abap_behv=>mk-on ).

      lv_task_counter += 1.
      lv_next_tanum_num += 1.
    ENDLOOP.

    IF lt_warehouse_tasks_rap IS INITIAL.
      APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv_empty>).
      <ls_kv_empty>-name  = zpru_if_computer_vision=>cs_context_field-warehousetasks-field_name.
      <ls_kv_empty>-value = ``.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zprur_task
           ENTITY task
           CREATE FROM lt_warehouse_tasks_rap
           MAPPED DATA(ls_mapped)
           FAILED DATA(ls_failed)
           " TODO: variable is assigned but never used (ABAP cleaner)
           REPORTED DATA(ls_reported).

    IF ls_failed IS NOT INITIAL.
      ev_error_flag = abap_true.
      RETURN.
    ENDIF.

    READ ENTITIES OF zprur_task
         ENTITY task
         ALL FIELDS WITH CORRESPONDING #( ls_mapped-task )
         RESULT DATA(lt_created_tasks_rap).

    lt_warehouse_tasks_out = CORRESPONDING #( lt_created_tasks_rap MAPPING FROM ENTITY ).

    APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv>).
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-warehousetasks-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = lt_warehouse_tasks_out
                                             hex_as_base64 = abap_false
                                             compress      = abap_true ).

    es_output = NEW zpru_tt_key_value( et_key_value_pairs ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_tool_provider IMPLEMENTATION.
  METHOD provide_tool_instance.
    CASE is_tool_master_data-toolname.
      WHEN `CREATE_CMR`.
        ro_executor = NEW lcl_adf_create_cmr( ).
      WHEN `CLASSIFY_DANGER_GOODS`.
        ro_executor = NEW lcl_adf_classify_danger_goods( ).
      WHEN `VALIDATE_CMR`.
        ro_executor = NEW lcl_adf_validate_cmr( ).
      WHEN `CREATE_INB_DELIVERY`.
        ro_executor = NEW lcl_adf_create_inb_delivery( ).
      WHEN `FIND_STORAGE_BIN`.
        ro_executor = NEW lcl_adf_find_storage_bin( ).
      WHEN `CREATE_WAREHOUSE_TASK`.
        ro_executor = NEW lcl_adf_create_warehouse_task( ).
      WHEN OTHERS.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDCASE.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_tool_info_provider IMPLEMENTATION.
  METHOD get_main_tool_info.
*    rs_main_tool_info-toolname        = is_tool_master_data-toolname.
*    rs_main_tool_info-tooldescription = is_tool_master_data-tooldesciption.
*    rs_main_tool_info-toolexplanation = is_tool_master_data-toolexplanation.
*    rs_main_tool_info-tooltype        = is_tool_master_data-tooltype.
  ENDMETHOD.

  METHOD set_tool_parameters.
*    rt_tool_param = VALUE #( BASE rt_tool_param
*      ( parameter_name        = `IS_INPUT`
*        parameter_description = `Input structure for the tool`
*        parameter_type        = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name
*        parameter_is_optional = abap_false ) ).
  ENDMETHOD.

  METHOD set_tool_properties.
*    rt_tool_properties = VALUE #( BASE rt_tool_properties
*      ( toolpropertyname  = `EXECUTION_TYPE`
*        toolpropertyvalue = `ABAP` ) ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_schema_provider IMPLEMENTATION.
  METHOD get_input_abap_type.
    CASE is_tool_master_data-toolname.
      WHEN `CREATE_CMR`.
        ro_structure_schema ?= cl_abap_structdescr=>describe_by_name(
                                   p_name = `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TS_CMR_CREATE_REQUEST` ).
      WHEN `CLASSIFY_DANGER_GOODS`.
        ro_structure_schema ?= cl_abap_structdescr=>describe_by_name(
                                   p_name = `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TS_CMR_CLASSIFY_REQ` ).
      WHEN `VALIDATE_CMR`.
        ro_structure_schema ?= cl_abap_structdescr=>describe_by_name(
                                   p_name = `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TS_CMR_VALIDATE_REQ` ).
      WHEN `CREATE_INB_DELIVERY`.
        ro_structure_schema ?= cl_abap_structdescr=>describe_by_name(
                                   p_name = `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TS_INB_DELIVERY_CREATE_REQUEST` ).
      WHEN `FIND_STORAGE_BIN`.
        ro_structure_schema ?= cl_abap_structdescr=>describe_by_name(
                                   p_name = `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TS_FIND_STORAGE_BIN_REQUEST` ).
      WHEN `CREATE_WAREHOUSE_TASK`.
        ro_structure_schema ?= cl_abap_structdescr=>describe_by_name(
                                   p_name = `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TS_CREATE_WHSE_TASK_REQUEST` ).
      WHEN OTHERS.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDCASE.
  ENDMETHOD.

  METHOD get_input_json_schema.
*    " Return the JSON schema for the tool input
*    " For ABAP-code tools, the schema is derived from the ABAP structure type
*    ro_json_schema ?= cl_abap_structdescr=>describe_by_name(
*      p_name = |\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TS_TOOL_INPUT_SCHEMA| ).
  ENDMETHOD.
ENDCLASS.
