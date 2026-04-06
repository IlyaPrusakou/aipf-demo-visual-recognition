@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Endusertext: {
  Label: '###GENERATED Core Data Service Entity'
}
@Objectmodel: {
  Sapobjectnodetype.Name: 'ZPRU_CMR_VALID'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_PRU_CMR_VALID
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_PRU_CMR_VALID
  association [1..1] to ZR_PRU_CMR_VALID as _BaseEntity on $projection.FINDINGUUID = _BaseEntity.FINDINGUUID
{
  key Findinguuid,
  Cmruuid,
  Cmrid,
  Cmritemuuid,
  Itemposition,
  Findingstatus,
  Findingtype,
  Fieldname,
  Findingmsg,
  @Semantics: {
    User.Createdby: true
  }
  Createdby,
  @Semantics: {
    Systemdatetime.Createdat: true
  }
  Createdat,
  _BaseEntity
}
