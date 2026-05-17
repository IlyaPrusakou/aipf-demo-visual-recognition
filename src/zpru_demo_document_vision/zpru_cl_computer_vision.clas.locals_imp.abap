CLASS lcl_adf_decision_provider IMPLEMENTATION.
  METHOD check_authorizations.
    ev_allowed = abap_true.
    RETURN.
  ENDMETHOD.

  METHOD process_thinking.
    DATA(lr_input_payload) = deserialize_input_to_payload( is_input_prompt ).
    DATA(lv_json_schema)   = build_cmr_json_schema( ).
    DATA(lr_gemini_payload) = build_gemini_request_payload( io_input_payload = lr_input_payload
                                                            iv_json_schema   = lv_json_schema ).

    DATA(lo_http_client) = create_gemini_http_client( ).
    DATA(lo_http_request) = lo_http_client->get_http_request( ).
    set_http_headers( lo_http_request ).

    DATA(lv_string_payload) = serialize_payload_to_json( lr_gemini_payload->* ).
    IF lv_string_payload IS NOT INITIAL.
      lo_http_request->set_text( i_text = lv_string_payload ).
    ENDIF.

*    execute_llm( EXPORTING io_http_client = lo_http_client
*                           iv_json_payload   = lv_string_payload ).
*

    DATA(lv_raw_response) = get_mock_test_response( ).
    strip_markdown_wrappers( CHANGING cv_response = lv_raw_response ).

    IF lv_raw_response IS NOT INITIAL.
      ev_thinking_output = lv_raw_response.
    ENDIF.

    add_execution_plan_step( EXPORTING iv_agentuuid = is_agent-agentuuid
                                       iv_sequence  = 1
                                       iv_toolname  = zpru_if_computer_vision=>cs_tools-create_cmr
                             CHANGING  ct_plan      = et_execution_plan ).
    add_execution_plan_step( EXPORTING iv_agentuuid = is_agent-agentuuid
                                       iv_sequence  = 2
                                       iv_toolname  = zpru_if_computer_vision=>cs_tools-classify_danger_goods
                             CHANGING  ct_plan      = et_execution_plan ).
    add_execution_plan_step( EXPORTING iv_agentuuid = is_agent-agentuuid
                                       iv_sequence  = 3
                                       iv_toolname  = zpru_if_computer_vision=>cs_tools-validate_cmr
                             CHANGING  ct_plan      = et_execution_plan ).
    add_execution_plan_step( EXPORTING iv_agentuuid = is_agent-agentuuid
                                       iv_sequence  = 4
                                       iv_toolname  = zpru_if_computer_vision=>cs_tools-create_inb_delivery
                             CHANGING  ct_plan      = et_execution_plan ).
    add_execution_plan_step( EXPORTING iv_agentuuid = is_agent-agentuuid
                                       iv_sequence  = 5
                                       iv_toolname  = zpru_if_computer_vision=>cs_tools-find_storage_bin
                             CHANGING  ct_plan      = et_execution_plan ).
    add_execution_plan_step( EXPORTING iv_agentuuid = is_agent-agentuuid
                                       iv_sequence  = 6
                                       iv_toolname  = zpru_if_computer_vision=>cs_tools-create_warehouse_task
                             CHANGING  ct_plan      = et_execution_plan ).

    ev_langu = sy-langu.
  ENDMETHOD.

  METHOD create_gemini_http_client.
    DATA(lv_url) = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`.
    TRY.
        DATA(lo_destination) = cl_http_destination_provider=>create_by_url( i_url = lv_url ).
        ro_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = lo_destination ).
      CATCH cx_http_dest_provider_error
            cx_web_http_client_error.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDTRY.
  ENDMETHOD.

  METHOD set_http_headers.
    io_http_request->set_header_field( i_name  = 'Content-Type'
                                       i_value = 'application/json' ).
    io_http_request->set_header_field( i_name  = 'x-goog-api-key'
                                       i_value = 'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm' ).
  ENDMETHOD.

  METHOD deserialize_input_to_payload.
    CREATE DATA ro_payload TYPE (is_input_prompt-type).
    ASSIGN ro_payload->* TO FIELD-SYMBOL(<ls_data>).
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.
    /ui2/cl_json=>deserialize( EXPORTING json          = is_input_prompt-string_content
                                         hex_as_base64 = abap_true
                               CHANGING  data          = <ls_data> ).
  ENDMETHOD.

  METHOD build_cmr_json_schema.
    rv_schema =
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
  ENDMETHOD.

  METHOD build_gemini_request_payload.
    CREATE DATA ro_gemini_req.
    ASSIGN ro_gemini_req->* TO FIELD-SYMBOL(<ls_req>).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO <ls_req>-contents ASSIGNING FIELD-SYMBOL(<ls_content>).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO <ls_content>-parts ASSIGNING FIELD-SYMBOL(<ls_part>).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    add_system_instructions( EXPORTING iv_json_schema = iv_json_schema
                             CHANGING  cs_part        = <ls_part> ).

    add_attachment_images( EXPORTING io_input_payload = io_input_payload
                           CHANGING  cs_content       = <ls_content> ).
  ENDMETHOD.

  METHOD add_system_instructions.
    cs_part-text = |{ cs_part-text } always use USD as currency, KG as weight and M3 as volume.{ cl_abap_char_utilities=>newline }|.
    cs_part-text = |{ cs_part-text } always give me output as json according the schema.{ cl_abap_char_utilities=>newline }|.
    cs_part-text = |{ cs_part-text } For output use this schema: { iv_json_schema }{ cl_abap_char_utilities=>newline }|.
  ENDMETHOD.

  METHOD add_attachment_images.
    FIELD-SYMBOLS <ls_payload> TYPE zbp_r_pru_message=>ts_doc_recognition.

    ASSIGN io_input_payload->* TO <ls_payload>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    LOOP AT <ls_payload>-message ASSIGNING FIELD-SYMBOL(<ls_message>).
      LOOP AT <ls_payload>-attachment ASSIGNING FIELD-SYMBOL(<ls_attachment>)
           WHERE messageid = <ls_message>-messageid.
        DATA(lv_image_base64) = cl_web_http_utility=>encode_x_base64( unencoded = <ls_attachment>-attachment ).

        APPEND INITIAL LINE TO cs_content-parts ASSIGNING FIELD-SYMBOL(<ls_part>).
        <ls_part>-inline_data-mime_type = 'image/jpeg'.
        <ls_part>-inline_data-data      = lv_image_base64.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD serialize_payload_to_json.
    rv_json = /ui2/cl_json=>serialize( data          = is_payload
                                       hex_as_base64 = abap_true
                                       pretty_name   = /ui2/cl_json=>pretty_mode-low_case
                                       compress      = abap_true ).
  ENDMETHOD.

  METHOD get_mock_test_response.
    rv_response =
      |[| &&
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
      |                "hazardclass": "FLAM",| &&
      |                "packinggroup": null| &&
      |              \},| &&
      |              \{| &&
      |                "itemposition": "prod2",| &&
      |                "marksnumbers": "prod2",| &&
      |                "packagecount": 8,| &&
      |                "packingmethod": "pallet",| &&
      |                "natureofgoods": "EXPLOS bananas",| &&
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
  ENDMETHOD.

  METHOD strip_markdown_wrappers.
    REPLACE FIRST OCCURRENCE OF '```json' IN cv_response WITH ''.
    REPLACE ALL OCCURRENCES OF '```' IN cv_response WITH ''.
  ENDMETHOD.

  METHOD add_execution_plan_step.
    APPEND INITIAL LINE TO ct_plan ASSIGNING FIELD-SYMBOL(<ls_plan>).
    <ls_plan>-agentuuid = iv_agentuuid.
    <ls_plan>-sequence  = iv_sequence.
    <ls_plan>-toolname  = iv_toolname.
  ENDMETHOD.

  METHOD prepare_first_tool_input.
    DATA(lt_raw_response) = parse_think_output_2_cmr_resp( iv_thinking_output ).
    IF lt_raw_response IS INITIAL.
      RETURN.
    ENDIF.

    CASE is_first_tool-toolname.
      WHEN `CREATE_CMR`.
        DATA(lt_creation_content) = map_response_2_creat_content( lt_raw_response ).

        DATA(ls_cmr_create_request) = VALUE zpru_if_computer_vision=>ts_cmr_create_request(
            cmrcreationcontent = /ui2/cl_json=>serialize( data          = lt_creation_content
                                                          hex_as_base64 = abap_true ) ).

        er_first_tool_input = NEW zpru_if_computer_vision=>ts_cmr_create_request( ls_cmr_create_request ).
      WHEN OTHERS.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDCASE.
  ENDMETHOD.

  METHOD parse_think_output_2_cmr_resp.
    /ui2/cl_json=>deserialize( EXPORTING json          = iv_thinking_output
                                         hex_as_base64 = abap_true
                               CHANGING  data          = rt_response ).
  ENDMETHOD.

  METHOD map_response_2_creat_content.
    DATA lt_header TYPE STANDARD TABLE OF zpru_cmr_header WITH EMPTY KEY.
    DATA lt_items  TYPE STANDARD TABLE OF zpru_cmr_item WITH EMPTY KEY.

    LOOP AT it_response ASSIGNING FIELD-SYMBOL(<ls_message>).
      APPEND INITIAL LINE TO rt_content ASSIGNING FIELD-SYMBOL(<ls_content>).
      <ls_content>-message = <ls_message>-messageid.

      LOOP AT <ls_message>-attachments ASSIGNING FIELD-SYMBOL(<ls_attachment>).
        LOOP AT <ls_attachment>-cmrheaders ASSIGNING FIELD-SYMBOL(<ls_raw_header>).
          APPEND INITIAL LINE TO lt_header ASSIGNING FIELD-SYMBOL(<ls_header>).
          <ls_header> = CORRESPONDING #( <ls_raw_header> ).
          TRY.
              <ls_header>-cmruuid = cl_system_uuid=>create_uuid_x16_static( ). " temporal uuid, after save will be changed
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
      <ls_content>-cmrheaders = lt_header.
      <ls_content>-cmritems   = lt_items.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_data_4_thinking.
    APPEND INITIAL LINE TO cs_decision_log-thinkingsteps ASSIGNING FIELD-SYMBOL(<ls_thinking_step>).
    <ls_thinking_step>-thinkingstepnumber   = get_last_thinkingstepnumber( cs_decision_log-thinkingsteps ).
    <ls_thinking_step>-thinkingstepdatetime = get_timestamp( ).
    <ls_thinking_step>-thinkingstepcontent  = `RAG data prepared for thinking`.
  ENDMETHOD.

  METHOD recall_memory.
    APPEND INITIAL LINE TO cs_decision_log-thinkingsteps ASSIGNING FIELD-SYMBOL(<ls_thinking_step>).
    <ls_thinking_step>-thinkingstepnumber   = get_last_thinkingstepnumber( cs_decision_log-thinkingsteps ).
    <ls_thinking_step>-thinkingstepdatetime = get_timestamp( ).
    <ls_thinking_step>-thinkingstepcontent  = `Memory recall completed`.
  ENDMETHOD.

  METHOD set_final_response_content.
    DATA lt_axc_head           TYPE zpru_if_axc_type_and_constant=>tt_axc_head.
    DATA lt_axc_query          TYPE zpru_if_axc_type_and_constant=>tt_axc_query.
    DATA lt_axc_steps          TYPE zpru_if_axc_type_and_constant=>tt_axc_step.
    DATA ls_recognition_output TYPE zbp_r_pru_message=>ts_recognition_output.

    DATA(lo_axc_service) = get_axc_service_instance( ).

    read_execution_data( EXPORTING iv_run_uuid    = iv_run_uuid
                                   iv_query_uuid  = iv_query_uuid
                                   io_axc_service = lo_axc_service
                         IMPORTING et_axc_head    = lt_axc_head
                                   et_axc_query   = lt_axc_query
                                   et_axc_steps   = lt_axc_steps ).

    assign_runtime_to_messages( EXPORTING io_controller         = io_controller
                                          it_axc_head           = lt_axc_head
                                          it_axc_query          = lt_axc_query
                                          it_axc_steps          = lt_axc_steps
                                CHANGING  cs_recognition_output = ls_recognition_output ).

    cs_final_response_body-responsecontent = /ui2/cl_json=>serialize( data          = ls_recognition_output
                                                                      hex_as_base64 = abap_true ).
    cs_final_response_body-type            = `\CLASS=ZBP_R_PRU_MESSAGE\TYPE=TS_RECOGNITION_OUTPUT`.

    append_freshest_context( EXPORTING io_controller = io_controller
                             CHANGING  cs_final_body = cs_final_response_body ).
  ENDMETHOD.

  METHOD get_axc_service_instance.
    ro_axc_service ?= zpru_cl_agent_service_mngr=>get_service( iv_service = `ZPRU_IF_AXC_SERVICE`
                                                               iv_context = zpru_if_agent_frw=>cs_context-standard ).
  ENDMETHOD.

  METHOD read_execution_data.
    io_axc_service->read_header(
      EXPORTING it_head_read_k = VALUE #( ( runuuid = iv_run_uuid
                                            control = VALUE #( runuuid          = abap_true
                                                               runid            = abap_true
                                                               agentuuid        = abap_true
                                                               userid           = abap_true
                                                               runstartdatetime = abap_true
                                                               runenddatetime   = abap_true ) ) )
      IMPORTING et_axc_head    = et_axc_head ).

    io_axc_service->read_query(
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
      IMPORTING et_axc_query    = et_axc_query ).

    io_axc_service->rba_step(
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
      IMPORTING et_axc_step   = et_axc_steps ).
  ENDMETHOD.

  METHOD assign_runtime_to_messages.
    DATA ls_doc_recognition TYPE zbp_r_pru_message=>ts_doc_recognition.

    SORT io_controller->mt_input_output BY number ASCENDING.
    DATA(ls_input_prompt) = VALUE #( io_controller->mt_input_output[ 1 ]-input_prompt OPTIONAL ).
    /ui2/cl_json=>deserialize( EXPORTING json          = ls_input_prompt-string_content
                                         hex_as_base64 = abap_true
                               CHANGING  data          = ls_doc_recognition ).
    " if there is multiple message - we don't know how to map message and specific run
    " so far only single message may processed correctly
    LOOP AT ls_doc_recognition-message ASSIGNING FIELD-SYMBOL(<ls_message>).
      APPEND INITIAL LINE TO cs_recognition_output-agent_execution_runtime
             ASSIGNING FIELD-SYMBOL(<ls_runtime>).
      <ls_runtime>-message = <ls_message>.
      <ls_runtime>-run     = CORRESPONDING #( it_axc_head ).
      <ls_runtime>-query   = CORRESPONDING #( it_axc_query ).
      <ls_runtime>-steps   = CORRESPONDING #( it_axc_steps ).
    ENDLOOP.
  ENDMETHOD.

  METHOD append_freshest_context.
    SORT io_controller->mt_input_output BY number DESCENDING.
    DATA(lt_freshest_context) = VALUE #( io_controller->mt_input_output[ 1 ]-key_value_pairs OPTIONAL ).

    LOOP AT lt_freshest_context ASSIGNING FIELD-SYMBOL(<ls_context>).
      APPEND INITIAL LINE TO cs_final_body-structureddata ASSIGNING FIELD-SYMBOL(<ls_structureddata>).
      <ls_structureddata>-name  = <ls_context>-name.
      <ls_structureddata>-value = <ls_context>-value.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_final_response_metadata.
    cs_reasoning_trace-rationalsummary = 'Document Visual Recognition completed. CMR data extracted, validated, and processed through the warehouse workflow.'.
    cs_reasoning_trace-confidencescore = `90.00`.
  ENDMETHOD.

  METHOD set_model_id.
    rv_model_id = `GEMINI_2.5_FLASH`.
  ENDMETHOD.

  METHOD set_result_comment.
    rv_result_comment = `Document Visual Recognition processing finished`.
  ENDMETHOD.

  METHOD execute_llm.
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
*                                hex_as_base64 = abap_true
*                               CHANGING  data = ls_llm_output ).
*
*    DATA(lv_raw_response) = VALUE #( ls_llm_output-candidates[ 1 ]-content-parts[ 1 ]-text OPTIONAL ).
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
    <ls_restriction>-agentrestrictionname = `READ_ONLY_ACCESS`.
    <ls_restriction>-agentrestriction     = `This agent only creates and reads CMR, inbound delivery, and warehouse data. It cannot modify or delete past records.`.
    APPEND INITIAL LINE TO rt_agent_restrictions ASSIGNING <ls_restriction>.
    <ls_restriction>-agentrestrictionname = `NO_FINANCIAL_TRANSACTIONS`.
    <ls_restriction>-agentrestriction     = `The agent does not process payments, invoices, or financial transactions.`.
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
    <ls_rule>-businessrulesname = `CURRENCY_RULE`.
    <ls_rule>-businessrule      = `Always use USD as currency for cash on delivery amounts.`.
    APPEND INITIAL LINE TO rt_business_rules ASSIGNING <ls_rule>.
    <ls_rule>-businessrulesname = `WEIGHT_UNIT_RULE`.
    <ls_rule>-businessrule      = `Use KG as default weight unit and M3 as default volume unit for item dimensions.`.
    APPEND INITIAL LINE TO rt_business_rules ASSIGNING <ls_rule>.
    <ls_rule>-businessrulesname = `MANDATORY_FIELDS_RULE`.
    <ls_rule>-businessrule      = `Sender info, consignee info, carrier info, taking-over place, delivery place, and taking-over date are mandatory for each CMR header. Nature of goods is mandatory for each item.`.
    APPEND INITIAL LINE TO rt_business_rules ASSIGNING <ls_rule>.
    <ls_rule>-businessrulesname = `DG_COMPLIANCE_RULE`.
    <ls_rule>-businessrule      = `Dangerous goods items must have UN number, hazard class, and packing group filled; otherwise flag as finding.`.
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
    <ls_restriction>-promptrestrictionname = `NO_HALLUCINATION`.
    <ls_restriction>-promptrestriction     = `Do not invent or hallucinate data. If a field cannot be extracted from the document, leave it null or empty.`.
    APPEND INITIAL LINE TO rt_prompt_restrictions ASSIGNING <ls_restriction>.
    <ls_restriction>-promptrestrictionname = `NO_EXECUTION`.
    <ls_restriction>-promptrestriction     = `Do not execute code, make changes, or perform any action outside of the tools provided to you.`.
    APPEND INITIAL LINE TO rt_prompt_restrictions ASSIGNING <ls_restriction>.
    <ls_restriction>-promptrestrictionname = `ONLY_STRUCTURED_OUTPUT`.
    <ls_restriction>-promptrestriction     = `Return only the requested structured data. Do not add any conversational or explanatory text.`.
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
    <ls_tech_rule>-technicalrulesname = `API_TIMEOUT`.
    <ls_tech_rule>-technicalrule      = `The Gemini API call may take up to 30 seconds. Handle timeout gracefully.`.
    APPEND INITIAL LINE TO rt_tech_rules ASSIGNING <ls_tech_rule>.
    <ls_tech_rule>-technicalrulesname = `BASE64_ENCODING`.
    <ls_tech_rule>-technicalrule      = `Images must be Base64-encoded before being sent to Gemini API. Use JPEG format.`.
    APPEND INITIAL LINE TO rt_tech_rules ASSIGNING <ls_tech_rule>.
    <ls_tech_rule>-technicalrulesname = `MAX_IMAGE_SIZE`.
    <ls_tech_rule>-technicalrule      = `Each image should not exceed 20 MB after Base64 encoding.`.
  ENDMETHOD.

  METHOD set_arbitrary_text.
    ev_arbitrarytexttitle = `AGENT_ORIGIN`.
    ev_arbitrarytext = `Developed for SAP S/4HANA warehouse automation scenarios.`.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_agent_mapper IMPLEMENTATION.
ENDCLASS.


CLASS lcl_adf_create_cmr IMPLEMENTATION.
  METHOD execute_code_int.
    DATA lt_headers_all        TYPE zpru_if_computer_vision=>tt_cmr_header_context.
    DATA lt_items_all          TYPE zpru_if_computer_vision=>tt_cmr_item_context.
    DATA lt_cmr_header_context TYPE zpru_if_computer_vision=>tt_cmr_header_context.
    DATA lt_cmr_item_context   TYPE zpru_if_computer_vision=>tt_cmr_item_context.

    DATA(lt_creation_content) = deserialize_cmr_creation_input( is_input ).

    LOOP AT lt_creation_content ASSIGNING FIELD-SYMBOL(<ls_cmrcreationcontent>).
      lt_headers_all = CORRESPONDING #( BASE ( lt_headers_all )
                                        <ls_cmrcreationcontent>-cmrheaders ).
      lt_items_all = CORRESPONDING #( BASE ( lt_items_all )
                                      <ls_cmrcreationcontent>-cmritems ).
    ENDLOOP.

    assign_cmr_ids( CHANGING ct_headers = lt_headers_all
                             ct_items   = lt_items_all ).

    DATA(lt_cmr_create_head) = prepare_header_rap_entities( lt_headers_all ).
    DATA(lt_cmr_create_item) = prepare_item_rap_entities( it_headers_create = lt_cmr_create_head
                                                          it_items          = lt_items_all ).

    IF lt_cmr_create_head IS INITIAL.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    " release temporarily key before save
    LOOP AT lt_cmr_create_head ASSIGNING FIELD-SYMBOL(<ls_head_create>)
         WHERE cmruuid IS NOT INITIAL.
      CLEAR <ls_head_create>-cmruuid.
    ENDLOOP.

    persist_cmr_via_rap( EXPORTING it_create_header = lt_cmr_create_head
                                   it_create_item   = lt_cmr_create_item
                         IMPORTING et_mapped_header = lt_cmr_header_context
                                   et_mapped_item   = lt_cmr_item_context
                         CHANGING  ev_error_flag    = ev_error_flag ).

    IF ev_error_flag = abap_true.
      RETURN.
    ENDIF.

    append_cmr_output_pairs( EXPORTING it_cmr_headers      = lt_cmr_header_context
                                       it_cmr_items        = lt_cmr_item_context
                                       it_creation_content = lt_creation_content
                             CHANGING  ct_key_value_pairs  = et_key_value_pairs ).

    es_output = NEW zpru_tt_key_value( et_key_value_pairs ).
  ENDMETHOD.

  METHOD deserialize_cmr_creation_input.
    FIELD-SYMBOLS <ls_cmr_create> TYPE zpru_if_computer_vision=>ts_cmr_create_request.

    ASSIGN is_input->* TO <ls_cmr_create>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    /ui2/cl_json=>deserialize( EXPORTING json          = <ls_cmr_create>-cmrcreationcontent
                                         hex_as_base64 = abap_true
                               CHANGING  data          = rt_creation ).
  ENDMETHOD.

  METHOD assign_cmr_ids.

    SELECT cmrid
    FROM  zr_pru_cmr_header
    ORDER BY cmrid DESCENDING
    INTO TABLE @DATA(lt_last_id) UP TO 1 ROWS.

    DATA(lv_max_cmrid) = VALUE #( lt_last_id[ 1 ]-cmrid OPTIONAL ).
    DATA(lv_next_cmrid_num) = CONV i( lv_max_cmrid ) + 1.

    LOOP AT ct_headers ASSIGNING FIELD-SYMBOL(<ls_header>).
      <ls_header>-cmrid = lv_next_cmrid_num.

      LOOP AT ct_items ASSIGNING FIELD-SYMBOL(<ls_item>)
           WHERE cmruuid = <ls_header>-cmruuid.
        <ls_item>-cmrid = <ls_header>-cmrid.
      ENDLOOP.

      lv_next_cmrid_num += 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD prepare_header_rap_entities.
    DATA(lv_header_cid) = 0.

    LOOP AT it_headers ASSIGNING FIELD-SYMBOL(<ls_header>).

      lv_header_cid += 1.
      APPEND INITIAL LINE TO rt_create ASSIGNING FIELD-SYMBOL(<ls_entity>).
      <ls_entity> = CORRESPONDING #( <ls_header> MAPPING TO ENTITY CHANGING CONTROL ).
      <ls_entity>-%cid = |H_{ lv_header_cid }|.

      <ls_entity>-%control-cmruuid = if_abap_behv=>mk-off.
    ENDLOOP.
  ENDMETHOD.

  METHOD prepare_item_rap_entities.
    DATA(lv_item_cid) = 1.

    LOOP AT it_items ASSIGNING FIELD-SYMBOL(<ls_item>)
         GROUP BY ( cmruuid = <ls_item>-cmruuid )
         ASSIGNING FIELD-SYMBOL(<group>).

      ASSIGN it_headers_create[ KEY entity COMPONENTS cmruuid = <group>-cmruuid ] TO FIELD-SYMBOL(<ls_header>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO rt_create ASSIGNING FIELD-SYMBOL(<ls_create_item>).
      <ls_create_item>-%cid_ref = <ls_header>-%cid.

      LOOP AT GROUP <group> ASSIGNING FIELD-SYMBOL(<ls_item_member>).
        APPEND INITIAL LINE TO <ls_create_item>-%target ASSIGNING FIELD-SYMBOL(<ls_target>).
        <ls_target> = CORRESPONDING #( <ls_item_member> MAPPING TO ENTITY CHANGING CONTROL ).
        <ls_target>-%cid =  |I_{ lv_item_cid }|.
        CLEAR: <ls_target>-cmruuid,
               <ls_target>-%control-cmruuid.
        lv_item_cid += 1.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD persist_cmr_via_rap.
    MODIFY ENTITIES OF zr_pru_cmr_header
           ENTITY zrprucmrheader
           CREATE FROM it_create_header
           ENTITY zrprucmrheader
           CREATE BY \_cmritems
           FROM it_create_item
           MAPPED DATA(ls_mapped)
           FAILED DATA(ls_failed).

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

    et_mapped_header = CORRESPONDING #( lt_new_cmr_headers MAPPING FROM ENTITY ).
    et_mapped_item   = CORRESPONDING #( lt_new_cmr_items MAPPING FROM ENTITY ).
  ENDMETHOD.

  METHOD append_cmr_output_pairs.
    APPEND INITIAL LINE TO ct_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv>).
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-cmrheaders-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = it_cmr_headers
                                             hex_as_base64 = abap_true
                                             compress      = abap_true ).

    APPEND INITIAL LINE TO ct_key_value_pairs ASSIGNING <ls_kv>.
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-cmritems-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = it_cmr_items
                                             hex_as_base64 = abap_true
                                             compress      = abap_true ).

    APPEND INITIAL LINE TO ct_key_value_pairs ASSIGNING <ls_kv>.
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-cmrcreationcontent-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = it_creation_content
                                             hex_as_base64 = abap_true
                                             compress      = abap_true ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_classify_danger_goods IMPLEMENTATION.
  METHOD execute_code_int.
    DATA lt_alert_rap TYPE TABLE FOR CREATE zr_pru_cmr_alert\\zrprucmralert.
    DATA lv_count     TYPE i.
    DATA lv_reason    TYPE string.

    DATA(lt_cmr_item_context) = deserialize_classify_input( is_input ).

    IF lt_cmr_item_context IS INITIAL.
      RETURN.
    ENDIF.

    lv_count = 0.
    LOOP AT lt_cmr_item_context ASSIGNING FIELD-SYMBOL(<ls_item>).
      lv_count += 1.
      DATA(lv_is_danger) = abap_false.
      CLEAR lv_reason.

      classify_single_item( EXPORTING is_item      = <ls_item>
                            IMPORTING ev_is_danger = lv_is_danger
                                      ev_reason    = lv_reason ).

      IF lv_is_danger = abap_true.
        DATA(ls_alert) = create_alert_entity( is_item      = <ls_item>
                                              iv_reason    = lv_reason
                                              iv_alert_seq = lv_count ).
        APPEND ls_alert TO lt_alert_rap.
      ENDIF.
    ENDLOOP.

    IF lt_alert_rap IS INITIAL.
      RETURN.
    ENDIF.

    persist_alerts_via_rap( EXPORTING it_alerts     = lt_alert_rap
                            IMPORTING et_alerts     = DATA(lt_cmr_alert_context)
                            CHANGING  ev_error_flag = ev_error_flag ).

    IF ev_error_flag = abap_true.
      RETURN.
    ENDIF.

    append_alert_output( EXPORTING it_alerts          = lt_cmr_alert_context
                         CHANGING  ct_key_value_pairs = et_key_value_pairs ).

    es_output = NEW zpru_tt_key_value( et_key_value_pairs ).
  ENDMETHOD.

  METHOD deserialize_classify_input.
    FIELD-SYMBOLS <ls_input> TYPE zpru_if_computer_vision=>ts_cmr_classify_req.

    ASSIGN is_input->* TO <ls_input>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-cmritems
                                         hex_as_base64 = abap_true
                               CHANGING  data          = rt_items ).
  ENDMETHOD.

  METHOD classify_single_item.
    ev_is_danger = abap_false.

    ev_reason = check_danger_by_hazard_class( is_item-hazardclass ).
    IF ev_reason IS NOT INITIAL.
      ev_is_danger = abap_true.
      RETURN.
    ENDIF.

    ev_reason = check_danger_by_un_number( is_item-unitednationnumber ).
    IF ev_reason IS NOT INITIAL.
      ev_is_danger = abap_true.
      RETURN.
    ENDIF.

    DATA(lv_nature_up) = to_upper( is_item-natureofgoods ).

    ev_reason = check_explosive( lv_nature_up ).
    IF ev_reason IS NOT INITIAL.
      ev_is_danger = abap_true.
      RETURN.
    ENDIF.

    ev_reason = check_flammable_gas( lv_nature_up ).
    IF ev_reason IS NOT INITIAL.
      ev_is_danger = abap_true.
      RETURN.
    ENDIF.

    ev_reason = check_flammable_liquid( lv_nature_up ).
    IF ev_reason IS NOT INITIAL.
      ev_is_danger = abap_true.
      RETURN.
    ENDIF.

    ev_reason = check_flammable_solid( lv_nature_up ).
    IF ev_reason IS NOT INITIAL.
      ev_is_danger = abap_true.
      RETURN.
    ENDIF.

    ev_reason = check_oxidiser( lv_nature_up ).
    IF ev_reason IS NOT INITIAL.
      ev_is_danger = abap_true.
      RETURN.
    ENDIF.

    ev_reason = check_toxic( lv_nature_up ).
    IF ev_reason IS NOT INITIAL.
      ev_is_danger = abap_true.
      RETURN.
    ENDIF.

    ev_reason = check_infectious( lv_nature_up ).
    IF ev_reason IS NOT INITIAL.
      ev_is_danger = abap_true.
      RETURN.
    ENDIF.

    ev_reason = check_radioactive( lv_nature_up ).
    IF ev_reason IS NOT INITIAL.
      ev_is_danger = abap_true.
      RETURN.
    ENDIF.

    ev_reason = check_corrosive( lv_nature_up ).
    IF ev_reason IS NOT INITIAL.
      ev_is_danger = abap_true.
      RETURN.
    ENDIF.

    ev_reason = check_hazardous_other( lv_nature_up ).
    IF ev_reason IS NOT INITIAL.
      ev_is_danger = abap_true.
      RETURN.
    ENDIF.
  ENDMETHOD.

  METHOD check_danger_by_hazard_class.
    IF iv_hazardclass IS NOT INITIAL.
      rv_reason = |Hazard class { iv_hazardclass } detected|.
    ENDIF.
  ENDMETHOD.

  METHOD check_danger_by_un_number.
    IF iv_un_number IS NOT INITIAL.
      rv_reason = |UN number { iv_un_number } present|.
    ENDIF.
  ENDMETHOD.

  METHOD check_explosive.
    IF iv_nature_up CS 'EXPLOS'.
      rv_reason = 'Explosive material detected in nature of goods'.
    ENDIF.
  ENDMETHOD.

  METHOD check_flammable_gas.
    IF    iv_nature_up CS 'FLAMMABLE GAS'
       OR iv_nature_up CS 'INFLAMMABLE GAS'
       OR iv_nature_up CS 'LPG'
       OR iv_nature_up CS 'LNG'
       OR iv_nature_up CS 'COMPRESSED GAS'
       OR iv_nature_up CS 'PROPANE'
       OR iv_nature_up CS 'BUTANE'
       OR iv_nature_up CS 'ACETYLENE'
       OR iv_nature_up CS 'HYDROGEN'.
      rv_reason = 'Flammable gas detected in nature of goods'.
    ENDIF.
  ENDMETHOD.

  METHOD check_flammable_liquid.
    IF    iv_nature_up CS 'FLAMMABLE LIQUID'
       OR iv_nature_up CS 'INFLAMMABLE LIQUID'
       OR iv_nature_up CS 'PETROL'
       OR iv_nature_up CS 'GASOLINE'
       OR iv_nature_up CS 'DIESEL'
       OR iv_nature_up CS 'KEROSENE'
       OR iv_nature_up CS 'ETHANOL'
       OR iv_nature_up CS 'METHANOL'
       OR iv_nature_up CS 'ACETONE'
       OR iv_nature_up CS 'BENZENE'
       OR iv_nature_up CS 'TOLUENE'
       OR iv_nature_up CS 'FUEL OIL'.
      rv_reason = 'Flammable liquid detected in nature of goods'.
    ENDIF.
  ENDMETHOD.

  METHOD check_flammable_solid.
    IF    iv_nature_up CS 'FLAMMABLE SOLID'
       OR iv_nature_up CS 'INFLAMMABLE SOLID'
       OR iv_nature_up CS 'PHOSPHORUS'
       OR iv_nature_up CS 'SULPHUR'
       OR iv_nature_up CS 'SULFUR'
       OR iv_nature_up CS 'MAGNESIUM'
       OR iv_nature_up CS 'ALUMINIUM POWDER'
       OR iv_nature_up CS 'ALUMINUM POWDER'.
      rv_reason = 'Flammable solid detected in nature of goods'.
    ENDIF.
  ENDMETHOD.

  METHOD check_oxidiser.
    IF    iv_nature_up CS 'OXIDIS'
       OR iv_nature_up CS 'OXIDIZ'
       OR iv_nature_up CS 'PEROXIDE'
       OR iv_nature_up CS 'PERMANGANATE'
       OR iv_nature_up CS 'CHLORATE'
       OR iv_nature_up CS 'NITRATE'
       OR iv_nature_up CS 'PERCHLORATE'.
      rv_reason = 'Oxidiser/organic peroxide detected in nature of goods'.
    ENDIF.
  ENDMETHOD.

  METHOD check_toxic.
    IF    iv_nature_up CS 'TOXIC'
       OR iv_nature_up CS 'POISON'
       OR iv_nature_up CS 'PESTICIDE'
       OR iv_nature_up CS 'HERBICIDE'
       OR iv_nature_up CS 'INSECTICIDE'
       OR iv_nature_up CS 'CYANIDE'
       OR iv_nature_up CS 'ARSENIC'
       OR iv_nature_up CS 'MERCURY'
       OR iv_nature_up CS 'CHLORINE'
       OR iv_nature_up CS 'AMMONIA'
       OR iv_nature_up CS 'FORMALDEHYDE'.
      rv_reason = 'Toxic substance detected in nature of goods'.
    ENDIF.
  ENDMETHOD.

  METHOD check_infectious.
    IF    iv_nature_up CS 'INFECTIOUS'
       OR iv_nature_up CS 'PATHOGEN'
       OR iv_nature_up CS 'CLINICAL WASTE'
       OR iv_nature_up CS 'MEDICAL WASTE'.
      rv_reason = 'Infectious substance detected in nature of goods'.
    ENDIF.
  ENDMETHOD.

  METHOD check_radioactive.
    IF    iv_nature_up CS 'RADIOACT'
       OR iv_nature_up CS 'NUCLEAR'
       OR iv_nature_up CS 'URANIUM'
       OR iv_nature_up CS 'PLUTONIUM'
       OR iv_nature_up CS 'ISOTOPE'.
      rv_reason = 'Radioactive material detected in nature of goods'.
    ENDIF.
  ENDMETHOD.

  METHOD check_corrosive.
    IF    iv_nature_up CS 'CORROSIVE'
       OR iv_nature_up CS 'ACID'
       OR iv_nature_up CS 'CAUSTIC'
       OR iv_nature_up CS 'SULPHURIC'
       OR iv_nature_up CS 'SULFURIC'
       OR iv_nature_up CS 'HYDROCHLORIC'
       OR iv_nature_up CS 'SODIUM HYDROXIDE'
       OR iv_nature_up CS 'POTASSIUM HYDROXIDE'
       OR iv_nature_up CS 'BLEACH'.
      rv_reason = 'Corrosive substance detected in nature of goods'.
    ENDIF.
  ENDMETHOD.

  METHOD check_hazardous_other.
    IF    iv_nature_up CS 'DANGEROUS GOODS'
       OR iv_nature_up CS 'HAZARDOUS'
       OR iv_nature_up CS 'LITHIUM BATTER'
       OR iv_nature_up CS 'DRY ICE'
       OR iv_nature_up CS 'MAGNETIS'.
      rv_reason = 'Hazardous material detected in nature of goods'.
    ENDIF.
  ENDMETHOD.

  METHOD create_alert_entity.
    TRY.
        rs_alert-alertuuid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.

    rs_alert-%cid          = |ALERT{ iv_alert_seq }|.
    rs_alert-cmruuid       = is_item-cmruuid.
    rs_alert-cmrid         = is_item-cmrid.
    rs_alert-cmritemuuid   = is_item-cmritemuuid.
    rs_alert-itemposition  = is_item-itemposition.
    rs_alert-natureofgoods = is_item-natureofgoods.
    rs_alert-alerttype     = 'DANGER_GOODS'.
    rs_alert-alertmessage  = iv_reason.

    rs_alert-%control      = VALUE #( alertuuid     = if_abap_behv=>mk-on
                                      cmruuid       = if_abap_behv=>mk-on
                                      cmrid         = if_abap_behv=>mk-on
                                      cmritemuuid   = if_abap_behv=>mk-on
                                      itemposition  = if_abap_behv=>mk-on
                                      natureofgoods = if_abap_behv=>mk-on
                                      alerttype     = if_abap_behv=>mk-on
                                      alertmessage  = if_abap_behv=>mk-on ).
  ENDMETHOD.

  METHOD persist_alerts_via_rap.
    CLEAR et_alerts.

    IF it_alerts IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_pru_cmr_alert
           ENTITY zrprucmralert
           CREATE FROM it_alerts
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

    et_alerts = CORRESPONDING #( lt_alert_create MAPPING FROM ENTITY ).
  ENDMETHOD.

  METHOD append_alert_output.
    APPEND INITIAL LINE TO ct_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv>).
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-cmralerts-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = it_alerts
                                             hex_as_base64 = abap_true
                                             compress      = abap_true ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_validate_cmr IMPLEMENTATION.
  METHOD execute_code_int.
    DATA lt_findings_rap TYPE TABLE FOR CREATE zr_pru_cmr_valid\\zrprucmrvalid.
    DATA lt_findings_out TYPE zpru_if_computer_vision=>tt_cmr_finding.
    DATA lt_cmr_status   TYPE zpru_if_computer_vision=>tt_cmr_overall_status.
    DATA lv_cid_counter  TYPE i VALUE 1.
    DATA lt_headers      TYPE zpru_if_computer_vision=>tt_cmr_header_context.
    DATA lt_items        TYPE zpru_if_computer_vision=>tt_cmr_item_context.

    deserialize_validation_input( EXPORTING is_input   = is_input
                                  IMPORTING et_headers = lt_headers
                                            et_items   = lt_items ).

    LOOP AT lt_headers ASSIGNING FIELD-SYMBOL(<ls_hdr>).
      validate_header_senderinfo( EXPORTING is_header       = <ls_hdr>
                                  CHANGING  ct_findings     = lt_findings_out
                                            ct_findings_rap = lt_findings_rap
                                            cv_cid_counter  = lv_cid_counter ).

      validate_header_consigneeinfo( EXPORTING is_header       = <ls_hdr>
                                     CHANGING  ct_findings     = lt_findings_out
                                               ct_findings_rap = lt_findings_rap
                                               cv_cid_counter  = lv_cid_counter ).

      validate_header_carrierinfo( EXPORTING is_header       = <ls_hdr>
                                   CHANGING  ct_findings     = lt_findings_out
                                             ct_findings_rap = lt_findings_rap
                                             cv_cid_counter  = lv_cid_counter ).

      validate_head_takingoverplace( EXPORTING is_header       = <ls_hdr>
                                     CHANGING  ct_findings     = lt_findings_out
                                               ct_findings_rap = lt_findings_rap
                                               cv_cid_counter  = lv_cid_counter ).

      validate_header_deliveryplace( EXPORTING is_header       = <ls_hdr>
                                     CHANGING  ct_findings     = lt_findings_out
                                               ct_findings_rap = lt_findings_rap
                                               cv_cid_counter  = lv_cid_counter ).

      validate_header_takingoverdate( EXPORTING is_header       = <ls_hdr>
                                      CHANGING  ct_findings     = lt_findings_out
                                                ct_findings_rap = lt_findings_rap
                                                cv_cid_counter  = lv_cid_counter ).

      validate_header_currency( EXPORTING is_header       = <ls_hdr>
                                CHANGING  ct_findings     = lt_findings_out
                                          ct_findings_rap = lt_findings_rap
                                          cv_cid_counter  = lv_cid_counter ).

      validate_item_count( EXPORTING is_header       = <ls_hdr>
                                     it_items        = lt_items
                           CHANGING  ct_findings     = lt_findings_out
                                     ct_findings_rap = lt_findings_rap
                                     cv_cid_counter  = lv_cid_counter ).

      LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_item>)
           WHERE cmruuid = <ls_hdr>-cmruuid.

        validate_item_natureofgoods( EXPORTING is_header       = <ls_hdr>
                                               is_item         = <ls_item>
                                     CHANGING  ct_findings     = lt_findings_out
                                               ct_findings_rap = lt_findings_rap
                                               cv_cid_counter  = lv_cid_counter ).

        validate_item_grossweight( EXPORTING is_header       = <ls_hdr>
                                             is_item         = <ls_item>
                                   CHANGING  ct_findings     = lt_findings_out
                                             ct_findings_rap = lt_findings_rap
                                             cv_cid_counter  = lv_cid_counter ).

        validate_item_weightunit( EXPORTING is_header       = <ls_hdr>
                                            is_item         = <ls_item>
                                  CHANGING  ct_findings     = lt_findings_out
                                            ct_findings_rap = lt_findings_rap
                                            cv_cid_counter  = lv_cid_counter ).

        validate_item_dg_fields( EXPORTING is_header       = <ls_hdr>
                                           is_item         = <ls_item>
                                 CHANGING  ct_findings     = lt_findings_out
                                           ct_findings_rap = lt_findings_rap
                                           cv_cid_counter  = lv_cid_counter ).
      ENDLOOP.

      calculate_cmr_status( EXPORTING is_header   = <ls_hdr>
                                      it_findings = lt_findings_out
                            CHANGING  ct_status   = lt_cmr_status ).
    ENDLOOP.

    persist_validation_findings( EXPORTING it_findings_rap = lt_findings_rap
                                 CHANGING  ev_error_flag   = ev_error_flag ).

    IF ev_error_flag = abap_true.
      RETURN.
    ENDIF.

    append_validation_output( EXPORTING it_cmr_status      = lt_cmr_status
                                        it_cmr_findings    = lt_findings_out
                              CHANGING  ct_key_value_pairs = et_key_value_pairs ).

    es_output = NEW zpru_tt_key_value( et_key_value_pairs ).
  ENDMETHOD.

  METHOD deserialize_validation_input.
    FIELD-SYMBOLS <ls_input> TYPE zpru_if_computer_vision=>ts_cmr_validate_req.

    ASSIGN is_input->* TO <ls_input>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-cmrheaders
                                         hex_as_base64 = abap_true
                               CHANGING  data          = et_headers ).
    /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-cmritems
                                         hex_as_base64 = abap_true
                               CHANGING  data          = et_items ).
  ENDMETHOD.

  METHOD validate_header_senderinfo.
    IF is_header-senderinfo IS NOT INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(lv_findinguuid) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.

    add_finding_to_output( EXPORTING is_finding_rap = VALUE #( findinguuid   = lv_findinguuid
                                                               cmruuid       = is_header-cmruuid
                                                               cmrid         = is_header-cmrid
                                                               findingstatus = 'INCOMPLETE'
                                                               findingtype   = 'MANDATORY_FIELD'
                                                               fieldname     = 'SENDERINFO'
                                                               findingmsg    = 'Sender information is missing'  )
                           CHANGING  ct_findings    = ct_findings  ).

    DATA(ls_latest_finding) = VALUE #( ct_findings[ lines( ct_findings ) ] OPTIONAL ).
    IF ls_latest_finding IS INITIAL.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO ct_findings_rap ASSIGNING FIELD-SYMBOL(<ls_rap>).

    <ls_rap> = CORRESPONDING #( ls_latest_finding ).
    <ls_rap>-%cid     = |FIND{ cv_cid_counter }|.

    <ls_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                 cmruuid       = if_abap_behv=>mk-on
                                 cmrid         = if_abap_behv=>mk-on
                                 findingstatus = if_abap_behv=>mk-on
                                 findingtype   = if_abap_behv=>mk-on
                                 fieldname     = if_abap_behv=>mk-on
                                 findingmsg    = if_abap_behv=>mk-on ).

    cv_cid_counter += 1.
  ENDMETHOD.

  METHOD add_finding_to_output.
    DATA(ls_finding) = is_finding_rap.
    APPEND ls_finding TO ct_findings.
  ENDMETHOD.

  METHOD validate_header_consigneeinfo.
    IF is_header-consigneeinfo IS NOT INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(lv_findinguuid) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.

    add_finding_to_output( EXPORTING is_finding_rap = VALUE #( findinguuid   = lv_findinguuid
                                                               cmruuid       = is_header-cmruuid
                                                               cmrid         = is_header-cmrid
                                                               findingstatus = 'INCOMPLETE'
                                                               findingtype   = 'MANDATORY_FIELD'
                                                               fieldname     = 'CONSIGNEEINFO'
                                                               findingmsg    = 'Consignee information is missing'  )
                           CHANGING  ct_findings    = ct_findings  ).
    DATA(ls_latest_finding) = VALUE #( ct_findings[ lines( ct_findings ) ] OPTIONAL ).
    IF ls_latest_finding IS INITIAL.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO ct_findings_rap ASSIGNING FIELD-SYMBOL(<ls_rap>).

    <ls_rap> = CORRESPONDING #( ls_latest_finding ).
    <ls_rap>-%cid     = |FIND{ cv_cid_counter }|.

    <ls_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                 cmruuid       = if_abap_behv=>mk-on
                                 cmrid         = if_abap_behv=>mk-on
                                 findingstatus = if_abap_behv=>mk-on
                                 findingtype   = if_abap_behv=>mk-on
                                 fieldname     = if_abap_behv=>mk-on
                                 findingmsg    = if_abap_behv=>mk-on  ).

    cv_cid_counter += 1.
  ENDMETHOD.

  METHOD validate_header_carrierinfo.
    IF is_header-carrierinfo IS NOT INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(lv_findinguuid) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.

    add_finding_to_output( EXPORTING is_finding_rap = VALUE #( findinguuid   = lv_findinguuid
                                                               cmruuid       = is_header-cmruuid
                                                               cmrid         = is_header-cmrid
                                                               findingstatus = 'INCOMPLETE'
                                                               findingtype   = 'MANDATORY_FIELD'
                                                               fieldname     = 'CARRIERINFO'
                                                               findingmsg    = 'Carrier information is missing'  )
                           CHANGING  ct_findings    = ct_findings  ).
    DATA(ls_latest_finding) = VALUE #( ct_findings[ lines( ct_findings ) ] OPTIONAL ).
    IF ls_latest_finding IS INITIAL.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO ct_findings_rap ASSIGNING FIELD-SYMBOL(<ls_rap>).

    <ls_rap> = CORRESPONDING #( ls_latest_finding ).
    <ls_rap>-%cid     = |FIND{ cv_cid_counter }|.

    <ls_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                 cmruuid       = if_abap_behv=>mk-on
                                 cmrid         = if_abap_behv=>mk-on
                                 findingstatus = if_abap_behv=>mk-on
                                 findingtype   = if_abap_behv=>mk-on
                                 fieldname     = if_abap_behv=>mk-on
                                 findingmsg    = if_abap_behv=>mk-on ).

    cv_cid_counter += 1.
  ENDMETHOD.

  METHOD validate_head_takingoverplace.
    IF is_header-takingoverplace IS NOT INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(lv_findinguuid) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.

    add_finding_to_output( EXPORTING is_finding_rap = VALUE #( findinguuid   = lv_findinguuid
                                                               cmruuid       = is_header-cmruuid
                                                               cmrid         = is_header-cmrid
                                                               findingstatus = 'INCOMPLETE'
                                                               findingtype   = 'MANDATORY_FIELD'
                                                               fieldname     = 'TAKINGOVERPLACE'
                                                               findingmsg    = 'Taking-over place is missing'  )
                           CHANGING  ct_findings    = ct_findings ).
    DATA(ls_latest_finding) = VALUE #( ct_findings[ lines( ct_findings ) ] OPTIONAL ).
    IF ls_latest_finding IS INITIAL.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO ct_findings_rap ASSIGNING FIELD-SYMBOL(<ls_rap>).

    <ls_rap> = CORRESPONDING #( ls_latest_finding ).
    <ls_rap>-%cid     = |FIND{ cv_cid_counter }|.

    <ls_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                 cmruuid       = if_abap_behv=>mk-on
                                 cmrid         = if_abap_behv=>mk-on
                                 findingstatus = if_abap_behv=>mk-on
                                 findingtype   = if_abap_behv=>mk-on
                                 fieldname     = if_abap_behv=>mk-on
                                 findingmsg    = if_abap_behv=>mk-on  ).

    cv_cid_counter += 1.
  ENDMETHOD.

  METHOD validate_header_deliveryplace.
    IF is_header-deliveryplace IS NOT INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(lv_findinguuid) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.

    add_finding_to_output( EXPORTING is_finding_rap = VALUE #( findinguuid   = lv_findinguuid
                                                               cmruuid       = is_header-cmruuid
                                                               cmrid         = is_header-cmrid
                                                               findingstatus = 'INCOMPLETE'
                                                               findingtype   = 'MANDATORY_FIELD'
                                                               fieldname     = 'DELIVERYPLACE'
                                                               findingmsg    = 'Delivery place is missing'  )
                           CHANGING  ct_findings    = ct_findings  ).
    DATA(ls_latest_finding) = VALUE #( ct_findings[ lines( ct_findings ) ] OPTIONAL ).
    IF ls_latest_finding IS INITIAL.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO ct_findings_rap ASSIGNING FIELD-SYMBOL(<ls_rap>).

    <ls_rap> = CORRESPONDING #( ls_latest_finding ).
    <ls_rap>-%cid     = |FIND{ cv_cid_counter }|.

    <ls_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                 cmruuid       = if_abap_behv=>mk-on
                                 cmrid         = if_abap_behv=>mk-on
                                 findingstatus = if_abap_behv=>mk-on
                                 findingtype   = if_abap_behv=>mk-on
                                 fieldname     = if_abap_behv=>mk-on
                                 findingmsg    = if_abap_behv=>mk-on  ).

    cv_cid_counter += 1.
  ENDMETHOD.

  METHOD validate_header_takingoverdate.
    IF NOT ( is_header-takingoverdate IS INITIAL OR is_header-takingoverdate = '00000000' ).
      RETURN.
    ENDIF.

    TRY.
        DATA(lv_findinguuid) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.

    add_finding_to_output( EXPORTING is_finding_rap = VALUE #( findinguuid   = lv_findinguuid
                                                               cmruuid       = is_header-cmruuid
                                                               cmrid         = is_header-cmrid
                                                               findingstatus = 'INCOMPLETE'
                                                               findingtype   = 'DATE_CHECK'
                                                               fieldname     = 'TAKINGOVERDATE'
                                                               findingmsg    = 'Taking-over date is missing'  )
                           CHANGING  ct_findings    = ct_findings  ).
    DATA(ls_latest_finding) = VALUE #( ct_findings[ lines( ct_findings ) ] OPTIONAL ).
    IF ls_latest_finding IS INITIAL.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO ct_findings_rap ASSIGNING FIELD-SYMBOL(<ls_rap>).

    <ls_rap> = CORRESPONDING #( ls_latest_finding ).
    <ls_rap>-%cid     = |FIND{ cv_cid_counter }|.

    <ls_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                 cmruuid       = if_abap_behv=>mk-on
                                 cmrid         = if_abap_behv=>mk-on
                                 findingstatus = if_abap_behv=>mk-on
                                 findingtype   = if_abap_behv=>mk-on
                                 fieldname     = if_abap_behv=>mk-on
                                 findingmsg    = if_abap_behv=>mk-on  ).

    cv_cid_counter += 1.
  ENDMETHOD.

  METHOD validate_header_currency.
    IF is_header-cashondelivery <= 0 OR is_header-currency IS NOT INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(lv_findinguuid) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.

    add_finding_to_output( EXPORTING is_finding_rap = VALUE #(
                               findinguuid   = lv_findinguuid
                               cmruuid       = is_header-cmruuid
                               cmrid         = is_header-cmrid
                               findingstatus = 'INCOMPLETE'
                               findingtype   = 'MANDATORY_FIELD'
                               fieldname     = 'CURRENCY'
                               findingmsg    = 'Currency required when cash on delivery is set'  )
                           CHANGING  ct_findings    = ct_findings  ).
    DATA(ls_latest_finding) = VALUE #( ct_findings[ lines( ct_findings ) ] OPTIONAL ).
    IF ls_latest_finding IS INITIAL.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO ct_findings_rap ASSIGNING FIELD-SYMBOL(<ls_rap>).

    <ls_rap> = CORRESPONDING #( ls_latest_finding ).
    <ls_rap>-%cid     = |FIND{ cv_cid_counter }|.

    <ls_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                 cmruuid       = if_abap_behv=>mk-on
                                 cmrid         = if_abap_behv=>mk-on
                                 findingstatus = if_abap_behv=>mk-on
                                 findingtype   = if_abap_behv=>mk-on
                                 fieldname     = if_abap_behv=>mk-on
                                 findingmsg    = if_abap_behv=>mk-on  ).

    cv_cid_counter += 1.
  ENDMETHOD.

  METHOD validate_item_count.
    DATA(lv_item_count) = REDUCE i( INIT n = 0
                                    FOR <it> IN it_items
                                    WHERE ( cmruuid = is_header-cmruuid )
                                    NEXT n = n + 1 ).
    IF lv_item_count <> 0.
      RETURN.
    ENDIF.

    TRY.
        DATA(lv_findinguuid) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.

    add_finding_to_output( EXPORTING is_finding_rap = VALUE #( findinguuid   = lv_findinguuid
                                                               cmruuid       = is_header-cmruuid
                                                               cmrid         = is_header-cmrid
                                                               findingstatus = 'INVALID'
                                                               findingtype   = 'ITEM_COUNT'
                                                               fieldname     = ''
                                                               findingmsg    = 'No items found for CMR'  )
                           CHANGING  ct_findings    = ct_findings ).
    DATA(ls_latest_finding) = VALUE #( ct_findings[ lines( ct_findings ) ] OPTIONAL ).
    IF ls_latest_finding IS INITIAL.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO ct_findings_rap ASSIGNING FIELD-SYMBOL(<ls_rap>).

    <ls_rap> = CORRESPONDING #( ls_latest_finding ).
    <ls_rap>-%cid     = |FIND{ cv_cid_counter }|.

    <ls_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                 cmruuid       = if_abap_behv=>mk-on
                                 cmrid         = if_abap_behv=>mk-on
                                 findingstatus = if_abap_behv=>mk-on
                                 findingtype   = if_abap_behv=>mk-on
                                 fieldname     = if_abap_behv=>mk-on
                                 findingmsg    = if_abap_behv=>mk-on ).

    cv_cid_counter += 1.
  ENDMETHOD.

  METHOD validate_item_natureofgoods.
    IF is_item-natureofgoods IS NOT INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(lv_findinguuid) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.

    add_finding_to_output( EXPORTING is_finding_rap = VALUE #(
                               findinguuid   = lv_findinguuid
                               cmruuid       = is_header-cmruuid
                               cmrid         = is_header-cmrid
                               cmritemuuid   = is_item-cmritemuuid
                               itemposition  = is_item-itemposition
                               findingstatus = 'INCOMPLETE'
                               findingtype   = 'MANDATORY_FIELD'
                               fieldname     = 'NATUREOFGOODS'
                               findingmsg    = |Nature of goods is missing for item { is_item-itemposition }|  )
                           CHANGING  ct_findings    = ct_findings  ).
    DATA(ls_latest_finding) = VALUE #( ct_findings[ lines( ct_findings ) ] OPTIONAL ).
    IF ls_latest_finding IS INITIAL.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO ct_findings_rap ASSIGNING FIELD-SYMBOL(<ls_rap>).

    <ls_rap> = CORRESPONDING #( ls_latest_finding ).
    <ls_rap>-%cid     = |FIND{ cv_cid_counter }|.

    <ls_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                 cmruuid       = if_abap_behv=>mk-on
                                 cmrid         = if_abap_behv=>mk-on
                                 findingstatus = if_abap_behv=>mk-on
                                 findingtype   = if_abap_behv=>mk-on
                                 fieldname     = if_abap_behv=>mk-on
                                 findingmsg    = if_abap_behv=>mk-on  ).

    cv_cid_counter += 1.
  ENDMETHOD.

  METHOD validate_item_grossweight.
    IF is_item-grossweight > 0.
      RETURN.
    ENDIF.

    TRY.
        DATA(lv_findinguuid) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.

    add_finding_to_output(
      EXPORTING is_finding_rap = VALUE #(
          findinguuid   = lv_findinguuid
          cmruuid       = is_header-cmruuid
          cmrid         = is_header-cmrid
          cmritemuuid   = is_item-cmritemuuid
          itemposition  = is_item-itemposition
          findingstatus = 'INCOMPLETE'
          findingtype   = 'WEIGHT_CHECK'
          fieldname     = 'GROSSWEIGHT'
          findingmsg    = |Gross weight must be greater than zero for item { is_item-itemposition }|  )
      CHANGING  ct_findings    = ct_findings ).
    DATA(ls_latest_finding) = VALUE #( ct_findings[ lines( ct_findings ) ] OPTIONAL ).
    IF ls_latest_finding IS INITIAL.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO ct_findings_rap ASSIGNING FIELD-SYMBOL(<ls_rap>).

    <ls_rap> = CORRESPONDING #( ls_latest_finding ).
    <ls_rap>-%cid     = |FIND{ cv_cid_counter }|.

    <ls_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                 cmruuid       = if_abap_behv=>mk-on
                                 cmrid         = if_abap_behv=>mk-on
                                 findingstatus = if_abap_behv=>mk-on
                                 findingtype   = if_abap_behv=>mk-on
                                 fieldname     = if_abap_behv=>mk-on
                                 findingmsg    = if_abap_behv=>mk-on  ).

    cv_cid_counter += 1.
  ENDMETHOD.

  METHOD validate_item_weightunit.
    IF is_item-weightunitfield IS NOT INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(lv_findinguuid) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.

    add_finding_to_output( EXPORTING is_finding_rap = VALUE #(
                               findinguuid   = lv_findinguuid
                               cmruuid       = is_header-cmruuid
                               cmrid         = is_header-cmrid
                               cmritemuuid   = is_item-cmritemuuid
                               itemposition  = is_item-itemposition
                               findingstatus = 'INCOMPLETE'
                               findingtype   = 'MANDATORY_FIELD'
                               fieldname     = 'WEIGHTUNITFIELD'
                               findingmsg    = |Weight unit is missing for item { is_item-itemposition }|  )
                           CHANGING  ct_findings    = ct_findings  ).
    DATA(ls_latest_finding) = VALUE #( ct_findings[ lines( ct_findings ) ] OPTIONAL ).
    IF ls_latest_finding IS INITIAL.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO ct_findings_rap ASSIGNING FIELD-SYMBOL(<ls_rap>).

    <ls_rap> = CORRESPONDING #( ls_latest_finding ).
    <ls_rap>-%cid     = |FIND{ cv_cid_counter }|.

    <ls_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                 cmruuid       = if_abap_behv=>mk-on
                                 cmrid         = if_abap_behv=>mk-on
                                 findingstatus = if_abap_behv=>mk-on
                                 findingtype   = if_abap_behv=>mk-on
                                 fieldname     = if_abap_behv=>mk-on
                                 findingmsg    = if_abap_behv=>mk-on  ).

    cv_cid_counter += 1.
  ENDMETHOD.

  METHOD validate_item_dg_fields.
    IF is_item-unitednationnumber IS INITIAL.

      TRY.
          DATA(lv_findinguuid) = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error.
      ENDTRY.

      add_finding_to_output( EXPORTING is_finding_rap = VALUE #(
                                 findinguuid   = lv_findinguuid
                                 cmruuid       = is_header-cmruuid
                                 cmrid         = is_header-cmrid
                                 cmritemuuid   = is_item-cmritemuuid
                                 itemposition  = is_item-itemposition
                                 findingstatus = 'INCOMPLETE'
                                 findingtype   = 'DG_FIELDS'
                                 fieldname     = 'UNITEDNATIONNUMBER'
                                 findingmsg    = |UN number required for dangerous goods item { is_item-itemposition }|  )
                             CHANGING  ct_findings    = ct_findings  ).

      DATA(ls_latest_finding) = VALUE #( ct_findings[ lines( ct_findings ) ] OPTIONAL ).
      IF ls_latest_finding IS INITIAL.
        RETURN.
      ENDIF.

      APPEND INITIAL LINE TO ct_findings_rap ASSIGNING FIELD-SYMBOL(<ls_rap>).

      <ls_rap> = CORRESPONDING #( ls_latest_finding ).
      <ls_rap>-%cid     = |FIND{ cv_cid_counter }|.

      <ls_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                   cmruuid       = if_abap_behv=>mk-on
                                   cmrid         = if_abap_behv=>mk-on
                                   findingstatus = if_abap_behv=>mk-on
                                   findingtype   = if_abap_behv=>mk-on
                                   fieldname     = if_abap_behv=>mk-on
                                   findingmsg    = if_abap_behv=>mk-on  ).

      cv_cid_counter += 1.
    ENDIF.

    IF is_item-hazardclass IS INITIAL.

      TRY.
          lv_findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error.
      ENDTRY.

      add_finding_to_output(
        EXPORTING is_finding_rap = VALUE #(
            findinguuid   = lv_findinguuid
            cmruuid       = is_header-cmruuid
            cmrid         = is_header-cmrid
            cmritemuuid   = is_item-cmritemuuid
            itemposition  = is_item-itemposition
            findingstatus = 'INCOMPLETE'
            findingtype   = 'DG_FIELDS'
            fieldname     = 'HAZARDCLASS'
            findingmsg    = |Hazard class required for dangerous goods item { is_item-itemposition }|  )
        CHANGING  ct_findings    = ct_findings  ).

      ls_latest_finding = VALUE #( ct_findings[ lines( ct_findings ) ] OPTIONAL ).
      IF ls_latest_finding IS INITIAL.
        RETURN.
      ENDIF.

      APPEND INITIAL LINE TO ct_findings_rap ASSIGNING <ls_rap>.

      <ls_rap> = CORRESPONDING #( ls_latest_finding ).
      <ls_rap>-%cid     = |FIND{ cv_cid_counter }|.

      <ls_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                   cmruuid       = if_abap_behv=>mk-on
                                   cmrid         = if_abap_behv=>mk-on
                                   findingstatus = if_abap_behv=>mk-on
                                   findingtype   = if_abap_behv=>mk-on
                                   fieldname     = if_abap_behv=>mk-on
                                   findingmsg    = if_abap_behv=>mk-on  ).

      cv_cid_counter += 1.
    ENDIF.

    IF is_item-packinggroup IS INITIAL.

      TRY.
          lv_findinguuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error.
      ENDTRY.

      add_finding_to_output(
        EXPORTING is_finding_rap = VALUE #(
            findinguuid   = lv_findinguuid
            cmruuid       = is_header-cmruuid
            cmrid         = is_header-cmrid
            cmritemuuid   = is_item-cmritemuuid
            itemposition  = is_item-itemposition
            findingstatus = 'INCOMPLETE'
            findingtype   = 'DG_FIELDS'
            fieldname     = 'PACKINGGROUP'
            findingmsg    = |Packing group required for dangerous goods item { is_item-itemposition }|  )
        CHANGING  ct_findings    = ct_findings  ).

      ls_latest_finding = VALUE #( ct_findings[ lines( ct_findings ) ] OPTIONAL ).
      IF ls_latest_finding IS INITIAL.
        RETURN.
      ENDIF.

      APPEND INITIAL LINE TO ct_findings_rap ASSIGNING <ls_rap>.

      <ls_rap> = CORRESPONDING #( ls_latest_finding ).
      <ls_rap>-%cid     = |FIND{ cv_cid_counter }|.

      <ls_rap>-%control = VALUE #( findinguuid   = if_abap_behv=>mk-on
                                   cmruuid       = if_abap_behv=>mk-on
                                   cmrid         = if_abap_behv=>mk-on
                                   findingstatus = if_abap_behv=>mk-on
                                   findingtype   = if_abap_behv=>mk-on
                                   fieldname     = if_abap_behv=>mk-on
                                   findingmsg    = if_abap_behv=>mk-on  ).

      cv_cid_counter += 1.
    ENDIF.
  ENDMETHOD.

  METHOD calculate_cmr_status.
    APPEND INITIAL LINE TO ct_status ASSIGNING FIELD-SYMBOL(<ls_status>).
    <ls_status>-cmruuid = is_header-cmruuid.
    <ls_status>-cmrid   = is_header-cmrid.

    IF line_exists( it_findings[ cmruuid       = is_header-cmruuid
                                 findingstatus = 'INVALID' ] ).
      <ls_status>-overallstatus = 'INVALID'.
    ELSE.
      IF line_exists( it_findings[ cmruuid = is_header-cmruuid ] ).
        <ls_status>-overallstatus = 'INCOMPLETE'.
      ELSE.
        <ls_status>-overallstatus = 'VALID'.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD persist_validation_findings.
    IF it_findings_rap IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_pru_cmr_valid
           ENTITY zrprucmrvalid
           CREATE FROM it_findings_rap
           " TODO: variable is assigned but never used (ABAP cleaner)
           MAPPED DATA(ls_mapped)
           FAILED DATA(ls_failed).

    IF ls_failed IS NOT INITIAL.
      ev_error_flag = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD append_validation_output.
    APPEND INITIAL LINE TO ct_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv>).
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-cmrstatus-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = it_cmr_status
                                             hex_as_base64 = abap_true
                                             compress      = abap_true ).

    APPEND INITIAL LINE TO ct_key_value_pairs ASSIGNING <ls_kv>.
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-cmrfinding-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = it_cmr_findings
                                             hex_as_base64 = abap_true
                                             compress      = abap_true ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_create_inb_delivery IMPLEMENTATION.
  METHOD execute_code_int.
    DATA lt_cmr_header TYPE zpru_if_computer_vision=>tt_cmr_header_context.
    DATA lt_cmr_item   TYPE zpru_if_computer_vision=>tt_cmr_item_context.
    DATA lt_headers_all TYPE zpru_if_computer_vision=>tt_inb_delivery_header_context.
    DATA lt_items_all   TYPE zpru_if_computer_vision=>tt_inb_delivery_item_context.
    DATA lt_delivery_header_ctx TYPE zpru_if_computer_vision=>tt_inb_delivery_header_context.
    DATA lt_delivery_item_ctx   TYPE zpru_if_computer_vision=>tt_inb_delivery_item_context.

    deserialize_inb_delivery_input( EXPORTING is_input      = is_input
                                    IMPORTING et_cmr_header = lt_cmr_header
                                              et_cmr_item   = lt_cmr_item ).

    map_cmr_to_delivery_content( EXPORTING it_cmr_header  = lt_cmr_header
                                           it_cmr_item    = lt_cmr_item
                                 IMPORTING et_headers_all = lt_headers_all
                                           et_items_all   = lt_items_all ).

    DATA(lt_create_head) = prepare_delivery_head_entities( lt_headers_all ).
    DATA(lt_create_item) = prepare_delivery_item_entities( it_headers_create = lt_create_head
                                                           it_items = lt_items_all ).

    IF lt_create_head IS INITIAL.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    persist_inb_delivery_via_rap( EXPORTING it_create_header = lt_create_head
                                            it_create_item   = lt_create_item
                                  IMPORTING et_mapped_header = lt_delivery_header_ctx
                                            et_mapped_item   = lt_delivery_item_ctx
                                  CHANGING  ev_error_flag    = ev_error_flag ).

    IF ev_error_flag = abap_true.
      RETURN.
    ENDIF.

    append_inb_delivery_output( EXPORTING it_delivery_headers = lt_delivery_header_ctx
                                          it_delivery_items   = lt_delivery_item_ctx
                                CHANGING  ct_key_value_pairs  = et_key_value_pairs ).

    es_output = NEW zpru_tt_key_value( et_key_value_pairs ).
  ENDMETHOD.

  METHOD deserialize_inb_delivery_input.
    FIELD-SYMBOLS <ls_input> TYPE zpru_if_computer_vision=>ts_inb_delivery_create_request.

    ASSIGN is_input->* TO <ls_input>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-cmrheaders
                                         hex_as_base64 = abap_true
                               CHANGING  data          = et_cmr_header ).
    /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-cmritems
                                         hex_as_base64 = abap_true
                               CHANGING  data          = et_cmr_item ).
  ENDMETHOD.

  METHOD map_cmr_to_delivery_content.
    SELECT MAX( deliveryid )
    FROM zprur_inbhdr
    INTO @DATA(lv_max_deliveryid).

    DATA(lv_next_num) = CONV i( lv_max_deliveryid ).

    LOOP AT it_cmr_header ASSIGNING FIELD-SYMBOL(<ls_cmr>).
      APPEND INITIAL LINE TO et_headers_all ASSIGNING FIELD-SYMBOL(<ls_hdr_out>).

      lv_next_num += 1.
      <ls_hdr_out>-deliveryid   = lv_next_num.
      <ls_hdr_out>-cmrreference = <ls_cmr>-cmrid.
      <ls_hdr_out>-vendor       = <ls_cmr>-senderinfo.
      <ls_hdr_out>-consignee    = <ls_cmr>-consigneeinfo.
      <ls_hdr_out>-arrivalplace = <ls_cmr>-deliveryplace.
      <ls_hdr_out>-deliverydate = <ls_cmr>-takingoverdate.

      LOOP AT it_cmr_item ASSIGNING FIELD-SYMBOL(<ls_cmr_item>)
           WHERE cmruuid = <ls_cmr>-cmruuid.
        APPEND INITIAL LINE TO et_items_all ASSIGNING FIELD-SYMBOL(<ls_item_out>).
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
  ENDMETHOD.

  METHOD prepare_delivery_head_entities.

    DATA(lv_count) = 1.
    LOOP AT it_headers ASSIGNING FIELD-SYMBOL(<ls_header>).
      APPEND INITIAL LINE TO rt_create ASSIGNING FIELD-SYMBOL(<ls_entity>).
      <ls_entity>-%cid         = |H_{ lv_count }|.
      <ls_entity>-deliveryid   = <ls_header>-deliveryid.
      <ls_entity>-vendor       = <ls_header>-vendor.
      <ls_entity>-consignee    = <ls_header>-consignee.
      <ls_entity>-arrivalplace = <ls_header>-arrivalplace.
      <ls_entity>-deliverydate = <ls_header>-deliverydate.
      <ls_entity>-cmrreference = <ls_header>-cmrreference.
      <ls_entity>-%control-deliveryid   = if_abap_behv=>mk-on.
      <ls_entity>-%control-vendor       = if_abap_behv=>mk-on.
      <ls_entity>-%control-consignee    = if_abap_behv=>mk-on.
      <ls_entity>-%control-arrivalplace = if_abap_behv=>mk-on.
      <ls_entity>-%control-deliverydate = if_abap_behv=>mk-on.
      <ls_entity>-%control-cmrreference = if_abap_behv=>mk-on.

      lv_count = lv_count + 1.

    ENDLOOP.
  ENDMETHOD.

  METHOD prepare_delivery_item_entities.
    DATA(lv_cid) = 1.

    LOOP AT it_items ASSIGNING FIELD-SYMBOL(<ls_item>)
         GROUP BY ( deliveryid = <ls_item>-deliveryid )
         ASSIGNING FIELD-SYMBOL(<group>).

      ASSIGN it_headers_create[ deliveryid = <group>-deliveryid ] TO FIELD-SYMBOL(<ls_header>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO rt_create ASSIGNING FIELD-SYMBOL(<ls_create_item>).
      <ls_create_item>-%cid_ref = <ls_header>-%cid.

      LOOP AT GROUP <group> ASSIGNING FIELD-SYMBOL(<ls_member>).
        APPEND INITIAL LINE TO <ls_create_item>-%target ASSIGNING FIELD-SYMBOL(<ls_target>).
        <ls_target>-deliveryid   = <ls_member>-deliveryid.
        <ls_target>-itempos      = <ls_member>-itempos.
        <ls_target>-materialdesc = <ls_member>-materialdesc.
        <ls_target>-quantity     = <ls_member>-quantity.
        <ls_target>-unit         = <ls_member>-unit.
        <ls_target>-grossweight  = <ls_member>-grossweight.
        <ls_target>-weightunit   = <ls_member>-weightunit.
        <ls_target>-hazardclass  = <ls_member>-hazardclass.
        <ls_target>-%cid         = |I_{ lv_cid }|.
        <ls_target>-%control-deliveryid   = if_abap_behv=>mk-on.
        <ls_target>-%control-itempos      = if_abap_behv=>mk-on.
        <ls_target>-%control-materialdesc = if_abap_behv=>mk-on.
        <ls_target>-%control-quantity     = if_abap_behv=>mk-on.
        <ls_target>-%control-unit         = if_abap_behv=>mk-on.
        <ls_target>-%control-grossweight  = if_abap_behv=>mk-on.
        <ls_target>-%control-weightunit   = if_abap_behv=>mk-on.
        <ls_target>-%control-hazardclass  = if_abap_behv=>mk-on.
        lv_cid += 1.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD persist_inb_delivery_via_rap.
    MODIFY ENTITIES OF zprur_inbhdr
           ENTITY inbhdr
           CREATE FROM it_create_header
           ENTITY inbhdr
           CREATE BY \_inbitm
           FROM it_create_item
           MAPPED DATA(ls_mapped)
           FAILED DATA(ls_failed).

    IF ls_failed IS NOT INITIAL.
      ev_error_flag = abap_true.
      RETURN.
    ENDIF.

    READ ENTITIES OF zprur_inbhdr
         ENTITY inbhdr
         ALL FIELDS WITH CORRESPONDING #( ls_mapped-inbhdr )
         RESULT DATA(lt_new_headers).

    READ ENTITIES OF zprur_inbhdr
         ENTITY inbitm
         ALL FIELDS WITH CORRESPONDING #( ls_mapped-inbitm )
         RESULT DATA(lt_new_items).

    et_mapped_header = CORRESPONDING #( lt_new_headers MAPPING FROM ENTITY ).
    et_mapped_item   = CORRESPONDING #( lt_new_items MAPPING FROM ENTITY ).
  ENDMETHOD.

  METHOD append_inb_delivery_output.
    APPEND INITIAL LINE TO ct_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv>).
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-inbdeliveryheaders-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = it_delivery_headers
                                             hex_as_base64 = abap_true
                                             compress      = abap_true ).

    APPEND INITIAL LINE TO ct_key_value_pairs ASSIGNING <ls_kv>.
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-inbdeliveryitems-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = it_delivery_items
                                             hex_as_base64 = abap_true
                                             compress      = abap_true ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_find_storage_bin IMPLEMENTATION.
  METHOD execute_code_int.
    DATA(lt_storage_bins) = query_available_bins( ).

    append_storage_bin_output( EXPORTING it_bins            = lt_storage_bins
                               CHANGING  ct_key_value_pairs = et_key_value_pairs ).

    es_output = NEW zpru_tt_key_value( et_key_value_pairs ).
  ENDMETHOD.

  METHOD query_available_bins.
    SELECT * FROM zprustorbin
      WHERE is_blocked = @abap_false
      ORDER BY bin_id
      INTO CORRESPONDING FIELDS OF TABLE @rt_bins.
    IF sy-subrc <> 0.
      CLEAR rt_bins.
    ENDIF.
  ENDMETHOD.

  METHOD append_storage_bin_output.
    APPEND INITIAL LINE TO ct_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv>).
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-storagebins-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = it_bins
                                             hex_as_base64 = abap_true
                                             compress      = abap_true ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_create_warehouse_task IMPLEMENTATION.
  METHOD execute_code_int.
    DATA lt_inb_headers  TYPE zpru_if_computer_vision=>tt_inb_delivery_header_context.
    DATA lt_inb_items    TYPE zpru_if_computer_vision=>tt_inb_delivery_item_context.
    DATA lt_storage_bins TYPE zpru_if_computer_vision=>tt_storage_bin_context.

    deserialize_wh_task_input( EXPORTING is_input        = is_input
                               IMPORTING et_inb_headers  = lt_inb_headers
                                         et_inb_items    = lt_inb_items
                                         et_storage_bins = lt_storage_bins ).

    DATA(lt_warehouse_tasks_rap) = build_warehouse_task_entities( it_inb_headers  = lt_inb_headers
                                                                  it_inb_items    = lt_inb_items
                                                                  it_storage_bins = lt_storage_bins ).

    IF lt_warehouse_tasks_rap IS INITIAL.
      RETURN.
    ENDIF.

    persist_tasks_via_rap( EXPORTING it_tasks      = lt_warehouse_tasks_rap
                           IMPORTING et_tasks      = DATA(lt_warehouse_tasks_out)
                           CHANGING  ev_error_flag = ev_error_flag ).

    IF ev_error_flag = abap_true.
      RETURN.
    ENDIF.

    append_wh_task_output( EXPORTING it_tasks           = lt_warehouse_tasks_out
                           CHANGING  ct_key_value_pairs = et_key_value_pairs ).

    es_output = NEW zpru_tt_key_value( et_key_value_pairs ).
  ENDMETHOD.

  METHOD deserialize_wh_task_input.
    FIELD-SYMBOLS <ls_input> TYPE zpru_if_computer_vision=>ts_create_whse_task_request.

    ASSIGN is_input->* TO <ls_input>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    IF <ls_input>-inbdeliveryheaders IS NOT INITIAL.
      /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-inbdeliveryheaders
                                           hex_as_base64 = abap_true
                                 CHANGING  data          = et_inb_headers ).
    ENDIF.

    IF <ls_input>-inbdeliveryitems IS NOT INITIAL.
      /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-inbdeliveryitems
                                           hex_as_base64 = abap_true
                                 CHANGING  data          = et_inb_items ).
    ENDIF.

    IF <ls_input>-storagebins IS NOT INITIAL.
      /ui2/cl_json=>deserialize( EXPORTING json          = <ls_input>-storagebins
                                           hex_as_base64 = abap_true
                                 CHANGING  data          = et_storage_bins ).
    ENDIF.
  ENDMETHOD.

  METHOD get_next_task_number.
    SELECT MAX( tanum ) FROM zprur_task INTO @DATA(lv_max_tanum).
    rv_next_tanum = CONV i( lv_max_tanum ) + 1.
  ENDMETHOD.

  METHOD build_warehouse_task_entities.
    DATA(lv_next_tanum_num) = get_next_task_number( ).
    DATA(lv_task_counter)   = 1.

    LOOP AT it_inb_items ASSIGNING FIELD-SYMBOL(<ls_inb_item>).
      ASSIGN it_inb_headers[ uuid = <ls_inb_item>-parent_uuid ] TO FIELD-SYMBOL(<ls_inb_header>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      DATA(lv_storage_bin) = `CLEAR`.
      ASSIGN it_storage_bins[ is_blocked = abap_false ] TO FIELD-SYMBOL(<ls_storage_bin>).
      IF sy-subrc = 0.
        lv_storage_bin = <ls_storage_bin>-bin_id.
      ENDIF.

      APPEND INITIAL LINE TO rt_tasks ASSIGNING FIELD-SYMBOL(<ls_task>).
      <ls_task>-%cid       = |TASK{ lv_task_counter }|.
      <ls_task>-tanum      = lv_next_tanum_num.
      <ls_task>-deliveryid = <ls_inb_header>-deliveryid.
      <ls_task>-itempos    = <ls_inb_item>-itempos.
      <ls_task>-material   = <ls_inb_item>-materialdesc.
      <ls_task>-quantity   = <ls_inb_item>-quantity.
      <ls_task>-unit       = <ls_inb_item>-unit.
      <ls_task>-sourcebin  = 'RECEIVING'.
      <ls_task>-destbin    = lv_storage_bin.
      <ls_task>-confstatus = 'O'.
      <ls_task>-%control   = VALUE #( tanum      = if_abap_behv=>mk-on
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
  ENDMETHOD.

  METHOD persist_tasks_via_rap.
    MODIFY ENTITIES OF zprur_task
           ENTITY task
           CREATE FROM it_tasks
           MAPPED DATA(ls_mapped)
           FAILED DATA(ls_failed).

    IF ls_failed IS NOT INITIAL.
      ev_error_flag = abap_true.
      RETURN.
    ENDIF.

    READ ENTITIES OF zprur_task
         ENTITY task
         ALL FIELDS WITH CORRESPONDING #( ls_mapped-task )
         RESULT DATA(lt_created_tasks).

    et_tasks = CORRESPONDING #( lt_created_tasks MAPPING FROM ENTITY ).
  ENDMETHOD.

  METHOD append_wh_task_output.
    APPEND INITIAL LINE TO ct_key_value_pairs ASSIGNING FIELD-SYMBOL(<ls_kv>).
    <ls_kv>-name  = zpru_if_computer_vision=>cs_context_field-warehousetasks-field_name.
    <ls_kv>-type  = cl_abap_typedescr=>describe_by_data( p_data = VALUE string( ) )->absolute_name.
    <ls_kv>-value = /ui2/cl_json=>serialize( data          = it_tasks
                                             hex_as_base64 = abap_true
                                             compress      = abap_true ).
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
    CASE is_tool_master_data-toolname.
      WHEN `CREATE_CMR`.
        ev_toolname        = `CREATE_CMR`.
        ev_tooldesciption  = `Create CMR`.
        ev_toolexplanation = `Parse extracted CMR JSON from LLM response, deserialize creation content,` &&
         `assign sequential CMR IDs, prepare and persist CMR headers and items via RAP entities (zr_pru_cmr_header/zrprucmrheader, zrprucmritem), then append out` &&
         `context fields CMRHEADERS, CMRITEMS, and CMRCREATIONCONTENT as key-value pairs.`.
        ev_tooltype        = zpru_if_adf_type_and_constant=>cs_step_type-abap_code.

      WHEN `CLASSIFY_DANGER_GOODS`.
        ev_toolname        = `CLASSIFY_DANGER_GOODS`.
        ev_tooldesciption  = `Dangerous goods classification`.
        ev_toolexplanation = `Deserialize CMR items from input, then classify each item for dangerous goods by checking` &&
        `explicit fields (hazard class, UN number) and free-text heuristics on nature of goods (explosive, flammable gas/liquid/solid, oxidiser,` &&
        `toxic, infectious, radioactive, corrosive, other hazardous materials). Create alert entities for detected dangerous goods with alert type 'DANGER_GOODS',` &&
        ` persist via RAP (zr_pru_cmr_alert/zrprucmralert), and append CMRALERTS context field.`.
        ev_tooltype        = zpru_if_adf_type_and_constant=>cs_step_type-abap_code.

      WHEN `VALIDATE_CMR`.
        ev_toolname        = `VALIDATE_CMR`.
        ev_tooldesciption  = `Validate CMR`.
        ev_toolexplanation = `Deserialize CMR headers and items from input, then validate mandatory fields: sender info, consignee info, carrier info, taking-over place,` &&
        ` delivery place, taking-over date, currency (when cash on delivery is set), item count` &&
        ` nature of goods, gross weight, weight unit. Also validate dangerous goods fields (UN number, hazard class, packing group). Create findings with status 'INCOMPLETE' or 'INVALID',` &&
        ` persist via RAP (zr_pru_cmr_valid/zrprucmrvalid), calculate overall CMR status (VALID/INCOMPLETE/INVALID), and append CMRSTATUS and CMRFINDING context fields.`.
        ev_tooltype        = zpru_if_adf_type_and_constant=>cs_step_type-abap_code.

      WHEN `CREATE_INB_DELIVERY`.
        ev_toolname        = `CREATE_INB_DELIVERY`.
        ev_tooldesciption  = `Create Inbound Delivery`.
        ev_toolexplanation = `Deserialize CMR headers and items, map them to inbound delivery structures by generating sequential delivery IDs, mapping CMR reference, vendor/sender, consignee, arrival/delivery place,` &&
        ` and item details (material description` &&
        ` quantity, weight, hazard class). Prepare and persist inbound delivery headers and items via RAP (zprur_inbhdr/inbhdr, inbitm), then append INBDELIVERYHEADERS and INBDELIVERYITEMS context fields.`.
        ev_tooltype        = zpru_if_adf_type_and_constant=>cs_step_type-abap_code.

      WHEN `FIND_STORAGE_BIN`.
        ev_toolname        = `FIND_STORAGE_BIN`.
        ev_tooldesciption  = `Find Storage Bin`.
        ev_toolexplanation = `Query available (non-blocked) storage bins from database table ZPRUSTORBIN ordered by bin_id, then serialize the result and append STORAGEBINS context field with the list of available bins for warehouse task allocation.`.
        ev_tooltype        = zpru_if_adf_type_and_constant=>cs_step_type-abap_code.

      WHEN `CREATE_WAREHOUSE_TASK`.
        ev_toolname        = `CREATE_WAREHOUSE_TASK`.
        ev_tooldesciption  = `Create Warehouse Task`.
        ev_toolexplanation = `Deserialize inbound delivery headers, items, and storage bins from input. Generate sequential warehouse task numbers via SELECT MAX(tanum).` &&
        ` Build warehouse task entities for each inbound item, assigning the first available non-blocked storage bin as destination,` &&
        ` 'RECEIVING' as source, and confirmation status 'O' (open). Persist tasks via RAP (zprur_task/task), then append WAREHOUSETASKS context field.`.
        ev_tooltype        = zpru_if_adf_type_and_constant=>cs_step_type-abap_code.

      WHEN OTHERS.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDCASE.
  ENDMETHOD.

  METHOD set_tool_parameters.
    CASE is_tool_master_data-toolname.
      WHEN `CREATE_CMR`.
        rt_perameters = VALUE #( BASE rt_perameters
          ( parametername        = `CMRCREATIONCONTENT`
            parameterdescription = `JSON string containing CMR creation content with headers and items extracted from LLM response`
            parametertype        = cl_abap_objectdescr=>exporting  )
          ( parametername        = `CMRCREATIONCONTENT`
            parameterdescription = ``
            parametertype        = cl_abap_objectdescr=>importing  )
          ( parametername        = `CMRITEMS`
            parameterdescription = ``
            parametertype        = cl_abap_objectdescr=>importing  )
          ( parametername        = `CMRHEADERS`
            parameterdescription = ``
            parametertype        = cl_abap_objectdescr=>importing  ) ).

      WHEN `CLASSIFY_DANGER_GOODS`.
        rt_perameters = VALUE #( BASE rt_perameters
          ( parametername        = `CMRHEADERS`
            parameterdescription = `JSON string with CMR header context data for item classification context`
            parametertype        = cl_abap_objectdescr=>exporting   )
          ( parametername        = `CMRITEMS`
            parameterdescription = `JSON string with CMR item data to classify for dangerous goods`
            parametertype        = cl_abap_objectdescr=>exporting  )
          ( parametername        = `CMRCREATIONCONTENT`
            parameterdescription = `JSON string with original CMR creation content for reference`
            parametertype        = cl_abap_objectdescr=>exporting   )
          ( parametername        = `cmralerts`
            parameterdescription = ``
            parametertype        = cl_abap_objectdescr=>importing   ) ).

      WHEN `VALIDATE_CMR`.
        rt_perameters = VALUE #( BASE rt_perameters
          ( parametername        = `CMRHEADERS`
            parameterdescription = `JSON string with CMR header context for validation of mandatory fields`
            parametertype        = cl_abap_objectdescr=>exporting  )
          ( parametername        = `CMRITEMS`
            parameterdescription = `JSON string with CMR item context for item-level validation`
            parametertype        = cl_abap_objectdescr=>exporting )
          ( parametername        = `CMRCREATIONCONTENT`
            parameterdescription = `JSON string with original CMR creation content for reference validation`
            parametertype        = cl_abap_objectdescr=>exporting  )
          ( parametername        = `CMRSTATUS`
            parameterdescription = ``
            parametertype        = cl_abap_objectdescr=>importing  )
          ( parametername        = `CMRFINDING`
            parameterdescription = ``
            parametertype        = cl_abap_objectdescr=>importing  ) ).

      WHEN `CREATE_INB_DELIVERY`.
        rt_perameters = VALUE #( BASE rt_perameters
          ( parametername        = `CMRHEADERS`
            parameterdescription = `JSON string with CMR header context mapped to inbound delivery headers`
            parametertype        = cl_abap_objectdescr=>exporting )
          ( parametername        = `CMRITEMS`
            parameterdescription = `JSON string with CMR item context mapped to inbound delivery items`
            parametertype        = cl_abap_objectdescr=>exporting )
          ( parametername        = `CMRCREATIONCONTENT`
            parameterdescription = `JSON string with original CMR creation content for audit reference`
            parametertype        = cl_abap_objectdescr=>exporting )
          ( parametername        = `INBDELIVERYHEADERS`
            parameterdescription = ``
            parametertype        = cl_abap_objectdescr=>importing  )
          ( parametername        = `INBDELIVERYITEMS`
            parameterdescription = ``
            parametertype        = cl_abap_objectdescr=>importing  )
          ( parametername        = `INBDELIVERYCREATIONCONTENT`
            parameterdescription = ``
            parametertype        = cl_abap_objectdescr=>importing  ) ).

      WHEN `FIND_STORAGE_BIN`.
        rt_perameters = VALUE #( BASE rt_perameters
          ( parametername        = `CMRHEADERS`
            parameterdescription = `JSON string with CMR headers used for bin search context (optional)`
            parametertype        = cl_abap_objectdescr=>exporting  )
          ( parametername        = `CMRITEMS`
            parameterdescription = `JSON string with CMR items used for bin search context (optional)`
            parametertype        = cl_abap_objectdescr=>exporting  )
          ( parametername        = `INBDELIVERYHEADERS`
            parameterdescription = `JSON string with inbound delivery headers for bin search reference`
            parametertype        = cl_abap_objectdescr=>exporting  )
          ( parametername        = `INBDELIVERYITEMS`
            parameterdescription = `JSON string with inbound delivery items to determine bin requirements`
            parametertype        = cl_abap_objectdescr=>exporting  )
          ( parametername        = `STORAGEBINS`
            parameterdescription = `JSON string with inbound delivery items to determine bin requirements`
            parametertype        = cl_abap_objectdescr=>importing  ) ).

      WHEN `CREATE_WAREHOUSE_TASK`.
        rt_perameters = VALUE #( BASE rt_perameters
          ( parametername        = `INBDELIVERYHEADERS`
            parameterdescription = `JSON string with inbound delivery headers for warehouse task creation`
            parametertype        = cl_abap_objectdescr=>exporting )
          ( parametername        = `INBDELIVERYITEMS`
            parameterdescription = `JSON string with inbound delivery items to create warehouse tasks for`
            parametertype        = cl_abap_objectdescr=>exporting )
          ( parametername        = `STORAGEBINS`
            parameterdescription = `JSON string with available storage bins for task destination assignment`
            parametertype        = cl_abap_objectdescr=>exporting  )
          ( parametername        = `WAREHOUSETASKS`
            parameterdescription = `JSON string with available storage bins for task destination assignment`
            parametertype        = cl_abap_objectdescr=>importing  ) ).

      WHEN OTHERS.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDCASE.
  ENDMETHOD.

  METHOD set_tool_properties.
    rt_tool_property = VALUE #( BASE rt_tool_property
      ( toolpropertyname  = `EXECUTION_TYPE`
        toolproperty = `ABAP` )
      ( toolpropertyname  = `RAP_PERSISTENCE`
        toolproperty = `TRUE` )
      ( toolpropertyname  = `CONTEXT_INPUT`
        toolproperty = `TRUE` )
      ( toolpropertyname  = `CONTEXT_OUTPUT`
        toolproperty = `TRUE` ) ).

    CASE is_tool_master_data-toolname.
      WHEN `CREATE_CMR`.
        rt_tool_property = VALUE #( BASE rt_tool_property
          ( toolpropertyname  = `RAP_ENTITY`
            toolproperty = `zr_pru_cmr_header / zrprucmrheader, zrprucmritem` )
          ( toolpropertyname  = `OUTPUT_FIELDS`
            toolproperty = `CMRHEADERS, CMRITEMS, CMRCREATIONCONTENT` )
          ( toolpropertyname  = `EXECUTION_SEQUENCE`
            toolproperty = `1` ) ).

      WHEN `CLASSIFY_DANGER_GOODS`.
        rt_tool_property = VALUE #( BASE rt_tool_property
          ( toolpropertyname  = `RAP_ENTITY`
            toolproperty = `zr_pru_cmr_alert / zrprucmralert` )
          ( toolpropertyname  = `OUTPUT_FIELDS`
            toolproperty = `CMRALERTS` )
          ( toolpropertyname  = `EXECUTION_SEQUENCE`
            toolproperty = `2` ) ).

      WHEN `VALIDATE_CMR`.
        rt_tool_property = VALUE #( BASE rt_tool_property
          ( toolpropertyname  = `RAP_ENTITY`
            toolproperty = `zr_pru_cmr_valid / zrprucmrvalid` )
          ( toolpropertyname  = `OUTPUT_FIELDS`
            toolproperty = `CMRSTATUS, CMRFINDING` )
          ( toolpropertyname  = `EXECUTION_SEQUENCE`
            toolproperty = `3` ) ).

      WHEN `CREATE_INB_DELIVERY`.
        rt_tool_property = VALUE #( BASE rt_tool_property
          ( toolpropertyname  = `RAP_ENTITY`
            toolproperty = `zprur_inbhdr / inbhdr, inbitm` )
          ( toolpropertyname  = `OUTPUT_FIELDS`
            toolproperty = `INBDELIVERYHEADERS, INBDELIVERYITEMS` )
          ( toolpropertyname  = `EXECUTION_SEQUENCE`
            toolproperty = `4` ) ).

      WHEN `FIND_STORAGE_BIN`.
        rt_tool_property = VALUE #( BASE rt_tool_property
          ( toolpropertyname  = `RAP_ENTITY`
            toolproperty = `ZPRUSTORBIN (database table read)` )
          ( toolpropertyname  = `OUTPUT_FIELDS`
            toolproperty = `STORAGEBINS` )
          ( toolpropertyname  = `READ_ONLY`
            toolproperty = `TRUE` )
          ( toolpropertyname  = `EXECUTION_SEQUENCE`
            toolproperty = `5` ) ).

      WHEN `CREATE_WAREHOUSE_TASK`.
        rt_tool_property = VALUE #( BASE rt_tool_property
          ( toolpropertyname  = `RAP_ENTITY`
            toolproperty = `zprur_task / task` )
          ( toolpropertyname  = `OUTPUT_FIELDS`
            toolproperty = `WAREHOUSETASKS` )
          ( toolpropertyname  = `EXECUTION_SEQUENCE`
            toolproperty = `6` ) ).

      WHEN OTHERS.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDCASE.
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
