//+------------------------------------------------------------------+
//|              LongProfitTargetReachedLookingToAdjustStopLoss.mqh |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property strict

#include "TradeState.mq4"
#include "ATRTrade.mq4"
#include "TradeClosed.mq4"
#include "OrderManager.mq4"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class LongProfitTargetReachedLookingToAdjustStopLoss : public TradeState {
public:
   LongProfitTargetReachedLookingToAdjustStopLoss(ATRTrade* aContext);
   virtual void update();
private:
   ATRTrade* context;
   datetime barStartTimeOfCurrentHH;
   double currentHH;
   datetime timeWhenProfitTargetWasReached;
   bool isNewBar();
};

LongProfitTargetReachedLookingToAdjustStopLoss::LongProfitTargetReachedLookingToAdjustStopLoss(ATRTrade* aContext) {
      currentHH=0;
      this.timeWhenProfitTargetWasReached=TimeCurrent();
      this.context = aContext;
};


void LongProfitTargetReachedLookingToAdjustStopLoss::update() {
   //check if order closed
   bool success=OrderSelect(context.getOrderTicket(),SELECT_BY_TICKET);
   if(!success) {
      context.addLogEntry("Unable to find order. Trade must have been closed", true);
      context.setState(new TradeClosed(context));
      delete GetPointer(this);
      return;
   }
   
   if(OrderCloseTime()!=0) {
      double riskReward = (OrderClosePrice() - context.getActualEntry()) / (context.getActualEntry() - context.getOriginalStopLoss());
      string logMessage;
      double pips = MathAbs(OrderClosePrice() - context.getActualEntry()) * OrderManager::getPipConversionFactor();
      if (OrderClosePrice() > context.getActualEntry()) {
         logMessage = "Gain of " + DoubleToString(pips,1) + " micro pips (" + DoubleToString(riskReward, 2) + "R).";
      } else {
         logMessage = "Loss of " + DoubleToString(pips, 1) + " micro pips.";
      }
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

   //if still in the same minute that reached the target -> wait for next bar
   if((TimeMinute(TimeCurrent())==TimeMinute(timeWhenProfitTargetWasReached)) && 
      (TimeHour(TimeCurrent())==TimeHour(timeWhenProfitTargetWasReached)) && 
      (TimeDay(TimeCurrent())==TimeDay(timeWhenProfitTargetWasReached))){return;}

      if(isNewBar()) 
        {
         if(currentHH==0) 
           {
            currentHH= High[1];
            barStartTimeOfCurrentHH=Time[1];
            context.addLogEntry("Initial high established at: " + DoubleToString(currentHH, Digits), true);
           }

         if(currentHH!=0) 
           {
            if(High[1]>currentHH) 
              {
               //save info rel. to previous HH
               double previousHH=currentHH;
               datetime barStartTimeOfPreviousHH=barStartTimeOfCurrentHH;
               //set new info
               currentHH=High[1];
               barStartTimeOfCurrentHH=Time[1];

               context.addLogEntry("Found new high at: " + DoubleToString(currentHH, Digits), true);

               //look if stop loss can be adjusted
               int shiftOfPreviousHH=iBarShift(Symbol(),PERIOD_M1,barStartTimeOfPreviousHH,true);
               if(shiftOfPreviousHH==-1) 
                 {
                  context.addLogEntry("Error: Could not fine start time of previous HH.", true);
                  return;
                 }
               int i=shiftOfPreviousHH-1; //exclude bar that made the previous HH
               bool downBarFound=false;
               double low=99999;
               while(i>1) 
                 {
                  if(Open[i]>Close[i]) downBarFound=true;
                  if(Low[i]<low) low=Low[i];
                  i--;
                 }
               if(!downBarFound || (low==99999)) 
                 {
                  context.addLogEntry("Coninuation bar - Do not adjust stop loss", true);
                  return;
                 }


               if(low!=99999) 
                 {
                  context.addLogEntry("Low point between highs is: " + DoubleToString(low, Digits), true);
                 }

               //factor in 20 micropips
               double buffer = context.getRangeBufferInMicroPips() / OrderManager::getPipConversionFactor(); ///Check for 3 digit pais
               if(downBarFound && (low-buffer>context.getInitialProfitTarget()) && (low -buffer>context.getStopLoss())) 
                 {
                  context.addLogEntry("Attempting to adjust stop loss to: " + DoubleToString(low-buffer,Digits), true);
                  //adjust stop loss
                  bool orderSelectResult=OrderSelect(context.getOrderTicket(),SELECT_BY_TICKET);
                  if(!orderSelectResult) 
                    {
                     context.addLogEntry("Error: Unable to adjust stop loss - Order not found", true);
                     return;
                    }
                  bool res=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(low-buffer,Digits),0,clrBlue);
                  int result=OrderManager::analzeAndProcessResult(context);
                  if(result==NO_ERROR) 
                    {
                     context.setStopLoss(NormalizeDouble(low-buffer,Digits));
                     context.addLogEntry("Stop loss succssfully adjusted", true);
                    }
                 }

               if(low-buffer<=context.getInitialProfitTarget()) 
                 {
                  context.addLogEntry("Low minus range buffer of " + IntegerToString(context.getRangeBufferInMicroPips()) + " micro pips is below initial profit target of: " + DoubleToString(context.getInitialProfitTarget(), Digits) + ". Do not adjust stop loss", true);
                  return;
                 }

               if(low -buffer<context.getStopLoss()) 
                 {
                 context.addLogEntry("Low minus range buffer of " + IntegerToString(context.getRangeBufferInMicroPips()) + " micro pips is below previous stop loss of: " + DoubleToString(context.getStopLoss(), Digits) + ". Do not adjust stop loss", true);
                 return;
                 }
              }
           }
        }
     }


bool LongProfitTargetReachedLookingToAdjustStopLoss::isNewBar() {
   static datetime lastbar=0;
   datetime curbar=Time[0];
   if(lastbar!=curbar) {
      lastbar=curbar;
      return (true);
   }
   else  {
      return(false);
   }
}
