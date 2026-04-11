@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Endusertext: {
  Label: '###GENERATED Core Data Service Entity'
}
@Objectmodel: {
  Semantickey: [ 'Deliveryid', 'Itempos' ]
}
@AccessControl.authorizationCheck: #MANDATORY
define view entity ZPRUC_INBITM
  as projection on ZPRUR_INBITM
  association [1..1] to ZPRUR_INBITM as _BaseEntity on $projection.UUID = _BaseEntity.UUID
{
  key UUID,
  ParentUUID,
  Deliveryid,
  Itempos,
  Materialdesc,
  @Semantics: {
    Quantity.Unitofmeasure: 'Unit'
  }
  Quantity,
  @Consumption: {
    Valuehelpdefinition: [ {
      Entity.Element: 'UnitOfMeasure', 
      Entity.Name: 'I_UnitOfMeasureStdVH', 
      Useforvalidation: true
    } ]
  }
  Unit,
  @Semantics: {
    Quantity.Unitofmeasure: 'Weightunit'
  }
  Grossweight,
  @Consumption: {
    Valuehelpdefinition: [ {
      Entity.Element: 'UnitOfMeasure', 
      Entity.Name: 'I_UnitOfMeasureStdVH', 
      Useforvalidation: true
    } ]
  }
  Weightunit,
  Hazardclass,
  _INBHDR : redirected to parent ZPRUC_INBHDR,
  _BaseEntity
}
