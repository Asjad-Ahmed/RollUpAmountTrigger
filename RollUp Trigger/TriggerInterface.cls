/*
    ** Created: 27/12/2022
    ** Author: Asjad Ahmed
    ** Description: Trigger Interface for dispatcher to implement 
    *  Each method will provide the defination of individual operations 
*/
public interface TriggerInterface {

    void BeforeInsert(List<SObject> newItems);
    void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
    void BeforeDelete(Map<Id, SObject> oldItems);
    void AfterInsert(Map<Id, SObject> newItems);
    void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems); 
    void AfterDelete(Map<Id, SObject> oldItems);
    void AfterUndelete(Map<Id, SObject> oldItems); 
    Boolean IsDisabled();

}