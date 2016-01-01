//+------------------------------------------------------------------+
//|                                               SessionFactory.mqh |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property strict

#include "Session.mq4"

class SessionFactory {
public:
   static Session* getCurrentSession(datetime aLengthOfSundaySession, int aHHLL_Threshold);
   static void cleanup();
private: 
   static int detectWeekStartShift();
   static Session* currentSession;
};   

      
Session* SessionFactory::currentSession = NULL;

//length of Sunday session is given in hours
static  Session* SessionFactory::getCurrentSession(datetime aLengthOfSundaySession, int aHHLL_Threshold) {
      int aLengthOfSundaySessionInHours = TimeHour(aLengthOfSundaySession);
      datetime weekStartTime = iTime(Symbol(), PERIOD_H1, SessionFactory::detectWeekStartShift());
      datetime previousFridayStartTime = iTime(Symbol(), PERIOD_H1, SessionFactory::detectWeekStartShift() + (24 - aLengthOfSundaySessionInHours));
      datetime currentTime = TimeCurrent();
      datetime fullDayInSeconds = 60 * 60 * 24;
      datetime timeElapsedSinceWeekStart = currentTime - weekStartTime;
      
      if (timeElapsedSinceWeekStart < aLengthOfSundaySession) {
         if ((SessionFactory::currentSession == NULL) || (SessionFactory::currentSession.getID() != 0)) {
            delete currentSession;
            currentSession = new Session (0,"SUNDAY",weekStartTime, weekStartTime + aLengthOfSundaySession, 0, false, 0);
         }
         return currentSession;
      }
      else if (timeElapsedSinceWeekStart < aLengthOfSundaySession + 1 * fullDayInSeconds) {
         if ((SessionFactory::currentSession == NULL) || (SessionFactory::currentSession.getID() != 1)) {
            delete currentSession;
            currentSession = new Session (1,"MONDAY",weekStartTime + aLengthOfSundaySession, weekStartTime + aLengthOfSundaySession + fullDayInSeconds, previousFridayStartTime, true, aHHLL_Threshold);
         }
         return currentSession;
      }
      else if (timeElapsedSinceWeekStart < aLengthOfSundaySession + 2 * fullDayInSeconds) {
         if ((SessionFactory::currentSession == NULL) || (SessionFactory::currentSession.getID() != 2)) {
            delete currentSession;
            currentSession = new Session (2,"TUESDAY",weekStartTime + aLengthOfSundaySession + fullDayInSeconds, weekStartTime + aLengthOfSundaySession + 2 * fullDayInSeconds, weekStartTime + aLengthOfSundaySession, true, aHHLL_Threshold);
         }
         return currentSession;
      }
      else if (timeElapsedSinceWeekStart < aLengthOfSundaySession + 3 * fullDayInSeconds) {
         if ((SessionFactory::currentSession == NULL) || (SessionFactory::currentSession.getID() != 3)) {
            delete currentSession;
            currentSession = new Session (3,"WEDNESDAY",weekStartTime + aLengthOfSundaySession + 2 * fullDayInSeconds, weekStartTime + aLengthOfSundaySession + 3* fullDayInSeconds, weekStartTime + aLengthOfSundaySession + fullDayInSeconds, true, aHHLL_Threshold);
         }
         return currentSession;
      }
      else if (timeElapsedSinceWeekStart < aLengthOfSundaySession + 4 * fullDayInSeconds) {
         if ((SessionFactory::currentSession == NULL) || (SessionFactory::currentSession.getID() != 4)) {
            delete currentSession;
            currentSession = new Session (4,"THURSDAY",weekStartTime + aLengthOfSundaySession + 3 * fullDayInSeconds, weekStartTime + aLengthOfSundaySession + 4* fullDayInSeconds, weekStartTime + aLengthOfSundaySession + 2 * fullDayInSeconds, true, aHHLL_Threshold);
         }
         return currentSession;
      }
      else if (timeElapsedSinceWeekStart < aLengthOfSundaySession + 4 * fullDayInSeconds + (fullDayInSeconds - aLengthOfSundaySession)) {
         if ((SessionFactory::currentSession == NULL) || (SessionFactory::currentSession.getID() != 5)) {
            delete currentSession;
            currentSession = new Session (5,"FRIDAY",weekStartTime + aLengthOfSundaySession + 4 * fullDayInSeconds, weekStartTime + aLengthOfSundaySession + 4 * fullDayInSeconds + (fullDayInSeconds - aLengthOfSundaySession), weekStartTime + aLengthOfSundaySession + 3 * fullDayInSeconds, true, aHHLL_Threshold);
         }
         return currentSession;
      }
      else {
         if ((SessionFactory::currentSession == NULL) || (SessionFactory::currentSession.getID() != -1)) {
            delete currentSession;
            currentSession = new Session (-1, "UNKNOWN", 0,0,0,false, 0);
            
         }
      return currentSession;
      }
}
   
static int SessionFactory::detectWeekStartShift() {
   int i = 0;
   bool shiftDetected = false;
   while (i<168) {
      if (iTime(Symbol(), PERIOD_H1, i) - iTime(Symbol(), PERIOD_H1, i+1) > 4*60*60) {
         shiftDetected = true; 
         break;
      }
      ++i;   
   }
   
   if (shiftDetected) return i;
   else {
      Print("Unable to detect weekstart - abort");
      return -1;
   }
}

static void SessionFactory::cleanup() {
      delete SessionFactory::currentSession;
}

