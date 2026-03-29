CLASS lhc_zr_pru_message DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR zrprumessage
        RESULT result,
      performvisualrecognition FOR MODIFY
        IMPORTING keys FOR ACTION zrprumessage~performvisualrecognition.
ENDCLASS.

CLASS lhc_zr_pru_message IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.
  METHOD performvisualrecognition.

    DATA lo_agent TYPE REF TO zpru_if_unit_agent.
    DATA ls_prompt TYPE zpru_s_prompt.
    DATA ls_payload TYPE zbp_r_pru_message=>ts_doc_recognition.

    IF lines( keys ) <> 1.
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_message
    IN LOCAL MODE
    ENTITY zrprumessage
    FROM VALUE #( FOR <ls_k1> IN keys ( messageid = <ls_k1>-messageid
                                        %is_draft = <ls_k1>-%is_draft
                                        %control-messageid = if_abap_behv=>mk-on
                                        %control-query = if_abap_behv=>mk-on ) )
    RESULT DATA(lt_root).

    IF lt_root IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_message
    IN LOCAL MODE
    ENTITY zrprumessage BY \_attachment
    FROM VALUE #( FOR <ls_k2> IN keys (  messageid = <ls_k2>-messageid
                                        %is_draft = <ls_k2>-%is_draft
                                        %control-messageid = if_abap_behv=>mk-on
                                        %control-attachmentid = if_abap_behv=>mk-on
                                        %control-attachment = if_abap_behv=>mk-on
                                        %control-mimetype = if_abap_behv=>mk-on
                                        %control-filename = if_abap_behv=>mk-on ) )
    RESULT DATA(lt_attachments).

    lo_agent = NEW zpru_cl_unit_agent( ).
    TRY.

        ls_payload-message    = CORRESPONDING #( lt_root MAPPING FROM ENTITY ).
        ls_payload-attachment = CORRESPONDING #( lt_attachments MAPPING FROM ENTITY ).
        ls_prompt-type           = `\CLASS=ZBP_R_PRU_MESSAGE\TYPE=TS_DOC_RECOGNITION`.

        ls_prompt-string_content = /ui2/cl_json=>serialize( data     = ls_payload
                                                            compress = abap_true ).
        lo_agent->plan_execution(
          EXPORTING
            iv_agent_name        = `DOC_VISUAL_RECOGNITION`
            is_prompt            = ls_prompt
      IMPORTING
        ev_built_run_uuid    = DATA(lv_built_run_uuid)
        ev_built_query_uuid  = DATA(lv_built_query_uuid) ).

        lo_agent->run_execution(
          EXPORTING
            iv_built_run_uuid      = lv_built_run_uuid
            iv_built_query_uuid    = lv_built_query_uuid
          IMPORTING
            ev_final_response      = DATA(lo_final_response)
            eo_executed_controller = DATA(lo_executed_controller) ).

      CATCH zpru_cx_agent_core.
        RETURN.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
