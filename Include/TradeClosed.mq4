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

#include "Trade.mq4"
#include "TradeState.mq4"

//Generic TradeState
class TradeClosed : public TradeState  {
public:
   TradeClosed(Trade* aContext);
   virtual void update(); 
private:
   Trade* context; 
};
  
TradeClosed::TradeClosed(Trade* aContext) 
     {
      this.context = aContext;
      context.setEndingBalance(AccountBalance());
      context.setTradeClosedDate(TimeCurrent());
      //context.setSpreadOrderClose((int) MarketInfo(Symbol(),MODE_SPREAD));
      context.addLogEntry("Trade is closed", true);
      
      context.writeLogToCSV();
      
      context.setFinalStateFlag();
      
     }
void TradeClosed::update() {
   /*if(OrderSelect(context.getOrderTicket(),SELECT_BY_TICKET,MODE_TRADES)) {
      bool success = false;
      if(OrderType()==OP_BUY) {
         this.context.addLogEntry("Trade is closed, but order is still open. Re-attempt to close order", true);
         success = OrderClose(context.getOrderTicket(), 4, Ask + 0.00050, 10, clrRed);
      }
      if(OrderType()==OP_SELL) {
         context.addLogEntry("Trade is closed, but order is still open. Re-attempt to close order", true);
         success = OrderClose(context.getOrderTicket(), 4, Bid - 0.00050, 10, clrRed);
      }
      if((OrderType()==OP_BUYLIMIT) || (OrderType()==OP_BUYSTOP) || (OrderType()==OP_SELLLIMIT) || (OrderType()==OP_SELLSTOP)) {
         context.addLogEntry("Trade is closed, but order is still open. Re-attempt to close order", true);
         success = OrderDelete(context.getOrderTicket(),clrRed);
      }
      if (success) {
         context.addLogEntry("Order deleted successfully", true);
         return;
      } 
      else {
         context.addLogEntry("Order could not be deleted. Error code: " + IntegerToString(GetLastError()) + " Wil re-try at next tick.", true);
         return;
      }
   }
   */
}