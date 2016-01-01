//+------------------------------------------------------------------+
//|                                                       Filled.mq4 |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property strict

#include "OrderState.mq4"
#include "Order.mq4"
#include "Final.mq4"

class Filled : OrderState {
public: 
   Filled(Order* _context) : OrderState(_context) {
   }

   virtual void update() {
      if (OrderSelect(context.getOrderTicket(), SELECT_BY_TICKET)) {
         //check if order has been closed
         if (OrderCloseTime() != 0) {
            context.setOrderType(ORDER_FINAL);
            context.setState(new Final(context));
            delete(GetPointer(this));
         }
      }
   }
};