@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'interface view for event'
@Metadata.ignorePropagatedAnnotations: true
define view entity Zi_Tb_Event as select from ztb_inc_event
association to parent ZR_TBINCIDENT as _Incident on $projection.IncidentUuid = _Incident.IncidentUUID
{
        key event_uuid as EventUuid,
    key incident_uuid as IncidentUuid,
    event_type as EventType,
    details as Details,
    created_by as CreatedBy,
    created_at as CreatedAt,
    last_changed_by as LastChangedBy,
    last_changed_at as LastChangedAt,
    _Incident
}
