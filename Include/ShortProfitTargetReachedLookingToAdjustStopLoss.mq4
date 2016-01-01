//+------------------------------------------------------------------+
//|                LowestLowReceivedEstablishingEligibilityRange.mq4 |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "TradeState.mq4"
#include "ATRTrade.mq4"
#include "TradeClosed.mq4"
#include "OrderManager.mq4"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ShortProfitTargetReachedLookingToAdjustStopLoss : public TradeState {
public:
   ShortProfitTargetReachedLookingToAdjustStopLoss(ATRTrade* aContext);
   virtual void update();
private:
   datetime  barStartTimeOfCurrentLL;
   double currentLL;
   datetime timeWhenProfitTargetWasReached;
   ATRTrade* context;
   
   bool isNewBar();
};
     
ShortProfitTargetReachedLookingToAdjustStopLoss::ShortProfitTargetReachedLookingToAdjustStopLoss(ATRTrade* aContext) {
   
   currentLL=99999;
   this.timeWhenProfitTargetWasReached=TimeCurrent();
   this.context = aContext;
}

void ShortProfitTargetReachedLookingToAdjustStopLoss::update() {
      
      //check if order closed
      bool success=OrderSelect(context.getOrderTicket(),SELECT_BY_TICKET);
      if(!success) 
        {
         context.addLogEntry("Unable to find order. Trade must have been closed", true);
         context.setState(new TradeClosed(context));
         delete GetPointer(this);
         return;
        }
      if(OrderCloseTime()!=0) 
        {
         string logMessage;
         
         double riskReward = double ((context.getActualEntry() - OrderClosePrice())) / (context.getOriginalStopLoss() - context.getActualEntry());
         
         double pips = MathAbs(OrderClosePrice() - context.getActualEntry()) * OrderManager::getPipConversionFactor();
         
         if (OrderClosePrice() > context.getActualEntry()) logMessage = "Loss of " + DoubleToString(pips,1) + " micro pips.";
         else logMessage = "Gain of " + DoubleToString(pips, 1) + " micro pips (" + DoubleToString(riskReward, 2) + "R).";
         context.addLogEntry("Stop loss triggered @" + DoubleToString(OrderClosePrice(), Digits) + " " + logMessage, true);
         context.addLogEntry("P/L of: $" + DoubleToString(OrderProfit(),2) + "; Commission: $" + DoubleToString(OrderCommission(),2) + "; Swap: $" + DoubleToString(OrderSwap(),2) + "; New Account balance: $" + DoubleToString(AccountBalance(),2), true);
         
         
         context.setRealizedPL(OrderProfit());
         context.setOrderCommission(OrderCommission());
         context.setOrderSwap(OrderSwap());
         context.setActualClose(OrderClosePrice());
         context.setState(new TradeClosed(context));
         delete GetPointer(this);
         return;
        }

      //order still open...

      //if still in same bar that made the profit target -> wait for next bar. 
      if((TimeMinute(TimeCurrent())==TimeMinute(timeWhenProfitTargetWasReached)) && 
         (TimeHour(TimeCurrent())==TimeHour(timeWhenProfitTargetWasReached)) && 
         (TimeDay(TimeCurrent())==TimeDay(timeWhenProfitTargetWasReached))){return;}

      if(isNewBar()) 
        {
         if(currentLL==99999) 
           {
            currentLL= Low[1];
            barStartTimeOfCurrentLL=Time[1];
            context.addLogEntry("Initial low established at: " + DoubleToString(currentLL, Digits), true);
            }

         if(currentLL!=99999) 
           {
            if(Low[1]<currentLL) 
              {
               //save info rel. to previous HH
               double previousLL=currentLL;
               datetime barStartTimeOfPreviousLL=barStartTimeOfCurrentLL;
               //set new info
               currentLL=Low[1];
               barStartTimeOfCurrentLL=Time[1];

               context.addLogEntry("Found new low at: " + DoubleToString(currentLL, Digits), true);

               //look if stop loss can be adjusted
               int shiftOfPreviousLL=iBarShift(Symbol(),PERIOD_M1,barStartTimeOfPreviousLL,true);
               if(shiftOfPreviousLL==-1) 
                 {
                  context.addLogEntry("Error: Could not fine start time of previous LL.", true);
                  return;
                 }
               int i=shiftOfPreviousLL-1; //exclude bar that made the previous HH
               bool upBarFound=false;
               double high=-1;
               while(i>1) 
                 {
                  if(Open[i]<Close[i]) upBarFound=true;
                  if(High[i]>high) high=High[i];
                  i--;
                 }
               if(!upBarFound || (high==-1)) 
                 {
                  context.addLogEntry("Coninuation bar - Do not adjust stop loss", true);
                  return;
                 }


               if(high!=-1) 
                 {
                  context.addLogEntry("High point between highs is: " + DoubleToString(high, Digits), true);
                 }
               double buffer = context.getRangeBufferInMicroPips() / OrderManager::getPipConversionFactor(); ///Check for 3 digit pais
               if(upBarFound && (high+buffer<context.getInitialProfitTarget()) && (high+buffer<context.getStopLoss())) 
                 {
                  //adjust stop loss
                  context.addLogEntry("Attempting to adjust stop loss to: " + DoubleToString(high+buffer,Digits), true);                  
                  bool orderSelectResult=OrderSelect(context.getOrderTicket(),SELECT_BY_TICKET);
                  if(!orderSelectResult) 
                    {
                     context.addLogEntry("Error: Unable to adjust stop loss - Order not found", true);
                     return;
                    }
                  bool res=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(high+buffer,Digits),0,clrBlue);
                  int result=OrderManager::analzeAndProcessResult(context);
                  if(result==NO_ERROR) 
                    {
                     context.setStopLoss(NormalizeDouble(high+buffer,Digits));
                     context.addLogEntry("Stop loss succssfully adjusted", true);
                    }
                 }

               if(high+buffer>=context.getInitialProfitTarget()) 
                 {
                  context.addLogEntry("High plus range buffer of " + IntegerToString(context.getRangeBufferInMicroPips()) + " micro pips is above initial profit target of: " + DoubleToString(context.getInitialProfitTarget(), Digits) + ". Do not adjust stop loss", true);
                  return;
                 }

               if(high+buffer>context.getStopLoss()) 
                 {
                  context.addLogEntry("High plus range buffer of " + IntegerToString(context.getRangeBufferInMicroPips()) + " micro pips is above previous stop loss: " + DoubleToString(context.getStopLoss(), Digits) + ". Do not adjust stop loss", true);
                  return;
                 }
              }
           }
        }
     }
     
bool ShortProfitTargetReachedLookingToAdjustStopLoss::isNewBar() {
   static datetime lastbar=0;
   datetime curbar=Time[0];
   if(lastbar!=curbar) {
      lastbar=curbar;
      return (true);
   }
   else {
      return(false);
   }
}