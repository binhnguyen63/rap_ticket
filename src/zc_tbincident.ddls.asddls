@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: '###GENERATED Core Data Service Entity'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZTBINCIDENT'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_TBINCIDENT
  provider contract transactional_query
  as projection on ZR_TBINCIDENT
  association [1..1] to ZR_TBINCIDENT as _BaseEntity on $projection.IncidentUUID = _BaseEntity.IncidentUUID
{
  key IncidentUUID,
  Title,
  Category,
  SourceSystem,
  Severity,
  Status,
  Description,
  AssignedTeam,
  ResultNote,
  @Semantics: {
    user.createdBy: true
  }
  CreatedBy,
  @Semantics: {
    systemDateTime.createdAt: true
  }
  CreatedAt,
  @Semantics: {
    user.lastChangedBy: true
  }
  LastChangedBy,
  @Semantics: {
    systemDateTime.lastChangedAt: true
  }
  LastChangedAt,
  _BaseEntity,
  _Check : redirected to composition child ZC_TB_CHECK,
  _Event : redirected to composition child Zc_Tb_Event
  
}
