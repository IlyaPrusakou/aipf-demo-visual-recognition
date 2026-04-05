CLASS zbp_r_pru_message DEFINITION
  PUBLIC
  ABSTRACT
  FINAL
  FOR BEHAVIOR OF zr_pru_message .

  PUBLIC SECTION.

    TYPES tt_message TYPE STANDARD TABLE OF zpru_message WITH EMPTY KEY.
    TYPES tt_attachment TYPE STANDARD TABLE OF zpru_attachment WITH EMPTY KEY.

    " recognition input
    TYPES: BEGIN OF ts_doc_recognition,
             message    TYPE tt_message,
             attachment TYPE tt_attachment,
           END OF ts_doc_recognition.


    TYPES: BEGIN OF ts_agent_execution_runtime,
             message TYPE zpru_message,
             run     TYPE zpru_tt_axc_head,
             query   TYPE zpru_tt_axc_query,
             steps   TYPE zpru_tt_axc_step,
           END OF ts_agent_execution_runtime.

    TYPES: tt_agent_execution_runtime TYPE STANDARD TABLE OF ts_agent_execution_runtime WITH EMPTY KEY.

    " recognition output
    TYPES: BEGIN OF ts_recognition_output,
             agent_execution_runtime TYPE tt_agent_execution_runtime,
           END OF ts_recognition_output.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zbp_r_pru_message IMPLEMENTATION.
ENDCLASS.
