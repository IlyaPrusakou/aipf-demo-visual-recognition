CLASS lcl_adf_decision_provider IMPLEMENTATION.
  METHOD check_authorizations.
    ev_allowed = abap_true.
    RETURN.
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
    DATA lt_creation_content TYPE zpru_if_computer_vision=>tt_cmr_create_content.

    /ui2/cl_json=>deserialize( EXPORTING json = iv_thinking_output
                               CHANGING  data = lt_raw_response ).

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

              LOOP AT <ls_raw_header>-cmritems ASSIGNING FIELD-SYMBOL(<ls_raw_item>).
                APPEND INITIAL LINE TO lt_items ASSIGNING FIELD-SYMBOL(<ls_item>).
                <ls_item> = CORRESPONDING #( <ls_raw_item> ).
                <ls_item>-cmrid = <ls_raw_header>-cmrid.
              ENDLOOP.
            ENDLOOP.
          ENDLOOP.
          <ls_cmrcreationrequest>-cmrheaders = lt_header .
          <ls_cmrcreationrequest>-cmritems   = lt_items .

        ENDLOOP.

        ls_cmr_create_request-cmrcreationcontent = /ui2/cl_json=>serialize( data = lt_creation_content ).

        er_first_tool_input = NEW zpru_if_computer_vision=>ts_cmr_create_request( ls_cmr_create_request ).
      WHEN OTHERS.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDCASE.
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
    DATA ls_llm_output       TYPE ts_gemini_response.
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
                               CHANGING  data = <ls_payload> ).

    CREATE DATA  ls_abap_payload.

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

    lv_string_payload = /ui2/cl_json=>serialize( data     = ls_abap_payload
                                                 pretty_name = /ui2/cl_json=>pretty_mode-low_case
                                                 compress = abap_true ).

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
    |                "natureofgoods": "EXPLOS bananas",| && "QQQ EPLOSIVE trigger on nature of goods"
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
    <ls_execution_plan>-agentuuid =   is_agent-agentuuid.
    <ls_execution_plan>-sequence = 1.
    <ls_execution_plan>-toolname = 'CREATE_CMR'.

    APPEND INITIAL LINE TO et_execution_plan ASSIGNING <ls_execution_plan>.
    <ls_execution_plan>-agentuuid = is_agent-agentuuid.
    <ls_execution_plan>-sequence  = 2.
    <ls_execution_plan>-toolname  = 'CLASSIFY_DANGER_GOODS'.

    APPEND INITIAL LINE TO et_execution_plan ASSIGNING <ls_execution_plan>.
    <ls_execution_plan>-agentuuid = is_agent-agentuuid.
    <ls_execution_plan>-sequence  = 3.
    <ls_execution_plan>-toolname  = 'VALIDATE_CMR'.

    ev_langu = sy-langu.

  ENDMETHOD.

  METHOD read_data_4_thinking.
  ENDMETHOD.

  METHOD recall_memory.
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
                               CHANGING  data = ls_doc_recognition ).

    " Build one runtime entry per message
    LOOP AT ls_doc_recognition-message ASSIGNING FIELD-SYMBOL(<ls_message>).
      APPEND INITIAL LINE TO ls_recognition_output-agent_execution_runtime ASSIGNING FIELD-SYMBOL(<ls_runtime>).
      <ls_runtime>-message = <ls_message>.
      <ls_runtime>-run     = CORRESPONDING #( lt_axc_head ).
      <ls_runtime>-query   = CORRESPONDING #( lt_axc_query ).
      <ls_runtime>-steps   = CORRESPONDING #( lt_axc_steps ).
    ENDLOOP.

    cs_final_response_body-responsecontent = /ui2/cl_json=>serialize( data = ls_recognition_output ).

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
  ENDMETHOD.

  METHOD set_model_id.
  ENDMETHOD.

  METHOD set_result_comment.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_short_memory_provider IMPLEMENTATION.
ENDCLASS.


CLASS lcl_adf_long_memory_provider IMPLEMENTATION.

ENDCLASS.


CLASS lcl_adf_agent_info_provider IMPLEMENTATION.
  METHOD get_agent_main_info.
  ENDMETHOD.

  METHOD get_free_text.
  ENDMETHOD.

  METHOD prepare_agent_domains.
  ENDMETHOD.

  METHOD set_agent_goals.
  ENDMETHOD.

  METHOD set_agent_restrictions.
  ENDMETHOD.

  METHOD set_tool_metadata.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_syst_prompt_provider IMPLEMENTATION.
  METHOD set_primary_session_task.
  ENDMETHOD.

  METHOD set_business_rules.
  ENDMETHOD.

  METHOD set_format_guidelines.
  ENDMETHOD.

  METHOD set_prompt_restrictions.
  ENDMETHOD.

  METHOD set_reasoning_step.
  ENDMETHOD.

  METHOD set_technical_rules.
  ENDMETHOD.

  METHOD set_arbitrary_text.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_create_cmr IMPLEMENTATION.
  METHOD execute_code_int.
    DATA lt_headers            TYPE zpru_if_computer_vision=>tt_cmr_header_context.
    DATA lt_items              TYPE zpru_if_computer_vision=>tt_cmr_item_context.
    DATA lt_headers_all        TYPE zpru_if_computer_vision=>tt_cmr_header_context.
    DATA lt_items_all          TYPE zpru_if_computer_vision=>tt_cmr_item_context.
    DATA lt_cmr_create_head    TYPE TABLE FOR CREATE zr_pru_cmr_header\\zrprucmrheader.
    DATA lt_cmr_create_item    TYPE TABLE FOR CREATE zr_pru_cmr_header\\zrprucmrheader\_cmritems.
    DATA lt_cmr_header_context TYPE zpru_if_computer_vision=>tt_cmr_header_context.
    DATA lt_cmr_item_context   TYPE zpru_if_computer_vision=>tt_cmr_item_context.
    DATA lt_creation_content TYPE zpru_if_computer_vision=>tt_cmr_create_content.

    FIELD-SYMBOLS <ls_cmr_create> TYPE zpru_if_computer_vision=>ts_cmr_create_request.

    ASSIGN is_input->* TO <ls_cmr_create>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.
    /ui2/cl_json=>deserialize( EXPORTING json = <ls_cmr_create>-cmrcreationcontent
                               CHANGING  data = lt_creation_content ).

    LOOP AT lt_creation_content ASSIGNING FIELD-SYMBOL(<ls_cmrcreationcontent>).
      lt_headers_all = CORRESPONDING #( BASE ( lt_headers_all ) <ls_cmrcreationcontent>-cmrheaders ).
      lt_items_all = CORRESPONDING #( BASE ( lt_items_all ) <ls_cmrcreationcontent>-cmritems ).
    ENDLOOP.

    SELECT MAX( cmrid )
      FROM zr_pru_cmr_header
      INTO @DATA(lv_max_cmrid).

    DATA(lv_next_cmrid_num) = CONV i( lv_max_cmrid ) + 1.

    LOOP AT lt_headers_all ASSIGNING FIELD-SYMBOL(<ls_header_cmrid>).
      <ls_header_cmrid>-cmrid = lv_next_cmrid_num.

      LOOP AT lt_items_all ASSIGNING FIELD-SYMBOL(<ls_item_cmrid>)
           WHERE cmruuid = <ls_header_cmrid>-cmruuid.
        <ls_item_cmrid>-cmrid = <ls_header_cmrid>-cmrid.
      ENDLOOP.

      lv_next_cmrid_num += 1.
    ENDLOOP.

    DATA(lv_item_cid) = 1.
    LOOP AT lt_headers_all ASSIGNING FIELD-SYMBOL(<ls_header>).

      APPEND INITIAL LINE TO lt_cmr_create_head ASSIGNING FIELD-SYMBOL(<ls_cmr_create_head>).
      <ls_cmr_create_head> = CORRESPONDING #( <ls_header> MAPPING TO ENTITY CHANGING CONTROL ).
      <ls_cmr_create_head>-%cid = '1'.

      LOOP AT lt_items_all ASSIGNING FIELD-SYMBOL(<ls_item>)
           WHERE cmruuid = <ls_header>-cmruuid.
        APPEND INITIAL LINE TO lt_cmr_create_item ASSIGNING FIELD-SYMBOL(<ls_cmr_create_item>).
        <ls_cmr_create_item>-%cid_ref = '1'.
        APPEND INITIAL LINE TO <ls_cmr_create_item>-%target ASSIGNING FIELD-SYMBOL(<ls_cmr_item_target>).
        <ls_cmr_item_target> = CORRESPONDING #( <ls_item> MAPPING TO ENTITY CHANGING CONTROL ).
        <ls_cmr_item_target>-%cid = lv_item_cid.

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
    <ls_key_value>-name  = 'CMRHEADERS'.
    <ls_key_value>-value = /ui2/cl_json=>serialize( data     = lt_cmr_header_context
                                                    compress = abap_true ).

    APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING <ls_key_value>.
    <ls_key_value>-name  = 'CMRITEMS'.
    <ls_key_value>-value = /ui2/cl_json=>serialize( data     = lt_cmr_item_context
                                                    compress = abap_true ).

    APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING <ls_key_value>.
    <ls_key_value>-name  = 'CMRCREATIONCONTENT'.
    <ls_key_value>-value = /ui2/cl_json=>serialize( data     = lt_creation_content
                                                    compress = abap_true ).
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

    FIELD-SYMBOLS <ls_input> TYPE  zpru_if_computer_vision=>ts_cmr_classify_req.

    ASSIGN is_input->* TO <ls_input>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-cmritems
                                         hex_as_base64 = abap_false
                               CHANGING  data          = lt_cmr_item_context ).

    IF lt_cmr_item_context IS INITIAL.
      APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv_empty>).
      <ls_kv_empty>-name  = 'CMRALERTS'.
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

    " --- Persist alerts ---
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

    " --- Emit output key-value pair ---
    APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv>).
    <ls_kv>-name  = 'CMRALERTS'.
    <ls_kv>-value = /ui2/cl_json=>serialize( data     = lt_cmr_alert_context
                                             compress = abap_true ).


  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_validate_cmr IMPLEMENTATION.
  METHOD execute_code_int.
    TYPES: BEGIN OF ts_header,
             cmruuid         TYPE zpru_cmr_header-cmruuid,
             cmrid           TYPE zpru_cmr_header-cmrid,
             senderinfo      TYPE zpru_cmr_header-senderinfo,
             consigneeinfo   TYPE zpru_cmr_header-consigneeinfo,
             deliveryplace   TYPE zpru_cmr_header-deliveryplace,
             takingoverplace TYPE zpru_cmr_header-takingoverplace,
             takingoverdate  TYPE zpru_cmr_header-takingoverdate,
             carrierinfo     TYPE zpru_cmr_header-carrierinfo,
             cashondelivery  TYPE zpru_cmr_header-cashondelivery,
             currency        TYPE zpru_cmr_header-currency,
           END OF ts_header,
           tt_headers TYPE STANDARD TABLE OF ts_header WITH EMPTY KEY.

    TYPES: BEGIN OF ts_item,
             cmruuid            TYPE zpru_cmr_item-cmruuid,
             cmritemuuid        TYPE zpru_cmr_item-cmritemuuid,
             cmrid              TYPE zpru_cmr_item-cmrid,
             itemposition       TYPE zpru_cmr_item-itemposition,
             natureofgoods      TYPE zpru_cmr_item-natureofgoods,
             grossweight        TYPE zpru_cmr_item-grossweight,
             weightunitfield    TYPE zpru_cmr_item-weightunitfield,
             unitednationnumber TYPE zpru_cmr_item-unitednationnumber,
             hazardclass        TYPE zpru_cmr_item-hazardclass,
             packinggroup       TYPE zpru_cmr_item-packinggroup,
           END OF ts_item,
           tt_items TYPE STANDARD TABLE OF ts_item WITH EMPTY KEY.

    TYPES: BEGIN OF ts_alert,
             alertuuid   TYPE zpru_cmr_alert-alertuuid,
             cmruuid     TYPE zpru_cmr_alert-cmruuid,
             cmritemuuid TYPE zpru_cmr_alert-cmritemuuid,
           END OF ts_alert,
           tt_alerts TYPE STANDARD TABLE OF ts_alert WITH EMPTY KEY.

    TYPES: BEGIN OF ts_finding_out,
             findinguuid   TYPE zpru_cmr_valid-findinguuid,
             cmruuid       TYPE zpru_cmr_valid-cmruuid,
             cmrid         TYPE zpru_cmr_valid-cmrid,
             cmritemuuid   TYPE zpru_cmr_valid-cmritemuuid,
             itemposition  TYPE zpru_cmr_valid-itemposition,
             findingstatus TYPE zpru_cmr_valid-findingstatus,
             findingtype   TYPE zpru_cmr_valid-findingtype,
             fieldname     TYPE zpru_cmr_valid-fieldname,
             findingmsg    TYPE zpru_cmr_valid-findingmsg,
           END OF ts_finding_out,
           tt_findings_out TYPE STANDARD TABLE OF ts_finding_out WITH EMPTY KEY.

    TYPES: BEGIN OF ts_cmr_status,
             cmruuid       TYPE zpru_cmr_header-cmruuid,
             cmrid         TYPE zpru_cmr_header-cmrid,
             overallstatus TYPE char10,
           END OF ts_cmr_status,
           tt_cmr_status TYPE STANDARD TABLE OF ts_cmr_status WITH EMPTY KEY.

    TYPES: BEGIN OF ts_validation_output,
             cmrstatus TYPE tt_cmr_status,
             findings  TYPE tt_findings_out,
           END OF ts_validation_output.

    DATA lt_headers      TYPE tt_headers.
    DATA lt_items        TYPE tt_items.
    DATA lt_alerts       TYPE tt_alerts.
    DATA lt_findings_rap TYPE TABLE FOR CREATE zr_pru_cmr_valid\\zrprucmrvalid.
    DATA lt_findings_out TYPE tt_findings_out.
    DATA lt_cmr_status   TYPE tt_cmr_status.
    DATA ls_output       TYPE ts_validation_output.
    DATA lv_headers_json TYPE string.
    DATA lv_items_json   TYPE string.
    DATA lv_alerts_json  TYPE string.
    DATA ls_finding_out  TYPE ts_finding_out.
    DATA lv_cid_counter  TYPE i VALUE 1.

    FIELD-SYMBOLS: <ls_input> TYPE zpru_s_cmr_validate_req.

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

    " --- Validate each CMR header ---
    LOOP AT lt_headers ASSIGNING FIELD-SYMBOL(<ls_hdr>).

      IF <ls_hdr>-senderinfo IS INITIAL.
        CLEAR ls_finding_out.
        APPEND INITIAL LINE TO lt_findings_rap ASSIGNING FIELD-SYMBOL(<ls_finding_rap>).

        TRY.
            <ls_finding_rap>-findinguuid   = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH   cx_uuid_error.
        ENDTRY.

        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
        <ls_finding_rap>-findingtype   = 'MANDATORY_FIELD'.
        <ls_finding_rap>-fieldname     = 'SENDERINFO'.
        <ls_finding_rap>-findingmsg    = 'Sender information is missing'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid          = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control      = VALUE #( findinguuid   = if_abap_behv=>mk-on
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
            <ls_finding_rap>-findinguuid   = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH   cx_uuid_error.
        ENDTRY.
        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
        <ls_finding_rap>-findingtype   = 'MANDATORY_FIELD'.
        <ls_finding_rap>-fieldname     = 'CONSIGNEEINFO'.
        <ls_finding_rap>-findingmsg    = 'Consignee information is missing'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid          = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control      = VALUE #( findinguuid   = if_abap_behv=>mk-on
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
            <ls_finding_rap>-findinguuid   = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH   cx_uuid_error.
        ENDTRY.
        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
        <ls_finding_rap>-findingtype   = 'MANDATORY_FIELD'.
        <ls_finding_rap>-fieldname     = 'CARRIERINFO'.
        <ls_finding_rap>-findingmsg    = 'Carrier information is missing'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid          = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control      = VALUE #( findinguuid   = if_abap_behv=>mk-on
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
            <ls_finding_rap>-findinguuid   = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH   cx_uuid_error.
        ENDTRY.
        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
        <ls_finding_rap>-findingtype   = 'MANDATORY_FIELD'.
        <ls_finding_rap>-fieldname     = 'TAKINGOVERPLACE'.
        <ls_finding_rap>-findingmsg    = 'Taking-over place is missing'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid          = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control      = VALUE #( findinguuid   = if_abap_behv=>mk-on
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
            <ls_finding_rap>-findinguuid   = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH   cx_uuid_error.
        ENDTRY.
        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
        <ls_finding_rap>-findingtype   = 'MANDATORY_FIELD'.
        <ls_finding_rap>-fieldname     = 'DELIVERYPLACE'.
        <ls_finding_rap>-findingmsg    = 'Delivery place is missing'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid          = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control      = VALUE #( findinguuid   = if_abap_behv=>mk-on
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
            <ls_finding_rap>-findinguuid   = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH   cx_uuid_error.
        ENDTRY.
        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
        <ls_finding_rap>-findingtype   = 'DATE_CHECK'.
        <ls_finding_rap>-fieldname     = 'TAKINGOVERDATE'.
        <ls_finding_rap>-findingmsg    = 'Taking-over date is missing'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid          = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control      = VALUE #( findinguuid   = if_abap_behv=>mk-on
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
            <ls_finding_rap>-findinguuid   = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH   cx_uuid_error.
        ENDTRY.
        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INCOMPLETE'.
        <ls_finding_rap>-findingtype   = 'MANDATORY_FIELD'.
        <ls_finding_rap>-fieldname     = 'CURRENCY'.
        <ls_finding_rap>-findingmsg    = 'Currency required when cash on delivery is set'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid          = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control      = VALUE #( findinguuid   = if_abap_behv=>mk-on
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

      " Item count check
      DATA(lv_item_count) = REDUCE i( INIT n = 0
                                      FOR <it> IN lt_items
                                      WHERE ( cmruuid = <ls_hdr>-cmruuid )
                                      NEXT n = n + 1 ).
      IF lv_item_count = 0.
        CLEAR ls_finding_out.
        APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
        TRY.
            <ls_finding_rap>-findinguuid   = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH   cx_uuid_error.
        ENDTRY.
        <ls_finding_rap>-cmruuid       = <ls_hdr>-cmruuid.
        <ls_finding_rap>-cmrid         = <ls_hdr>-cmrid.
        <ls_finding_rap>-findingstatus = 'INVALID'.
        <ls_finding_rap>-findingtype   = 'ITEM_COUNT'.
        <ls_finding_rap>-fieldname     = ''.
        <ls_finding_rap>-findingmsg    = 'No items found for CMR'.
        <ls_finding_rap>-createdby     = sy-uname.
        GET TIME STAMP FIELD <ls_finding_rap>-createdat.
        <ls_finding_rap>-%cid          = |FIND{ lv_cid_counter }|.
        <ls_finding_rap>-%control      = VALUE #( findinguuid   = if_abap_behv=>mk-on
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

      " Per-item checks
      LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_item>)
           WHERE cmruuid = <ls_hdr>-cmruuid.

        IF <ls_item>-natureofgoods IS INITIAL.
          CLEAR ls_finding_out.
          APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
          TRY.
              <ls_finding_rap>-findinguuid   = cl_system_uuid=>create_uuid_x16_static( ).
            CATCH   cx_uuid_error.
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
          <ls_finding_rap>-%cid          = |FIND{ lv_cid_counter }|.
          <ls_finding_rap>-%control      = VALUE #( findinguuid   = if_abap_behv=>mk-on
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
              <ls_finding_rap>-findinguuid   = cl_system_uuid=>create_uuid_x16_static( ).
            CATCH   cx_uuid_error.
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
          <ls_finding_rap>-%cid          = |FIND{ lv_cid_counter }|.
          <ls_finding_rap>-%control      = VALUE #( findinguuid   = if_abap_behv=>mk-on
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
              <ls_finding_rap>-findinguuid   = cl_system_uuid=>create_uuid_x16_static( ).
            CATCH   cx_uuid_error.
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
          <ls_finding_rap>-%cid          = |FIND{ lv_cid_counter }|.
          <ls_finding_rap>-%control      = VALUE #( findinguuid   = if_abap_behv=>mk-on
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

        " DG cross-check: item flagged as dangerous goods → UN/hazard/packing fields required
        READ TABLE lt_alerts WITH KEY cmritemuuid = <ls_item>-cmritemuuid
             TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          IF <ls_item>-unitednationnumber IS INITIAL.
            CLEAR ls_finding_out.
            APPEND INITIAL LINE TO lt_findings_rap ASSIGNING <ls_finding_rap>.
            TRY.
                <ls_finding_rap>-findinguuid   = cl_system_uuid=>create_uuid_x16_static( ).
              CATCH   cx_uuid_error.
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
            <ls_finding_rap>-%cid          = |FIND{ lv_cid_counter }|.
            <ls_finding_rap>-%control      = VALUE #( findinguuid   = if_abap_behv=>mk-on
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
                <ls_finding_rap>-findinguuid   = cl_system_uuid=>create_uuid_x16_static( ).
              CATCH   cx_uuid_error.
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
            <ls_finding_rap>-%cid          = |FIND{ lv_cid_counter }|.
            <ls_finding_rap>-%control      = VALUE #( findinguuid   = if_abap_behv=>mk-on
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
                <ls_finding_rap>-findinguuid   = cl_system_uuid=>create_uuid_x16_static( ).
              CATCH   cx_uuid_error.
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
            <ls_finding_rap>-%cid          = |FIND{ lv_cid_counter }|.
            <ls_finding_rap>-%control      = VALUE #( findinguuid   = if_abap_behv=>mk-on
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

      " Derive overall status for this CMR
      APPEND INITIAL LINE TO lt_cmr_status ASSIGNING FIELD-SYMBOL(<ls_status>).
      <ls_status>-cmruuid = <ls_hdr>-cmruuid.
      <ls_status>-cmrid   = <ls_hdr>-cmrid.

      READ TABLE lt_findings_out WITH KEY cmruuid       = <ls_hdr>-cmruuid
                                          findingstatus = 'INVALID'
           TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        <ls_status>-overallstatus = 'INVALID'.
      ELSE.
        READ TABLE lt_findings_out WITH KEY cmruuid = <ls_hdr>-cmruuid
             TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          <ls_status>-overallstatus = 'INCOMPLETE'.
        ELSE.
          <ls_status>-overallstatus = 'VALID'.
        ENDIF.
      ENDIF.

    ENDLOOP.

    " --- Persist findings using RAP ---
    IF lt_findings_rap IS NOT INITIAL.
      MODIFY ENTITIES OF zr_pru_cmr_valid
             ENTITY zrprucmrvalid
             CREATE FROM lt_findings_rap
             MAPPED DATA(ls_mapped)
             FAILED DATA(ls_failed).
      IF ls_failed IS NOT INITIAL.
        ev_error_flag = abap_true.
        RETURN.
      ENDIF.
    ENDIF.

    " --- Emit output key-value pair ---
    ls_output-cmrstatus = lt_cmr_status.
    ls_output-findings  = lt_findings_out.

    APPEND INITIAL LINE TO et_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv>).
    <ls_kv>-name  = 'CMRVALIDATION'.
    <ls_kv>-value = /ui2/cl_json=>serialize( data     = ls_output
                                              compress = abap_true ).
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
      WHEN OTHERS.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDCASE.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_tool_info_provider IMPLEMENTATION.
  METHOD get_main_tool_info.
  ENDMETHOD.

  METHOD set_tool_parameters.
  ENDMETHOD.

  METHOD set_tool_properties.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_schema_provider IMPLEMENTATION.
  METHOD get_input_abap_type.
    CASE is_tool_master_data-toolname.
      WHEN `CREATE_CMR`.
        ro_structure_schema ?= cl_abap_structdescr=>describe_by_name( p_name = `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TS_CMR_CREATE_REQUEST` ).
      WHEN `CLASSIFY_DANGER_GOODS`.
        ro_structure_schema ?= cl_abap_structdescr=>describe_by_name( p_name = `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TS_CMR_CLASSIFY_REQ` ).
      WHEN `VALIDATE_CMR`.
        ro_structure_schema ?= cl_abap_structdescr=>describe_by_name( p_name = `\INTERF=ZPRU_IF_COMPUTER_VISION\TYPE=TS_CMR_VALIDATE_REQ` ).
      WHEN OTHERS.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDCASE.
  ENDMETHOD.

  METHOD get_input_json_schema.
  ENDMETHOD.
ENDCLASS.
