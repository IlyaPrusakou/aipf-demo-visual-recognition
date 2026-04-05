@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Message Step'
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
define view entity zc_pru_message_step 
as projection on zr_pru_message_step
{
    key Stepassignmentuuid,
    Stepuuid,
    Stepnumber,
    Messageid,
    Queryuuid,
    Runuuid,
    Tooluuid,
    Stepsequence,
    Stepstatus,
    Stepstartdatetime,
    Stependdatetime,
    Stepinputprompt,
    Stepoutputresponse,
    /* Associations */
    _message : redirected to parent ZC_PRU_MESSAGE
}
