//+------------------------------------------------------------------+
//|                                          BuyLimitOrderOpened.mqh |
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
#include "BuyOrderFilledProfitTargetNotReached.mq4"
#include "OrderManager.mq4"

class BuyLimitOrderOpened : public TradeState {
public: 
   BuyLimitOrderOpened(ATRTrade* aContext);
   virtual void update();

private: 
   ATRTrade* context; //hides context in Trade
};

BuyLimitOrderOpened::BuyLimitOrderOpened(ATRTrade* aContext) {
      this.context = aContext;
}
void BuyLimitOrderOpened::update() {
   if(Ask > context.getCancelPrice()) {
      context.addLogEntry("Ask price went above cancel level", true);
      
      ErrorType result = OrderManager::deleteOrder(context.getOrderTicket(), context);
      
      if (result == NO_ERROR) {
         context.addLogEntry("Order deleted successfully", true);
         context.setState(new TradeClosed(context));
         delete GetPointer(this);
         return;
      }
      
      if (result == RETRIABLE_ERROR) {
         context.addLogEntry("Order could not be deleted. Error code: " + IntegerToString(GetLastError()) + " Will re-try at next tick.", true);
         return;
      }

      if (result == NON_RETRIABLE_ERROR) {
         ///review the logic of this 
         context.addLogEntry("Order could not be deleted. Error code: " + IntegerToString(GetLastError()) + " Trade will close", true);
         context.setState(new TradeClosed(context));
         delete (GetPointer(this));
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