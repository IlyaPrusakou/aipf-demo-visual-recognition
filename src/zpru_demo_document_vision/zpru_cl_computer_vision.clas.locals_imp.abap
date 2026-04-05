CLASS lcl_adf_decision_provider IMPLEMENTATION.
  METHOD check_authorizations.
    RETURN.
  ENDMETHOD.

  METHOD prepare_first_tool_input.

    TYPES:

      BEGIN OF ts_items,
        cmrid              TYPE char10,
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

      tt_items TYPE STANDARD TABLE OF ts_items WITH EMPTY KEY,

      BEGIN OF ts_headers,
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
      END OF ts_headers,

      BEGIN OF ts_response,
        header TYPE ts_headers,
        items  TYPE tt_items,
      END OF ts_response,

      tt_response_root TYPE STANDARD TABLE OF ts_response WITH EMPTY KEY.

    DATA lt_raw_response TYPE tt_response_root.
    DATA ls_cmr_create_request TYPE zpru_s_cmr_create_request.
    DATA lt_header TYPE STANDARD TABLE OF zpru_cmr_header WITH EMPTY KEY.
    DATA lt_items TYPE STANDARD TABLE OF zpru_cmr_item WITH EMPTY KEY.
    DATA LS_PAYLOAD TYPE zbp_r_pru_message=>ts_doc_recognition.

    /ui2/cl_json=>deserialize( EXPORTING json = iv_thinking_output
                               CHANGING  data = lt_raw_response ).

    IF lt_raw_response IS INITIAL.
      RETURN.
    ENDIF.

    CASE is_first_tool-toolname.
      WHEN `CREATE_CMR`.

        LOOP AT lt_raw_response ASSIGNING FIELD-SYMBOL(<ls_raw_response>).
          APPEND INITIAL LINE TO lt_header ASSIGNING FIELD-SYMBOL(<ls_header>).
          <ls_header> = CORRESPONDING #( <ls_raw_response>-header ).

          LOOP AT <ls_raw_response>-items ASSIGNING FIELD-SYMBOL(<ls_raw_item>).
            APPEND INITIAL LINE TO lt_items ASSIGNING  FIELD-SYMBOL(<ls_item>).
            <ls_item> = CORRESPONDING #( <ls_raw_item> ).
          ENDLOOP.
        ENDLOOP.

        ls_cmr_create_request-cmrheaders = /ui2/cl_json=>serialize( data     = lt_header ).
        ls_cmr_create_request-cmritems = /ui2/cl_json=>serialize( data     = lt_items ).

        er_first_tool_input = NEW zpru_s_cmr_create_request( ls_cmr_create_request ).
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
    DATA ls_llm_output TYPE ts_gemini_response.
    DATA lR_payload TYPE REF TO data.
    DATA lv_output_schema TYPE string.

    FIELD-SYMBOLS <LS_PAYLOAD> TYPE zbp_r_pru_message=>ts_doc_recognition.

    lv_gemini_url = `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`.
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
                                       i_value = 'MY API KEY' ).

    CREATE DATA lR_payload TYPE (is_input_prompt-type).

    ASSIGN lR_payload->* TO <LS_PAYLOAD>.
    IF SY-SUBRC <> 0.
    RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    /ui2/cl_json=>deserialize( EXPORTING json = is_input_prompt-string_content
                               CHANGING  data = <LS_PAYLOAD> ).

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
      |      "header": \{| &&
      |        "type": "object",| &&
      |        "properties": \{| &&
      |          "cmrid": \{ "type": "string" \},| &&
      |          "senderinfo": \{ "type": "string" \},| &&
      |          "consigneeinfo": \{ "type": "string" \},| &&
      |          "deliveryplace": \{ "type": "string" \},| &&
      |          "takingoverplace": \{ "type": "string" \},| &&
      |          "takingoverdate": \{ "type": "string" \},| &&
      |          "carrierinfo": \{ "type": "string" \},| &&
      |          "successivecarrier": \{ "type": "string" \},| &&
      |          "carrierreservice": \{ "type": "string" \},| &&
      |          "senderinstruction": \{ "type": "string" \},| &&
      |          "cashondelivery": \{ "type": "number" \},| &&
      |          "currency": \{ "type": "string" \},| &&
      |          "establishedplace": \{ "type": "string" \},| &&
      |          "establisheddate": \{ "type": "string" \},| &&
      |          "createdby": \{ "type": "string" \},| &&
      |          "createdat": \{ "type": "string" \},| &&
      |          "lastchangedby": \{ "type": "string" \},| &&
      |          "lastchangedat": \{ "type": "string" \}| &&
      |        \},| &&
      |        "required": ["cmrid"]| &&
      |      \},| &&
      |      "items": \{| &&
      |        "type": "array",| &&
      |        "items": \{| &&
      |          "type": "object",| &&
      |          "properties": \{| &&
      |            "cmrid": \{ "type": "string" \},| &&
      |            "itemposition": \{ "type": "string" \},| &&
      |            "marksnumbers": \{ "type": "string" \},| &&
      |            "packagecount": \{ "type": "integer" \},| &&
      |            "packingmethod": \{ "type": "string" \},| &&
      |            "natureofgoods": \{ "type": "string" \},| &&
      |            "statisticalnumber": \{ "type": "string" \},| &&
      |            "weightunitfield": \{ "type": "string" \},| &&
      |            "volumeunitfield": \{ "type": "string" \},| &&
      |            "grossweight": \{ "type": "number" \},| &&
      |            "volume": \{ "type": "number" \},| &&
      |            "unitednationnumber": \{ "type": "string" \},| &&
      |            "hazardclass": \{ "type": "string" \},| &&
      |            "packinggroup": \{ "type": "string" \}| &&
      |          \},| &&
      |          "required": ["itemposition", "natureofgoods"]| &&
      |        \}| &&
      |      \}| &&
      |    \},| &&
      |    "required": ["header", "items"]| &&
      |  \}| &&
      |\}|.

    APPEND INITIAL LINE TO <ls_abap_payload>-contents ASSIGNING FIELD-SYMBOL(<ls_contnent>).
    APPEND INITIAL LINE TO <ls_contnent>-parts ASSIGNING FIELD-SYMBOL(<ls_part>).

    LOOP AT <LS_PAYLOAD>-message ASSIGNING FIELD-SYMBOL(<ls_message>).

      <ls_part>-text = |{ <ls_part>-text } always use USD as currency, KG as weight and M3 as volume.{ cl_abap_char_utilities=>newline }|.
      <ls_part>-text = |{ <ls_part>-text } always give me output as json according the schema.{ cl_abap_char_utilities=>newline }|.
      <ls_part>-text = |{ <ls_part>-text } For output use this schema: { lv_json_schema }{ cl_abap_char_utilities=>newline }|.

      LOOP AT <LS_PAYLOAD>-attachment ASSIGNING FIELD-SYMBOL(<ls_attachment>)
                                    WHERE messageid = <ls_message>-messageid.
        DATA(lv_image_base64) = cl_web_http_utility=>encode_x_base64( unencoded = <ls_attachment>-attachment ).

        APPEND INITIAL LINE TO <ls_contnent>-parts ASSIGNING <ls_part>.
        <ls_part>-inline_data-mime_type = 'image/jpeg'.
        <ls_part>-inline_data-data = lv_image_base64.
      ENDLOOP.
    ENDLOOP.

    lv_string_payload = /ui2/cl_json=>serialize( data     = ls_abap_payload
                                                 compress = abap_true ).

    IF lv_string_payload IS INITIAL.
      RETURN.
    ENDIF.

    lo_http_request->set_text( i_text = lv_string_payload ).

    TRY.
        DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>post ).
      CATCH cx_web_http_client_error.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDTRY.

    IF lo_response->get_status( )-code <> `200`.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    DATA(lv_gemini_output) = lo_response->get_text( ).

    /ui2/cl_json=>deserialize( EXPORTING json = lv_gemini_output
                               CHANGING  data = ls_llm_output ).

    DATA(lv_raw_response) = VALUE #( ls_llm_output-candidates[ 1 ]-content-parts[ 1 ]-text OPTIONAL ).

    IF lv_raw_response IS INITIAL.
      RETURN.
    ENDIF.

    ev_thinking_output = lv_raw_response.

  ENDMETHOD.

  METHOD read_data_4_thinking.
  ENDMETHOD.

  METHOD recall_memory.
  ENDMETHOD.

  METHOD set_final_response_content.
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
    DATA lt_headers         TYPE STANDARD TABLE OF zpru_cmr_header WITH EMPTY KEY.
    DATA lt_items           TYPE STANDARD TABLE OF zpru_cmr_item WITH EMPTY KEY.
    DATA lt_cmr_create_head TYPE TABLE FOR CREATE zr_pru_cmr_header\\zrprucmrheader.
    DATA lt_cmr_create_item TYPE TABLE FOR CREATE zr_pru_cmr_header\\zrprucmrheader\_cmritems.

    FIELD-SYMBOLS <ls_cmr_create> TYPE zpru_s_cmr_create_request.

    ASSIGN is_input->* TO <ls_cmr_create>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDIF.

    /ui2/cl_json=>deserialize( EXPORTING json          = <ls_cmr_create>-cmrheaders
                                         hex_as_base64 = abap_false
                               CHANGING  data          = lt_headers ).

    /ui2/cl_json=>deserialize( EXPORTING json          = <ls_cmr_create>-cmritems
                                         hex_as_base64 = abap_false
                               CHANGING  data          = lt_items ).
    DATA(lv_item_cid) = 1.
    LOOP AT lt_headers ASSIGNING FIELD-SYMBOL(<ls_header>).

      APPEND INITIAL LINE TO lt_cmr_create_head ASSIGNING FIELD-SYMBOL(<ls_cmr_create_head>).
      <ls_cmr_create_head> = CORRESPONDING #( <ls_header> MAPPING TO ENTITY CHANGING CONTROL ).
      <ls_cmr_create_head>-%cid = '1'.

      LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_item>)
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
           " TODO: variable is assigned but never used (ABAP cleaner)
           MAPPED DATA(ls_mapped)
           " TODO: variable is assigned but never used (ABAP cleaner)
           FAILED DATA(ls_failed)
           " TODO: variable is assigned but never used (ABAP cleaner)
           REPORTED DATA(ls_reported).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_adf_tool_provider IMPLEMENTATION.
  METHOD provide_tool_instance.
    CASE is_tool_master_data-toolname.
      WHEN `CREATE_CMR`.
        ro_executor = NEW lcl_adf_create_cmr( ).
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
        ro_structure_schema ?= cl_abap_structdescr=>describe_by_name( p_name = `ZPRU_S_CMR_CREATE_REQUEST` ).
      WHEN OTHERS.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDCASE.
  ENDMETHOD.

  METHOD get_input_json_schema.
  ENDMETHOD.
ENDCLASS.
