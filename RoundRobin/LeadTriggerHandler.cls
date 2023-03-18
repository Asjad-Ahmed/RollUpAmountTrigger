public class LeadTriggerHandler implements TriggerInterface{
    
    
    public static Boolean TriggerDisabled = false;
    /*
Checks to see if the trigger has been disabled either by custom setting or by running code
*/
    public boolean IsDisabled(){
        return TriggerDisabled; 
    }
    
    public void BeforeInsert(List<SObject> newItems){}
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){}
    
    // After Trigger Events
    public void AfterInsert(Map<Id, SObject> newItems){
        /*     Map<Id, Lead> triggerNewMap = (Map<Id, Lead>)newItems;
RoundRobinLeadAssignment(triggerNewMap.values());
*/
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id, Lead> triggerNewMap = (Map<Id, Lead>)newItems;
        Map<Id, Lead> triggerOldMap = (Map<Id, Lead>)newItems;
        
        RoundRobinLeadAssignment(triggerNewMap.values(),triggerOldMap.values());
        
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
        
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
        
    }
    
    
    public static void RoundRobinLeadAssignment(list<Lead> leads,list<Lead> Oldleads){
        Map<Id, List<String>> mapQIdUserId = new Map<Id, List<String>>();
        Set<Id> setQueueIds  = new Set<Id>();
        List<Lead> NewLeads = new List<Lead>();

//=========================================================================Meta Data Map=====================================================================================================================
        Map<String, Decimal> mapQueueNameWithCurrentCount= new Map<String, Decimal>();
        Map<id,Round_Robin__c> mapOfRoundRobin = new Map<id,Round_Robin__c>();
        Map<Id, String> mapQueueIdWithQueueName = new Map<Id, String>();
        Map<String, Id> mapRRIdWithName = new Map<String, Id>();
        Map<String, Decimal> mapQueueIdWithTltMember = new Map<String, Decimal>();
        Map<String, Map<Decimal, Id>> metaDataMap = new Map<String, Map<Decimal, Id>>(); // <queue Name - (username - his number)>
        Map<Id, GroupMember> mapQueueMembers = new Map<Id, GroupMember>([SELECT Group.Name, Group.Type,GroupId, UserOrGroupId FROM GroupMember WHERE Group.Type = 'Queue']);
        for (GroupMember gm : mapQueueMembers.values()) {
            mapQueueIdWithQueueName.put(gm.GroupId, gm.Group.Name);
        }
        System.debug('mapQueueIdWithQueueName== '+mapQueueIdWithQueueName);
        
        for(Round_Robin__c objRR : [SELECT Id, Is_Active__c, Name, Current_Count__c, Total_Members__c, (SELECT Id, User_Number__c, User__c, Active__c FROM Round_Robin_Assignees__r) FROM Round_Robin__c WHERE Is_Active__c = true]){
            Map<Decimal, Id> mapUserWithNum = new  Map<Decimal, Id>();
            for (Round_Robin_Assignee__c objRRAsgn : objRR.Round_Robin_Assignees__r) {
                mapUserWithNum.put(objRRAsgn.User_Number__c ,objRRAsgn.User__c);
            }
            metaDataMap.put(objRR.Name, new Map<Decimal, Id>(mapUserWithNum));  
            mapQueueNameWithCurrentCount.put(objRR.Name, objRR.Current_Count__c);
            mapQueueIdWithTltMember.put(objRR.Name, objRR.Total_Members__c);
            mapRRIdWithName.put(objRR.Name, objRR.Id);
        }
        system.debug('metaDataMap'+metaDataMap);
        system.debug('mapQueueNameWithCurrentCount'+mapQueueNameWithCurrentCount);


//===========================================================================================================================================================================================
        List<Lead> listUpdateList = new List<Lead>();
        List<Round_Robin__c> listRRList = new List<Round_Robin__c>();
          List<Lead> LeadToProcess = [SELECT id,OwnerId from Lead where Id IN: Leads];
        for(Lead objLead: LeadToProcess)
        {
            system.debug('ownerid'+objLead.OwnerId);
            if (mapQueueIdWithQueueName.containsKey(objLead.OwnerId)) {// OwnerId = Queue Id
                string key = mapQueueIdWithQueueName.get(objLead.OwnerId);// US, uk
                Decimal QueueCurrentCount = 0;
                Decimal UpdatedQueueCurrentCount = 0;
                Decimal totalMember = 0;
                String userId;
                if (mapQueueNameWithCurrentCount.containsKey(key)) {
                    QueueCurrentCount = mapQueueNameWithCurrentCount.get(key);
                    totalMember = mapQueueIdWithTltMember.get(key);
                }
                if (QueueCurrentCount >= totalMember) {
                    userId = metaDataMap.get(key).get(1);
                    mapQueueNameWithCurrentCount.put(key, 1);
                    UpdatedQueueCurrentCount = 1;
                }else {
                    if (metaDataMap.get(key).containsKey(QueueCurrentCount+1)) {
                        userId = metaDataMap.get(key).get(QueueCurrentCount+1);
                        mapQueueNameWithCurrentCount.put(key, QueueCurrentCount+1);
                        UpdatedQueueCurrentCount = QueueCurrentCount+1;
                    }
                }
                if (userId != null && userId != '') {
                    objLead.OwnerId = userId;
                    
                    Round_Robin__c objRR = new Round_Robin__c();
                    objRR.Id = mapRRIdWithName.get(key);
                    objRR.Last_assigned_user__c = userId;
                    objRR.Current_Count__c = UpdatedQueueCurrentCount;
                     mapOfRoundRobin.put(objRR.Id,objRR);

                    listRRList.add(objRR);
                    listUpdateList.add(objLead);
                }
                
            }
        }
        if (!listUpdateList.isEmpty() ) {
            update listUpdateList;
        }
        if (!listRRList.isEmpty() ) {
            update mapOfRoundRobin.values();
        }
    }
    
    
}