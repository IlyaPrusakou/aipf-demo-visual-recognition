
CLASS lcl_adf_decision_provider IMPLEMENTATION.
  METHOD check_authorizations.
  ENDMETHOD.

  METHOD prepare_first_tool_input.
  ENDMETHOD.

  METHOD process_thinking.
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

    DATA lt_headers TYPE STANDARD TABLE OF zpru_cmr_header WITH EMPTY KEY.
    DATA lt_items TYPE STANDARD TABLE OF zpru_cmr_item WITH EMPTY KEY.
    DATA lt_cmr_create_head TYPE TABLE FOR CREATE zr_pru_cmr_header\\zrprucmrheader.
    DATA lt_cmr_create_item TYPE TABLE FOR CREATE zr_pru_cmr_header\\zrprucmrheader\_cmritems.

    FIELD-SYMBOLS: <ls_cmr_create> TYPE zpru_s_cmr_create_request.

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

        lv_item_cid = lv_item_cid + 1.
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
    REPORTED DATA(ls_reported).

  ENDMETHOD.
ENDCLASS.

CLASS lcl_adf_tool_provider IMPLEMENTATION.
  METHOD provide_tool_instance.
    CASE  is_tool_master_data-toolname.
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
    CASE  is_tool_master_data-toolname.
      WHEN `CREATE_CMR`.
        ro_structure_schema ?= cl_abap_structdescr=>describe_by_name( p_name = `ZPRU_S_CMR_CREATE_REQUEST` ).
      WHEN OTHERS.
        RAISE EXCEPTION NEW zpru_cx_agent_core( ).
    ENDCASE.
  ENDMETHOD.

  METHOD get_input_json_schema.
  ENDMETHOD.

ENDCLASS.
