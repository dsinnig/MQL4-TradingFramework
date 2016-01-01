//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "TradeState.mq4"
#include "ATRTrade.mq4"
#include "ShortProfitTargetReachedLookingToAdjustStopLoss.mq4"

class SellOrderFilledProfitTargetNotReached : public TradeState {
public:
   SellOrderFilledProfitTargetNotReached(ATRTrade* aContext);
   virtual void update() ;

private: 
  ATRTrade* context; //hides conext in Trade
};
  
SellOrderFilledProfitTargetNotReached::SellOrderFilledProfitTargetNotReached(ATRTrade* aContext) {
   this.context = aContext;
   context.setOrderFilledDate(TimeCurrent());
};

void SellOrderFilledProfitTargetNotReached::update() {
   //see if stopped out
   bool success=OrderSelect(context.getOrderTicket(),SELECT_BY_TICKET);
   if(!success) {
      context.addLogEntry("Unable to find order. Trade must have been closed", true);
      context.setState(new TradeClosed(context));
      delete GetPointer(this);
      return;
   }
   
   if(OrderCloseTime()!=0) {
      double pips = MathAbs(OrderClosePrice() - context.getActualEntry()) * OrderManager::getPipConversionFactor();
      string logMessage = "Loss of " + DoubleToString(pips, 1) + " micro pips.";
      context.addLogEntry("Stop loss triggered @" + DoubleToString(OrderClosePrice(), Digits) + " " + logMessage, true);
      context.addLogEntry("P/L: $" + DoubleToString(OrderProfit(),2) + "; Commission: $" + DoubleToString(OrderCommission(),2) + "; Swap: $" + DoubleToString(OrderSwap(),2) + "; New Account balance: $" + DoubleToString(AccountBalance(),2), true);
      
      
      context.setRealizedPL(OrderProfit());
      context.setOrderCommission(OrderCommission());
      context.setOrderSwap(OrderSwap());
      
      context.setActualClose(OrderClosePrice());
      context.setState(new TradeClosed(context));
      delete GetPointer(this);
      return;
   }
   
   
   if(Ask < context.getInitialProfitTarget()) {
      context.addLogEntry("Initial profit target reached. Looking to adjust stop loss", true);
      context.setState(new ShortProfitTargetReachedLookingToAdjustStopLoss(context));
      delete GetPointer(this);
   }
}
