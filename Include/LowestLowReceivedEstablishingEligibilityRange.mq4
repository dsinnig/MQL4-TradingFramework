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

#include "TradeState.mq4"
#include "TradeClosed.mq4"
#include "ATRTrade.mq4"
#include "StopBuyOrderOpened.mq4"
#include "BuyLimitOrderOpened.mq4"



class LowestLowReceivedEstablishingEligibilityRange : public TradeState {
public:
   LowestLowReceivedEstablishingEligibilityRange(ATRTrade* aContext);
   virtual void update(); 
   
private:
   ATRTrade* context; //hides conext in Trade
   datetime entryTime;
   double rangeLow;
   double rangeHigh;
   int barCounter;
   static bool isNewBar();
};

LowestLowReceivedEstablishingEligibilityRange::LowestLowReceivedEstablishingEligibilityRange(ATRTrade *aContext) {
    this.context = aContext;
    this.entryTime = Time[0];
    this.rangeHigh = -1;
    this.rangeLow=99999;
    this.barCounter=0;
    context.setTradeType(LONG);

    context.addLogEntry("Lowest Low found - establishing eligibility range. Lowest low: " + DoubleToString(Close[0], Digits), true); 
}


void LowestLowReceivedEstablishingEligibilityRange::update()  {
    double factor = OrderManager::getPipConversionFactor(); 
    
    //update range lows and range highs
    if(Low[0]<rangeLow) rangeLow=Low[0];  {
      if(High[0]>rangeHigh) rangeHigh=High[0];
    }
    
    if (isNewBar()) barCounter++;
    
    

    //Waiting Period over? (deault is 10mins + 1min)
    //if(Time[0]-entryTime>=60*(context.getLengthIn1MBarsOfWaitingPeriod()+1))  {
      if (barCounter > context.getLengthIn1MBarsOfWaitingPeriod()+1) {
         
         context.setRSI(iCustom(NULL, 0, "RSI", 15, 0, 0));
         context.setRSI5M(iCustom(NULL, PERIOD_M5,"RSI", 15,0,0));
         context.setRSI15M(iCustom(NULL, PERIOD_M15, "RSI", 15,0,0));
         context.setRSI30M(iCustom(NULL, PERIOD_M30, "RSI", 15,0,0));
         context.setMomentum(iCustom(NULL, 0, "Momentum", 14,0,0));
         context.setMomentum5M(iCustom(NULL, PERIOD_M5, "Momentum", 14,0,0));
         context.setMomentum15M(iCustom(NULL, PERIOD_M15, "Momentum", 14,0,0));
         context.setMomentum30M(iCustom(NULL, PERIOD_M30, "Momentum", 14,0,0));
         context.setStochastics(iCustom(NULL, 0, "Stochastic", 5,3,3,0,0));
         context.setStochastics5M(iCustom(NULL, PERIOD_M5, "Stochastic", 5,3,3,0,0));
         context.setStochastics15M(iCustom(NULL, PERIOD_M15, "Stochastic", 5,3,3,0,0));
         context.setStochastics30M(iCustom(NULL, PERIOD_M30, "Stochastic", 5,3,3,0,0));
         //ToDo: Stocastic indoicator
         
         int rangePips = (int)((rangeHigh-rangeLow)*factor); ///Works for 5 Digts pairs. Verify that calculation is valid for 3 Digits pairs
         int ATRPips = (int) (context.getATR() * factor); ///Works for 5 Digts pairs. Verify that calculation is valid for 3 Digits pairs
         
         context.addLogEntry("Range established at: " + IntegerToString(rangePips) + " microp pips. HH=" + DoubleToString(rangeHigh, Digits) + ", LL=" + DoubleToString(rangeLow, Digits), true);
         context.setRangeLow(rangeLow);
         context.setRangeHigh(rangeHigh);
         context.setRangePips(rangePips);

         //Range too large for limit or stop order
         if((rangeHigh-rangeLow)>((context.getPercentageOfATRForMaxVolatility()/100.00)*context.getATR()))  {
            context.addLogEntry("Range (" + IntegerToString(rangePips) + " micro pips) greater than " + DoubleToString(context.getPercentageOfATRForMaxVolatility(), 2) + "% of ATR (" + IntegerToString(ATRPips) + " micro pips)", true);
            context.setState(new TradeClosed(context));
            delete GetPointer(this);
         }
         else {
            double entryPrice = 0.0;
            double stopLoss = 0.0;
            double cancelPrice = 0.0;
            int orderType = -1;
            TradeState* nextState = NULL;
            int orderTicket = -1;
            double positionSize = 0;
            double buffer = context.getRangeBufferInMicroPips() / factor; ///Works for 5 Digts pairs. Verify that calculation is valid for 3 Digits pairs
            //Range is less than max risk
            if ((rangeHigh-rangeLow)<((context.getPercentageOfATRForMaxRisk()/100.00)*context.getATR())) {
               
               //write to log
               context.addLogEntry("Range " + IntegerToString(rangePips) + " is less than max risk (" + DoubleToString(context.getPercentageOfATRForMaxRisk(), 2) + "% of ATR (" + IntegerToString(ATRPips) + " micro pips))", true); 
               
               entryPrice = rangeHigh + buffer;
               stopLoss = rangeLow - buffer;
               cancelPrice = rangeLow;
               orderType = OP_BUYSTOP; 
               context.setOrderType("BUY_STOP");
               nextState = new StopBuyOrderOpened(context);
            }
            else 
            //Range is above risk level, but below max volatility level. Current Ask price is larger than entry level.  
            if (((rangeHigh-rangeLow)<((context.getPercentageOfATRForMaxVolatility()/100.00)*context.getATR())) && 
                 (Ask > rangeLow + context.getATR() * (context.getPercentageOfATRForMaxRisk()/100.00) + buffer)) {
               
               //write to log
               context.addLogEntry("Range (" + IntegerToString(rangePips) + " micro pips) is greater than max risk (" + DoubleToString(context.getPercentageOfATRForMaxRisk(), 2) +  
                                   "%) but less than max. volatility (" + DoubleToString(context.getPercentageOfATRForMaxVolatility(), 2) + "%) of ATR (" + IntegerToString(ATRPips) + " micro pips). Ask price is greater than entry price.", true); 
                              
               entryPrice = rangeLow + context.getATR() * (context.getPercentageOfATRForMaxRisk()/100.00) + buffer;
               stopLoss = rangeLow - buffer;
               cancelPrice = rangeLow + context.getATR() * context.getPercentageOfATRForMaxVolatility() / 100.00; //cancel if above 20% of ATR
               orderType = OP_BUYLIMIT;
               context.setOrderType("BUY_LIMIT");
               nextState = new BuyLimitOrderOpened(context);
               
            } else 
            //Range is above risk level, but below max volatility level. Current Ask price is less than entry level.  
            if (((rangeHigh-rangeLow)<((context.getPercentageOfATRForMaxVolatility()/100.00)*context.getATR())) && 
                 (Ask < rangeLow + context.getATR() * (context.getPercentageOfATRForMaxRisk()/100.00) + buffer)) {
                
                //write to log
                context.addLogEntry("Range (" + IntegerToString(rangePips) + " micro pips) is greater than max risk " + DoubleToString(context.getPercentageOfATRForMaxRisk(), 2) +  
                                   "% but less than max. volatility " + DoubleToString(context.getPercentageOfATRForMaxVolatility(), 2) + "% of ATR (" + IntegerToString(ATRPips) + " micro pips). Ask price is less than entry price.", true); 
                                
                Print ("ATR: ", DoubleToString(context.getATR(),10));
                Print ("Range lowL: ", rangeLow);
                Print ("Buffer: ", buffer);
                
                entryPrice = rangeLow + context.getATR() * (context.getPercentageOfATRForMaxRisk()/100.00) + buffer;
                stopLoss = rangeLow - buffer;
                cancelPrice = rangeLow;
                orderType = OP_BUYSTOP; 
                context.setOrderType("BUY_STOP");
                nextState = new StopBuyOrderOpened(context);
             }
             
             //only place order if entryPrice was calculated. I.e., if any of the three previous if/else cases was exercised. 
             if (entryPrice != 0.0) {
                int riskPips = (int) (MathAbs(stopLoss - entryPrice) * factor);
                double riskCapital = AccountBalance() * 0.0075;
                
                
                Print ("RiskPips: ", riskPips);
                Print ("Risk Capital", riskCapital);
                positionSize = NormalizeDouble(OrderManager::getLotSize(riskCapital, riskPips),context.getLotDigits());
                
                Print ("Lot size: ", OrderManager::getLotSize(riskCapital, riskPips));
                Print ("Position size: ", positionSize);
                
                context.addLogEntry("AccountBalance: $" + DoubleToString(AccountBalance(), 2) + "; Risk Capital: $" + DoubleToString(riskCapital, 2) + "; Risk pips: " + DoubleToString(riskPips, 2) + " micro pips; Position Size: " + DoubleToString(positionSize, 2) + " lots; Pip value: " + DoubleToString(OrderManager::getPipValue(),Digits), true);
                
                //place Order
                ErrorType result = OrderManager::submitNewOrder(orderType, entryPrice, stopLoss, 0, cancelPrice, positionSize, context);
                
                context.setStartingBalance(AccountBalance());
                context.setOrderPlacedDate(TimeCurrent());
                context.setSpreadOrderOpen((int) MarketInfo(Symbol(),MODE_SPREAD));
                context.setAskPriceBeforeOrderEntry(Ask);
                context.setBidPriceBeforeOrderEntry(Bid);
                
                if(result==NO_ERROR)  {
                    context.setInitialProfitTarget (NormalizeDouble(context.getPlannedEntry() + ((context.getPlannedEntry() - context.getStopLoss()) * (context.getMinProfitTarget())), Digits));
                    context.setState(nextState);
                    context.addLogEntry("Order successfully placed. Initial Profit target is: " + DoubleToString(context.getInitialProfitTarget(), Digits) + " (" + IntegerToString((int) (MathAbs(context.getInitialProfitTarget() - context.getPlannedEntry()) * factor)) + " micro pips)" + " Risk is: " + IntegerToString((int) riskPips) + " micro pips" , true);
                    delete GetPointer(this);
                    return;
                }
               if((result==RETRIABLE_ERROR) && (context.getOrderTicket()==-1))  {
                    context.addLogEntry("Order entry failed. Error code: " + IntegerToString(GetLastError()) + ". Will re-try at next tick", true);
                    delete nextState;
                    return;
               }

               //this should never happen...
               if((context.getOrderTicket()!=-1) && (RETRIABLE_ERROR || NON_RETRIABLE_ERROR))  {
                    context.addLogEntry("Error ocured but order is still open. Error code: " + IntegerToString(GetLastError()) + ". Continue with trade. Initial Profit target is: " + DoubleToString(context.getInitialProfitTarget(), Digits) + " (" + IntegerToString((int) (MathAbs(context.getInitialProfitTarget() - context.getPlannedEntry()) * factor)) + " micro pips)" + " Risk is: " + IntegerToString((int) riskPips) + " micro pips" , true);
                    context.setInitialProfitTarget (NormalizeDouble(context.getPlannedEntry() + ((context.getPlannedEntry() - context.getStopLoss()) * ( context.getMinProfitTarget())), Digits));
                    context.setState(nextState);
                    delete GetPointer(this);
                    return;
                 }

               if((result==NON_RETRIABLE_ERROR) && (context.getOrderTicket()==-1))  {
                  context.addLogEntry("Non-recoverable error occurred. Errorcode: " + IntegerToString(GetLastError()) + ". Trade will be canceled", true);
                  context.setState(new TradeClosed(context));
                  delete nextState;
                  delete GetPointer(this);
                  return;
               }
            } //end for if that checks if entryPrice is != 0.0
        } //end else (that checks for general trade eligibility)
     } //end if for range delay check
} 

bool LowestLowReceivedEstablishingEligibilityRange::isNewBar() {
   static datetime lastbar=0;
   datetime curbar=Time[0];
   if(lastbar!=curbar) {
      lastbar=curbar;
      return (true);
   }
   else {
      return(false);
   }
}