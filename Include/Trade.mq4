

//+------------------------------------------------------------------+
//|                                                        Trade.mqh |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property strict

#include "TradeState.mq4"
#include "Order.mq4"

enum TradeType { 
   FLAT,
   LONG, 
   SHORT
};

class Trade {
public: 
    Trade(string _strategyLabel, int _lotDigits, string _logFileName, int _emailNotificationLevel);
    ~Trade(); 
    void update(); 
    void setState(TradeState *aState); 
    void setTradeType(TradeType _type);
    TradeType getTradeType() const;
    string getId() const; 
    void setActualClose (double close);
    double getActualClose() const;
    void setLotDigits (int _lotDigits);
    int getLotDigits() const;
    double getRealizedPL() const;
    double getUnrealizedPL() const;
    double getTotalEquity() const;
    double getTotalCommission() const ;
    double getTotalSwap() const;    
    void setStartingBalance (double _balance);
    double getStartingBalance() const;
    void setEndingBalance (double _balance);
    double getEndingBalance() const;   
    void setTradeOpenedDate(datetime _date); 
    datetime getTradeOpenedDate() const;
    void setTradeClosedDate(datetime _date); 
    datetime getTradeClosedDate() const;
    bool isInFinalState() const;
    void setFinalStateFlag();
    void addLogEntry(string entry, bool print);
    void addLogEntry(int level, string subject, string body);
    void printLog() const;
    void writeLogToFile(string filename, bool append) const;
    void writeLogToHTML(string filename, bool append) const;
    virtual void writeLogToCSV() const;
    
    void addOrder(Order* order);
    int getNumberOfPendingOrders() const;
    int getNumberOfFilledOrders() const;
    int getNumberOfClosedOrders() const;
    void deleteAllPendingOrders();
    void closeAllFilledOrders();
    

protected: 
    int orderTicket;
    string id;
    double startingBalance;
    double endingBalance;
    int lotDigits;
    TradeType tradeType;
        
    datetime tradeOpenedDate;
    datetime tradeClosedDate;
    
    string logFileName;
    string datetimeToExcelDate(datetime _date) const;
    string tradeTypeToString(TradeType _type) const;
    string strategyLabel;
    int emailNotificationLevel;

private:
    TradeState* state;
    bool finalState;
    string log[1000];
    int logSize;  
    static const int OFFSET;
    Order* orders[1000];
    int numberOrders;
};



const int Trade::OFFSET = (-7) *60*60;

Trade::Trade(string _stategyLabel, int _lotDigits, string _logFileName, int _emailNotificationLevel) {
    this.logFileName = _logFileName;
    this.tradeType = FLAT;
    this.startingBalance = AccountBalance();
    this.endingBalance = 0;
    this.lotDigits = _lotDigits;
    this.state=NULL;
    this.orderTicket=-1;
    this.logSize=0;
    this.numberOrders = 0;
        
    this.tradeOpenedDate = TimeCurrent();
    this.tradeClosedDate = -1;
    
    this.finalState = false;
    this.strategyLabel = _stategyLabel;
    this.emailNotificationLevel = _emailNotificationLevel;

    this.id=Symbol() + 
            IntegerToString(TimeYear(TimeCurrent()+OFFSET))+ "-" +
            IntegerToString(TimeMonth(TimeCurrent()+OFFSET), 2, '0')+ "-" +
            IntegerToString(TimeDay(TimeCurrent()+OFFSET), 2, '0')+ "::" +
            IntegerToString(TimeHour(TimeCurrent()+OFFSET), 2, '0')+ ":" +
            IntegerToString(TimeMinute(TimeCurrent()+OFFSET), 2, '0')+ ":" +
            IntegerToString(TimeSeconds(TimeCurrent()+OFFSET), 2, '0');
            
    if (!IsTesting()) {
        string filename = Symbol() + "_" + TimeToStr(TimeCurrent(), TIME_DATE);
        int filehandle=FileOpen(filename, FILE_WRITE | FILE_READ | FILE_TXT);
        if(filehandle!=INVALID_HANDLE) {
            FileSeek(filehandle, 0, SEEK_END);
            FileWrite(filehandle, "****Trade: ", this.id, " ****");
            FileClose(filehandle);
        }
        else Print("Operation FileOpen failed, error ",GetLastError());
    }
}



Trade::~Trade() {
    delete state;
    for (int i = 0; i <= numberOrders; ++i) {
        delete this.orders[i];
    }
}

void Trade::update() {
    if(state!=NULL)
       state.update();
    
    for (int i = 0; i <= numberOrders; ++i) {
        this.orders[i].update();
    }
    
}

void Trade::addOrder(Order* order) {
    this.orders[numberOrders] = order;
    numberOrders++;
}

int Trade::getNumberOfPendingOrders() const {
    int numberOfPendingOrders = 0;
    for (int i = 0; i <= numberOrders; ++i) {
        OrderType orderType = this.orders[i].getOrderType();
        if ((orderType == ORDER_BUY_LIMIT) || (orderType == ORDER_SELL_LIMIT) || (orderType == ORDER_BUY_STOP) || (orderType == ORDER_SELL_STOP)) {
            numberOfPendingOrders++;
        }
    }
    return numberOfPendingOrders;
}

int Trade::getNumberOfFilledOrders() const {
    int numberOfFilledOrders = 0;
    for (int i = 0; i <= numberOrders; ++i) {
        OrderType orderType = this.orders[i].getOrderType();
        if ((orderType == ORDER_BUY) || (orderType == ORDER_SELL)) {
            numberOfFilledOrders++;
        }
    }
    return numberOfFilledOrders;
}

int Trade::getNumberOfClosedOrders() const {
    int numberOfClosedOrders = 0;
    for (int i = 0; i <= numberOrders; ++i) {
        OrderType orderType = this.orders[i].getOrderType();
        if (orderType == ORDER_FINAL) {
            numberOfClosedOrders++;
        }
    }
    return numberOfClosedOrders;
}

void Trade::deleteAllPendingOrders() {
    for (int i = 0; i <= numberOrders; ++i) {
        OrderType orderType = this.orders[i].getOrderType();
        if ((orderType == ORDER_BUY_LIMIT) || (orderType == ORDER_SELL_LIMIT) || (orderType == ORDER_BUY_STOP) || (orderType == ORDER_SELL_STOP)) {
            this.orders[i].deleteOrder();
        }
    }
}

void Trade::closeAllFilledOrders() {
    for (int i = 0; i <= numberOrders; ++i) {
        OrderType orderType = this.orders[i].getOrderType();
        if ((orderType == ORDER_BUY) || (orderType == ORDER_SELL)) {
            this.orders[i].closeOrder();
        }
    }
}

void Trade::addLogEntry(string entry, bool print) {
    this.log[logSize] = TimeToStr(TimeCurrent()+OFFSET, TIME_DATE | TIME_SECONDS) + ": " + entry;
    logSize++;
    
    if (!IsTesting()) {
        //write to file
        string filename = Symbol() + "_" + TimeToStr(TimeCurrent(), TIME_DATE);
        int filehandle=FileOpen(filename, FILE_WRITE | FILE_READ | FILE_TXT);
        if(filehandle!=INVALID_HANDLE) {
            FileSeek(filehandle, 0, SEEK_END);
            FileWrite(filehandle, TimeToStr(TimeCurrent()+OFFSET, TIME_DATE | TIME_SECONDS) + ": " + entry);
            FileClose(filehandle);
        }
        else Print("Operation FileOpen failed, error ",GetLastError());
    }
    //enable this only when in Not Testmode or in DEBUG mode
    //if (print) 
        //Print(TimeToStr(TimeCurrent(), TIME_DATE | TIME_SECONDS) + ": TradeID: " + this.id + " " + entry);
}

void Trade::addLogEntry(int level, string _subject, string _body="") {
    if (_subject == "") return;
    string subject = strategyLabel + " " + Symbol() + "  " + TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES) + " Trade ID: " + this.id + " " + _subject;
    Print(subject);
    this.log[logSize] = subject;
    logSize++;
    this.log[logSize] = _body;
    logSize++;
    
    if ((this.emailNotificationLevel >= level) && (!IsTesting()))  {
        //Subject has a max length of 127 - trim required
        subject = StringSubstr(subject, 0, MathMin(StringLen(subject), 127));
        SendMail(subject, _body);
    }

    if (!IsTesting()) {
        //write to file
        string filename = strategyLabel + " " + Symbol() + "_" + TimeToStr(TimeCurrent(), TIME_DATE);
        int filehandle = FileOpen(filename, FILE_WRITE | FILE_READ | FILE_TXT);
        FileSeek(filehandle, 0, SEEK_END);

        FileWriteString(filehandle, subject, StringLen(subject));
        FileWriteString(filehandle, "\n", 1);
        FileWriteString(filehandle, _body, StringLen(_body));
        FileWriteString(filehandle, "\n", 1);
        FileClose(filehandle);
    }
}


void Trade::printLog() const {
    Print ("****Trade: ", this.id, " ****");
    for (int i = 0; i < logSize; ++i) {
        Print(log[i]);
    }
}

void Trade::writeLogToFile(string filename, bool append) const {
    ResetLastError();
    int openFlags;
    if (append)
        openFlags = FILE_WRITE | FILE_READ | FILE_TXT;
    else 
        openFlags = FILE_WRITE | FILE_TXT;
    
    int filehandle=FileOpen(filename, openFlags);
    if (append)
        FileSeek(filehandle, 0, SEEK_END);
    if(filehandle!=INVALID_HANDLE) {
        FileWrite(filehandle, "****Trade: ", this.id, " ****");
        for (int i = 0; i < logSize; ++i) {
            FileWrite(filehandle, log[i]);
        }
        FileClose(filehandle);
    }
    else Print("Operation FileOpen failed, error ",GetLastError());
}

void Trade::writeLogToHTML(string filename, bool append) const {
    ResetLastError();
    int openFlags;
    if (append)
        openFlags = FILE_WRITE | FILE_READ | FILE_TXT;
    else 
        openFlags = FILE_WRITE | FILE_TXT;
    
    int filehandle=FileOpen(filename, openFlags);
    if (append)
        FileSeek(filehandle, 0, SEEK_END);
    
    if(filehandle!=INVALID_HANDLE) {
        FileWrite(filehandle, "<b>****Trade: ", this.id, " **** </b>");
        FileWrite(filehandle, "<ul>");
        for (int i = 0; i < logSize; ++i) {
            FileWrite(filehandle, "<li>" + log[i] + "</li>");
        }
        FileWrite(filehandle, "</ul>");
        FileClose(filehandle);
    }
    else Print("Operation FileOpen failed, error ",GetLastError());
}

void Trade::writeLogToCSV() const {
    ResetLastError();
    int openFlags;
    openFlags = FILE_WRITE | FILE_READ | FILE_CSV;
    int filehandle=FileOpen(this.logFileName, openFlags, ",");
  if(filehandle!=INVALID_HANDLE) {
        FileSeek(filehandle, 0, SEEK_END); //go to the end of the file
        
        //if first entry, write column headers
        if (FileTell(filehandle)==0) {
            FileWrite(filehandle, "TRADE_ID", "ORDER_TICKET", "TRADE_TYPE", "SYMBOL", "TRADE_OPENED_DATE", "STARTING_BALANCE", "REALIZED PL", "COMMISSION", "SWAP", "ENDING_BALANCE", "TRADE_CLOSED_DATE");
        }
            
        FileWrite(filehandle, this.id, this.orderTicket, tradeTypeToString(this.tradeType), Symbol(), datetimeToExcelDate(this.tradeOpenedDate), this.startingBalance, this.getRealizedPL(), this.getTotalCommission(), this.getTotalSwap(), this.endingBalance, datetimeToExcelDate(this.tradeClosedDate));
    }
    FileClose(filehandle);
}


void Trade::setState(TradeState *aState) {
    this.state=aState;
}

string Trade::getId() const {
    return id;
}

void Trade::setLotDigits (int _lotDigits) {
    this.lotDigits = _lotDigits;
}

int Trade::getLotDigits() const {
    return lotDigits;
}
    
double Trade::getRealizedPL() const {
    double profit = 0;
    for (int i = 0; i <= numberOrders; ++i) {
        if (this.orders[i].getOrderType() == ORDER_FINAL) {
            profit += this.orders[i].getOrderProfit();
        }
    }
    return profit;
}

double Trade::getUnrealizedPL() const {
    double profit = 0;
    for (int i = 0; i <= numberOrders; ++i) {
        if (this.orders[i].getOrderType() != ORDER_FINAL) {
            profit += this.orders[i].getOrderProfit();
        }
    }
    return profit;
}

double Trade::getTotalEquity() const {
    double profit = 0;
    for (int i = 0; i <= numberOrders; ++i) {
        profit += this.orders[i].getOrderProfit();
    }
    return profit;
}

double Trade::getTotalCommission() const {
    double commission = 0;
    for (int i = 0; i <= numberOrders; ++i) {
        commission += this.orders[i].getOrderCommission();
    }
    return commission;
}

double Trade::getTotalSwap() const {
    double swap = 0;
    for (int i = 0; i <= numberOrders; ++i) {
        swap += this.orders[i].getOrderSwap();
    }
    return swap;
}

void Trade::setStartingBalance (double _balance) {
    this.startingBalance = _balance;
}

double Trade::getStartingBalance() const {
    return startingBalance;
}

void Trade::setEndingBalance (double _balance) {
    this.endingBalance = _balance;
}

double Trade::getEndingBalance() const {
    return endingBalance;
}

void Trade::setTradeOpenedDate(datetime _date) {
    this.tradeOpenedDate = _date;
}

datetime Trade::getTradeOpenedDate() const {
    return this.tradeOpenedDate;
}

void Trade::setTradeClosedDate(datetime _date) {
    this.tradeClosedDate = _date;
}

datetime Trade::getTradeClosedDate() const {
    return this.tradeClosedDate;
}

void Trade::setTradeType(TradeType _type) {
    this.tradeType = _type;
}
TradeType Trade::getTradeType() const {
    return this.tradeType;
}

string Trade::datetimeToExcelDate(datetime _date) const {
    if (_date == -1) return "";
    else return IntegerToString(TimeYear(_date),4,'0') + "-" + 
                IntegerToString(TimeMonth(_date),2,'0') + "-" + 
                IntegerToString(TimeDay(_date),2,'0') + " " + 
                IntegerToString(TimeHour(_date),2,'0') + ":" + 
                IntegerToString(TimeMinute(_date),2,'0') + ":" + 
                IntegerToString(TimeSeconds(_date),2,'0');
    
}

string Trade::tradeTypeToString(TradeType _type) const {
    switch (_type) {
        case LONG: return "LONG";
        case SHORT: return "SHORT";
        case FLAT: return "FLAT";
    }
    return "FLAT";
}

bool Trade::isInFinalState() const {
    return this.finalState;
}

void Trade::setFinalStateFlag() {
    this.finalState = true;
}

