@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Endusertext: {
  Label: '###GENERATED Core Data Service Entity'
}
@Objectmodel: {
  Sapobjectnodetype.Name: 'ZTBINCIDENT'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_TBINCIDENT
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_TBINCIDENT
  association [1..1] to ZR_TBINCIDENT as _BaseEntity on $projection.INCIDENTUUID = _BaseEntity.INCIDENTUUID
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
    User.Createdby: true
  }
  CreatedBy,
  @Semantics: {
    Systemdatetime.Createdat: true
  }
  CreatedAt,
  @Semantics: {
    User.Lastchangedby: true
  }
  LastChangedBy,
  @Semantics: {
    Systemdatetime.Lastchangedat: true
  }
  LastChangedAt,
  _BaseEntity
}
