public class OpportunityLineItemtriggerHandler implements TriggerInterface{
	public static Boolean TriggerDisabled = false;
    /*
    	Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public boolean IsDisabled(){
        return TriggerDisabled; 
    }

    public void BeforeInsert(List<SObject> newItems){}

    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        //Map<Id, OpportunityLineItem> mapOfTriggerNew = (Map<Id, OpportunityLineItem>)newItems;
    }
	
    public void BeforeDelete(Map<Id, SObject> oldItems){}
    
    // After Trigger Events
    public void AfterInsert(Map<Id, SObject> newItems){
       Map<Id, OpportunityLineItem> triggerNewMap = (Map<Id, OpportunityLineItem>)newItems;
        rollUpAmountOpportunity(triggerNewMap.values());
        
    }

    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id, OpportunityLineItem> triggerNewMap = (Map<Id, OpportunityLineItem>)newItems;
        rollUpAmountOpportunity(triggerNewMap.values());
    }

    public void AfterDelete(Map<Id, SObject> oldItems){
        Map<Id, OpportunityLineItem> triggerNewMap = (Map<Id, OpportunityLineItem>)oldItems;
        rollUpAmountOpportunity(triggerNewMap.values());
    }

    public void AfterUndelete(Map<Id, SObject> oldItems){
        Map<Id, OpportunityLineItem> triggerNewMap = (Map<Id, OpportunityLineItem>)oldItems;
        rollUpAmountOpportunity(triggerNewMap.values());
    }
    
    public static void rollUpAmountOpportunity(List<OpportunityLineItem> triggerNewOld)
    {
        Set<Id> opportunityIds = new Set<Id>();
        List<Opportunity> lstOpportunity = new List<Opportunity>();
            for (OpportunityLineItem oli : triggerNewOld) {
                opportunityIds.add(oli.OpportunityId);
            }
        // Query the OpportunityLineItem records
        List<AggregateResult> result = [SELECT OpportunityId, SUM(Custom_Amount__c) sumAmount FROM OpportunityLineItem WHERE OpportunityId IN :opportunityIds GROUP BY OpportunityId];
        
        // Update the Total Paisa field on Opportunity
        for (AggregateResult ar : result) {
            Opportunity objOpp = new Opportunity();
            objOpp.Id = (Id)ar.get('OpportunityId');
            objOpp.Custom_Total_Amount__c = (Double) ar.get('sumAmount');
            lstOpportunity.add(objOpp);
        }
        if(!lstOpportunity.isEmpty())
        	update lstOpportunity;
	}
}
