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


class OrderManager {
public:
   static double getPipConversionFactor();
   static double getPipValue();
   static double getLotSize(double riskCapital, int riskPips);
};

static double OrderManager::getPipValue() {
      double point;
      if (Digits == 5)
         point = Point;
      else 
         point = Point / 10.0;
      Print ("TickSize: ", MarketInfo(Symbol(), MODE_TICKSIZE));
      Print ("TickValue: ", MarketInfo(Symbol(), MODE_TICKVALUE));
      return (MarketInfo(Symbol(), MODE_TICKVALUE) * point) / MarketInfo(Symbol(), MODE_TICKSIZE);
}

static double OrderManager::getLotSize(double riskCapital, int riskPips) {
   double pipValue = OrderManager::getPipValue();
   Print ("Pipvalue: ", pipValue);   
   return riskCapital / ((double) riskPips * pipValue);   
}

static double OrderManager::getPipConversionFactor() {
    //multiplier depending on YEN or non YEN pairs
    if (Digits == 5)
      return 100000.00;
    else
      return 10000.00;
}


