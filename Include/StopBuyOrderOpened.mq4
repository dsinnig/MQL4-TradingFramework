//+------------------------------------------------------------------+
//|                                           StopBuyOrderOpened.mq4 |
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
#include "BuyOrderFilledProfitTargetNotReached.mq4"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class StopBuyOrderOpened : public TradeState {
public:
   StopBuyOrderOpened(ATRTrade* aContext);
   virtual void update(); 
     
private:
   ATRTrade* context; //hides conext in Trade
};

StopBuyOrderOpened::StopBuyOrderOpened(ATRTrade* aContext) {
   this.context = aContext;
}

void StopBuyOrderOpened::update() {
   if(Ask<=context.getCancelPrice()) {
      context.addLogEntry("Ask price went below cancel level. Attempting to delete order.", true);
      
      //delete Order
      ErrorType result = OrderManager::deleteOrder(context.getOrderTicket(), context);
      
      if(result==NO_ERROR) {
         context.addLogEntry("Order deleted successfully", true);
         context.setState(new TradeClosed(context));
         delete GetPointer(this);
         return;
      }
      
      if(result==RETRIABLE_ERROR) {
         context.addLogEntry("Order could not be deleted. Will re-try at next tick.", true);
         return;
      }
      
      if(result==NON_RETRIABLE_ERROR) {
         context.addLogEntry("Order could not be deleted. Abort trade.", true);
         context.setState(new TradeClosed(context));
         delete GetPointer(this);
         return;
      }
   }
   
   if(OrderSelect(context.getOrderTicket(),SELECT_BY_TICKET,MODE_TRADES)) {
      if(OrderType()==OP_BUY) {
         context.addLogEntry("Order got filled at price: " + DoubleToStr(OrderOpenPrice(), Digits()), true);
         context.setActualEntry(OrderOpenPrice());
         context.setState(new BuyOrderFilledProfitTargetNotReached(context));
         delete GetPointer(this);
         return;
      }
   }
}