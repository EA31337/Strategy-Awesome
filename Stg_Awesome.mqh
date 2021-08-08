/**
 * @file
 * Implements Awesome strategy based on for the Awesome oscillator.
 */

// User input params.
INPUT string __Awesome_Parameters__ = "-- Awesome strategy params --";  // >>> Awesome <<<
INPUT float Awesome_LotSize = 0;                                        // Lot size
INPUT int Awesome_SignalOpenMethod = 8;                                 // Signal open method (-127-127)
INPUT float Awesome_SignalOpenLevel = 0.0f;                             // Signal open level (>0.0001)
INPUT int Awesome_SignalOpenFilterMethod = 32;                          // Signal open filter method (0-1)
INPUT int Awesome_SignalOpenBoostMethod = 0;                            // Signal open boost method (0-1)
INPUT float Awesome_SignalCloseLevel = 0.0f;                            // Signal close level (>0.0001)
INPUT int Awesome_SignalCloseMethod = 2;                                // Signal close method (-127-127)
INPUT int Awesome_PriceStopMethod = 1;                                  // Price stop method
INPUT float Awesome_PriceStopLevel = 0;                                 // Price stop level
INPUT int Awesome_TickFilterMethod = 1;                                 // Tick filter method
INPUT float Awesome_MaxSpread = 4.0;                                    // Max spread to trade (pips)
INPUT short Awesome_Shift = 0;           // Shift (relative to the current bar, 0 - default)
INPUT int Awesome_OrderCloseTime = -20;  // Order close time in mins (>0) or bars (<0)
INPUT string __Awesome_Indi_Awesome_Parameters__ =
    "-- Awesome strategy: Awesome indicator params --";  // >>> Awesome strategy: Awesome indicator <<<
INPUT int Awesome_Indi_Awesome_Shift = 0;                // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_Awesome_Params_Defaults : AOParams {
  Indi_Awesome_Params_Defaults() : AOParams(::Awesome_Indi_Awesome_Shift) {}
} indi_awesome_defaults;

// Defines struct with default user strategy values.
struct Stg_Awesome_Params_Defaults : StgParams {
  Stg_Awesome_Params_Defaults()
      : StgParams(::Awesome_SignalOpenMethod, ::Awesome_SignalOpenFilterMethod, ::Awesome_SignalOpenLevel,
                  ::Awesome_SignalOpenBoostMethod, ::Awesome_SignalCloseMethod, ::Awesome_SignalCloseLevel,
                  ::Awesome_PriceStopMethod, ::Awesome_PriceStopLevel, ::Awesome_TickFilterMethod, ::Awesome_MaxSpread,
                  ::Awesome_Shift, ::Awesome_OrderCloseTime) {}
} stg_awesome_defaults;

// Struct to define strategy parameters to override.
struct Stg_Awesome_Params : StgParams {
  StgParams sparams;

  // Struct constructors.
  Stg_Awesome_Params(StgParams &_sparams) : sparams(stg_awesome_defaults) { sparams = _sparams; }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_Awesome : public Strategy {
 public:
  Stg_Awesome(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_Awesome *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    StgParams _stg_params(stg_awesome_defaults);
#ifdef __config__
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_awesome_m1, stg_awesome_m5, stg_awesome_m15, stg_awesome_m30,
                             stg_awesome_h1, stg_awesome_h4, stg_awesome_h8);
#endif
    // Initialize indicator.
    AOParams _indi_params(_tf);
    _stg_params.SetIndicator(new Indi_AO(_indi_params));
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams(_magic_no, _log_level);
    Strategy *_strat = new Stg_Awesome(_stg_params, _tparams, _cparams, "Awesome");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_AO *_indi = GetIndicator();
    bool _result = _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    IndicatorSignal _signals = _indi.GetSignals(4, _shift);
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        // Signal "saucer": 3 positive columns, medium column is smaller than 2 others.
        _result = _indi[CURR][0] < 0 && _indi.IsIncreasing(3);
        _result &= _indi.IsIncByPct(_level, 0, 0, 2);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        // @todo: Signal: Changing from negative values to positive.
        break;
      case ORDER_TYPE_SELL:
        // Signal "saucer": 3 negative columns, medium column is larger than 2 others.
        _result = _indi[CURR][0] > 0 && _indi.IsDecreasing(3);
        _result &= _indi.IsDecByPct(-_level, 0, 0, 2);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        // @todo: Signal: Changing from positive values to negative.
        break;
    }
    return _result;
  }
};
