@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Attachment'
define view entity ZR_PRU_ATTACHMENT
  as select from zpru_attachment

  association to parent ZR_PRU_MESSAGE as _message on $projection.Messageid = _message.Messageid

{
  key attachmentid    as Attachmentid,
      messageid       as Messageid,
      @Semantics.largeObject: { mimeType: 'Mimetype', fileName: 'Filename', contentDispositionPreference: #INLINE }
      attachment      as Attachment,
      filename        as Filename,
      @Semantics.mimeType: true 
      mimetype        as Mimetype,
      @Semantics.user.createdBy: true
      created_by      as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at      as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by as LastChangedBy,

      _message
}
