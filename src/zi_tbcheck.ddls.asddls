

@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'interface view for check table'
@Metadata.ignorePropagatedAnnotations: true
define view entity Zi_Tbcheck as select from ztb_inc_check
association to parent ZR_TBINCIDENT as _Incident on $projection.IncidentUuid = _Incident.IncidentUUID
{
        key check_uuid as CheckUuid,
    key incident_uuid as IncidentUuid,
    check_type as CheckType,
    check_result as CheckResult,
    message as Message,
    score as Score,
    created_by as CreatedBy,
    created_at as CreatedAt,
    last_changed_by as LastChangedBy,
    last_changed_at as LastChangedAt,
    _Incident
    
}
