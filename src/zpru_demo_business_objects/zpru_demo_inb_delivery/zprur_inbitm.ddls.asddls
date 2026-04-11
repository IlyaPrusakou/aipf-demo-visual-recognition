@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@ObjectModel.semanticKey: [ 'Deliveryid', 'Itempos' ]
define view entity ZPRUR_INBITM
  as select from ZPRUINBITM as INBITM
  association to parent ZPRUR_INBHDR as _INBHDR on $projection.ParentUuid = _INBHDR.Uuid
{
  key uuid as UUID,
  parent_uuid as ParentUUID,
  deliveryid as Deliveryid,
  itempos as Itempos,
  materialdesc as Materialdesc,
  @Semantics.quantity.unitOfMeasure: 'Unit'
  quantity as Quantity,
  @Consumption.valueHelpDefinition: [ {
    entity.name: 'I_UnitOfMeasureStdVH', 
    entity.element: 'UnitOfMeasure', 
    useForValidation: true
  } ]
  unit as Unit,
  @Semantics.quantity.unitOfMeasure: 'Weightunit'
  grossweight as Grossweight,
  @Consumption.valueHelpDefinition: [ {
    entity.name: 'I_UnitOfMeasureStdVH', 
    entity.element: 'UnitOfMeasure', 
    useForValidation: true
  } ]
  weightunit as Weightunit,
  hazardclass as Hazardclass,
  _INBHDR
}
