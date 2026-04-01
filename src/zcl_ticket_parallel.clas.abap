CLASS zcl_ticket_parallel DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .



  PUBLIC SECTION.
    CONSTANTS: BEGIN OF ticketStatus,
                 open    TYPE string VALUE 'O',
                 pending TYPE string VALUE 'P',
                 closed  TYPE string VALUE 'C',
               END OF ticketStatus.

    TYPES: BEGIN OF zty_inc_check_input,
             incident_uuid TYPE sysuuid_x16,
             title         TYPE ztb_incident-title,
             description   TYPE ztb_incident-description,
             category      TYPE ztb_incident-category,
             check_type    TYPE c LENGTH 120,
           END OF zty_inc_check_input.
    TYPES: BEGIN OF zty_inc_check_result,
             incident_uuid TYPE sysuuid_x16,
             check_type    TYPE c LENGTH 120,
             check_result  TYPE c LENGTH 50,
             message       TYPE c LENGTH 120,
             score         TYPE i,
             severity      TYPE zde_severity,
             assigned_team TYPE ztb_incident-assigned_team,
           END OF zty_inc_check_result.

    INTERFACES if_serializable_object .
    INTERFACES if_abap_parallel .

    METHODS constructor
      IMPORTING is_input TYPE zty_inc_check_input.

    METHODS get_result
      RETURNING VALUE(rv_result) TYPE zty_inc_check_result.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA: ms_input  TYPE zty_inc_check_input,
          ms_result TYPE zty_inc_check_result.
    METHODS run_severity_check.
    METHODS run_duplicate_check.
    METHODS run_routing_check.



ENDCLASS.



CLASS zcl_ticket_parallel IMPLEMENTATION.


  METHOD if_abap_parallel~do.
    CASE ms_input-check_type.
      WHEN 'SEVERITY'.
        run_severity_check( ).
      WHEN 'DUPLICATE'.
        run_duplicate_check(  ).
      WHEN 'ROUTING'.
        run_routing_check(  ).
    ENDCASE.
  ENDMETHOD.
  METHOD constructor.
    ms_input = is_input.
  ENDMETHOD.

  METHOD get_result.
    RETURN ms_result.
  ENDMETHOD.

  METHOD run_duplicate_check.

    DATA lv_count TYPE i.
    ms_result-incident_uuid = ms_input-incident_uuid.
    ms_result-check_type = ms_input-check_type.

    SELECT COUNT( * )
    FROM ztb_incident
    WHERE title = @ms_input-title
    AND status = @ticketStatus-open
    AND incident_uuid <> @ms_input-incident_uuid
    INTO @lv_count.

    IF lv_count > 0.
      ms_result-check_result = 'DUPLICATE FOUND'.
      ms_result-message = 'Another open ticket has the same title'.
      ms_result-score = 80.
    ELSE.
      ms_result-check_result = 'NO DUPLICATE'.
      ms_result-message = 'No similar open incident found'.
      ms_result-score = 0.
    ENDIF.


  ENDMETHOD.

  METHOD run_routing_check.
    ms_result-incident_uuid = ms_input-incident_uuid.
    ms_result-check_type    = 'ROUTING'.

    CASE ms_input-category.
      WHEN 'API'.
        ms_result-check_result = 'TECH_SUPPORT'.
        ms_result-message      = 'Routed by category'.
        ms_result-assigned_team = 'TECH_SUPPORT'.
      WHEN 'BILLING'.
        ms_result-check_result = 'BILLING_TEAM'.
        ms_result-message      = 'Routed by category'.
        ms_result-assigned_team = 'BILLING_TEAM'.
      WHEN OTHERS.
        ms_result-check_result = 'GENERAL'.
        ms_result-message      = 'Default routing used'.
        ms_result-assigned_team = 'GENERAL_TEAM'.
    ENDCASE.
  ENDMETHOD.

  METHOD run_severity_check.
    ms_result-incident_uuid = ms_input-incident_uuid.
    ms_result-check_type    = 'SEVERITY'.

    IF ms_input-title CS 'failed'
       OR ms_input-description CS 'failed'.
      ms_result-check_result = 'HIGH'.
      ms_result-message      = 'Failure keyword found'.
      ms_result-score        = 90.
      ms_result-severity     = 'C'.
    ELSE.
      ms_result-check_result = 'NORMAL'.
      ms_result-message      = 'No failure keyword found'.
      ms_result-score        = 10.
      ms_result-severity = 'L'.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
