@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZPRU_CMR_VALID'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_PRU_CMR_VALID
  as select from ZPRU_CMR_VALID
{
  key findinguuid as Findinguuid,
  cmruuid as Cmruuid,
  cmrid as Cmrid,
  cmritemuuid as Cmritemuuid,
  itemposition as Itemposition,
  findingstatus as Findingstatus,
  findingtype as Findingtype,
  fieldname as Fieldname,
  findingmsg as Findingmsg,
  @Semantics.user.createdBy: true
  createdby as Createdby,
  @Semantics.systemDateTime.createdAt: true
  createdat as Createdat
}
