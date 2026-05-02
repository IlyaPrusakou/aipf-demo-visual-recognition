CLASS zpru_cl_doc_vis_test_data DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    CLASS-METHODS refresh_test_data.
ENDCLASS.


CLASS zpru_cl_doc_vis_test_data IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    refresh_test_data( ).
  ENDMETHOD.

  METHOD refresh_test_data.
    DATA lt_agent           TYPE STANDARD TABLE OF zpru_agent WITH EMPTY KEY.
    DATA lt_agent_tool      TYPE STANDARD TABLE OF zpru_agent_tool WITH EMPTY KEY.

    TRY.
        DATA(lv_agent_uuid1) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.

    lt_agent = VALUE #( agenttype   = 'AGTYP1'
                        agentstatus = 'N'
                        createdby   = ''
                        createdat   = '0.0000000'
                        changedby   = ''
                        ( agentuuid            = lv_agent_uuid1
                          agentname            = 'DOC_VISUAL_RECOGNITION'
                          decisionprovider     = 'ZPRU_CL_COMPUTER_VISION'
                          shortmemoryprovider  = 'ZPRU_CL_COMPUTER_VISION'
                          longmemoryprovider   = 'ZPRU_CL_COMPUTER_VISION'
                          agentinfoprovider    = 'ZPRU_CL_COMPUTER_VISION'
                          systempromptprovider = 'ZPRU_CL_COMPUTER_VISION'
                          agentmapper          = 'ZPRU_CL_COMPUTER_VISION' ) ).
    TRY.
        lt_agent_tool = VALUE #( ( tooluuid           = cl_system_uuid=>create_uuid_x16_static( )
                                   agentuuid          = lv_agent_uuid1
                                   toolname           = 'CREATE_CMR'
                                   toolprovider       = 'ZPRU_CL_COMPUTER_VISION'
                                   steptype           = 'B'
                                   toolschemaprovider = 'ZPRU_CL_COMPUTER_VISION'
                                   toolinfoprovider   = 'ZPRU_CL_COMPUTER_VISION'  )
                                 ( tooluuid           = cl_system_uuid=>create_uuid_x16_static( )
                                   agentuuid          = lv_agent_uuid1
                                   toolname           = 'CLASSIFY_DANGER_GOODS'
                                   toolprovider       = 'ZPRU_CL_COMPUTER_VISION'
                                   steptype           = 'B'
                                   toolschemaprovider = 'ZPRU_CL_COMPUTER_VISION'
                                   toolinfoprovider   = 'ZPRU_CL_COMPUTER_VISION'  )
                                 ( tooluuid           = cl_system_uuid=>create_uuid_x16_static( )
                                   agentuuid          = lv_agent_uuid1
                                   toolname           = 'VALIDATE_CMR'
                                   toolprovider       = 'ZPRU_CL_COMPUTER_VISION'
                                   steptype           = 'B'
                                   toolschemaprovider = 'ZPRU_CL_COMPUTER_VISION'
                                   toolinfoprovider   = 'ZPRU_CL_COMPUTER_VISION'  )
                                 ( tooluuid           = cl_system_uuid=>create_uuid_x16_static( )
                                   agentuuid          = lv_agent_uuid1
                                   toolname           = 'CREATE_INB_DELIVERY'
                                   toolprovider       = 'ZPRU_CL_COMPUTER_VISION'
                                   steptype           = 'B'
                                   toolschemaprovider = 'ZPRU_CL_COMPUTER_VISION'
                                   toolinfoprovider   = 'ZPRU_CL_COMPUTER_VISION'  )
                                 ( tooluuid           = cl_system_uuid=>create_uuid_x16_static( )
                                   agentuuid          = lv_agent_uuid1
                                   toolname           = 'FIND_STORAGE_BIN'
                                   toolprovider       = 'ZPRU_CL_COMPUTER_VISION'
                                   steptype           = 'B'
                                   toolschemaprovider = 'ZPRU_CL_COMPUTER_VISION'
                                   toolinfoprovider   = 'ZPRU_CL_COMPUTER_VISION'  )
                                 ( tooluuid           = cl_system_uuid=>create_uuid_x16_static( )
                                   agentuuid          = lv_agent_uuid1
                                   toolname           = 'CREATE_WAREHOUSE_TASK'
                                   toolprovider       = 'ZPRU_CL_COMPUTER_VISION'
                                   steptype           = 'B'
                                   toolschemaprovider = 'ZPRU_CL_COMPUTER_VISION'
                                   toolinfoprovider   = 'ZPRU_CL_COMPUTER_VISION'  ) ).
      CATCH cx_uuid_error.
    ENDTRY.

    SELECT * FROM zpru_agent
      WHERE agentname = 'DOC_VISUAL_RECOGNITION'
      INTO TABLE @DATA(lt_agent_to_be_del).
    IF sy-subrc = 0.
      DELETE zpru_agent FROM TABLE @lt_agent_to_be_del.
    ENDIF.

    IF lt_agent_to_be_del IS NOT INITIAL.
      SELECT * FROM zpru_agent_tool
        FOR ALL ENTRIES IN @lt_agent_to_be_del
        WHERE agentuuid = @lt_agent_to_be_del-agentuuid
        INTO TABLE @DATA(lt_tool_to_be_del).
      IF sy-subrc = 0.
        DELETE zpru_agent_tool FROM TABLE @lt_tool_to_be_del.
      ENDIF.
    ENDIF.

    MODIFY zpru_agent FROM TABLE @lt_agent.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      RETURN.
    ENDIF.
    MODIFY zpru_agent_tool FROM TABLE @lt_agent_tool.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      RETURN.
    ENDIF.

    COMMIT WORK.
  ENDMETHOD.

ENDCLASS.
