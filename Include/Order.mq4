//+------------------------------------------------------------------+
//|                                                        Order.mq4 |
//|                                                    Daniel Sinnig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Daniel Sinnig"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "Trade.mq4"
#include "OrderState.mq4"
#include "Pending.mq4"
#include "Filled.mq4"
#include "Final.mq4"
#include "Strategy.mq4"

enum OrderType { 
   //enumerators have length restriction
   ORDER_INIT, ORDER_BUY_LIMIT, ORDER_SELL_LIMIT, ORDER_BUY_STOP, ORDER_SELL_STOP, ORDER_BUY, ORDER_SELL, ORDER_FINAL
};

enum ErrorType { 
   ORDER_STATUS_NO_ERROR,
   ORDER_STATUS_RETRIABLE_ERROR,
   ORDER_STATUS_NON_RETRIABLE_ERROR
};
    
class Order {
private: 
   OrderState* state;
   Trade* trade;
   double entryPrice;
   double stopLoss;
   double takeProfit;
   double cancelPrice;
   double positionSize;
   OrderType orderType;
   int orderTicket;
   int magicNumber;

public: 
    Order(Trade* _trade) {
      this.trade = _trade;
      this.orderType = ORDER_INIT;
      this.magicNumber = 0;
      //this.state = NULL;
    }
   
    Order(Trade* _trade, int _magicNumber) {
        this.trade = _trade;
        this.orderType = ORDER_INIT;
        this.state = NULL;
        this.magicNumber = _magicNumber;
    }
        
   virtual void update()  {
        if (state != NULL) state.update();
   }

   OrderState* getState() const   {
      return state;
   }

   void setState(OrderState* _state) {
      this.state = _state;
   }
   
   
   bool isFilled() const {
      if (OrderSelect(this.orderTicket, SELECT_BY_TICKET)) {
        int mql4OrderType = OrderType();
        if ((mql4OrderType == OP_BUY) || (mql4OrderType == OP_SELL)) {
            return true;
        } else return false;
      } else return -1;
   }
   
   virtual datetime getOrderCloseTime() const  {
      if (OrderSelect(this.orderTicket, SELECT_BY_TICKET)) return OrderCloseTime();
      else return -1;
   }

   virtual double getOrderProfit() const {
      if (OrderSelect(this.orderTicket, SELECT_BY_TICKET)) return OrderProfit();
      else return 0;
   }

   virtual double getOrderCommission() const {
      if (OrderSelect(this.orderTicket, SELECT_BY_TICKET)) return OrderCommission();
      else return 0;
   }

   virtual double getOrderSwap() const {
      if (OrderSelect(this.orderTicket, SELECT_BY_TICKET)) return OrderSwap();
      else return 0;
   }

   virtual double getOrderOpenPrice() const {
      if (OrderSelect(this.orderTicket, SELECT_BY_TICKET)) return OrderOpenPrice(); 
      else return -1;
   }

   virtual double getOrderClosePrice() const  {
      if (OrderSelect(this.orderTicket, SELECT_BY_TICKET)) return OrderClosePrice();
      else return -1;
   }
   
   OrderType getOrderType() const {
      return orderType;
   }
   
   void setOrderType(OrderType _type) {
      this.orderType = _type;
   }

   double getEntryPrice() const {
      return this.entryPrice;
   }
   
   void setEntryPrice(double _entryPrice) {
      this.entryPrice = _entryPrice;
   }
   
   double getStopLoss() const {
      return this.stopLoss;
   }
   
   void setStopLoss(double _stopLoss) {
      this.stopLoss = _stopLoss;
   }

   
   double getTakeProfit() const {
      return this.takeProfit;
   }
   
   void setTakeProfit(double _takeProfit) {
      this.takeProfit = _takeProfit;
   }
   
   double getCancelPrice() const {
      return this.cancelPrice;
   }
    
   void setCancelPrice(double _cancelPrice) {
      this.cancelPrice = _cancelPrice;
   }
   
   double getPositionSize() const {
      return positionSize;
   }

   void setPositionSize(double _positionSize) {
      this.positionSize = _positionSize;
   }

   int getOrderTicket() const {
      return this.orderTicket;
   }
   
   void setOrderTicket(int _orderTicket) {
      this.orderTicket = _orderTicket;
   }
   
    void setOrderPlacedDate(datetime _date); 
    datetime getOrderPlacedDate() const;
    void setOrderFilledDate(datetime _date); 
    datetime getOrderFilledDate() const;
    void setTradeClosedDate(datetime _date); 
    datetime getTradeClosedDate() const;
    void setSpreadOrderOpen(int _spread);
    int getSpreadOrderOpen() const;
    void setSpreadOrderClose(int _spread);
    int getSpreadOrderClose() const;
   
   

   Trade* getTrade() const {
      return trade;
   }
   
   void setTrade(Trade* _trade) {
      this.trade = _trade;
   }

   virtual ErrorType submitNewOrder(int mql4OrderType, double _entryPrice, double _stopLoss, double _takeProfit, double _cancelPrice, double _positionSize)
        {
            if (this.orderType != ORDER_INIT)
            {
                trade.addLogEntry("Order already submitted", true);
                return ORDER_STATUS_NON_RETRIABLE_ERROR;
            }

            int maxSlippage = 4;
            datetime expiration = 0;
            color arrowColor = clrNONE;
            if ((mql4OrderType == OP_BUY) || (mql4OrderType == OP_BUYLIMIT) || (mql4OrderType == OP_BUYSTOP)) arrowColor = Blue;
            if ((mql4OrderType == OP_SELL) || (mql4OrderType == OP_SELLLIMIT) || (mql4OrderType == OP_SELLSTOP)) arrowColor = Red;

            _entryPrice = NormalizeDouble(_entryPrice, Digits);
            _stopLoss = NormalizeDouble(_stopLoss, Digits);
            _takeProfit = NormalizeDouble(_takeProfit, Digits);
            _cancelPrice = NormalizeDouble(_cancelPrice, Digits);
            /// TODO Parametrize
            _positionSize = NormalizeDouble(_positionSize, trade.getLotDigits());


            //will be overrided later on
            OrderType type;

            string orderTypeStr;
            string entryPriceStr = "";
            string stopLossStr = "";
            string takeProfitStr = "";
            string cancelPriceStr = "";
            string positionSizeStr = "";

            switch (mql4OrderType)
            {
                case OP_BUY: { orderTypeStr = "BUY Market Order"; type = ORDER_BUY;  break; }
                case OP_SELL: { orderTypeStr = "SELl Market Order"; type = ORDER_SELL; break; }
                case OP_BUYLIMIT:
                    {
                        orderTypeStr = "BUY Limit Order";
                        type = ORDER_BUY_LIMIT;
                        if (Ask - _entryPrice < MarketInfo(Symbol(), MODE_STOPLEVEL))
                        {
                            trade.addLogEntry("Desired entry price of " + DoubleToString(_entryPrice, Digits) + " is too close to current Ask of " + DoubleToString(Ask, Digits) + " Adjusting to " + DoubleToString(Ask - MarketInfo(Symbol(), MODE_STOPLEVEL), Digits), true);
                            _entryPrice = Ask - MarketInfo(Symbol(), MODE_STOPLEVEL);
                            
                        }
                        break;
                    }
                case OP_SELLLIMIT:
                    {
                        orderTypeStr = "SELL Limit Order";
                        type = ORDER_SELL_LIMIT;
                        if (_entryPrice - Bid < MarketInfo(Symbol(), MODE_STOPLEVEL))
                        {
                            trade.addLogEntry("Desired entry price of " + DoubleToString(_entryPrice, Digits) + " is too close to current Bid of " + DoubleToString(Bid, Digits) + " Adjusting to " + DoubleToString(Bid + MarketInfo(Symbol(), MODE_STOPLEVEL), Digits), true);
                            _entryPrice = Bid + MarketInfo(Symbol(), MODE_STOPLEVEL);
                            
                        }
                        break;
                    }
                case OP_BUYSTOP:
                    {
                        orderTypeStr = "BUY Stop Order";
                        type = ORDER_BUY_STOP;
                        //check if entryPrice is too close to market price and adjust accordingly

                        if (entryPrice - Ask < MarketInfo(Symbol(), MODE_STOPLEVEL))
                        {
                            trade.addLogEntry("Desired entry price of " + DoubleToString(_entryPrice, Digits) + " is too close to current Ask of " + DoubleToString(Ask, Digits) + " Adjusting to " + DoubleToString(Ask + MarketInfo(Symbol(), MODE_STOPLEVEL), Digits), true);
                            _entryPrice = Ask + MarketInfo(Symbol(), MODE_STOPLEVEL);
                            
                        }
                        break;
                    }
                case OP_SELLSTOP:
                    {
                        orderTypeStr = "SELL Stop Order";
                        type = ORDER_SELL_STOP;
                        if (Bid - _entryPrice < MarketInfo(Symbol(), MODE_STOPLEVEL))
                        {
                            trade.addLogEntry("Desired entry price of " + DoubleToString(_entryPrice, Digits) + " is too close to current Bid of " + DoubleToString(Bid, Digits) + " Adjusting to " + DoubleToString(Bid - MarketInfo(Symbol(), MODE_STOPLEVEL), Digits), true);
                            _entryPrice = Bid - MarketInfo(Symbol(), MODE_STOPLEVEL);
                            
                        }
                        break;
                    }
                default: { trade.addLogEntry("Invalid Order Type. Abort Trade", true); return ORDER_STATUS_NON_RETRIABLE_ERROR; }
            }


            if (_entryPrice != 0) entryPriceStr = "; entry price: " + DoubleToString(entryPrice, Digits);
            if (_stopLoss != 0) stopLossStr = "; stop loss: " + DoubleToString(stopLoss, Digits);
            if (_takeProfit != 0) takeProfitStr = "; take profit: " + DoubleToString(takeProfit, Digits);
            if (_cancelPrice != 0) cancelPriceStr = "; cancel price: " + DoubleToString(cancelPrice, Digits);

            ///Parametrize
            positionSizeStr = "; position size: " + DoubleToString(_positionSize, 2) + " lots";

            trade.addLogEntry("Attemting to place " + orderTypeStr + entryPriceStr + stopLossStr + takeProfitStr + cancelPriceStr + positionSizeStr, true);

            int ticket = OrderSend(Symbol(), mql4OrderType, _positionSize, _entryPrice, maxSlippage, _stopLoss, _takeProfit, trade.getId(), this.magicNumber, expiration, arrowColor);
            this.orderTicket = ticket;
            
            ErrorType result = analzeAndProcessResult(trade);
            
            if (result == ORDER_STATUS_NO_ERROR)
            {
                this.entryPrice = _entryPrice;
                this.positionSize = _positionSize;
                this.stopLoss = _stopLoss;
                this.takeProfit = _takeProfit;
                this.cancelPrice = _cancelPrice;
                this.orderType = type;
                if ((mql4OrderType == OP_BUY) || (mql4OrderType == OP_SELL)) {
                    delete this.state;
                    this.state = new Filled(GetPointer(this));
                }
                if ((mql4OrderType == OP_BUYLIMIT) || (mql4OrderType == OP_SELLLIMIT) || (mql4OrderType == OP_BUYSTOP) || (mql4OrderType == OP_SELLSTOP)) {
                    delete this.state;
                    this.state = new Pending(GetPointer(this));
                }
                trade.addLogEntry(1, "Order successfully placed", 
                                        "Order ticket: " + IntegerToString(ticket) + "\n" +
                                        "Order type: " + orderTypeStr + "\n" +
                                        "Entry price: " + DoubleToString(_entryPrice, 5) + "\n" +
                                        "Position size: " + DoubleToString(_positionSize,5) + "\n" +
                                        "Stop loss: " + DoubleToString(_stopLoss, 5) + "\n" +
                                        "Take profit: " + DoubleToString(_takeProfit, 5) + "\n" +
                                        "Cancel price: " + DoubleToString(_cancelPrice, 5)
                                        );
            } else
            {
                trade.addLogEntry(1, "Alert: Order could not be placed - Check Log for details");
            }
            return result;
        }

        virtual ErrorType deleteOrder()
        {
            if ((orderType != ORDER_SELL_LIMIT) && (orderType != ORDER_SELL_STOP) && (orderType != ORDER_BUY_LIMIT) && (orderType == ORDER_SELL_STOP))
            {
                trade.addLogEntry(1, "Filled orded cannot be delete, it must be closed");
                return ORDER_STATUS_NON_RETRIABLE_ERROR;
            }

            trade.addLogEntry(3, "Attemting to delete Order (ticket number: " + IntegerToString(orderTicket) + ")");
            ResetLastError();
            bool success = OrderDelete(orderTicket, Red);
            if (success)
            {
                trade.addLogEntry(2, "Order (" + IntegerToString(orderTicket) +") successfully deleted");
            } else
            {
                trade.addLogEntry(2, "Alert!: Order (" + IntegerToString(orderTicket) + ") could not be deleted - check log for details");
            }


            //TODO include error handling here
            delete(this.state);
            this.state = new Final(GetPointer(this));
            this.orderType = ORDER_FINAL;
            return analzeAndProcessResult(trade);
        }

        virtual ErrorType closeOrder() {
            if ((orderType != ORDER_SELL) && (orderType != ORDER_BUY))
            {
                trade.addLogEntry(1, "Closing the order failed. Order is not filled or already closed.");
                return ORDER_STATUS_NON_RETRIABLE_ERROR;
            }
            trade.addLogEntry(3, "Attemting to close Order (ticket number: " + IntegerToString(orderTicket) + ")");
            ResetLastError();
            
            
            int maxSlippage = 2.0;
            bool success = false;
            if (orderType == ORDER_BUY) {
                success = OrderClose(this.orderTicket, this.positionSize, Bid, maxSlippage, Blue);    
            }
            if (orderType == ORDER_SELL) {
                success = OrderClose(this.orderTicket, this.positionSize, Ask, maxSlippage, Red);  
            }
            
            
            if (success)
            {
                trade.addLogEntry(2, "Order (" + IntegerToString(orderTicket) +") successfully closed");
            } else
            {
                trade.addLogEntry(2, "Alert!: Order (" + IntegerToString(orderTicket) + ") could not be closed - check log for details");
            }

            //TODO include error handling here
            delete(this.state);
            this.state = new Final(GetPointer(this));
            this.orderType = ORDER_FINAL;
            return analzeAndProcessResult(trade);
        }

        
        virtual ErrorType modifyOrder(double newOpenPrice, double newStopLoss, double newTakeProfit)
        {
            if ((orderType == ORDER_INIT) || (orderType == ORDER_FINAL))
            {
                trade.addLogEntry("Order not open", true);
                return ORDER_STATUS_NON_RETRIABLE_ERROR;
            }

            datetime expiration = 0;
            
            color arrowColor = clrNONE;
            if ((orderType == ORDER_BUY) || (orderType == ORDER_BUY_LIMIT) || (orderType == ORDER_BUY_STOP)) arrowColor = Blue;
            if ((orderType == ORDER_SELL) || (orderType == ORDER_SELL_LIMIT) || (orderType == ORDER_SELL_STOP)) arrowColor = Red;

            newOpenPrice = NormalizeDouble(newOpenPrice, Digits);
            newStopLoss = NormalizeDouble(newStopLoss, Digits);
            newTakeProfit = NormalizeDouble(newTakeProfit, Digits);

            string newOpenPriceStr = "";
            string newStopLossStr = "";
            string newTakeProfitStr = "";

            if (newOpenPrice != 0.0) newOpenPriceStr = "; entry price: " + DoubleToString(newOpenPrice, Digits);
            if (newStopLoss != 0.0) newStopLossStr = "; stop loss: " + DoubleToString(newStopLoss, Digits);
            if (newTakeProfit != 0.0) newTakeProfitStr = "; take profit: " + DoubleToString(newTakeProfit, Digits);

            trade.addLogEntry(3, "Attemting to modify order to: NewOpenPrice: " + newOpenPriceStr + " NewStopLoss: " + newStopLossStr + " NewTakeProfit: " + newTakeProfitStr);

            bool res = OrderModify(this.orderTicket, newOpenPrice, newStopLoss, newTakeProfit, expiration, arrowColor);

            ErrorType result = analzeAndProcessResult(trade);

            if (result == ORDER_STATUS_NO_ERROR)
            {
                this.entryPrice = newOpenPrice;
                this.stopLoss = newStopLoss;
                this.takeProfit = newTakeProfit;
                trade.addLogEntry(1, "Order successfully modified", 
                                        "NewOpenPrice: " + newOpenPriceStr + "\n" +
                                        "NewStopLoss: " + newStopLossStr + "\n" +
                                        "NewTakeProfit: " + newTakeProfitStr);
            } else
            {
                trade.addLogEntry(2, "Altert: Order could not be modifed - check log for details.");
            }

            return result;

        }

        void adjustOrder (Stategy* stopLossAdjustmentStrategy, Strategy takeProfitAdjustmentStrategy, Exception* exception) {
            
            
            
        }

        

        static ErrorType analzeAndProcessResult(Trade* trade)
        {
            int result = GetLastError();
            switch (result)
            {
                //No Error
                case 0: return (ORDER_STATUS_NO_ERROR);
                // Not crucial errors                  
                case 4:
                    Alert("Trade server is busy");
                    trade.addLogEntry("Trade server is busy. Waiting 3000ms and then re-try", true);
                    Sleep(3000);
                    return (ORDER_STATUS_RETRIABLE_ERROR);
                case 135:
                    Alert("Price changed. Refreshing Rates");
                    trade.addLogEntry("Price changed. Refreshing Rates and retry", true);
                    RefreshRates();
                    return (ORDER_STATUS_RETRIABLE_ERROR);
                case 136:
                    Alert("No prices. Refreshing Rates and retry");
                    trade.addLogEntry("No prices. Refreshing Rates and retry", true);
                    while (RefreshRates() == false)
                        Sleep(1);
                    return (ORDER_STATUS_RETRIABLE_ERROR);
                case 137:
                    Alert("Broker is busy");
                    trade.addLogEntry("Broker is busy. Waiting 3000ms and then re-try", true);
                    Sleep(3000);
                    return (ORDER_STATUS_RETRIABLE_ERROR);
                case 146:
                    Alert("Trading subsystem is busy.");
                    trade.addLogEntry("Trade system is busy. Waiting 500ms and then re-try", true);
                    Sleep(500);
                    return (ORDER_STATUS_RETRIABLE_ERROR);
                // Critical errors      
                case 2:
                    Alert("Common error.");
                    trade.addLogEntry("Common error. Abort trade", true);
                    return (ORDER_STATUS_NON_RETRIABLE_ERROR);
                case 5:
                    Alert("Old terminal version.");
                    trade.addLogEntry("Old terminal version. Abort trade", true);
                    return (ORDER_STATUS_NON_RETRIABLE_ERROR);
                case 64:
                    Alert("Account blocked.");
                    trade.addLogEntry("Account blocked. Abort trade", true);
                    return (ORDER_STATUS_NON_RETRIABLE_ERROR);
                case 133:
                    Alert("Trading forbidden.");
                    trade.addLogEntry("Trading forbidden. Abort trade", true);
                    return (ORDER_STATUS_NON_RETRIABLE_ERROR);
                case 134:
                    Alert("Not enough money to execute operation.");
                    trade.addLogEntry("Not enough money to execute operation. Abort trade", true);
                    return (ORDER_STATUS_NON_RETRIABLE_ERROR);
                case 4108:
                    Alert("Order ticket was not found. Abort trade");
                    trade.addLogEntry("Order ticket was not found. Abort trade", true);
                    return (ORDER_STATUS_NON_RETRIABLE_ERROR);
                default:
                    Alert("Unknown error, error code: ", result);
                    return (ORDER_STATUS_NON_RETRIABLE_ERROR);
            } //end of switch
        }

};
