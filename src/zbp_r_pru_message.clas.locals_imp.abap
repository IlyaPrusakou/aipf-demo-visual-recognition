CLASS lhc_zr_pru_message DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING
      REQUEST requested_authorizations FOR zrprumessage
      RESULT result.
    METHODS performvisualrecognition FOR MODIFY
      IMPORTING keys FOR ACTION zrprumessage~performvisualrecognition.
ENDCLASS.


CLASS lhc_zr_pru_message IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD performvisualrecognition.
    DATA lo_agent            TYPE REF TO zpru_if_unit_agent.
    DATA ls_prompt           TYPE zpru_s_prompt.
    DATA ls_agent_input      TYPE zbp_r_pru_message=>ts_doc_recognition.
    DATA ls_agent_output     TYPE zbp_r_pru_message=>ts_recognition_output.
    DATA lt_message_step_crt TYPE TABLE FOR CREATE zr_pru_message\\zrprumessage\_messagestep.

    IF lines( keys ) <> 1.
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_message
         IN LOCAL MODE
         ENTITY zrprumessage
         FROM VALUE #( FOR <ls_k1> IN keys
                       ( messageid          = <ls_k1>-messageid
                         %is_draft          = <ls_k1>-%is_draft
                         %control-MessageId = if_abap_behv=>mk-on
                         %control-Query     = if_abap_behv=>mk-on ) )
         RESULT DATA(lt_root).

    IF lt_root IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_message
         IN LOCAL MODE
         ENTITY zrprumessage BY \_attachment
         FROM VALUE #( FOR <ls_k2> IN keys
                       ( messageid             = <ls_k2>-messageid
                         %is_draft             = <ls_k2>-%is_draft
                         %control-MessageId    = if_abap_behv=>mk-on
                         %control-AttachmentId = if_abap_behv=>mk-on
                         %control-Attachment   = if_abap_behv=>mk-on
                         %control-MimeType     = if_abap_behv=>mk-on
                         %control-FileName     = if_abap_behv=>mk-on ) )
         RESULT DATA(lt_attachments).

    lo_agent = NEW zpru_cl_unit_agent( ).

    TRY.

        ls_agent_input-message    = CORRESPONDING #( lt_root MAPPING FROM ENTITY ).
        ls_agent_input-attachment = CORRESPONDING #( lt_attachments MAPPING FROM ENTITY ).
        ls_prompt-type           = `\CLASS=ZBP_R_PRU_MESSAGE\TYPE=TS_DOC_RECOGNITION`.

        ls_prompt-string_content = /ui2/cl_json=>serialize( data     = ls_agent_input
                                                            compress = abap_true ).

        lo_agent->plan_execution( EXPORTING iv_agent_name       = `DOC_VISUAL_RECOGNITION`
                                            is_prompt           = ls_prompt
                                  IMPORTING ev_built_run_uuid   = DATA(lv_built_run_uuid)
                                            ev_built_query_uuid = DATA(lv_built_query_uuid) ).

        lo_agent->run_execution( EXPORTING iv_built_run_uuid      = lv_built_run_uuid
                                           iv_built_query_uuid    = lv_built_query_uuid
                                 IMPORTING ev_final_response      = DATA(lv_final_response)
                                 " TODO: variable is assigned but never used (ABAP cleaner)
                                           eo_executed_controller = DATA(lo_executed_controller) ).

        CAST zpru_if_agent_base( lo_agent )->get_response_content( EXPORTING iv_final_response = lv_final_response
                                                                   IMPORTING ed_response_body  = ls_agent_output ).

      CATCH zpru_cx_agent_core.
        RETURN.
    ENDTRY.

    DATA(lv_count) = 0.
    LOOP AT lt_root ASSIGNING FIELD-SYMBOL(<ls_message>).

      ASSIGN ls_agent_output-agent_execution_runtime[ message-messageid = <ls_message>-messageid ] TO FIELD-SYMBOL(<ls_agent>).
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.

      APPEND INITIAL LINE TO lt_message_step_crt ASSIGNING FIELD-SYMBOL(<ls_message_step_crt>).
      <ls_message_step_crt>-%is_draft = <ls_message>-%is_draft.
      <ls_message_step_crt>-messageid = <ls_message>-messageid.

      LOOP AT <ls_agent>-steps ASSIGNING FIELD-SYMBOL(<ls_step>).
        lv_count += 1.
        APPEND INITIAL LINE TO <ls_message_step_crt>-%target ASSIGNING FIELD-SYMBOL(<ls_step_target>).
        <ls_step_target>-%cid               = lv_count.
        <ls_step_target>-%is_draft          = <ls_message_step_crt>-%is_draft.
        <ls_step_target>-stepuuid           = <ls_step>-stepuuid.
        <ls_step_target>-stepnumber         = <ls_step>-stepnumber.
        <ls_step_target>-messageid          = <ls_message_step_crt>-messageid.
        <ls_step_target>-queryuuid          = <ls_step>-queryuuid.
        <ls_step_target>-runuuid            = <ls_step>-runuuid.
        <ls_step_target>-tooluuid           = <ls_step>-tooluuid.
        <ls_step_target>-stepsequence       = <ls_step>-stepsequence.
        <ls_step_target>-stepstatus         = <ls_step>-stepstatus.
        <ls_step_target>-stepstartdatetime  = <ls_step>-stepstartdatetime.
        <ls_step_target>-stependdatetime    = <ls_step>-stependdatetime.
        <ls_step_target>-stepinputprompt    = <ls_step>-stepinputprompt.
        <ls_step_target>-stepoutputresponse = <ls_step>-stepoutputresponse.

        <ls_step_target>-%control-stepuuid           = if_abap_behv=>mk-on.
        <ls_step_target>-%control-stepnumber         = if_abap_behv=>mk-on.
        <ls_step_target>-%control-messageid          = if_abap_behv=>mk-on.
        <ls_step_target>-%control-queryuuid          = if_abap_behv=>mk-on.
        <ls_step_target>-%control-runuuid            = if_abap_behv=>mk-on.
        <ls_step_target>-%control-tooluuid           = if_abap_behv=>mk-on.
        <ls_step_target>-%control-stepsequence       = if_abap_behv=>mk-on.
        <ls_step_target>-%control-stepstatus         = if_abap_behv=>mk-on.
        <ls_step_target>-%control-stepstartdatetime  = if_abap_behv=>mk-on.
        <ls_step_target>-%control-stependdatetime    = if_abap_behv=>mk-on.
        <ls_step_target>-%control-stepinputprompt    = if_abap_behv=>mk-on.
        <ls_step_target>-%control-stepoutputresponse = if_abap_behv=>mk-on.

      ENDLOOP.
    ENDLOOP.

    IF lt_message_step_crt IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_pru_message
           IN LOCAL MODE
           ENTITY zrprumessage
           CREATE BY \_messagestep
           FROM lt_message_step_crt.
  ENDMETHOD.
ENDCLASS.
