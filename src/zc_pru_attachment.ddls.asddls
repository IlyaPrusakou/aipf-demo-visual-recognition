@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment'
@Metadata.allowExtensions: true
define view entity ZC_PRU_ATTACHMENT
  as projection on ZR_PRU_ATTACHMENT

{
  key Attachmentid,
      Messageid,
      Attachment,
      Filename,
      Mimetype,
      @Semantics: {
        user.createdBy: true
      }
      CreatedBy,
      @Semantics: {
        systemDateTime.createdAt: true
      }
      CreatedAt,
      @Semantics: {
        user.localInstanceLastChangedBy: true
      }
      LastChangedBy,

      /* Associations */
      _message : redirected to parent ZC_PRU_MESSAGE
}
