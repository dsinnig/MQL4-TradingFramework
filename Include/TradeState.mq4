//+------------------------------------------------------------------+
//|                                                   TradeState.mqh |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property strict

class Trade;

class TradeState {
public:
   TradeState() {
   };

   virtual void update() {
      Print("TradeState::update is abstract method - should never be called");
      ExportClose();
   }
};