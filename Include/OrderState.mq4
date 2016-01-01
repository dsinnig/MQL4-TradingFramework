//+------------------------------------------------------------------+
//|                                                   OrderState.mq4 |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property strict

class Order;

class OrderState {
public:
   OrderState(Order* _context) {
      this.context = _context;   
   }

   virtual void update() {
      Print("Abstract method - should never be called");
      ExpertRemove();
   }

protected: 
   Order* context;
};