@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: '###GENERATED Core Data Service Entity'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZPRUINBHDR', 
  semanticKey: [ 'Deliveryid' ]
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZPRUC_INBHDR
  provider contract transactional_query
  as projection on ZPRUR_INBHDR
  association [1..1] to ZPRUR_INBHDR as _BaseEntity on $projection.UUID = _BaseEntity.UUID
{
  key UUID,
  Deliveryid,
  Vendor,
  Consignee,
  Deliverydate,
  Cmrreference,
  Arrivalplace,
  @Semantics: {
    user.createdBy: true
  }
  LocalCreatedBy,
  @Semantics: {
    systemDateTime.createdAt: true
  }
  LocalCreatedAt,
  @Semantics: {
    user.localInstanceLastChangedBy: true
  }
  LocalLastChangedBy,
  @Semantics: {
    systemDateTime.localInstanceLastChangedAt: true
  }
  LocalLastChangedAt,
  @Semantics: {
    systemDateTime.lastChangedAt: true
  }
  LastChangedAt,
  _INBITM : redirected to composition child ZPRUC_INBITM,
  _BaseEntity
}
