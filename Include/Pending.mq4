//+------------------------------------------------------------------+
//|                                                      Pending.mq4 |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property strict

#include "OrderState.mq4"
#include "Filled.mq4"
#include "Order.mq4"

class Pending : OrderState {
public: 
   Pending(Order* _context) : OrderState(_context) {
   }

   virtual void update() {
      if (OrderSelect(context.getOrderTicket(), SELECT_BY_TICKET)) {
        if (OrderType() == OP_BUY)  {
            context.setOrderType(ORDER_BUY);
            context.setState(new Filled(context));
            delete GetPointer(this);
        }

        if (OrderType() == OP_SELL)  {
            context.setOrderType(ORDER_SELL);
            context.setState(new Filled(context));
            delete GetPointer(this);
        }
        
        
        //check if cancel level reached
        int mql4OrderType = OrderType();
        if ((mql4OrderType == OP_BUYSTOP) || (mql4OrderType == OP_BUYLIMIT)) {
            if (Bid < context.getCancelPrice()) {
                context.getTrade().addLogEntry(2, "Cancel level reached. Deleting Order");
                context.deleteOrder();
                //transition to final state is defined in deleteOrder
            }
        }
        
        if ((mql4OrderType == OP_SELLSTOP) || (mql4OrderType == OP_SELLLIMIT)) {
            if (Ask > context.getCancelPrice()) {
                context.getTrade().addLogEntry(2, "Cancel level reached. Deleting Order");
                context.deleteOrder();
                //transition to final state is defined in deleteOrder
            }
        }      
      }
      else context.setOrderType(ORDER_FINAL);
   }
};