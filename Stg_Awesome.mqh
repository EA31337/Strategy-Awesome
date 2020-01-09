//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements Awesome strategy based on for the Awesome oscillator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_AO.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __Awesome_Parameters__ = "-- Awesome strategy params --";  // >>> Awesome <<<
INPUT int Awesome_Active_Tf = 0;  // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32,H4=64...)
INPUT ENUM_TRAIL_TYPE Awesome_TrailingStopMethod = 3;     // Trail stop method
INPUT ENUM_TRAIL_TYPE Awesome_TrailingProfitMethod = 22;  // Trail profit method
INPUT int Awesome_Shift = 0;                              // Shift (relative to the current bar, 0 - default)
INPUT double Awesome_SignalOpenLevel = 0.0004;            // Signal open level (>0.0001)
INPUT int Awesome_SignalBaseMethod = 0;                   // Signal base method (0-1)
INPUT int Awesome_SignalOpenMethod1 = 0;                  // Open condition 1 (0-1023)
INPUT int Awesome_SignalOpenMethod2 = 0;                  // Open condition 2 (0-)
INPUT double Awesome_SignalCloseLevel = 0.0004;           // Signal close level (>0.0001)
INPUT ENUM_MARKET_EVENT Awesome_SignalCloseMethod1 = 0;   // Signal close method 1
INPUT ENUM_MARKET_EVENT Awesome_SignalCloseMethod2 = 0;   // Signal close method 2
INPUT double Awesome_MaxSpread = 6.0;                     // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_Awesome_Params : Stg_Params {
  unsigned int Awesome_Period;
  ENUM_APPLIED_PRICE Awesome_Applied_Price;
  int Awesome_Shift;
  ENUM_TRAIL_TYPE Awesome_TrailingStopMethod;
  ENUM_TRAIL_TYPE Awesome_TrailingProfitMethod;
  double Awesome_SignalOpenLevel;
  long Awesome_SignalBaseMethod;
  long Awesome_SignalOpenMethod1;
  long Awesome_SignalOpenMethod2;
  double Awesome_SignalCloseLevel;
  ENUM_MARKET_EVENT Awesome_SignalCloseMethod1;
  ENUM_MARKET_EVENT Awesome_SignalCloseMethod2;
  double Awesome_MaxSpread;

  // Constructor: Set default param values.
  Stg_Awesome_Params()
      : Awesome_Shift(::Awesome_Shift),
        Awesome_TrailingStopMethod(::Awesome_TrailingStopMethod),
        Awesome_TrailingProfitMethod(::Awesome_TrailingProfitMethod),
        Awesome_SignalOpenLevel(::Awesome_SignalOpenLevel),
        Awesome_SignalBaseMethod(::Awesome_SignalBaseMethod),
        Awesome_SignalOpenMethod1(::Awesome_SignalOpenMethod1),
        Awesome_SignalOpenMethod2(::Awesome_SignalOpenMethod2),
        Awesome_SignalCloseLevel(::Awesome_SignalCloseLevel),
        Awesome_SignalCloseMethod1(::Awesome_SignalCloseMethod1),
        Awesome_SignalCloseMethod2(::Awesome_SignalCloseMethod2),
        Awesome_MaxSpread(::Awesome_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_Awesome : public Strategy {
 public:
  Stg_Awesome(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_Awesome *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_Awesome_Params _params;
    switch (_tf) {
      case PERIOD_M1: {
        Stg_Awesome_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_Awesome_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_Awesome_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_Awesome_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_Awesome_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_Awesome_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    IndicatorParams ao_iparams(10, INDI_AO);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_AO(ao_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.Awesome_SignalBaseMethod, _params.Awesome_SignalOpenMethod1,
                       _params.Awesome_SignalOpenMethod2, _params.Awesome_SignalCloseMethod1,
                       _params.Awesome_SignalCloseMethod2, _params.Awesome_SignalOpenLevel,
                       _params.Awesome_SignalCloseLevel);
    sparams.SetStops(_params.Awesome_TrailingProfitMethod, _params.Awesome_TrailingStopMethod);
    sparams.SetMaxSpread(_params.Awesome_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Awesome(sparams, "Awesome");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double ao_0 = ((Indi_AO *)this.Data()).GetValue(0);
    double ao_1 = ((Indi_AO *)this.Data()).GetValue(1);
    double ao_2 = ((Indi_AO *)this.Data()).GetValue(2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level == EMPTY) _signal_level = GetSignalOpenLevel();
    switch (_cmd) {
      /*
        //7. Awesome Oscillator
        //Buy: 1. Signal "saucer" (3 positive columns, medium column is smaller than 2 others); 2. Changing from
        negative values to positive.
        //Sell: 1. Signal "saucer" (3 negative columns, medium column is larger than 2 others); 2. Changing from
        positive values to negative. if
        ((iAO(NULL,piao,2)>0&&iAO(NULL,piao,1)>0&&iAO(NULL,piao,0)>0&&iAO(NULL,piao,1)<iAO(NULL,piao,2)&&iAO(NULL,piao,1)<iAO(NULL,piao,0))||(iAO(NULL,piao,1)<0&&iAO(NULL,piao,0)>0))
        {f7=1;}
        if
        ((iAO(NULL,piao,2)<0&&iAO(NULL,piao,1)<0&&iAO(NULL,piao,0)<0&&iAO(NULL,piao,1)>iAO(NULL,piao,2)&&iAO(NULL,piao,1)>iAO(NULL,piao,0))||(iAO(NULL,piao,1)>0&&iAO(NULL,piao,0)<0))
        {f7=-1;}
      */
      case ORDER_TYPE_BUY:
        /*
          bool _result = Awesome_0[LINE_LOWER] != 0.0 || Awesome_1[LINE_LOWER] != 0.0 || Awesome_2[LINE_LOWER] != 0.0;
          if (METHOD(_signal_method, 0)) _result &= Open[CURR] > Close[CURR];
          if (METHOD(_signal_method, 1)) _result &= !Awesome_On_Sell(tf);
          if (METHOD(_signal_method, 2)) _result &= Awesome_On_Buy(fmin(period + 1, M30));
          if (METHOD(_signal_method, 3)) _result &= Awesome_On_Buy(M30);
          if (METHOD(_signal_method, 4)) _result &= Awesome_2[LINE_LOWER] != 0.0;
          if (METHOD(_signal_method, 5)) _result &= !Awesome_On_Sell(M30);
          */
        break;
      case ORDER_TYPE_SELL:
        /*
          bool _result = Awesome_0[LINE_UPPER] != 0.0 || Awesome_1[LINE_UPPER] != 0.0 || Awesome_2[LINE_UPPER] != 0.0;
          if (METHOD(_signal_method, 0)) _result &= Open[CURR] < Close[CURR];
          if (METHOD(_signal_method, 1)) _result &= !Awesome_On_Buy(tf);
          if (METHOD(_signal_method, 2)) _result &= Awesome_On_Sell(fmin(period + 1, M30));
          if (METHOD(_signal_method, 3)) _result &= Awesome_On_Sell(M30);
          if (METHOD(_signal_method, 4)) _result &= Awesome_2[LINE_UPPER] != 0.0;
          if (METHOD(_signal_method, 5)) _result &= !Awesome_On_Buy(M30);
          */
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};
