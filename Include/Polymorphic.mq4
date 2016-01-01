//+------------------------------------------------------------------+
//|  9:21 PM 4/30/2014                               polymorphic.mqh |
//|                               Copyright © 2014, William H Roeder |
//|                                        mailto:WHRoeder@yahoo_com |
//| Adds safe dynamic cast and reflection capabilities to classes
//|
//| Give credit                       
//+------------------------------------------------------------------+

#property library
#property strict
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define DYNAMIC_CAST(stringCLASS,typenameBASE) virtual Polymorphic* dynamic_cast(const string c) const{ return( (c==stringCLASS) ? GetPointer(this) : typenameBASE::dynamic_cast(c) );}
#define INSTANCE_OF(typenameBASE) virtual bool instanceOf(const string t) const {return(t==typename(this) || typenameBASE::instanceOf(t));}

class Polymorphic {
public:
   virtual Polymorphic* dynamic_cast(const string c) const { 
      return(NULL); 
   }
   virtual bool instanceOf(const string t) const{return t==typename(this);}
};


class Base : public Polymorphic {
public: 
   DYNAMIC_CAST("Base",Polymorphic);
   INSTANCE_OF(Base);   
};

class Derived1 : public Base {
public: 
   DYNAMIC_CAST("Derived1",Base);
   INSTANCE_OF(Derived1);   
};

class Derived2 : public Base {
public: 
   DYNAMIC_CAST("Derived2",Base);
   INSTANCE_OF(Derived2);   
};


