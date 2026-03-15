
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'projection view for check table'
@Metadata.ignorePropagatedAnnotations: true
define view entity Zc_Tb_Check 
as projection on Zi_Tbcheck


{
        key CheckUuid,
    key IncidentUuid,
    CheckType,
    CheckResult,
    Message,
    Score,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    _Incident : redirected to parent ZC_TBINCIDENT
}
