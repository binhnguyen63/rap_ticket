CLASS zcl_ticket_check_parallel DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
    TYPES rv_results_types TYPE STANDARD TABLE OF zcl_ticket_parallel=>zty_inc_check_result WITH EMPTY KEY.
    METHODS analyze_incident
      IMPORTING iv_input          TYPE zcl_ticket_parallel=>zty_inc_check_input
      RETURNING VALUE(rv_results) TYPE rv_results_types.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ticket_check_parallel IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.


  ENDMETHOD.

  METHOD analyze_incident.
    DATA lt_tasks TYPE cl_abap_parallel=>t_in_inst_tab.

    INSERT NEW zcl_ticket_parallel(
      is_input = VALUE zcl_ticket_parallel=>zty_inc_check_input(
        incident_uuid = iv_input-incident_uuid
        title         = iv_input-title
        description   = iv_input-description
        category      = iv_input-category
        check_type    = 'SEVERITY' ) )
      INTO TABLE lt_tasks.
    INSERT NEW zcl_ticket_parallel(
     is_input = VALUE zcl_ticket_parallel=>zty_inc_check_input(
       incident_uuid = iv_input-incident_uuid
       title         = iv_input-title
       description   = iv_input-description
       category      = iv_input-category
       check_type    = 'DUPLICATE' ) )
     INTO TABLE lt_tasks.

    INSERT NEW zcl_ticket_parallel(
      is_input = VALUE zcl_ticket_parallel=>zty_inc_check_input(
        incident_uuid = iv_input-incident_uuid
        title         = iv_input-title
        description   = iv_input-description
        category      = iv_input-category
        check_type    = 'ROUTING' ) )
      INTO TABLE lt_tasks.
    NEW cl_abap_parallel( p_num_tasks = 3 )->run_inst(
    EXPORTING
      p_in_tab  = lt_tasks
    IMPORTING
      p_out_tab = DATA(lt_finished)
  ).

    LOOP AT lt_finished INTO DATA(ls_finished).
      APPEND CAST zcl_ticket_parallel(
               ls_finished-inst )->get_result( ) TO rv_results.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
