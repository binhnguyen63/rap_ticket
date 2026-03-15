@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZTBINCIDENT'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_TBINCIDENT
  as select from ztb_incident
  composition [0..*] of Zi_Tbcheck as _Check
  composition [0..*] of Zi_Tb_Event as _Event
{
  key incident_uuid as IncidentUUID,
  title as Title,
  category as Category,
  source_system as SourceSystem,
  severity as Severity,
  status as Status,
  description as Description,
  assigned_team as AssignedTeam,
  result_note as ResultNote,
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.lastChangedBy: true
  last_changed_by as LastChangedBy,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,
  _Check,
  _Event
}
