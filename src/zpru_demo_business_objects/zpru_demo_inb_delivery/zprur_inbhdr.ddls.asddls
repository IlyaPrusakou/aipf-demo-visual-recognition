@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZPRUINBHDR'
@EndUserText.label: '###GENERATED Core Data Service Entity'
@ObjectModel.semanticKey: [ 'Deliveryid' ]
define root view entity ZPRUR_INBHDR
  as select from zpruinbhdr as INBHDR
  composition [1..*] of ZPRUR_INBITM as _INBITM
{
  key uuid as UUID,
  deliveryid as Deliveryid,
  vendor as Vendor,
  consignee as Consignee,
  deliverydate as Deliverydate,
  cmrreference as Cmrreference,
  arrivalplace as Arrivalplace,
  @Semantics.user.createdBy: true
  local_created_by as LocalCreatedBy,
  @Semantics.systemDateTime.createdAt: true
  local_created_at as LocalCreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,
  _INBITM
}
