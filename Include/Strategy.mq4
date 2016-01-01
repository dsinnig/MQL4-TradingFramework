//+------------------------------------------------------------------+
//|                                                     Strategy.mq4 |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//|                  Interface for adjusting stopLoss and takeProfit |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

class Strategy {
   virtual double adjust()  {
        Print("Strategy::adjust is abstract method - should never be called. Shutting down EA");
        ExpertRemove();
        return 0.0;
   }
};

///Determine runtime type of an object
