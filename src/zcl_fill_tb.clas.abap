CLASS zcl_fill_tb DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_fill_tb IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    DATA: lt_incident TYPE STANDARD TABLE OF ztb_incident,
          lt_check    TYPE STANDARD TABLE OF ztb_inc_check.

    DELETE FROM ztb_inc_check.
    DELETE FROM ztb_incident.

    TRY.

        lt_incident = VALUE #(
          ( client = sy-mandt
            incident_uuid  = cl_system_uuid=>create_uuid_x16_static( )
            title          = 'INC001'
            category       = 'NETWORK'
            source_system  = 'SAP'
            severity       = 'C'
            status         = 'O'
            description    = 'Network outage in data center'
            assigned_team  = 'BASIS'
            result_note    = 'Investigating root cause' )

          ( client = sy-mandt
            incident_uuid  = cl_system_uuid=>create_uuid_x16_static( )
            title          = 'INC002'
            category       = 'APP'
            source_system  = 'EXT'
            severity       = 'M'
            status         = 'P'
            description    = 'Application crash on login'
            assigned_team  = 'DEV'
            result_note    = 'Fix in progress' )

          ( client = sy-mandt
            incident_uuid  = cl_system_uuid=>create_uuid_x16_static( )
            title          = 'INC003'
            category       = 'DB'
            source_system  = 'SAP'
            severity       = 'L'
            status         = 'C'
            description    = 'Database cleanup completed'
            assigned_team  = 'SUPPORT'
            result_note    = 'Issue resolved' )

          ( client = sy-mandt
            incident_uuid  = cl_system_uuid=>create_uuid_x16_static( )
            title          = 'INC004'
            category       = 'NETWORK'
            source_system  = 'EXT'
            severity       = 'C'
            status         = 'O'
            description    = 'Router failure detected'
            assigned_team  = 'BASIS'
            result_note    = 'Awaiting hardware replacement' )

          ( client = sy-mandt
            incident_uuid  = cl_system_uuid=>create_uuid_x16_static( )
            title          = 'INC005'
            category       = 'APP'
            source_system  = 'SAP'
            severity       = 'C'
            status         = 'P'
            description    = 'UI alignment issue in dashboard'
            assigned_team  = 'DEV'
            result_note    = 'Patch being tested' )
        ).

        INSERT ztb_incident FROM TABLE @lt_incident.

        lt_check = VALUE #(

       " INC002 (Pending) ✔
       ( client        = sy-mandt
         check_uuid    = cl_system_uuid=>create_uuid_x16_static( )
         incident_uuid = lt_incident[ 2 ]-incident_uuid
         check_type    = 'LOG'
         check_result  = 'F'
         message       = 'Application dump found'
         score         = 30 )

       ( client        = sy-mandt
         check_uuid    = cl_system_uuid=>create_uuid_x16_static( )
         incident_uuid = lt_incident[ 2 ]-incident_uuid
         check_type    = 'MEMORY'
         check_result  = 'N'
         message       = 'No critical memory issue'
         score         = 55 )

       " INC003 (Closed) ✔
       ( client        = sy-mandt
         check_uuid    = cl_system_uuid=>create_uuid_x16_static( )
         incident_uuid = lt_incident[ 3 ]-incident_uuid
         check_type    = 'CLEANUP'
         check_result  = 'S'
         message       = 'Cleanup job completed'
         score         = 100 )

       " INC005 (Pending) ✔
       ( client        = sy-mandt
         check_uuid    = cl_system_uuid=>create_uuid_x16_static( )
         incident_uuid = lt_incident[ 5 ]-incident_uuid
         check_type    = 'UI'
         check_result  = 'N'
         message       = 'No major UI issue'
         score         = 60 )

       ( client        = sy-mandt
         check_uuid    = cl_system_uuid=>create_uuid_x16_static( )
         incident_uuid = lt_incident[ 5 ]-incident_uuid
         check_type    = 'PATCH'
         check_result  = 'S'
         message       = 'Patch test successful'
         score         = 95 )
     ).
        INSERT ztb_inc_check FROM TABLE @lt_check.

        out->write(
          |Inserted { lines( lt_incident ) } incidents and { lines( lt_check ) } checks.|
        ).

      CATCH cx_uuid_error INTO DATA(lx_uuid).
        out->write( lx_uuid->get_text( ) ).
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
