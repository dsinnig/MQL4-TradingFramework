//+------------------------------------------------------------------+
//|                                                        Final.mq4 |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property strict

#include "OrderState.mq4"
#include "Order.mq4"

class Final : OrderState {
public: 
   Final(Order* _context) : OrderState(_context) {
   }

   virtual void update() {
      if (!context.getOrderCloseTime() == 0)
            {
                context.setOrderType(ORDER_FINAL);
            }
   }
};