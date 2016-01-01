//+------------------------------------------------------------------+
//|                                                         test.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "../Include/Polymorphic.mq4"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   Polymorphic* p1 = new Derived1();
   Polymorphic* p2 = new Derived2();
   Derived1* s1 = p1.dynamic_cast("Derived1");
   Derived1* s2 = p2.dynamic_cast("Derived1"); //this will return NULL as types are not compatible. 
   //Derived1* s3 = (Derived1*) p2; ///This will crash. 
   
   Polymorphic* p3 = new Base();
   Base* b = p3.dynamic_cast("Base");
   
   Print (s1);
   Print (s2);
   Print (b);
   
   delete s1;
   delete p2;
   delete b;
    
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
