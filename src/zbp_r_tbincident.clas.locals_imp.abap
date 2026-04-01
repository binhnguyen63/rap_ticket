CLASS lhc_zr_tbincident DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    CONSTANTS: BEGIN OF ticketStatus,
                 open    TYPE string VALUE 'O',
                 pending TYPE string VALUE 'P',
                 closed  TYPE string VALUE 'C',
               END OF ticketStatus.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR ZrTbincident
        RESULT result,
      AnalyzeIncident FOR MODIFY
        IMPORTING keys FOR ACTION ZrTbincident~AnalyzeIncident RESULT result.

    METHODS CloseIncident FOR MODIFY
      IMPORTING keys FOR ACTION ZrTbincident~CloseIncident RESULT result.

    METHODS ResolveIncident FOR MODIFY
      IMPORTING keys   FOR ACTION ZrTbincident~ResolveIncident
      RESULT    result.

    METHODS StartWork FOR MODIFY
      IMPORTING keys FOR ACTION ZrTbincident~StartWork RESULT result.
ENDCLASS.

CLASS lhc_zr_tbincident IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD AnalyzeIncident.

    DATA lt_tasks TYPE cl_abap_parallel=>t_in_inst_tab.
    DATA lt_results TYPE STANDARD TABLE OF zcl_ticket_parallel=>zty_inc_check_result
                    WITH EMPTY KEY.

    READ ENTITIES OF zr_tbincident IN LOCAL MODE
    ENTITY zrtbincident
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(tickets).

    LOOP AT tickets ASSIGNING FIELD-SYMBOL(<ticket1>).
      IF <ticket1>-Status <> ticketStatus-open.
        APPEND VALUE #( %tky = <ticket1>-%tky ) TO failed-zrtbincident.

        APPEND VALUE #(
            %tky = <ticket1>-%tky
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = 'AnalyzeIncident only allowed when status is OPEN'
            )
        ) TO reported-zrtbincident.
      ELSE.
         INSERT NEW zcl_ticket_parallel(
        is_input = VALUE zcl_ticket_parallel=>zty_inc_check_input(
          incident_uuid = <ticket1>-IncidentUUID
          title         = <ticket1>-Title
          description   = <ticket1>-Description
          category      = <ticket1>-Category
          check_type    = 'SEVERITY' ) )
        INTO TABLE lt_tasks.

      INSERT NEW zcl_ticket_parallel(
        is_input = VALUE zcl_ticket_parallel=>zty_inc_check_input(
          incident_uuid = <ticket1>-IncidentUUID
          title         = <ticket1>-Title
          description   = <ticket1>-Description
          category      = <ticket1>-Category
          check_type    = 'DUPLICATE' ) )
        INTO TABLE lt_tasks.

      INSERT NEW zcl_ticket_parallel(
        is_input = VALUE zcl_ticket_parallel=>zty_inc_check_input(
          incident_uuid = <ticket1>-IncidentUUID
          title         = <ticket1>-Title
          description   = <ticket1>-Description
          category      = <ticket1>-Category
          check_type    = 'ROUTING' ) )
        INTO TABLE lt_tasks.
      ENDIF.
    ENDLOOP.

     " Run parallel checks
    IF lt_tasks IS NOT INITIAL.

      NEW cl_abap_parallel( p_num_tasks = 3 )->run_inst(
        EXPORTING
          p_in_tab  = lt_tasks
        IMPORTING
          p_out_tab = DATA(lt_finished)
      ).

      LOOP AT lt_finished INTO DATA(ls_finished).
        APPEND CAST zcl_ticket_parallel(
                 ls_finished-inst )->get_result( )
          TO lt_results.
      ENDLOOP.

    ENDIF.

     LOOP AT tickets INTO DATA(ticket) WHERE Status = ticketStatus-open.

      DATA(lv_severity)      = VALUE ztb_incident-severity( ).
      DATA(lv_assigned_team) = VALUE ztb_incident-assigned_team( ).
      DATA(lv_result_note)   = VALUE ztb_incident-result_note( ).

      LOOP AT lt_results INTO DATA(ls_result)
        WHERE incident_uuid = ticket-IncidentUUID.

        CASE ls_result-check_type.
          WHEN 'SEVERITY'.
            IF ls_result-severity IS NOT INITIAL.
              lv_severity = ls_result-severity.
            ENDIF.

          WHEN 'ROUTING'.
            IF ls_result-assigned_team IS NOT INITIAL.
              lv_assigned_team = ls_result-assigned_team.
            ENDIF.

          WHEN 'DUPLICATE'.
            IF ls_result-check_result = 'DUPLICATE FOUND'.
              lv_result_note = 'Duplicate ticket found'.
            ENDIF.
        ENDCASE.

      ENDLOOP.

      IF lv_result_note IS INITIAL.
        lv_result_note = 'Analysis completed'.
      ENDIF.

      MODIFY ENTITIES OF zr_tbincident IN LOCAL MODE
        ENTITY zrtbincident
        CREATE BY \_check
        FROM VALUE #(
          (
            %tky = ticket-%tky
            %target = VALUE #(
              FOR ls_create IN lt_results
              INDEX INTO lv_idx
              WHERE ( incident_uuid = ticket-IncidentUUID )
              (
                %cid        = |CHK-{ lv_idx  }|
                CheckUuid   = cl_system_uuid=>create_uuid_x16_static( )
                CheckType   = ls_create-check_type
                CheckResult = ls_create-check_result
                Message     = ls_create-message
                Score       = ls_create-score
                %control = VALUE #(
                  CheckUuid   = if_abap_behv=>mk-on
                  CheckType   = if_abap_behv=>mk-on
                  CheckResult = if_abap_behv=>mk-on
                  Message     = if_abap_behv=>mk-on
                  Score       = if_abap_behv=>mk-on
                )
              )
            )
          )
        )
        MAPPED   DATA(ls_mapped)
        FAILED   DATA(ls_failed)
        REPORTED DATA(ls_reported).

      MODIFY ENTITIES OF zr_tbincident IN LOCAL MODE
        ENTITY zrtbincident
        UPDATE FIELDS ( Status Severity AssignedTeam ResultNote )
        WITH VALUE #(
          (
            %tky         = ticket-%tky
            Status       = ticketStatus-pending
            Severity     = lv_severity
            AssignedTeam = lv_assigned_team
            ResultNote   = lv_result_note
          )
        ).

    ENDLOOP.





*    TRY.
*        MODIFY ENTITIES OF zr_tbincident IN LOCAL MODE
*        ENTITY zrtbincident
*        UPDATE FIELDS ( status )
*        WITH VALUE #(
*            FOR ticket IN tickets WHERE ( status = ticketstatus-open ) (
*                %tky = ticket-%tky
*                status = ticketstatus-pending
*            )
*         ).
*
*        MODIFY ENTITIES OF zr_tbincident IN LOCAL MODE
*          ENTITY zrtbincident
*          CREATE BY \_check
*          FROM VALUE #(
*            FOR ticket IN tickets (
*              IncidentUuid = ticket-IncidentUUID
*              %target = VALUE #(
*                (
*                  %cid = '34'
*                  CheckUuid   = cl_system_uuid=>create_uuid_x16_static( )
*                  CheckType   = 'CONNECTIVITY'
*                  CheckResult = 'S'
*                  Message     = 'Check queued'
*                  Score       = 0
*                  %control = VALUE #(
*                    CheckUuid   = if_abap_behv=>mk-on
*                    CheckType   = if_abap_behv=>mk-on
*                    CheckResult = if_abap_behv=>mk-on
*                    Message     = if_abap_behv=>mk-on
*                    Score       = if_abap_behv=>mk-on
*                  )
*                )
*                (
*                  %cid = '35'
*                  CheckUuid   = cl_system_uuid=>create_uuid_x16_static( )
*                  CheckType   = 'AUTH'
*                  CheckResult = 'S'
*                  Message     = 'Check queued'
*                  Score       = 0
*                  %control = VALUE #(
*                    CheckUuid   = if_abap_behv=>mk-on
*                    CheckType   = if_abap_behv=>mk-on
*                    CheckResult = if_abap_behv=>mk-on
*                    Message     = if_abap_behv=>mk-on
*                    Score       = if_abap_behv=>mk-on
*                  )
*                )
*                (
*                  %cid = '36'
*                  CheckUuid   = cl_system_uuid=>create_uuid_x16_static( )
*                  CheckType   = 'DATA'
*                  CheckResult = 'S'
*                  Message     = 'Check queued'
*                  Score       = 0
*                  %control = VALUE #(
*                    CheckUuid   = if_abap_behv=>mk-on
*                    CheckType   = if_abap_behv=>mk-on
*                    CheckResult = if_abap_behv=>mk-on
*                    Message     = if_abap_behv=>mk-on
*                    Score       = if_abap_behv=>mk-on
*                  )
*                )
*              )
*            )
*          )
*          MAPPED DATA(ls_mapped)
*          FAILED DATA(ls_failed)
*          REPORTED DATA(ls_reported).



        READ ENTITIES OF zr_tbincident IN LOCAL MODE
        ENTITY zrtbincident
        ALL FIELDS WITH
        CORRESPONDING #( keys )
        RESULT DATA(modified_tickets).
*      CATCH cx_uuid_error.
*        "handle exception
*    ENDTRY.



    LOOP AT modified_tickets ASSIGNING FIELD-SYMBOL(<ticket>).

      APPEND VALUE #(
          %key = <ticket>-%key
          %param = <ticket>
      ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD CloseIncident.
    READ ENTITIES OF zr_tbincident IN LOCAL MODE
    ENTITY zrtbincident
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(tickets).

    LOOP AT tickets ASSIGNING FIELD-SYMBOL(<ticket1>).
      IF <ticket1>-Status = ticketStatus-closed.
        APPEND VALUE #( %tky = <ticket1>-%tky ) TO failed-zrtbincident.

        APPEND VALUE #(
            %tky = <ticket1>-%tky
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = 'The ticket is already closed!'
            )
        ) TO reported-zrtbincident.
      ENDIF.
    ENDLOOP.


    MODIFY ENTITIES OF zr_tbincident IN LOCAL MODE
    ENTITY zrtbincident
    UPDATE FIELDS ( status )
    WITH VALUE #(
        FOR ticket IN tickets (
            %tky = ticket-%tky
            status = ticketStatus-closed
        )
     ).

    READ ENTITIES OF zr_tbincident IN LOCAL MODE
    ENTITY ZrTbincident
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(modified_tickets).



    LOOP AT modified_tickets ASSIGNING FIELD-SYMBOL(<ticket>).
      APPEND VALUE #(
          %key = <ticket>-%key
          %param = <ticket>
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD ResolveIncident.



    READ ENTITIES OF zr_tbincident IN LOCAL MODE
    ENTITY ZrTbincident
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(tickets).


    LOOP AT tickets ASSIGNING FIELD-SYMBOL(<ticket>).
      IF <ticket>-Status = ticketStatus-closed.
        APPEND VALUE #( %tky = <ticket>-%tky ) TO failed-zrtbincident.

        APPEND VALUE #(
            %tky = <ticket>-%tky
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = 'The ticket is already closed/resolved'
                )
         ) TO reported-zrtbincident.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zr_tbincident IN LOCAL MODE
    ENTITY ZrTbincident
    UPDATE FIELDS ( Status ResultNote )
    WITH VALUE #(
      FOR ticket IN tickets (
      %tky = ticket-%tky
      Status = ticketStatus-closed
    ResultNote = keys[ %tky = ticket-%tky ]-%param-result_note
      )
    ).

    READ ENTITIES OF zr_tbincident IN LOCAL MODE
    ENTITY ZrTbincident
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(updated_tickets).

    LOOP AT updated_tickets ASSIGNING FIELD-SYMBOL(<updated_ticket>).
      APPEND VALUE #(
          %key = <updated_ticket>-%key
          %param = <updated_ticket>
       ) TO result.
    ENDLOOP.


  ENDMETHOD.

  METHOD StartWork.
  ENDMETHOD.

ENDCLASS.
