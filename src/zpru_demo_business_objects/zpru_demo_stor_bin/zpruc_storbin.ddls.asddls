@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Endusertext: {
  Label: '###GENERATED Core Data Service Entity'
}
@Objectmodel: {
  Sapobjectnodetype.Name: 'ZPRUSTORBIN', 
  Semantickey: [ 'BinID' ]
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZPRUC_STORBIN
  provider contract TRANSACTIONAL_QUERY
  as projection on ZPRUR_STORBIN
  association [1..1] to ZPRUR_STORBIN as _BaseEntity on $projection.UUID = _BaseEntity.UUID
{
  key UUID,
  BinID,
  BinType,
  IsBlocked,
  @Consumption: {
    Valuehelpdefinition: [ {
      Entity.Element: 'Currency', 
      Entity.Name: 'I_CurrencyStdVH', 
      Useforvalidation: true
    } ]
  }
  CukyField,
  @Semantics: {
    Quantity.Unitofmeasure: 'WeightUnit'
  }
  MaxWeight,
  @Consumption: {
    Valuehelpdefinition: [ {
      Entity.Element: 'UnitOfMeasure', 
      Entity.Name: 'I_UnitOfMeasureStdVH', 
      Useforvalidation: true
    } ]
  }
  WeightUnit,
  @Semantics: {
    User.Createdby: true
  }
  LocalCreatedBy,
  @Semantics: {
    Systemdatetime.Createdat: true
  }
  LocalCreatedAt,
  @Semantics: {
    User.Localinstancelastchangedby: true
  }
  LocalLastChangedBy,
  @Semantics: {
    Systemdatetime.Localinstancelastchangedat: true
  }
  LocalLastChangedAt,
  @Semantics: {
    Systemdatetime.Lastchangedat: true
  }
  LastChangedAt,
  _BaseEntity
}
