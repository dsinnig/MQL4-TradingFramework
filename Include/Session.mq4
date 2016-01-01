//+------------------------------------------------------------------+
//|                                                      Session.mqh |
//|                                                    Daniel Sinnig |
//|                                                                  |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      ""
#property strict

class Session {
   
public: 
   Session(int aSessionID, string aSessionName, datetime aSessionStartDateTime, datetime aSessionEndDateTime, datetime aHHLL_ReferenceDateTime, bool tradingFlag, int aHHLLThreshold);
  
   void initialize();
   int update(double price);

   datetime getSessionStartTime() const;
   datetime getSessionEndTime() const;
   datetime getHHLL_ReferenceDateTime() const;
   string getName() const;
   double getHighestHigh() const;
   datetime getHighestHighTime() const;
   double getLowestLow() const;
   datetime getLowestLowTime() const;
   double getATR() const;
   int getID() const;
   bool tradingAllowed() const;
   double getTenDayLow() const;
   double getTenDayHigh() const;
      
private: 
   int sessionID;
   string sessionName;
   datetime sessionStartDateTime;
   datetime sessionEndDateTime;
   datetime HHLL_ReferenceDateTime; 
   double highestHigh;
   datetime dateOfHighestHigh;
   double lowestLow;
   datetime dateOfLowestLow;
   double atr;
   int HHLL_Threshold;
   bool isTradingAllowed;
   double tenDayLow;
   double tenDayHigh;
};


//Implementation

Session::Session (int aSessionID, string aSessionName, datetime aSessionStartDateTime, datetime aSessionEndDateTime, datetime aHHLL_ReferenceDateTime, bool tradingFlag, int aHHLLThreshold) {
 
      this.sessionID = aSessionID;
      this.sessionName = aSessionName;
      this.sessionStartDateTime = aSessionStartDateTime;
      this.sessionEndDateTime = aSessionEndDateTime;
      this.HHLL_ReferenceDateTime = aHHLL_ReferenceDateTime;
      this.isTradingAllowed = tradingFlag;
      this.HHLL_Threshold = aHHLLThreshold;
      this.highestHigh = -1;
      this.lowestLow = 9999999999;
      this.dateOfHighestHigh = 0;
      this.dateOfLowestLow = 0;
      
      initialize();
}

void Session::initialize() {
   
   this.highestHigh = -1;
   this.lowestLow = 999999;
   this.dateOfHighestHigh = 0;
   this.dateOfLowestLow = 0;
   this.atr = 0;
   
   if (this.isTradingAllowed) {
      int indexOfReferenceStart = iBarShift(Symbol(), PERIOD_H1, this.HHLL_ReferenceDateTime, true);

      if (indexOfReferenceStart == -1) {
         Print("Could not find Shift of first 1H bar of reference period");
         return;
      }
      
      int indexOfHighestHigh = iHighest(Symbol(),PERIOD_H1,MODE_HIGH,indexOfReferenceStart,0);
      
      Print("Index of HH is: ", indexOfHighestHigh);
      
      int indexOfLowestLow = iLowest(Symbol(), PERIOD_H1, MODE_LOW, indexOfReferenceStart,0);
      
      if ((indexOfHighestHigh == -1) || (indexOfLowestLow == -1)) {
         Print ("Could not find highest high or lowest low for reference period");
         return;
      }
      
      this.highestHigh = iHigh(Symbol(), PERIOD_H1, indexOfHighestHigh);
      
      Print ("Highest High is: ", this.highestHigh);
      
      this.dateOfHighestHigh = iTime(Symbol(), PERIOD_H1, indexOfHighestHigh);
      
      Print ("Date of highest high is: ", this.dateOfHighestHigh);
      
      this.lowestLow = iLow(Symbol(), PERIOD_H1, indexOfLowestLow);
      this.dateOfLowestLow = iTime(Symbol(), PERIOD_H1, indexOfLowestLow);
   
      //check if new High / Low happened in last 100 minutes - if yes update dateOfLowestLow / dateOfHighestHigh with accurate timestamp
      int i = HHLL_Threshold; //paratrize
      while (i > 0) {
         if (Low[i] == lowestLow) {
            dateOfLowestLow = Time[i];
         }
         if (High[i] == highestHigh) {
            dateOfHighestHigh = Time[i];
         }
         i--;
      }
   
   //calculate ATR
   int lookBack1HPeriod = 10*24; //10days lookback
   //get shift for session start
   int indexOfSessionStart = iBarShift(Symbol(), PERIOD_H1, this.sessionStartDateTime, true);
   
   double sum = 0;
   double _tenDayHigh = 0;
   double _tenDayLow = 9999;
   
   
   for (i = 0; i < 10; ++i) {
           
      double periodHigh = iHigh(Symbol(), PERIOD_H1, iHighest(Symbol(),PERIOD_H1,MODE_HIGH,24,(indexOfSessionStart + i*24) + 1));
      double periodLow = iLow(Symbol(), PERIOD_H1, iLowest(Symbol(),PERIOD_H1,MODE_LOW,24,(indexOfSessionStart + i*24) + 1));
      
      if (periodHigh > _tenDayHigh) _tenDayHigh = periodHigh;
      if (periodLow < _tenDayLow) _tenDayLow = periodLow;
      
      sum = sum + (periodHigh - periodLow);
   
   }
   
   this.atr = sum / 10.0;
   this.tenDayHigh = _tenDayHigh;
   this.tenDayLow = _tenDayLow;
   
   } //end if TradingAllowed
}

int Session::update(double price) {
   if (this.isTradingAllowed) {
      if (price > this.highestHigh) {
         bool validHighestHigh = false;
         if ((TimeCurrent() - this.dateOfHighestHigh) > (HHLL_Threshold * 60)) {
            validHighestHigh = true;
         }
         this.highestHigh = price;
         this.dateOfHighestHigh = TimeCurrent();
         if (validHighestHigh) return 1;
      }
      
      if (price < this.lowestLow) {
         bool validLowestLow = false;
         if ((TimeCurrent() - this.dateOfLowestLow) > (HHLL_Threshold * 60)) {
            validLowestLow = true;
         }
         this.lowestLow = price;
         this.dateOfLowestLow = TimeCurrent();
         if (validLowestLow) return -1;
      }
   }   
   return 0;
}


datetime Session::getSessionStartTime() const {
   return sessionStartDateTime;
}

datetime Session::getSessionEndTime() const {
   return sessionEndDateTime;
}

datetime Session::getHHLL_ReferenceDateTime() const {
   return HHLL_ReferenceDateTime;
}

string Session::getName() const {
   return sessionName;
}

double Session::getHighestHigh() const {
   return highestHigh;
}

datetime Session::getHighestHighTime() const {
   return dateOfHighestHigh;
}

double Session::getLowestLow() const {
   return lowestLow;
}

datetime Session::getLowestLowTime() const {
   return dateOfLowestLow;
}

double Session::getATR() const {
   return this.atr;
}

int Session::getID() const {
   return this.sessionID;
}

bool Session::tradingAllowed() const {
   return this.isTradingAllowed;
}

double Session::getTenDayHigh() const {
   return this.tenDayHigh;
}

double Session::getTenDayLow() const {
   return this.tenDayLow;
}