
CLASS lcl_adf_decision_provider IMPLEMENTATION.
  METHOD check_authorizations.
    RETURN.
  ENDMETHOD.

  METHOD prepare_first_tool_input.
    DATA ls_cmr_create_request TYPE zpru_s_cmr_create_request.

    CASE is_first_tool-toolname.
      WHEN `CREATE_CMR`.
        " ls_cmr_create_request-cmrheaders = headers
        " ls_cmr_create_request-cmritems = items
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
    DATA lt_abap_payload     TYPE REF TO ts_gemini_request.
    DATA lv_string_payload   TYPE string.
    DATA ls_llm_output TYPE ts_gemini_response.
    DATA ls_payload TYPE zbp_r_pru_message=>ts_doc_recognition.

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

    /ui2/cl_json=>deserialize( EXPORTING json = is_input_prompt-string_content
                               CHANGING  data = ls_payload ).


    LOOP AT ls_payload-message ASSIGNING FIELD-SYMBOL(<ls_message>).
      LOOP AT ls_payload-attachment ASSIGNING FIELD-SYMBOL(<ls_attachment>)
                                    WHERE messageid = <ls_message>-messageid.






      ENDLOOP.
    ENDLOOP.



*    cl_web_http_utility=>encode_x_base64( unencoded = 'payload' ).

    " prepare abap payload

    lv_string_payload = /ui2/cl_json=>serialize( data     = lt_abap_payload
                                                 compress = abap_true ).

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
