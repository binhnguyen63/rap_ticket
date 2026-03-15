@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'projection view for event'
@Metadata.ignorePropagatedAnnotations: true
define view entity Zc_Tb_Event
 as projection on Zi_Tb_Event
{
        key EventUuid,
    key IncidentUuid,
    EventType,
    Details,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    _Incident : redirected to parent ZC_TBINCIDENT
    
}
